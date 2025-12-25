const std = @import("std");
const args_parser = @import("cli/args.zig");
const wyzie = @import("api/wyzie.zig");
const menu = @import("ui/menu.zig");
const http_client = @import("api/http_client.zig");
const Color = @import("ui/terminal.zig").Color;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse arguments
    const args = args_parser.parseArgs(allocator) catch |err| {
        switch (err) {
            error.MissingImdbId => {
                std.debug.print("{s}Error:{s} Missing IMDB ID argument\n", .{ Color.red, Color.reset });
                std.debug.print("Use {s}subz --help{s} for usage information\n\n", .{ Color.cyan, Color.reset });
            },
            error.MissingLanguage => {
                std.debug.print("{s}Error:{s} Missing language argument after -l/--language\n", .{ Color.red, Color.reset });
            },
            error.MissingSeason => {
                std.debug.print("{s}Error:{s} Missing season argument after -s/--season\n", .{ Color.red, Color.reset });
            },
            error.MissingEpisode => {
                std.debug.print("{s}Error:{s} Missing episode argument after -e/--episode\n", .{ Color.red, Color.reset });
            },
            else => {
                std.debug.print("{s}Error:{s} Failed to parse arguments: {}\n", .{ Color.red, Color.reset, err });
            },
        }
        return err;
    };

    if (args.help) {
        args_parser.printHelp();
        return;
    }

    if (args.version) {
        args_parser.printVersion();
        return;
    }

    // Validate IMDB ID format
    if (!args_parser.isValidImdbId(args.imdb_id)) {
        std.debug.print("{s}Error:{s} Invalid IMDB ID format: {s}\n", .{ Color.red, Color.reset, args.imdb_id });
        std.debug.print("Expected format: tt followed by 7-8 digits (e.g., tt0133093)\n", .{});
        std.debug.print("Get IMDB IDs from: https://www.imdb.com/\n\n", .{});
        return error.InvalidImdbId;
    }

    // Search for subtitles
    std.debug.print("{s}🔍 Searching subtitles for {s}...{s}\n", .{ Color.cyan, args.imdb_id, Color.reset });

    const subtitles = wyzie.searchSubtitles(
        allocator,
        args.imdb_id,
        args.language,
        args.season,
        args.episode,
    ) catch |err| {
        switch (err) {
            error.HttpRequestFailed => {
                std.debug.print("{s}Error:{s} Failed to connect to subtitle service\n", .{ Color.red, Color.reset });
                std.debug.print("→ Check your internet connection\n", .{});
                std.debug.print("→ Try again in a few moments\n\n", .{});
            },
            error.InvalidJson => {
                std.debug.print("{s}Error:{s} Invalid response from subtitle service\n", .{ Color.red, Color.reset });
                std.debug.print("→ The service might be temporarily unavailable\n", .{});
                std.debug.print("→ Try again later\n\n", .{});
            },
            else => {
                std.debug.print("{s}Error:{s} Failed to search subtitles: {}\n\n", .{ Color.red, Color.reset, err });
            },
        }
        return err;
    };
    defer {
        for (subtitles) |*sub| {
            sub.deinit(allocator);
        }
        allocator.free(subtitles);
    }

    if (subtitles.len == 0) {
        std.debug.print("{s}Error:{s} No subtitles found for {s} in language '{s}'\n", .{
            Color.red,
            Color.reset,
            args.imdb_id,
            args.language,
        });
        std.debug.print("→ Try a different language code: -l en, -l es, -l fr\n", .{});
        std.debug.print("→ Check if the IMDB ID is correct\n", .{});
        if (args.season != null or args.episode != null) {
            std.debug.print("→ Verify season/episode numbers are correct\n", .{});
        }
        std.debug.print("\n", .{});
        return error.NoSubtitlesFound;
    }

    std.debug.print("{s}✓ Found {d} subtitle(s){s}\n\n", .{ Color.green, subtitles.len, Color.reset });

    // Select subtitle
    const selected_index = if (subtitles.len == 1) blk: {
        std.debug.print("Auto-selecting single result...\n", .{});
        break :blk 0;
    } else blk: {
        const index = try menu.showMenu(allocator, subtitles);
        if (index == null) {
            std.debug.print("{s}Selection cancelled{s}\n", .{ Color.yellow, Color.reset });
            return;
        }
        break :blk index.?;
    };

    const subtitle = subtitles[selected_index];

    // Download subtitle
    std.debug.print("\n{s}⬇️  Downloading:{s} {s}\n", .{ Color.cyan, Color.reset, subtitle.media_name });

    const filename = try subtitle.getFilename(allocator);
    defer allocator.free(filename);

    var client = try http_client.HttpClient.init(allocator);
    defer client.deinit();

    client.downloadFile(subtitle.url, filename) catch |err| {
        std.debug.print("{s}Error:{s} Failed to download subtitle: {}\n", .{ Color.red, Color.reset, err });
        std.debug.print("→ The subtitle file may have been removed\n", .{});
        std.debug.print("→ Try selecting a different subtitle\n\n", .{});
        return err;
    };

    std.debug.print("{s}✓ Downloaded:{s} {s}\n", .{ Color.green, Color.reset, filename });
    std.debug.print("\n{s}Done! ✨{s}\n", .{ Color.bold, Color.reset });
}
