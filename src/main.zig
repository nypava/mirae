const rl = @import("raylib");
const std = @import("std");
const utils = @import("utils/root.zig");

const print = std.debug.print;

const FPS = 60;

const PositionType = struct {
    x: f32,
    y: f32,
};

const SizeType = struct {
    w: ?f32,
    h: ?f32,
};

const TimerArgsType = struct {
    unit: u8,
    value: []const u8,
};

const ArgsType = struct {
    time: *TimerArgsType,
    alarm: bool
};

const LINE_WIDTH = 10;
const FONT_SIZE = 80.0;
const HELP_MESSAGE = 
    \\
    \\ Mirae - simple timer / stopwatch 
    \\ 
    \\ Usage: 
    \\  mirae [time] [unit] [options]
    \\ 
    \\ Time formats
    \\  mirae HH:MM:SS          set timer using full format
    \\  mirae HH:MM h           set timer in hour and minute
    \\  mirae MM:SS [m]         set timer in minute and second
    \\  mirae <value> [s|m|h]   set timer with unit (second, minute, hour) 
    \\ 
    \\ Stopwatch Mode
    \\  mirae                   if no <time> is provided, mirae runs as stop watch mode
    \\
    \\ Options
    \\  -a, --alarm      play alarm sound when time is up 
    \\  -h, --help    Show this help message
    \\
;

const options = .{
    .alarm = .{"-a", "--alarm"},
    .help = .{"--help", "-h"}
};

const time_units = [_]u8{'s', 'm', 'h'};

fn textColor(second: u32, warning: bool)  rl.Color{
    if (!warning) {
        return .light_gray;
    }

    if (second % 2 == 0) {
        return rl.Color{.r = 177, .g = 87, .b = 87, .a = 255};
    } else {
        return .light_gray;
    }
}

fn printString(str: []const u8) !void {
    var buf: [4096]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&buf);
    stdout.interface.print("{s}", .{str}) catch return stdout.err.?;
    stdout.interface.flush() catch return stdout.err.?;
}

fn argsParser(input: []const u8, args: *ArgsType, buffer: *[100]u8) !void {

    var is_int: bool = true;

    const f_len = utils.removeFromString(input, ':',  buffer);

    _ =  std.fmt.parseInt(u32, buffer[0..f_len], 10) catch {
        is_int = false;
    };
   
    if (std.mem.eql(u8, input, options.alarm[0]) or std.mem.eql(u8, input, options.alarm[1])) {
        args.alarm = true;
        return;
    }

    if (std.mem.eql(u8, input, options.help[0]) or std.mem.eql(u8, input, options.help[1])) {
        try printString(HELP_MESSAGE);
        std.process.exit(0);
        return;
    }
    if (is_int) {
        args.time.value = input;
        return;
    } else {
        for (time_units) |unit| {
            if (input[0] == unit ) {
                args.time.unit = input[0];
                return;
            }
        }
    }

    try printString("Invalid argument ");
    try printString(input);
    try printString(HELP_MESSAGE);
    std.process.exit(0);
    return;
}

