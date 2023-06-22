const std = @import("std");
const Timer = std.time.Timer;
const print = std.debug.print;
const assert = std.debug.assert;

const DIMESIONS = [_]u8{20, 40};
const SIZE = DIMESIONS[0] * DIMESIONS[1];
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


    var gol = GameOfLife(DIMESIONS[0], DIMESIONS[1]).init();
    gol.switchCells(&acorn);


    var timer = try Timer.start();
    var read_time: u64 = 0;
    var print_time: u64 = 0;
    
    var out_board = [_][DIMESIONS[1]]bool{[_]bool{false} ** DIMESIONS[1]} ** DIMESIONS[0];

    // =======================
    print("Read time\n", .{});
    timer.reset();
    for (0..DIMESIONS[0] - 1) |o| {
        for (0..DIMESIONS[1] - 1) |p| {
            out_board[o][p] = @bitCast(bool, gol.cells[o][p]);
        }
    }
    read_time = timer.lap();
    // =======================

    // =======================
    timer.reset();
    printBoard(out_board);
    print_time = timer.lap();
    print("read time:  {d}ms\n", .{read_time  / 1000});
    print("print time: {d}ms\n", .{print_time / 1000});
    // =======================
    

    print("\n", .{});
    const IterTimes = struct { list: u64 = 0, };
    var iter_times: IterTimes = .{};
    
    // =======================
    timer.reset();
    gol.nextIterationList();
    iter_times.list = timer.lap();
    comptime { if (SHOW_BOARD_STATE) { printBoard(gol.cells); } }
    print("list iter_time: {d}ms\n", .{iter_times.list / 1000});
    // =======================


    gol.nextIterationVector();
}

inline fn printBoard(board: [DIMESIONS[0]][DIMESIONS[1]]bool) void {
    print("board state: \n", .{});
    print("=" ** DIMESIONS[1] ++ "\n", .{});
    for (0..board.len) |i| {
        for (0..board[0].len) |j| {
            print("{s}", .{ if (board[i][j]) "X" else "."});
        }
        print("\n", .{});
    }
    print("=" ** DIMESIONS[1] ++ "\n", .{});
}



fn GameOfLife(comptime x: usize, comptime y: usize) type {
    return struct {
        const Self = @This();
        cells: [x]@Vector(y, u1),
        iteration: u32,
        
        pub fn init() Self {
            return Self {
                .cells = [_]@Vector(y, u1){@splat(y, @as(u1, 0))} ** x,
                .iteration = 0,
            };
        }

        pub fn switchCells(self: *Self, cells_to_set: [][2]usize) void {
            for (cells_to_set) |cell| {
                self.cells[cell[0]][cell[1]] = ~self.cells[cell[0]][cell[1]];
            }
        }

        pub fn nextIterationList(self: *Self) void {
            self.iteration += 1;
            var neighbours = [_][y]u8{[_]u8{0} ** y} ** x;
            
            // algorythm for game of life inspired by APL solutiuons
            // NOTE: it is possible to do it faster using vectors
            // TODO: make it use vectors

            // calculating number of living neighbours
            inline for (1..x - 2) |i| {
                for (1..y - 2) |j| {
                    // horizontal and vertical shifts
                    neighbours[i - 1][j] += self.cells[i][j]; // left  shift
                    neighbours[i + 1][j] += self.cells[i][j]; // right shift
                    neighbours[i][j - 1] += self.cells[i][j]; // up    shift
                    neighbours[i][j + 1] += self.cells[i][j]; // down  shift
                
                    // diagonal shifts
                    neighbours[i - 1][j - 1] += self.cells[i][j]; // left  up   shift
                    neighbours[i + 1][j - 1] += self.cells[i][j]; // right up   shift
                    neighbours[i - 1][j + 1] += self.cells[i][j]; // left  down shift
                    neighbours[i + 1][j + 1] += self.cells[i][j]; // right down shift
                }
            }

            // switching cells
            inline for (0..x - 1) |i| {
                for (0..y - 1) |j| {
                    var cell_neighbours = neighbours[i][j];

                    // 1. Any live cell with fewer than two live neighbours dies, as if by underpopulation
                    if (cell_neighbours < 2 and self.cells[i][j] == 1) { self.cells[i][j] = 0; }

                    // 2. Any live cell with two or three live neighbours lives on to the next generation.
                    // NO-OP

                    // 3. Any live cell with more than three live neighbours dies, as if by overpopulation.
                    if (cell_neighbours > 3 and self.cells[i][j] == 1) { self.cells[i][j] = 0; }

                    // 4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction
                    if (cell_neighbours == 3 and self.cells[i][j] == 0) { self.cells[i][j] = 0; }
                }
            }
        }

        pub fn nextIterationVector(self: *Self) void {
            // rotation bitmasks fo SIMD operations
            comptime var row_left_rot:  @Vector(DIMESIONS[0], u16) = undefined;
            comptime var row_right_rot: @Vector(DIMESIONS[0], u16) = undefined;
            comptime var col_left_rot:  @Vector(DIMESIONS[1], u16) = undefined;
            comptime var col_right_rot: @Vector(DIMESIONS[1], u16) = undefined;

            // row left rotation vector
            row_left_rot[DIMESIONS[0] - 1] = 0;
            inline for (0..DIMESIONS[0] - 1) |i| { row_left_rot[i] = i + 1; }

            // row right rotation vector
            row_right_rot[0] = DIMESIONS[0] - 1;
            inline for (1..DIMESIONS[0]) |i| { row_right_rot[i] = i - 1; }

            // col left rotation vector
            col_left_rot[DIMESIONS[1] - 1] = 0;
            inline for (0..DIMESIONS[1] - 1) |i| { col_left_rot[i] = i + 1; }

            // col right rotation vector
            col_right_rot[0] = DIMESIONS[1] - 1;
            inline for (1..DIMESIONS[1]) |i| { col_right_rot[i] = i - 1; }
        

            self.iteration += 1;
            var neighbours = [_]@Vector(DIMESIONS[1], u4){} ** x;
            _ = neighbours;

            print("\n{any}", .{row_left_rot});
            print("\n{any}", .{row_right_rot});
            print("\n{any}", .{col_left_rot});
            print("\n{any}", .{col_right_rot});
        }
    };
}
