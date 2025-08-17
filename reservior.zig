const std = @import("std");
const ArrayList = std.ArrayList;
const HashMap = std.AutoArrayHashMap;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const log = std.log.scoped(.reservior);
const math = std.math;
/// sources: 0. https://www.romu-random.org/
///          1. https://www.pcg-random.org/posts/pcg-passes-practrand.html
///          2. https://en.wikipedia.org/wiki/Pearson%27s_chi-squared_test
/// interesting links: - https://en.wikipedia.org/wiki/Yarrow_algorithm
pub fn main() !void {
    try mainReservior();
}

fn mainReservior() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // defer {
    //     const status = gpa.deinit();
    //     if (status == .leak) {
    //         @panic("there was a leak. call a plumber");
    //     }
    // }

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip();

    const debug_print: bool = std.mem.eql(u8, "1", args.next() orelse "0");
    // const n: u32 = try std.fmt.parseInt(u32, args.next() orelse "10", 10);
    // const k: u32 = try std.fmt.parseInt(u32, args.next() orelse "5", 10);
    // const iterations : u32 = try std.fmt.parseInt(u32, args.next() orelse "100000", 10);
    const n: u32 = 10;
    const k: u32 = 5;
    const iterations: u32 = 100000;

    if (debug_print) {
        std.debug.print("n {}, k {}, iterations {}\r\n", .{ n, k, iterations });
    }

    const seed: u64 = blk: {
        const curr = std.time.timestamp();
        break :blk @intCast(curr);
    };
    var random_context = std.Random.DefaultPrng.init(seed);
    // var random_context = std.Random.RomuTrio.init(seed);
    const random = random_context.random();

    const list = try allocator.alloc(u32, n);
    // defer allocator.free(list);
    const sample = try allocator.alloc(u32, k);
    // defer allocator.free(sample);

    for (list, 1..) |*v, i| {
        v.* = @intCast(i);
    }
    if (debug_print) {
        std.debug.print("list {any}\r\n", .{list});
    }

    const histogram = try allocator.alloc(u32, math.pow(u32, 2, n + 1)); // used extra memory, can optimize by changing the hashing

    @memset(histogram, 0);

    const hist_numbers = try allocator.alloc(u32, n + 1); // is it a bloom filter when it doesn't voom voom?
    // is it hist when it is not hysterical?
    // that is the filter. so map-reduce your own hashmap to infinityyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
    @memset(hist_numbers, 0);

    for (0..iterations) |i| {
        generateSample(list, sample, random, k, n);
        if (debug_print) {
            std.debug.print("{} -> {any}\r\n", .{ i, sample });
        }
        for (sample) |s| {
            hist_numbers[s] += 1;
        }
        const h = hashSample(sample);
        histogram[h] += 1;
    }

    if (debug_print) {
        std.debug.print("{any}\r\n", .{hist_numbers});
        std.debug.print("----------------\r\n", .{});
    }
    // Note(surrlim): wtf andrew?
    const stdout_file = std.io.getStdOut();
    const stdout_writer = stdout_file.writer();
    // var buff: [1024*4]u8 = undefined;
    // var stdout = stdout_writer.initInterface(&buff);
    var stdout_buffered = std.io.bufferedWriter(stdout_writer);
    var stdout = stdout_buffered.writer();

    try stdout.print("bits, count\r\n", .{});
    for (histogram, 0..) |h, i| {
        if (i % 2 == 0 and countBits(@intCast(i)) == k)
            try stdout.print("{},{}\r\n", .{ i, h });
    }

    try stdout_buffered.flush();
}
// just a simple bitset hash because the sample size is k <= n and the numbers are in [1,n]
fn hashSample(sample: []u32) u32 {
    assert(sample.len < 32);
    var res: u32 = 0;
    for (sample) |v| {
        res = res | math.pow(u32, 2, v);
    }
    return res;
}
// excludes bit-0 because the hash doesn't count it too.
fn countBits(n: u32) u32 {
    var count: u32 = 0;
    inline for (1..10 + 1) |i| {
        count += (n >> i) & 1;
    }
    return count;
}
fn generateSample(list: []const u32, sample: []u32, random: std.Random, k: u32, n: u32) void {
    const kf: f32 = @floatFromInt(k);
    var W: f32 = exp(ln(random.float(f32)) / kf);
    var i: u32 = 0;
    while (i < k) : (i += 1) {
        sample[i] = list[i];
    }

    i = k - 1;
    var __guard_i: u32 = 1000000;
    while (__guard_i > 0) : (__guard_i -= 1) {
        // variable N with P(N = n) = W(1-W)^n
        const geometric_w: u32 = @intFromFloat(math.floor(ln(random.float(f32)) / ln(1 - W)));
        i += geometric_w + 1;

        if (i < n) {
            const kickout_index = random.uintLessThan(usize, k);
            sample[kickout_index] = list[i];

            W = W * exp(ln(random.float(f32)) / kf);
        } else break;
    }
}

fn exp(a: f32) f32 {
    return math.exp(a);
}
fn ln(a: f32) f32 {
    return math.log(f32, math.e, a);
}
