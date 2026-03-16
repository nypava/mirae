pub const guiUtils = @import("gui.zig");
const std = @import("std");

/// Remove a character from a string
///
/// Parameters
/// - `string`: a string which a character will be removed 
/// - `removable`: a character which will be removed from a string
///
/// Returns 
/// The size of string after the character is removed
pub fn removeFromString(string: []const u8, removable: u8, out: []u8) usize {
    var index: usize = 0;

    for (string) |c| {
        if (c != removable) {
            out[index] = c;
            index += 1;
        }
    }

    return index;
}

/// Calculates the total time in seconds from a time string and a unit.
/// 
/// Parameters
/// - `time_string`: the input string containing digits and optional ':' delimiters.
/// - `unit`: character ['s', 'm', or 'h']
///
/// Returns
/// The total time in seconds as a `u32`.
pub fn calculateTime(time_string: []const u8, unit: u8) error{InvalidDelimiter, Overflow, InvalidCharacter}!u32 {
    var total_time: u32 = 0;

    const delimiter_count = std.mem.count(u8, time_string, ":");


    if (delimiter_count == 2 or delimiter_count == 1){
        var split_time = std.mem.splitBackwardsAny(u8, time_string, ":");
        var iter: usize = 0;
    
        if (unit == 'h' and (delimiter_count == 1)) {
            iter = 1; // HH:MM
        }

        while (split_time.next()) |time| {
            const time_int = try std.fmt.parseInt(u32, time, 10);

            if (iter == 0) {
                total_time += time_int;
            } else if (iter == 1) {
                total_time += time_int * 60;
            } else if (iter == 2) {
                total_time += time_int * 60 * 60;
            }
            iter += 1;
        } 

    } else if (delimiter_count == 0){
        const time_int = try std.fmt.parseInt(u32, time_string, 10);

        if (unit ==  's') {
            total_time += time_int;
        } else if (unit ==  'm') {
            total_time += time_int * 60;
        } else if (unit ==  'h') {
            total_time += time_int * 60 * 60;
        }
    } else {
        return error.InvalidDelimiter;
    }

    return total_time;
}
