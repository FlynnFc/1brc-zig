const std = @import("std");
const time = std.time;
const Instant = time.Instant;
const Timer = time.Timer;
const print = std.debug.print;

const City = struct {
    min: f64,
    max: f64,
    sum: f64,
    count: u32,
};

const Error = error{
    InvalidLength,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var cities = std.StringHashMap(City).init(allocator);
    defer cities.deinit();
    var file = try std.fs.cwd().openFile("measurements.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    const start = try Instant.now();
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var parts = std.mem.splitAny(u8, line, ";");
        const city: []const u8 = parts.first();
        const temp: []const u8 = parts.next().?;
        const temp_f64 = try std.fmt.parseFloat(f64, temp);
        const city_copy = try allocator.dupe(u8, city);
        if (cities.getPtr(city_copy)) |v| {
            v.*.count += 1;
            v.*.sum += temp_f64;
            if (v.min == 0 or temp_f64 < v.min) {
                v.*.min = temp_f64;
            }
            if (temp_f64 > v.max) {
                v.*.max = temp_f64;
            }
        } else {
            const new_city = City{ .min = temp_f64, .max = temp_f64, .sum = temp_f64, .count = 1 };
            try cities.put(city_copy, new_city);
        }
    }
    var iter = cities.iterator();
    while (iter.next()) |entry| {
        _ = entry.key_ptr.*;
        const v = entry.value_ptr.*;
        _ = v.sum / @as(f64, @floatFromInt(v.count));
        _ = v.min;
        _ = v.max;
        _ = v.count;

        // std.debug.print("City: {s}, Min: {}, Max: {}, Avg: {}, Count: {}\n", .{ city, min, max, avg, count });
    }
    const end = try Instant.now();
    const elapsed1: f64 = @floatFromInt(end.since(start));
    print("Time elapsed is: {d:.3}ms\n", .{
        elapsed1 / time.ns_per_ms,
    });
}
