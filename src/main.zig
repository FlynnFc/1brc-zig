const std = @import("std");

const City = struct {
    min: f64,
    max: f64,
    sum: f64,
    count: u32,
};

const Error = error{
    InvalidLength,
};

fn bytesToFloat(bytes: []u8) !f64 {
    if (bytes.len != 8) {
        return Error.InvalidLength;
    }

    const u64Value = @as(u64, bytes.ptr);
    return @as(f64, u64Value);
}

pub fn main() !void {
    var cities = std.StringHashMap(City).init(std.heap.page_allocator);
    defer cities.deinit();
    var file = try std.fs.cwd().openFile("weather_stations.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var city: []u8 = undefined;
        var temp: f64 = undefined;
        for (0.., line) |i, c| {
            if (c == ';') {
                temp = try std.fmt.parseFloat(f64, line[i + 1 ..]);
                city = line[0..i];
                if (cities.get(city)) |v| {
                    v.count += 1;
                    v.sum += temp;
                    if (v.min == 0 or temp < v.min) {
                        v.min = temp;
                    }
                    if (temp > v.max) {
                        v.max = temp;
                    }
                    break;
                } else {
                    const new_city = City{ .min = temp, .max = temp, .sum = temp, .count = 1 };
                    try cities.put(city, new_city);
                }
            }
        }
    }
    var iter = cities.iterator();
    while (iter.next()) |entry| {
        const city = entry.key_ptr.*;
        const v = entry.value_ptr.*;

        const avg = v.sum / @as(f64, v.count);
        const min = v.min;
        const max = v.max;
        const count = v.count;
        const city_str = std.mem.toString(city);

        std.debug.print("City: {}, Min: {}, Max: {}, Avg: {}, Count: {}\n", .{ city_str, min, max, avg, count });
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
