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

const ArgsType = struct {
    unit: u8,
    value: []const u8,
};

const time_units = [_]u8{'s', 'm', 'h'};

fn argsParser(input: []const u8, args: *ArgsType, buffer: *[100]u8) !void {
    var is_int: bool = true;

    const f_len = utils.removeFromString(input, ':',  buffer);

    _ =  std.fmt.parseInt(u32, buffer[0..f_len], 10) catch {
        is_int = false;
    };
    
    if (is_int) {
        args.value = input;
        return;
    } else {
        for (time_units) |unit| {
            if (input[0] == unit ) {
                args.unit = input[0];
                return;
            }
        }
    }
}

pub fn main() anyerror!void {
    var args = std.process.args();
    _ = args.next();
    
    // var input_time: u32 = 0;
    var timer_args: ArgsType = .{
        .unit = 's',
        .value = "",
    };

    while (args.next()) |arg| {
        var buffer: [100]u8 = undefined;
        try argsParser(arg, &timer_args,  &buffer);
    }
    
    const time_second:u32 = try utils.calculateTime(timer_args.value, timer_args.unit);

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

    while (!rl.windowShouldClose()) { 
        const delta_time = rl.getFrameTime();
        gui_time += delta_time;
        
        const float_time: f32 = @max(@as(f32, @floatFromInt(time_second)) - gui_time, 0);
        const int_time: u32 = @intFromFloat(@ceil(float_time));

        var buffer: [32]u8 = undefined;
        const hours: u32 = int_time / 3600;
        const minutes: u32 = (int_time % 3600) / 60;
        const seconds: u32 = int_time % 60;
        const timer_str = try std.fmt.bufPrintZ(&buffer, "{:02}:{:02}:{:02}", .{ hours, minutes, seconds });

        const text_size = rl.measureTextEx(try rl.getFontDefault(), timer_str, 60, 6);
        const text_position = utils.guiUtils.calculateCenter(text_size.x, text_size.y);
    
        const rectangle_padding: SizeType = .{
            .w = 100,
            .h = 60,
        };

        if (rectangle_size.h == null) {
            rectangle_size.h = text_size.y + rectangle_padding.h.?;
            rectangle_size.w = text_size.x + rectangle_padding.w.?;
        }

        const rectangle_position = utils.guiUtils.calculateCenter(rectangle_size.w.?, rectangle_size.h.?);

        rl.beginDrawing();
        
        // Timer
        rl.drawText(timer_str, @as(i32, @intFromFloat(text_position.x)), @as(i32, @intFromFloat(text_position.y)), 60, .light_gray);

    
        const rx_int:i32  = @intFromFloat(rectangle_position.x);
        const ry_int:i32  = @intFromFloat(rectangle_position.y);
        const rw_int:i32  = @intFromFloat(rectangle_size.w.?);
        const rh_int:i32  = @intFromFloat(rectangle_size.h.?);

        const primeter:f32 = (@as(f32, @floatFromInt(rh_int)) + @as(f32, @floatFromInt(rw_int))) * 2;
        // const primeter:f32 = @as(f32, @floatFromInt(rw_int));
        var progress_length:i32 = @intFromFloat(float_time/(@as(f32, @floatFromInt(time_second))) * primeter);

        
        // Progress rectangle
        if (progress_length > 0) {
            const right_progress = @min(progress_length, rh_int);
            progress_length -= right_progress;

            const bottom_progress = @min(progress_length, rw_int);
            progress_length -= bottom_progress;


            const left_progress = @min(progress_length, rh_int);   
            progress_length -= left_progress;

            const top_progress = @min(progress_length, rw_int);

            rl.drawLine(
                rx_int,
                ry_int,
                rx_int + top_progress,
                ry_int,
                .light_gray
            );

            rl.drawLine(
                rx_int + rw_int,
                ry_int,
                rx_int + rw_int,
                ry_int + right_progress,
                .light_gray
            );

            rl.drawLine(
                rx_int + rw_int,
                ry_int + rh_int,
                rx_int + rw_int - bottom_progress,
                ry_int + rh_int,
                .light_gray
            );

            rl.drawLine(
                rx_int,
                ry_int + rh_int,
                rx_int,
                ry_int + rh_int - left_progress,
                .light_gray
            );

        }

        defer rl.endDrawing();

        rl.clearBackground(.black);
    }
}
