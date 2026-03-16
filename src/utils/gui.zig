const rl = @import("raylib");

const PositionType = struct {
    x: f32,
    y: f32,
};

pub fn calculateCenter(object_width: f32, object_height: f32)  PositionType {
    const center_x = (@as(f32, @floatFromInt(rl.getScreenWidth())) - object_width)/2;
    const center_y = (@as(f32, @floatFromInt(rl.getScreenHeight())) - object_height)/2;
    return PositionType{.x = center_x, .y = center_y};
}

