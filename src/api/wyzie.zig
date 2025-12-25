const std = @import("std");
const types = @import("types.zig");
const HttpClient = @import("http_client.zig").HttpClient;

const Subtitle = types.Subtitle;

/// Search subtitles from Wyzie Subs API
pub fn searchSubtitles(
    allocator: std.mem.Allocator,
    imdb_id: []const u8,
    language: []const u8,
    season: ?u32,
    episode: ?u32,
) ![]Subtitle {
    var client = try HttpClient.init(allocator);
    defer client.deinit();

    // Build URL
    const url = if (season != null and episode != null)
        try std.fmt.allocPrint(
            allocator,
            "https://sub.wyzie.ru/search?id={s}&language={s}&season={d}&episode={d}",
            .{ imdb_id, language, season.?, episode.? },
        )
    else if (season != null)
        try std.fmt.allocPrint(
            allocator,
            "https://sub.wyzie.ru/search?id={s}&language={s}&season={d}",
            .{ imdb_id, language, season.? },
        )
    else if (episode != null)
        try std.fmt.allocPrint(
            allocator,
            "https://sub.wyzie.ru/search?id={s}&language={s}&episode={d}",
            .{ imdb_id, language, episode.? },
        )
    else
        try std.fmt.allocPrint(
            allocator,
            "https://sub.wyzie.ru/search?id={s}&language={s}",
            .{ imdb_id, language },
        );
    defer allocator.free(url);

    std.log.info("Fetching: {s}", .{url});

    // Make HTTP request
    const response_body = try client.get(url);
    defer allocator.free(response_body);

    std.log.info("Response body length: {d}", .{response_body.len});
    if (response_body.len > 0 and response_body.len < 500) {
        std.log.info("Response body: {s}", .{response_body});
    }

    // Parse JSON response
    return try parseSubtitlesJson(allocator, response_body);
}

/// Parse Wyzie Subs JSON response into Subtitle array
fn parseSubtitlesJson(allocator: std.mem.Allocator, json_data: []const u8) ![]Subtitle {
    const parsed = try std.json.parseFromSlice(
        std.json.Value,
        allocator,
        json_data,
        .{},
    );
    defer parsed.deinit();

    const root = parsed.value;

    // Wyzie returns an array of subtitle objects, or an error object
    const array = switch (root) {
        .array => |arr| arr,
        .object => |obj| {
            // Check if this is an error response
            if (getString(obj, "message")) |msg| {
                std.log.info("API message: {s}", .{msg});
            }
            // Return empty array for error responses
            return &[_]Subtitle{};
        },
        else => {
            std.log.err("Expected JSON array or object, got: {}", .{root});
            return error.InvalidJson;
        },
    };

    var subtitles = std.ArrayList(Subtitle){};
    errdefer {
        for (subtitles.items) |*sub| {
            sub.deinit(allocator);
        }
        subtitles.deinit(allocator);
    }

    for (array.items) |item| {
        const obj = switch (item) {
            .object => |o| o,
            else => continue,
        };

        const subtitle = Subtitle{
            .id = try allocator.dupe(u8, getString(obj, "id") orelse continue),
            .url = try allocator.dupe(u8, getString(obj, "url") orelse continue),
            .language = try allocator.dupe(u8, getString(obj, "language") orelse continue),
            .display_name = try allocator.dupe(u8, getString(obj, "display") orelse continue),
            .format = try allocator.dupe(u8, getString(obj, "format") orelse continue),
            .encoding = try allocator.dupe(u8, getString(obj, "encoding") orelse continue),
            .media_name = try allocator.dupe(u8, getString(obj, "media") orelse continue),
            .is_hearing_impaired = getBool(obj, "isHearingImpaired") orelse false,
            .source = try allocator.dupe(u8, getString(obj, "source") orelse continue),
        };

        try subtitles.append(allocator, subtitle);
    }

    return subtitles.toOwnedSlice(allocator);
}

/// Helper to get string value from JSON object
fn getString(obj: std.json.ObjectMap, key: []const u8) ?[]const u8 {
    const value = obj.get(key) orelse return null;
    return switch (value) {
        .string => |s| s,
        else => null,
    };
}

/// Helper to get boolean value from JSON object
fn getBool(obj: std.json.ObjectMap, key: []const u8) ?bool {
    const value = obj.get(key) orelse return null;
    return switch (value) {
        .bool => |b| b,
        else => null,
    };
}
