const std = @import("std");
const Timer = std.time.Timer;
const print = std.debug.print;
const assert = std.debug.assert;

const DIMESIONS = [_]u16{200, 400};
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
    if (SHOW_BOARD_STATE) { printBoard(out_board); }
    print_time = timer.lap();
    print("read time:  {d}ms\n", .{read_time / 1000});
    if (SHOW_BOARD_STATE) { print("print time: {d}ms\n", .{print_time / 1000}); } else { print("print time: N/A\n", .{}); }
    // =======================
    

    print("\n", .{});
    const IterTimes = struct { list: u64 = 0, vector: u64 = 0, };
    var iter_times: IterTimes = .{};
    
    // =======================
    timer.reset();
    gol.nextIterationList();
    iter_times.list = timer.lap();
    if (SHOW_BOARD_STATE) { printBoard(gol.cells); }
    print("list iter_time: {d}ms\n", .{iter_times.list / 1000});
    if (SHOW_BOARD_STATE) { print("\n", .{}); }
    // =======================


    // =======================
    timer.reset();
    gol.nextIterationVector();
    iter_times.vector = timer.lap();
    if (SHOW_BOARD_STATE) { printBoard(gol.cells); }
    print("vector iter_time: {d}ms\n", .{iter_times.vector / 1000});
    // =======================
}

inline fn printBoard(board: anytype) void {
    print("board state: \n", .{});
    print("=" ** DIMESIONS[1] ++ "\n", .{});
    for (0..DIMESIONS[0]) |i| {
        for (0..DIMESIONS[1]) |j| {
            print("{s}", .{ if (@bitCast(bool, board[i][j])) "X" else "."});
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
            for (1..x - 2) |i| {
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
            for (0..x - 1) |i| {
                for (0..y - 1) |j| {
                    var cell_neighbours = neighbours[i][j];

                    // 1. Any live cell with fewer than two live neighbours dies, as if by underpopulation
                    if (cell_neighbours < 2 and @bitCast(bool, self.cells[i][j]) == true) { self.cells[i][j] = 0; }

                    // 2. Any live cell with two or three live neighbours lives on to the next generation.
                    // NO-OP

                    // 3. Any live cell with more than three live neighbours dies, as if by overpopulation.
                    if (cell_neighbours > 3 and @bitCast(bool, self.cells[i][j]) == true) { self.cells[i][j] = 0; }

                    // 4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction
                    if (cell_neighbours == 3 and @bitCast(bool, self.cells[i][j]) == false) { self.cells[i][j] = 1; }
                }
            }
        }

        pub fn nextIterationVector(self: *Self) void {
            comptime var col_left_rot:  @Vector(y, u16) = undefined;
            comptime var col_right_rot: @Vector(y, u16) = undefined;

            // col left rotation vector
            col_left_rot[y - 1] = 0;
            @setEvalBranchQuota(100000);
            inline for (0..y - 1) |i| { col_left_rot[i] = i + 1; }

            // col right rotation vector
            col_right_rot[0] = y - 1;
            @setEvalBranchQuota(100000);
            inline for (1..y) |i| { col_right_rot[i] = i - 1; }
        
            // add iteration
            self.iteration += 1;
            var neighbours = [_]@Vector(y, u4){@splat(y, @as(u1, 0))} ** x;

            // column up and down rotations
            for (&neighbours, self.cells) |*n_column, c_column| {
                n_column.* += @shuffle(u4, c_column, undefined, col_left_rot);
                n_column.* += @shuffle(u4, c_column, undefined, col_right_rot);
            }

            // row left and light rotations
            for (1..x) |i| {
                neighbours[i - 1] += self.cells[i];
                neighbours[x - 1] += self.cells[0];
            }
            
            for (0..x - 1) |i| {
                neighbours[i + 1] += self.cells[i];
                neighbours[0] += self.cells[x - 1];
            }

            // row column left up and left down rotations
            for (1..x) |i| {
                neighbours[i - 1] += @shuffle(u4, self.cells[i], undefined, col_left_rot);
                neighbours[x - 1] += @shuffle(u4, self.cells[0], undefined, col_left_rot);
                neighbours[i - 1] += @shuffle(u4, self.cells[i], undefined, col_right_rot);
                neighbours[x - 1] += @shuffle(u4, self.cells[0], undefined, col_right_rot);
            }

            for (0..x - 1) |i| {
                neighbours[i + 1] +=  @shuffle(u4, self.cells[i], undefined, col_left_rot);
                neighbours[0] +=  @shuffle(u4, self.cells[x - 1], undefined, col_left_rot);
                neighbours[i + 1] +=  @shuffle(u4, self.cells[i], undefined, col_right_rot);
                neighbours[0] +=  @shuffle(u4, self.cells[x - 1], undefined, col_right_rot);
            }

            // game of life algorythm
            for (&neighbours, &self.cells) |*n_list, *c_list| {
                // 1. Any live cell with fewer than two live neighbours dies, as if by underpopulation
                c_list.* ^= (c_list.* & @bitCast(@Vector(y, u1), n_list.* < @splat(y, @as(u4, 2))));
                
                // 2. Any live cell with two or three live neighbours lives on to the next generation.
                // NO-OP
                
                // 3. Any live cell with more than three live neighbours dies, as if by overpopulation.
                c_list.* ^= (c_list.* & @bitCast(@Vector(y, u1), n_list.* > @splat(y, @as(u4, 3))));

                // 4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction
                c_list.* |= (~c_list.* & @bitCast(@Vector(y, u1), n_list.* == @splat(y, @as(u4, 3))));
            }
        }
    };
}
