const std = @import("std");

/// Simple HTTP client wrapper for GET requests
pub const HttpClient = struct {
    allocator: std.mem.Allocator,
    io_threaded: *std.Io.Threaded,
    client: std.http.Client,

    pub fn init(allocator: std.mem.Allocator) !HttpClient {
        const io_threaded = try allocator.create(std.Io.Threaded);
        io_threaded.* = std.Io.Threaded.init(allocator);

        return .{
            .allocator = allocator,
            .io_threaded = io_threaded,
            .client = std.http.Client{
                .allocator = allocator,
                .io = io_threaded.io(),
            },
        };
    }

    pub fn deinit(self: *HttpClient) void {
        self.client.deinit();
        self.allocator.destroy(self.io_threaded);
    }

    /// Perform HTTP GET request and return response body
    pub fn get(self: *HttpClient, url: []const u8) ![]u8 {
        // Use the request API directly with a manual read
        const uri = try std.Uri.parse(url);
        var req = try self.client.request(.GET, uri, .{});
        defer req.deinit();

        try req.sendBodiless();

        var redirect_buffer: [1024]u8 = undefined;
        var response = try req.receiveHead(&redirect_buffer);

        // Read the body regardless of status
        var transfer_buffer: [4096]u8 = undefined;
        var decompress_buffer: [65536]u8 = undefined; // Must be at least flate.max_window_len
        var decompress: std.http.Decompress = undefined;
        const reader = response.readerDecompressing(&transfer_buffer, &decompress, &decompress_buffer);

        const body = try reader.allocRemaining(self.allocator, .unlimited);

        // Check status after reading body
        if (response.head.status != .ok) {
            // Log the response body for debugging
            if (body.len > 0) {
                std.log.err("HTTP request failed with status: {} - Response: {s}", .{ response.head.status, body });
            } else {
                std.log.err("HTTP request failed with status: {}", .{response.head.status});
            }
            // For 400 with "No subtitles found", this is not a connection error
            if (response.head.status == .bad_request) {
                // Return empty response instead of error
                // The caller will see an empty JSON array
                return body;
            }
            self.allocator.free(body);
            return error.HttpRequestFailed;
        }

        return body;
    }

    /// Download file from URL and save to disk
    pub fn downloadFile(self: *HttpClient, url: []const u8, filename: []const u8) !void {
        const data = try self.get(url);
        defer self.allocator.free(data);

        const file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();

        try file.writeAll(data);
    }
};
