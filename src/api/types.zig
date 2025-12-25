const std = @import("std");

/// Represents a subtitle search result from Wyzie Subs API
pub const Subtitle = struct {
    id: []const u8,
    url: []const u8,
    language: []const u8,
    display_name: []const u8,
    format: []const u8,
    encoding: []const u8,
    media_name: []const u8,
    is_hearing_impaired: bool,
    source: []const u8,

    /// Extracts filename from URL or generates one
    pub fn getFilename(self: *const Subtitle, allocator: std.mem.Allocator) ![]u8 {
        // Try to extract filename from media_name or use a generated one
        const sanitized = try sanitizeFilename(allocator, self.media_name);
        defer allocator.free(sanitized);

        return std.fmt.allocPrint(
            allocator,
            "{s}.{s}",
            .{ sanitized, self.format },
        );
    }

    pub fn deinit(self: *Subtitle, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.url);
        allocator.free(self.language);
        allocator.free(self.display_name);
        allocator.free(self.format);
        allocator.free(self.encoding);
        allocator.free(self.media_name);
        allocator.free(self.source);
    }
};

/// Sanitize filename by removing/replacing invalid characters
fn sanitizeFilename(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    var result = try allocator.alloc(u8, name.len);
    var i: usize = 0;

    for (name) |c| {
        switch (c) {
            '/', '\\', ':', '*', '?', '"', '<', '>', '|' => result[i] = '_',
            ' ' => result[i] = '.',
            else => result[i] = c,
        }
        i += 1;
    }

    return result;
}