pub fn main() anyerror!void {
    var args = std.process.args();
    _ = args.next();

    var timer_args: TimerArgsType = .{
        .unit = 's',
        .value = "0",
    };

    var parsed_args: ArgsType = .{
        .time = &timer_args,
        .alarm = false,
    };

    while (args.next()) |arg| {
        var buffer: [100]u8 = undefined;
        try argsParser(arg, &parsed_args,  &buffer);
    }

    const time_second:u32 = try utils.calculateTime(timer_args.value, timer_args.unit);
    const f_time_second: f32 = @floatFromInt(time_second);

    rl.initAudioDevice();
    const alarm_audio = rl.loadMusicStream("asset/alarm_sound.wav");
    rl.playMusicStream(try alarm_audio);

    // GUI 
    const screenWidth = 600;
    const screenHeight = 250;

    rl.initWindow(screenWidth, screenHeight, "Mirae");
    defer rl.closeWindow(); 

    rl.setTargetFPS(FPS); 

    var gui_time: f32 = 0;
    var rectangle_size: SizeType = .{
        .h = null,
        .w = null 
    };


    var user_ratio: f32 = 0;

    var stop: bool = false;
    var warning: bool = false;

    while (!rl.windowShouldClose()) { 
    
        // Keyboard events handle
        if (rl.isKeyPressed(.space) or rl.isKeyPressed(.p)){
            stop = !stop;
        } else if (rl.isKeyPressed(.w)) {
            warning = !warning;
        } else if (rl.isKeyPressed(.kp_add)){
            user_ratio += 0.1;
        } else if (rl.isKeyPressed(.minus)){
            user_ratio -= 0.1;
        } else if (rl.isKeyPressed(.r)) {
            gui_time = 0;
        }

        const delta_time = rl.getFrameTime();
        gui_time += if(stop) 0 else delta_time ;

        const float_time: f32 = if (time_second != 0) @max(@as(f32, @floatFromInt(time_second)) - gui_time, 0)
                                else gui_time;

        const int_time: u32 = @intFromFloat(@ceil(float_time));

        if (((f_time_second - float_time) / f_time_second) >= 0.8) {
            warning = true;
        }

        if (int_time == 0 and parsed_args.alarm) {
            rl.updateMusicStream(try alarm_audio);
        }
        
        const screen_ratio: f32 =  @as(f32, @floatFromInt(rl.getScreenWidth())) / 600.0 + user_ratio;  
        var buffer: [32]u8 = undefined;
        const hours: u32 = int_time / 3600;
        const minutes: u32 = (int_time % 3600) / 60;
        const seconds: u32 = int_time % 60;
        const timer_str = try std.fmt.bufPrintZ(&buffer, "{:02}:{:02}:{:02}", .{ hours, minutes, seconds });
            
        const font_size = FONT_SIZE * screen_ratio;
        const text_size = rl.measureTextEx(try rl.getFontDefault(), timer_str, font_size, 6 * screen_ratio);
        const text_position = utils.guiUtils.calculateCenter(text_size.x, text_size.y);

        // const rectangle_padding: SizeType = .{
        //     .w = 100.0 * screen_ratio,
        //     .h = 60.0 * screen_ratio,
        // };

        rectangle_size.h = @floatFromInt(rl.getScreenHeight());
        rectangle_size.w = @floatFromInt(rl.getScreenWidth());

        const rectangle_position = utils.guiUtils.calculateCenter(rectangle_size.w.?, rectangle_size.h.?);

        rl.beginDrawing();

        rl.drawText(
            timer_str, 
            @as(i32, @intFromFloat(text_position.x)), 
            @as(i32, @intFromFloat(text_position.y)), 
            @as(i32, @intFromFloat(font_size)),
            textColor(seconds, warning)
        );

        const rx:f32  = rectangle_position.x;
        const ry:f32  = rectangle_position.y;
        const rw:f32  = rectangle_size.w.?;
        const rh:f32  = rectangle_size.h.?;
        const rw_int:i32  =  @intFromFloat(@ceil(rw));
        const rh_int:i32  =  @intFromFloat(@ceil(rh));

        const primeter:f32 = (@as(f32, @floatFromInt(rh_int)) + @as(f32, @floatFromInt(rw_int))) * 2;

        var progress_length:i32 = if(time_second > 0) @intFromFloat(float_time/(@as(f32, @floatFromInt(time_second))) * primeter)
                                  else 0;

        // Progress rectangle
        if (progress_length > 0) {
            const right_progress = @min(progress_length, rh_int);
            progress_length -= right_progress;

            const bottom_progress = @min(progress_length, rw_int);
            progress_length -= bottom_progress;

            const left_progress = @min(progress_length, rh_int);   
            progress_length -= left_progress;

            const top_progress = @min(progress_length, rw_int);

            rl.drawLineEx(
                .{.x = rx, .y = ry},
                .{.x = rx + @as(f32, @floatFromInt(top_progress)), .y = ry},
                LINE_WIDTH * screen_ratio,
                .light_gray
            );
            rl.drawLineEx(
                .{.x = rx + rw - (1 * screen_ratio), .y = ry},
                .{.x = rx + rw - (1 * screen_ratio), .y = ry + @as(f32, @floatFromInt(right_progress))},
                LINE_WIDTH * screen_ratio,
                .light_gray
            );
            rl.drawLineEx(
                .{.x = rx + rw, .y = ry + rh},
                .{.x = rx + rw - @as(f32, @floatFromInt(bottom_progress)), .y = ry + rh},
                LINE_WIDTH * screen_ratio,
                .light_gray
            );
            rl.drawLineEx(
                .{.x = rx + (1 * screen_ratio), .y = ry + rh},
                .{.x = rx + (1 * screen_ratio), .y = ry + rh - @as(f32, @floatFromInt(left_progress))},
                LINE_WIDTH * screen_ratio,
                .light_gray
            );

        }
        defer rl.endDrawing();
        rl.clearBackground(.black);
    }
}
