pub fn GameOfLife(comptime w: usize, comptime h: usize) type {
    return struct {
        const Self = @This();
        cells: @Vector(w * h, u1),
        iteration: u32,
        
        pub fn init() Self {
            return Self {
                .cells = @splat(w * h, @as(u1, 0)),
                .iteration = 0,
            };
        }

        pub fn switchCells(self: *Self, cells_to_set: [][2]usize) void {
            for (cells_to_set) |cell| {
                self.cells[cell[0] + cell[1] * h] = ~self.cells[cell[0] + cell[1] * h];
            }
        }

        pub fn nextIterationList(self: *Self) void {
            self.iteration += 1;
            var neighbours: [w * h]u8 = [_]u8{0} ** (w * h);
            
            // algorythm for game of life inspired by APL solutiuons
            // NOTE: it is possible to do it faster using vectors
            // TODO: make it use vectors

            // calculating number of living neighbours
            for (1..w - 1) |j| {
                for (1..h - 1) |i| {
                    // horizontal and vertical shifts
                    neighbours[(i - 1) + j * h] += self.cells[i + j * h]; // left  shift
                    neighbours[(i + 1) + j * h] += self.cells[i + j * h]; // right shift
                    neighbours[i + (j - 1) * h] += self.cells[i + j * h]; // up    shift
                    neighbours[i + (j + 1) * h] += self.cells[i + j * h]; // down  shift
                
                    // diagonal shifts
                    neighbours[(i - 1) + (j - 1) * h] += self.cells[i + j * h]; // left  up   shift
                    neighbours[(i + 1) + (j - 1) * h] += self.cells[i + j * h]; // right up   shift
                    neighbours[(i - 1) + (j + 1) * h] += self.cells[i + j * h]; // left  down shift
                    neighbours[(i + 1) + (j + 1) * h] += self.cells[i + j * h]; // right down shift
                }
            }

            // switching cells
            for (0..w) |j| {
                for (0..h - 1) |i| {
                    var cell_neighbours = neighbours[i + j * h];

                    // 1. Any live cell with fewer than two live neighbours dies, as if by underpopulation
                    if (cell_neighbours < 2 and @bitCast(bool, self.cells[i + j * h]) == true) { self.cells[i + j * h] = 0; }

                    // 2. Any live cell with two or three live neighbours lives on to the next generation.
                    // NO-OP

                    // 3. Any live cell with more than three live neighbours dies, as if by overpopulation.
                    if (cell_neighbours > 3 and @bitCast(bool, self.cells[i + j * h]) == true) { self.cells[i + j * h] = 0; }

                    // 4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction
                    if (cell_neighbours == 3 and @bitCast(bool, self.cells[i + j * h]) == false) { self.cells[i + j * h] = 1; }
                }
            }
        }


        pub fn nextIterationVector(self: *Self) void {
            // perpendicular offsets
            comptime var left_offset = @splat(w * h, @as(i32, 0));
            comptime {
                @setEvalBranchQuota(100000000);
                for (0..w * h) |i| { left_offset[i] = @intCast(i32, i + 1); }
                @setEvalBranchQuota(100000000);
                for (1..h + 1) |i| { left_offset[(i * w) - 1] = @intCast(i32, i - 1) * w; }
            }
            comptime var right_offset = @splat(w * h, @as(i32, 0));
            comptime {
                @setEvalBranchQuota(100000000);
                for (1..w * h) |i| { right_offset[i] = @intCast(i32, i - 1); }
                @setEvalBranchQuota(100000000);
                for (0..h) |i| { right_offset[w * i] = (w * @intCast(i32, i + 1)) - 1; }
            }
            comptime var up_offset = @splat(w * h, @as(i32, 0));
            comptime {
                @setEvalBranchQuota(100000000);
                for (0..w * h - w) |i| { up_offset[i] = @intCast(i32, i + w); }
                @setEvalBranchQuota(100000000);
                for (0..w) |i| { up_offset[i + (w * h - w)] = @intCast(i32, i); }
            }
            comptime var down_offset = @splat(w * h, @as(i32, 0));
            comptime {
                @setEvalBranchQuota(100000000);
                for (w..w * h) |i| { down_offset[i] = @intCast(i32, i - w); }
                @setEvalBranchQuota(100000000);
                for (0..w) |i| { down_offset[i] = @intCast(i32, i + (w * h - w)); }
            }

            // diagonal offsets
            comptime var left_up_offset = @shuffle(i32, left_offset, undefined, up_offset);
            comptime var left_down_offset = @shuffle(i32, left_offset, undefined, down_offset);
            comptime var right_down_offset = @shuffle(i32, right_offset, undefined, down_offset);
            comptime var right_up_offset = @shuffle(i32, right_offset, undefined, up_offset);   


            // add iteration
            self.iteration += 1;
            var neighbours = @splat(w * h, @as(u4, 0));

            neighbours += @shuffle(u4, self.cells, undefined, left_offset);
            neighbours += @shuffle(u4, self.cells, undefined, right_offset);
            neighbours += @shuffle(u4, self.cells, undefined, up_offset);
            neighbours += @shuffle(u4, self.cells, undefined, down_offset);

            neighbours += @shuffle(u4, self.cells, undefined, left_up_offset);
            neighbours += @shuffle(u4, self.cells, undefined, right_up_offset);
            neighbours += @shuffle(u4, self.cells, undefined, left_down_offset);
            neighbours += @shuffle(u4, self.cells, undefined, right_down_offset);


            // game of life algorythm
            
            // 1. Any live cell with fewer than two live neighbours dies, as if by underpopulation
            self.cells ^= (self.cells & @bitCast(@Vector(w * h, u1), neighbours < @splat(w * h, @as(u4, 2))));
            
            // 2. Any live cell with two or three live neighbours lives on to the next generation.
            // NO-OP
            
            // 3. Any live cell with more than three live neighbours dies, as if by overpopulation.
            self.cells ^= (self.cells & @bitCast(@Vector(w * h, u1), neighbours > @splat(w * h, @as(u4, 3))));

            // 4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction
            self.cells |= (~self.cells & @bitCast(@Vector(w * h, u1), neighbours == @splat(w * h, @as(u4, 3))));
        
        }

        
        pub fn nextIterationListDumb(self: *Self) void {
            self.iteration += 1;
            var next_iter = [_]@Vector(h, u1){@splat(h, @as(u1, 0))} ** w;        

            // calculating number of living neighbours
            var neighbours: u4 = 0;
            for (1..w - 2) |i| {
                for (1..h - 2) |j| {
                    neighbours = 0;
                    
                    neighbours += self.cells[i-1][j-1];
                    neighbours += self.cells[i-1][j];
                    neighbours += self.cells[i-1][j+1];
                    neighbours += self.cells[i][j-1]; 
                    neighbours += self.cells[i][j+1];
                    neighbours += self.cells[i+1][j-1];
                    neighbours += self.cells[i-1][j];
                    neighbours += self.cells[i+1][j+1];
                    
                    // 1. Any live cell with fewer than two live neighbours dies, as if by underpopulation
                    if (neighbours < 2 and @bitCast(bool, self.cells[i][j]) == true) { next_iter[i][j] = 0; }

                    // 2. Any live cell with two or three live neighbours lives on to the next generation.
                    // NO-OP

                    // 3. Any live cell with more than three live neighbours dies, as if by overpopulation.
                    if (neighbours > 3 and @bitCast(bool, self.cells[i][j]) == true) { next_iter[i][j] = 0; }

                    // 4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction
                    if (neighbours == 3 and @bitCast(bool, self.cells[i][j]) == false) { next_iter[i][j] = 1; }

                }
            }

            self.cells = next_iter;
        }

    };
}
