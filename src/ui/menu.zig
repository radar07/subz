const std = @import("std");
const terminal = @import("terminal.zig");
const types = @import("../api/types.zig");

const Terminal = terminal.Terminal;
const Color = terminal.Color;
const Subtitle = types.Subtitle;

/// Show interactive menu for subtitle selection
/// Returns the index of selected subtitle, or null if cancelled
pub fn showMenu(
    _: std.mem.Allocator,
    subtitles: []const Subtitle,
) !?usize {
    if (subtitles.len == 0) return null;

    var term = try Terminal.init();
    defer term.deinit();

    var selected: usize = 0;

    while (true) {
        term.clearScreen();
        term.moveCursor(1, 1);

        // Print title
        std.debug.print("{s}{s}Select subtitle to download:{s}\n\n", .{
            Color.bold,
            Color.cyan,
            Color.reset,
        });

        // Print subtitle list
        for (subtitles, 0..) |sub, i| {
            if (i == selected) {
                // Highlighted selection
                std.debug.print("{s}{s}  > ", .{ Color.bg_green, Color.bold });
            } else {
                std.debug.print("    ", .{});
            }

            std.debug.print("[{d}] {s} - {s}", .{
                i + 1,
                sub.display_name,
                sub.media_name,
            });

            if (i == selected) {
                std.debug.print("{s}", .{Color.reset});
            }
            std.debug.print("\n", .{});

            // Print details
            std.debug.print("      {s}Format:{s} {s} | {s}Source:{s} {s}", .{
                Color.dim,
                Color.reset,
                sub.format,
                Color.dim,
                Color.reset,
                sub.source,
            });

            if (sub.is_hearing_impaired) {
                std.debug.print(" | {s}HI{s}", .{ Color.yellow, Color.reset });
            }

            std.debug.print("\n", .{});
        }

        // Print instructions
        std.debug.print("\n{s}↑↓{s} Navigate | {s}Enter{s} Select | {s}ESC{s} Cancel\n", .{
            Color.green,
            Color.reset,
            Color.green,
            Color.reset,
            Color.red,
            Color.reset,
        });

        // Read key input
        const key = try term.readKey();
        switch (key) {
            .up => {
                if (selected > 0) {
                    selected -= 1;
                }
            },
            .down => {
                if (selected < subtitles.len - 1) {
                    selected += 1;
                }
            },
            .enter => {
                // Clear screen before returning
                term.clearScreen();
                return selected;
            },
            .escape, .ctrl_c => {
                // Clear screen before returning
                term.clearScreen();
                return null;
            },
            else => {},
        }
    }
}
