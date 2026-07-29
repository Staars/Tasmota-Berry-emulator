# Two Dots for LVGL

class TwoDotsGame
    var scr, layer
    var grid, grid_size
    var dot_objects
    var score, moves, target_score, level
    var score_label, moves_label, target_label
    var hres, vres, dot_size, grid_start_x, grid_start_y, padding
    var current_path, path_lines
    var colors
    var game_over

    def init()
        lv.start()
        self.hres = lv.get_hor_res()
        self.vres = lv.get_ver_res()
        self.grid_size = 6
        self.score = 0
        self.moves = 30
        self.target_score = 50
        self.level = 1
        self.game_over = false
        self.current_path = []
        self.path_lines = []

        self.colors = [
            0xFF0000,   # Red
            0x0000FF,   # Blue
            0xFFFF00,   # Yellow
            0x00FF00,   # Green
            0xFF00FF    # Purple
        ]

        var avail = self.hres < (self.vres - 120) ? self.hres : (self.vres - 120)
        self.padding = 5
        self.dot_size = int((avail - self.padding * (self.grid_size + 1)) / self.grid_size)
        self.grid_start_x = int((self.hres - (self.dot_size * self.grid_size + self.padding * (self.grid_size + 1))) / 2)
        self.grid_start_y = 100

        self.init_grid()
        self.create_ui()
        self.update_display()
        print("Two Dots loaded – drag same color dots!")
    end

    def random_color()
        import crypto
        return crypto.random(1)[0] % size(self.colors)
    end

    def init_grid()
        self.grid = []
        self.dot_objects = []
        var r = 0
        while r < self.grid_size
            var row_g = []
            var row_o = []
            var c = 0
            while c < self.grid_size
                var color = self.random_color()
                while (c >= 2 && row_g[c-1] == color && row_g[c-2] == color) ||
                      (r >= 2 && self.grid[r-1][c] == color && self.grid[r-2][c] == color)
                    color = self.random_color()
                end
                row_g.push(color)
                row_o.push(nil)
                c += 1
            end
            self.grid.push(row_g)
            self.dot_objects.push(row_o)
            r += 1
        end
    end

    def create_ui()
        self.scr = lv.scr_act()
        self.scr.set_style_bg_color(lv.color(0xF5F5DC), 0)

        var title = lv.label(self.scr)
        var f = lv.montserrat_font(20)
        if f != nil title.set_style_text_font(f, 0) end
        title.set_text("Two Dots")
        title.set_pos(10, 5)
        title.set_style_text_color(lv.color(0x2C3E50), 0)

        self.score_label  = self.make_stat_box(5,            "Score",  0x3498DB)
        self.target_label = self.make_stat_box(self.hres/3+5, "Target", 0x2ECC71)
        self.moves_label  = self.make_stat_box(self.hres*2/3+5,"Moves",  0xE74C3C)

        var new_btn = lv.btn(self.scr)
        new_btn.set_size(60, 30)
        new_btn.set_pos(self.hres - 65, 8)
        new_btn.set_style_bg_color(lv.color(0x95A5A6), 0)
        new_btn.set_style_radius(5, 0)
        var nl = lv.label(new_btn)
        nl.set_text("New")
        nl.center()
        nl.set_style_text_color(lv.color(0xFFFFFF), 0)
        new_btn.add_event_cb(/o,e,u->self.new_game(), lv.EVENT_CLICKED, 0)

        self.layer = lv.layer_top()
        self.layer.set_style_bg_opa(0, 0)

        var touch_area = lv.obj(self.scr)
        var grid_extent = self.dot_size * self.grid_size + self.padding * (self.grid_size + 1)
        touch_area.set_size(grid_extent, grid_extent)
        touch_area.set_pos(self.grid_start_x, self.grid_start_y)
        touch_area.set_style_bg_opa(0, 0)
        touch_area.set_style_border_width(0, 0)
        touch_area.add_flag(lv.OBJ_FLAG_CLICKABLE)
        touch_area.clear_flag(lv.OBJ_FLAG_SCROLLABLE)

        touch_area.add_event_cb(/o,e,u->self.touch_start(o,e,u),  lv.EVENT_PRESSED,  0)
        touch_area.add_event_cb(/o,e,u->self.touch_move(o,e,u),   lv.EVENT_PRESSING, 0)
        touch_area.add_event_cb(/o,e,u->self.touch_end(o,e,u),    lv.EVENT_RELEASED, 0)
    end

    def make_stat_box(x, txt, bgcol)
        var box = lv.obj(self.scr)
        box.set_size(int(self.hres/3)-10, 40)
        box.set_pos(x, 35)
        box.set_style_bg_color(lv.color(bgcol), 0)
        box.set_style_radius(5, 0)
        box.set_style_border_width(0, 0)

        var f12 = lv.montserrat_font(14)
        var title = lv.label(box)
        if f12 != nil title.set_style_text_font(f12, 0) end
        title.set_text(txt)
        title.set_pos(5, 3)
        title.set_style_text_color(lv.color(0xFFFFFF), 0)

        var f14 = lv.montserrat_font(20)
        var val = lv.label(box)
        if f14 != nil val.set_style_text_font(f14, 0) end
        val.set_pos(5, 20)
        val.set_style_text_color(lv.color(0xFFFFFF), 0)
        return val
    end

    def dot_coords(row, col)
        var x = self.grid_start_x + self.padding + col * (self.dot_size + self.padding)
        var y = self.grid_start_y + self.padding + row * (self.dot_size + self.padding)
        return {"x": x, "y": y}
    end

    def update_display()
        var r = 0
        while r < self.grid_size
            var c = 0
            while c < self.grid_size
                if self.dot_objects[r][c] != nil
                    self.dot_objects[r][c].delete()
                    self.dot_objects[r][c] = nil
                end
                c += 1
            end
            r += 1
        end

        r = 0
        while r < self.grid_size
            var c = 0
            while c < self.grid_size
                var idx = self.grid[r][c]
                if idx >= 0
                    var dot = lv.obj(self.scr)
                    var p = self.dot_coords(r, c)
                    dot.set_pos(p['x'], p['y'])
                    dot.set_size(self.dot_size, self.dot_size)
                    dot.set_style_bg_color(lv.color(self.colors[idx]), 0)
                    dot.set_style_radius(self.dot_size/2, 0)
                    dot.set_style_border_width(2, 0)
                    dot.set_style_border_color(lv.color(0xFFFFFF), 0)
                    dot.clear_flag(lv.OBJ_FLAG_CLICKABLE)
                    dot.set_user_data(r*10 + c)
                    self.dot_objects[r][c] = dot
                end
                c += 1
            end
            r += 1
        end

        self.score_label.set_text(str(self.score))
        self.moves_label.set_text(str(self.moves))
        self.target_label.set_text(str(self.target_score))
    end

    def clear_path_lines()
        var k = 0
        while k < size(self.path_lines)
            self.path_lines[k].delete()
            k += 1
        end
        self.path_lines = []
    end

    def draw_path()
        self.clear_path_lines()
        if size(self.current_path) < 2 return end

        var idx = 0
        while idx < size(self.current_path) - 1
            var a = self.current_path[idx]
            var b = self.current_path[idx+1]
            var pa = self.dot_coords(a['row'], a['col'])
            var pb = self.dot_coords(b['row'], b['col'])

            var p1 = lv.point()
            var p2 = lv.point()
            p1.x = pa['x'] + self.dot_size/2
            p1.y = pa['y'] + self.dot_size/2
            p2.x = pb['x'] + self.dot_size/2
            p2.y = pb['y'] + self.dot_size/2

            var line = lv.line(self.layer)
            var pts = lv.lv_point_arr([p1, p2])
            line.set_points(pts, 2)
            line.set_style_line_width(6, 0)
            line.set_style_line_rounded(true, 0)
            var col = self.colors[self.grid[a['row']][a['col']]]
            line.set_style_line_color(lv.color(col), 0)
            self.path_lines.push(line)
            idx += 1
        end
    end

    def are_adjacent(p1, p2)
        var dr = p1['row'] - p2['row']; if dr < 0 dr = -dr end
        var dc = p1['col'] - p2['col']; if dc < 0 dc = -dc end
        return (dr == 1 && dc == 0) || (dr == 0 && dc == 1)
    end

    def pos_in_path(row, col)
        var idx = 0
        while idx < size(self.current_path)
            var p = self.current_path[idx]
            if p['row'] == row && p['col'] == col return idx end
            idx += 1
        end
        return -1
    end

    def touch_start(obj, evt, user_data)
        if self.game_over return end
        var indev = lv.indev_active()
        if !indev return end

        var point = lv.point()
        indev.get_point(point)

        var col = int((point.x - self.grid_start_x - self.padding) / (self.dot_size + self.padding))
        var row = int((point.y - self.grid_start_y - self.padding) / (self.dot_size + self.padding))

        if row < 0 || row >= self.grid_size || col < 0 || col >= self.grid_size return end
        if self.grid[row][col] < 0 return end

        self.cancel_path()
        self.current_path.push({"row": row, "col": col})
        self.highlight_dot(row, col, true)
        self.draw_path()
    end

    def touch_move(obj, evt, user_data)
        if self.game_over || size(self.current_path) == 0 return end
        var indev = lv.indev_active()
        if !indev return end

        var point = lv.point()
        indev.get_point(point)

        var col = int((point.x - self.grid_start_x - self.padding) / (self.dot_size + self.padding))
        var row = int((point.y - self.grid_start_y - self.padding) / (self.dot_size + self.padding))

        if row < 0 || row >= self.grid_size || col < 0 || col >= self.grid_size return end
        if self.grid[row][col] < 0 return end

        var last = self.current_path[size(self.current_path)-1]

        if size(self.current_path) >= 2
            var prev = self.current_path[size(self.current_path)-2]
            if prev['row'] == row && prev['col'] == col
                var removed = self.current_path.pop()
                self.highlight_dot(removed['row'], removed['col'], false)
                self.draw_path()
                return
            end
        end

        if self.pos_in_path(row, col) >= 0 return end
        if !self.are_adjacent(last, {"row": row, "col": col}) return end

        var first = self.current_path[0]
        if self.grid[row][col] != self.grid[first['row']][first['col']] return end

        self.current_path.push({"row": row, "col": col})
        self.highlight_dot(row, col, true)
        self.draw_path()
    end

    def touch_end(obj, evt, user_data)
        if self.game_over return end
        if size(self.current_path) >= 2
            self.clear_path()
        else
            self.cancel_path()
        end
    end

    def highlight_dot(row, col, on)
        var dot = self.dot_objects[row][col]
        if !dot return end
        if on
            dot.set_style_border_width(4, 0)
            dot.set_style_border_color(lv.color(0x000000), 0)
        else
            dot.set_style_border_width(2, 0)
            dot.set_style_border_color(lv.color(0xFFFFFF), 0)
        end
    end

    def cancel_path()
        var idx = 0
        while idx < size(self.current_path)
            var p = self.current_path[idx]
            self.highlight_dot(p['row'], p['col'], false)
            idx += 1
        end
        self.current_path = []
        self.clear_path_lines()
    end

    def clear_path()
        if size(self.current_path) < 2
            self.cancel_path()
            return
        end

        var points = size(self.current_path)
        if self.check_square()
            points *= 2
            print("Square bonus!")
        end

        self.score += points
        self.moves -= 1

        var idx = 0
        while idx < size(self.current_path)
            var p = self.current_path[idx]
            self.grid[p['row']][p['col']] = -1
            idx += 1
        end

        self.drop_dots()
        self.fill_top_rows()

        self.current_path = []
        self.clear_path_lines()
        self.update_display()
        self.check_end_game()
    end

    def drop_dots()
        var c = 0
        while c < self.grid_size
            var write = self.grid_size - 1
            var read = self.grid_size - 1
            while read >= 0
                if self.grid[read][c] >= 0
                    if read != write
                        self.grid[write][c] = self.grid[read][c]
                        self.grid[read][c] = -1
                    end
                    write -= 1
                end
                read -= 1
            end
            c += 1
        end
    end

    def fill_top_rows()
        var c = 0
        while c < self.grid_size
            var r = 0
            while r < self.grid_size
                if self.grid[r][c] == -1
                    self.grid[r][c] = self.random_color()
                end
                r += 1
            end
            c += 1
        end
    end

    def bubble_sort(lst)
        var n = size(lst)
        var i = 0
        while i < n - 1
            var j = 0
            while j < n - i - 1
                if lst[j] > lst[j+1]
                    var temp = lst[j]
                    lst[j] = lst[j+1]
                    lst[j+1] = temp
                end
                j += 1
            end
            i += 1
        end
    end

    def check_square()
        if size(self.current_path) < 4 return false end
        var first = self.current_path[0]
        var last = self.current_path[size(self.current_path)-1]
        if !self.are_adjacent(first, last) return false end

        var corners = []
        var idx = 0
        while idx < size(self.current_path)
            var p = self.current_path[idx]
            if idx == 0 || idx == size(self.current_path)-1
                corners.push(p)
            else
                var prev = self.current_path[idx-1]
                var nxt = self.current_path[(idx+1) % size(self.current_path)]
                if (prev['row'] == p['row'] && nxt['row'] != p['row']) ||
                   (prev['col'] == p['col'] && nxt['col'] != p['col'])
                    corners.push(p)
                end
            end
            idx += 1
        end
        if size(corners) != 4 return false end

        var rs = []
        var cs = []
        var k = 0
        while k < 4
            rs.push(corners[k]['row'])
            cs.push(corners[k]['col'])
            k += 1
        end

        self.bubble_sort(rs)
        self.bubble_sort(cs)

        return rs[0] == rs[1] && rs[2] == rs[3] && cs[0] == cs[1] && cs[2] == cs[3]
    end

    def check_end_game()
        while self.score >= self.target_score
            print("Level " + str(self.level) + " complete! Score: " + str(self.score))
            self.level += 1
            self.target_score += 30
            self.moves += 5
            self.target_label.set_text(str(self.target_score))
        end
        if self.moves <= 0
            self.game_over = true
            print("Game Over! Final score: " + str(self.score))
        end
    end

    def new_game()
        self.score = 0
        self.moves = 30
        self.target_score = 50
        self.level = 1
        self.game_over = false
        self.current_path = []
        self.clear_path_lines()
        self.init_grid()
        self.update_display()
        self.target_label.set_text(str(self.target_score))
        print("New game started!")
    end
end

#- START -#
var twodots = TwoDotsGame()
