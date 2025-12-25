const std = @import("std");

pub const Key = enum {
    up,
    down,
    enter,
    escape,
    ctrl_c,
    unknown,
};

pub const Terminal = struct {
    original_termios: std.posix.termios,
    stdin_handle: std.posix.fd_t,

    pub fn init() !Terminal {
        const stdin = std.Io.File.stdin();

        // Save original terminal settings
        const original = try std.posix.tcgetattr(stdin.handle);

        // Enter raw mode
        var raw = original;
        raw.lflag.ICANON = false;
        raw.lflag.ECHO = false;
        raw.lflag.ISIG = false;
        raw.iflag.IXON = false;
        raw.iflag.ICRNL = false;
        raw.oflag.OPOST = false;

        try std.posix.tcsetattr(stdin.handle, .FLUSH, raw);

        // Hide cursor
        std.debug.print("\x1b[?25l", .{});

        return .{
            .original_termios = original,
            .stdin_handle = stdin.handle,
        };
    }

    pub fn deinit(self: *Terminal) void {
        // Show cursor
        std.debug.print("\x1b[?25h", .{});

        // Restore terminal settings
        std.posix.tcsetattr(self.stdin_handle, .FLUSH, self.original_termios) catch {};
    }

    pub fn clearScreen(_: *Terminal) void {
        std.debug.print("\x1b[2J\x1b[H", .{});
    }

    pub fn moveCursor(_: *Terminal, row: u16, col: u16) void {
        std.debug.print("\x1b[{d};{d}H", .{ row, col });
    }

    pub fn readKey(self: *Terminal) !Key {
        var buffer: [1]u8 = undefined;
        _ = try std.posix.read(self.stdin_handle, &buffer);
        const byte = buffer[0];

        if (byte == '\x1b') { // Escape sequence
            // Try to read next bytes
            _ = std.posix.read(self.stdin_handle, &buffer) catch {
                return .escape;
            };
            const next = buffer[0];

            if (next == '[') {
                _ = try std.posix.read(self.stdin_handle, &buffer);
                const arrow = buffer[0];
                return switch (arrow) {
                    'A' => .up,
                    'B' => .down,
                    else => .unknown,
                };
            }
            return .escape;
        }

        return switch (byte) {
            '\r', '\n' => .enter,
            '\x03' => .ctrl_c, // Ctrl+C
            else => .unknown,
        };
    }
};

/// ANSI color codes for output
pub const Color = struct {
    pub const reset = "\x1b[0m";
    pub const bold = "\x1b[1m";
    pub const dim = "\x1b[2m";
    pub const green = "\x1b[32m";
    pub const yellow = "\x1b[33m";
    pub const blue = "\x1b[34m";
    pub const cyan = "\x1b[36m";
    pub const red = "\x1b[31m";
    pub const bg_green = "\x1b[42m";
    pub const bg_blue = "\x1b[44m";
};
