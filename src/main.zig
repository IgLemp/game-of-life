const std = @import("std");
const Timer = std.time.Timer;
const print = std.debug.print;
const assert = std.debug.assert;
const gol2D = @import("gol2D.zig").GameOfLife;
const gol1D = @import("gol1D.zig").GameOfLife;

const WIDTH = 300;
const HEIGHT = 400;
const SIZE = WIDTH * HEIGHT;
const SHOW_BOARD_STATE = false;

pub fn main() !void {
    var acorn = [_][2]usize{
        [2]usize{ 10, 10 },
        [2]usize{ 11, 10 },
        [2]usize{ 11, 12 },
        [2]usize{ 13, 11 },
        [2]usize{ 14, 10 },
        [2]usize{ 15, 10 },
        [2]usize{ 16, 10 },
    };

    var glider = [_][2]usize{
        [2]usize{ 1, 1 },
        [2]usize{ 1, 3 },
        [2]usize{ 2, 3 },
        [2]usize{ 2, 2 },
        [2]usize{ 3, 2 },
    };
    _ = glider;


    var gol2d = gol2D(WIDTH, HEIGHT).init();
    gol2d.switchCells(&acorn);
    var gol1d = gol1D(WIDTH, HEIGHT).init();
    _ = gol1d;
    gol2d.switchCells(&acorn);



    var timer = try Timer.start();
    var read_time: u64 = 0;
    var print_time: u64 = 0;
    
    var out_board = [_][HEIGHT]bool{[_]bool{false} ** HEIGHT} ** WIDTH;
    std.debug.print("board size: {d}x{d}", .{WIDTH, HEIGHT});

    // =======================
    timer.reset();
    for (0..WIDTH - 1) |o| {
        for (0..HEIGHT - 1) |p| {
            out_board[o][p] = @bitCast(bool, gol2d.cells[o][p]);
        }
    }
    read_time = timer.lap();
    // =======================

    // =======================
    timer.reset();
    if (SHOW_BOARD_STATE) { printBoard(out_board); }
    print_time = timer.lap();
    print("read time:  {d} ms\n", .{read_time / (1000 * 1000)});
    if (SHOW_BOARD_STATE) { print("print time: {d} ms\n", .{print_time / (1000 * 1000)}); } else { print("print time: N/A\n", .{}); }
    // =======================
    

    print("\n", .{});
    const IterTimes = struct { 
        list: u64 = 0,
        vector: u64 = 0,
        list_dumb: u64 = 0,
        list_flat: u64 = 0,
        vector_flat: u64 = 0,
    };
    
    var iter_times: IterTimes = .{};
    
    // =======================
    timer.reset();
    gol2d.nextIterationList();
    iter_times.list = timer.lap();
    if (SHOW_BOARD_STATE) { printBoard(gol2d.cells); }
    print("list: {d} ms\n", .{iter_times.list / (1000 * 1000)});
    if (SHOW_BOARD_STATE) { print("\n", .{}); }
    // =======================


    // =======================
    timer.reset();
    gol2d.nextIterationVector();
    iter_times.vector = timer.lap();
    if (SHOW_BOARD_STATE) { printBoard(gol2d.cells); }
    print("vector: {d} ms\n", .{iter_times.vector / (1000 * 1000)});
    // =======================


    // =======================
    timer.reset();
    gol2d.nextIterationListDumb();
    iter_times.list_dumb = timer.lap();
    if (SHOW_BOARD_STATE) { printBoard(gol2d.cells); }
    print("list-dumb: {d} ms\n", .{iter_times.list_dumb / (1000 * 1000)});
    // =======================


    // =======================
    // timer.reset();
    // gol1d.nextIterationList();
    // iter_times.list_flat = timer.lap();
    // if (SHOW_BOARD_STATE) { printBoard(gol1d.cells); }
    // print("list-flat: {d} ms\n", .{iter_times.list_flat / (1000 * 1000)});
    // ======================= 


    // ======================= 
    // timer.reset();
    // gol1d.nextIterationVector();
    // iter_times.vector_flat = timer.lap();
    // if (SHOW_BOARD_STATE) { printBoard(gol1d.cells); }
    // print("vector-flat: {d} ms\n", .{iter_times.vector_flat / (1000 * 1000)});
    // ======================= 
}


inline fn printBoard(board: anytype) void {
    print("board state: \n", .{});
    print("=" ** HEIGHT ++ "\n", .{});
    for (0..WIDTH) |i| {
        for (0..HEIGHT) |j| {
            print("{s}", .{ if (@bitCast(bool, board[i][j])) "X" else "."});
        }
        print("\n", .{});
    }
    print("=" ** HEIGHT ++ "\n", .{});
}

