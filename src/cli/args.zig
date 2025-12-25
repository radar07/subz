const std = @import("std");

pub const Args = struct {
    imdb_id: []const u8,
    language: []const u8 = "en",
    season: ?u32 = null,
    episode: ?u32 = null,
    help: bool = false,
    version: bool = false,
};

pub fn parseArgs(allocator: std.mem.Allocator) !Args {
    var args_iter = try std.process.argsWithAllocator(allocator);
    defer args_iter.deinit();

    // Skip program name
    _ = args_iter.skip();

    var result = Args{
        .imdb_id = "",
    };

    while (args_iter.next()) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            result.help = true;
            return result;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            result.version = true;
            return result;
        } else if (std.mem.eql(u8, arg, "-l") or std.mem.eql(u8, arg, "--language")) {
            const lang = args_iter.next() orelse {
                std.log.err("Missing language argument", .{});
                return error.MissingLanguage;
            };
            result.language = lang;
        } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--season")) {
            const season_str = args_iter.next() orelse {
                std.log.err("Missing season argument", .{});
                return error.MissingSeason;
            };
            result.season = try std.fmt.parseInt(u32, season_str, 10);
        } else if (std.mem.eql(u8, arg, "-e") or std.mem.eql(u8, arg, "--episode")) {
            const episode_str = args_iter.next() orelse {
                std.log.err("Missing episode argument", .{});
                return error.MissingEpisode;
            };
            result.episode = try std.fmt.parseInt(u32, episode_str, 10);
        } else if (result.imdb_id.len == 0) {
            result.imdb_id = arg;
        } else {
            std.log.err("Unknown argument: {s}", .{arg});
            return error.UnknownArgument;
        }
    }

    if (result.imdb_id.len == 0 and !result.help and !result.version) {
        std.log.err("Missing IMDB ID argument", .{});
        return error.MissingImdbId;
    }

    return result;
}

pub fn printHelp() void {
    const help_text =
        \\subz - Subtitle Downloader
        \\
        \\Usage: subz [OPTIONS] <imdb_id>
        \\
        \\Arguments:
        \\  <imdb_id>                IMDB ID (e.g., tt0133093 for The Matrix)
        \\
        \\Options:
        \\  -l, --language <LANG>    Language code (default: en)
        \\                           Common: en, es, fr, de, pt, ko, ja, zh
        \\  -s, --season <NUM>       Season number (for TV shows)
        \\  -e, --episode <NUM>      Episode number (for TV shows)
        \\  -h, --help               Show this help message
        \\  -v, --version            Show version information
        \\
        \\Examples:
        \\  subz tt0133093                  # The Matrix (English)
        \\  subz tt0133093 -l es            # Spanish subtitles
        \\  subz tt0944947 -s 1 -e 1        # Game of Thrones S01E01
        \\
        \\Get IMDB IDs from: https://www.imdb.com/
        \\IMDB ID format: tt followed by 7-8 digits (found in movie URL)
        \\
    ;
    std.debug.print("{s}\n", .{help_text});
}

pub fn printVersion() void {
    std.debug.print("subz version 0.1.0\n", .{});
}

/// Validate IMDB ID format (tt followed by digits)
pub fn isValidImdbId(imdb_id: []const u8) bool {
    if (imdb_id.len < 9 or imdb_id.len > 10) return false;
    if (!std.mem.startsWith(u8, imdb_id, "tt")) return false;

    for (imdb_id[2..]) |c| {
        if (!std.ascii.isDigit(c)) return false;
    }

    return true;
}
