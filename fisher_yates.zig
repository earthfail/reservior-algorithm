const std = @import("std");
const ArrayList = std.ArrayList;
const HashMap = std.AutoArrayHashMap;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const log = std.log.scoped(.fisher);
const math = std.math;

pub fn main() !void {
    try mainFisher();
}
// key type for hash map
const Key = u64;

fn mainFisher() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();
    // defer {
    //     const status = gpa.deinit();
    //     if (status == .leak) {
    //         @panic("there was a leak. call a plumber");
    //     }
    // }
    var stdout_buffer: [4 * 1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip();
    const debug_print: bool = std.mem.eql(u8, "1", args.next() orelse "0");
    const n: u32 = try std.fmt.parseInt(u32, args.next() orelse "5", 10);
    const iterations: u32 = try std.fmt.parseInt(u32, args.next() orelse "10000", 10);
    const Mode = enum { forward, backward, generation };
    const mode: Mode = std.meta.stringToEnum(Mode, args.next() orelse "forward") orelse .forward;
    if (debug_print) {
        try print(stdout, "n {}, iterations {}, mode {}\r\n", .{ n, iterations, mode });
    }

    const seed: u64 = blk: {
        const curr = std.time.timestamp();
        break :blk @intCast(curr);
    };
    var random_context = std.Random.DefaultPrng.init(seed);
    const random = random_context.random();

    const list = try allocator.alloc(u32, n);

    if (mode != .generation) {
        var hist = HashMap(Key, u64).init(allocator);
        for (0..iterations) |i| {
            initList(list);
            switch (mode) {
                .forward => shuffleForward(random, list),
                .backward => shuffleBackward(random, list),
                else => unreachable,
            }
            const h = hashPermutation(list, n);
            const h_res = try hist.getOrPut(h);
            if (!h_res.found_existing) {
                h_res.value_ptr.* = 0;
            }
            h_res.value_ptr.* += 1;

            if (debug_print) {
                try print(stdout, "{} -> {d},{any}\n", .{ i, h, list });
            }
        }
        if (debug_print) {
            try print(stdout, "----------------\n", .{});
        }
        var it = hist.iterator();
        while (it.next()) |entry| {
            try print(stdout, "{d},{d}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
    } else {
        const indices_buffer = try allocator.alloc(usize, n - 1);
        const list1 = list;
        const list2 = try allocator.alloc(u32, list1.len);
        for (0..iterations) |i| {
            initList(list1);
            initList(list2);
            generatePermutationIndices(random, indices_buffer);
            for (0..indices_buffer.len) |j| {
                const j_conj = indices_buffer.len - 1 - j;
                // simulate swapping in backward iteration
                std.mem.swap(u32, &list1[j_conj], &list1[indices_buffer[j_conj]]);
                // simulate swapping in forward iteration
                std.mem.swap(u32, &list2[j], &list2[indices_buffer[j]]);
            }
            if (debug_print) {
                try print(stdout, "{} -> {any}\n", .{ i, list1 });
                try print(stdout, "{} -> {any}\n", .{ i, list2 });
            }
        }
    }
    stdout.flush() catch {};
}

// اعتبر المتوالية كانها عدد في ميزان س زائد واحد
fn hashPermutation(sample: []u32, n: u32) u64 {
    assert(sample.len == n);
    const scale = n + 1;
    var res: u64 = 0;
    var pow: u64 = 1;
    for (sample) |v| {
        assert(v < scale);
        res += v * pow;
        pow *= scale;
    }
    return res;
}
fn shuffleBackward(random: std.Random, list: []u32) void {
    var i: usize = list.len;
    while (i > 1) {
        i -= 1;
        const j = random.uintAtMost(usize, i);

        const tmp = list[i];
        list[i] = list[j];
        list[j] = tmp;
    }
}
fn shuffleForward(random: std.Random, list: []u32) void {
    var i: usize = 1;
    while (i < list.len) : (i += 1) {
        const j = random.uintAtMost(usize, i);

        const tmp = list[i];
        list[i] = list[j];
        list[j] = tmp;
    }
}

fn generatePermutationIndices(random: std.Random, buffer: []usize) void {
    // buffer size is the number of random numbers we want to generate
    // if we want to permutate `list` then its size is `list.len - 1`
    for (buffer, 1..) |*v, i| {
        v.* = random.uintAtMost(usize, i);
    }
}

fn initList(list: []u32) void {
    for (list, 1..) |*v, i| {
        v.* = @intCast(i);
    }
}

fn print(writer: *std.Io.Writer, comptime format: []const u8, args: anytype) !void {
    writer.print(format, args) catch |err| switch (err) {
        std.Io.Writer.Error.WriteFailed => {},
        else => return err,
    };
}
