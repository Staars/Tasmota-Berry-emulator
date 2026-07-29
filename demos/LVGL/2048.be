#- 2048 Game for Tasmota LVGL -#
#- Swipe to play -#

class Game2048
    var scr
    var grid
    var tiles
    var score
    var best_score
    var score_label
    var best_label
    var game_over
    var hres
    var vres
    var tile_size
    var grid_padding
    var grid_start_x
    var grid_start_y
    var touch_start_x
    var touch_start_y
    var touch_active

    def init()
        lv.start()
        self.hres = lv.get_hor_res()
        self.vres = lv.get_ver_res()
        self.score = 0
        self.best_score = 0
        self.game_over = false
        self.touch_active = false

        #- Calculate tile size based on screen -#
        var available_size = self.hres < (self.vres - 100) ? self.hres : (self.vres - 100)
        self.grid_padding = 10
        self.tile_size = int((available_size - 50) / 4)
        self.grid_start_x = int((self.hres - (self.tile_size * 4 + self.grid_padding * 5)) / 2)
        self.grid_start_y = 80

        #- Initialize game state -#
        self.grid = []
        var i = 0
        while i < 4
            self.grid.push([0, 0, 0, 0])
            i += 1
        end

        self.tiles = []

        self.create_ui()
        self.add_random_tile()
        self.add_random_tile()
        self.update_display()

        print("2048 Game loaded! Swipe to play.")
    end

    #- Create UI -#
    def create_ui()
        self.scr = lv.scr_act()
        self.scr.set_style_bg_color(lv.color(0xFAF8EF), lv.PART_MAIN | lv.STATE_DEFAULT)

        #- Title -#
        var title = lv.label(self.scr)
        var f20 = lv.montserrat_font(20)
        if f20 != nil title.set_style_text_font(f20, lv.PART_MAIN | lv.STATE_DEFAULT) end
        title.set_text("2048")
        title.set_pos(10, 10)
        title.set_style_text_color(lv.color(0x776E65), lv.PART_MAIN | lv.STATE_DEFAULT)

        #- Score display -#
        var score_container = lv.obj(self.scr)
        score_container.set_size(int(self.hres / 3) - 10, 50)
        score_container.set_pos(int(self.hres / 3) + 5, 5)
        score_container.set_style_bg_color(lv.color(0xBBADA0), lv.PART_MAIN | lv.STATE_DEFAULT)
        score_container.set_style_radius(5, lv.PART_MAIN | lv.STATE_DEFAULT)
        score_container.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)

        var score_title = lv.label(score_container)
        var f12 = lv.montserrat_font(14)
        if f12 != nil score_title.set_style_text_font(f12, lv.PART_MAIN | lv.STATE_DEFAULT) end
        score_title.set_text("SCORE")
        score_title.set_pos(5, 2)
        score_title.set_style_text_color(lv.color(0xEEE4DA), lv.PART_MAIN | lv.STATE_DEFAULT)

        self.score_label = lv.label(score_container)
        var f16 = lv.montserrat_font(14)
        if f16 != nil self.score_label.set_style_text_font(f16, lv.PART_MAIN | lv.STATE_DEFAULT) end
        self.score_label.set_text("0")
        self.score_label.set_pos(75, 2)
        self.score_label.set_style_text_color(lv.color(0xFFFFFF), lv.PART_MAIN | lv.STATE_DEFAULT)

        #- Best score -#
        var best_container = lv.obj(self.scr)
        best_container.set_size(int(self.hres / 3) - 10, 50)
        best_container.set_pos(int(self.hres * 2 / 3) + 5, 5)
        best_container.set_style_bg_color(lv.color(0xBBADA0), lv.PART_MAIN | lv.STATE_DEFAULT)
        best_container.set_style_radius(5, lv.PART_MAIN | lv.STATE_DEFAULT)
        best_container.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)

        var best_title = lv.label(best_container)
        if f12 != nil best_title.set_style_text_font(f12, lv.PART_MAIN | lv.STATE_DEFAULT) end
        best_title.set_text("BEST")
        best_title.set_pos(5, 2)
        best_title.set_style_text_color(lv.color(0xEEE4DA), lv.PART_MAIN | lv.STATE_DEFAULT)

        self.best_label = lv.label(best_container)
        if f16 != nil self.best_label.set_style_text_font(f16, lv.PART_MAIN | lv.STATE_DEFAULT) end
        self.best_label.set_text("0")
        self.best_label.set_pos(75, 2)
        self.best_label.set_style_text_color(lv.color(0xFFFFFF), lv.PART_MAIN | lv.STATE_DEFAULT)

        #- New Game button -#
        var new_btn = lv.btn(self.scr)
        new_btn.set_size(80, 35)
        new_btn.set_pos(10, 40)
        new_btn.set_style_bg_color(lv.color(0x8F7A66), lv.PART_MAIN | lv.STATE_DEFAULT)
        new_btn.set_style_radius(5, lv.PART_MAIN | lv.STATE_DEFAULT)
        var new_label = lv.label(new_btn)
        new_label.set_text("New")
        new_label.center()
        new_label.set_style_text_color(lv.color(0xF9F6F2), lv.PART_MAIN | lv.STATE_DEFAULT)
        new_btn.add_event_cb(/obj, evt -> self.new_game(), lv.EVENT_CLICKED, 0)

        #- Game grid background -#
        var grid_bg = lv.obj(self.scr)
        grid_bg.set_size(self.tile_size * 4 + self.grid_padding * 5,
                         self.tile_size * 4 + self.grid_padding * 5)
        grid_bg.set_pos(self.grid_start_x, self.grid_start_y)
        grid_bg.set_style_bg_color(lv.color(0xBBADA0), lv.PART_MAIN | lv.STATE_DEFAULT)
        grid_bg.set_style_radius(5, lv.PART_MAIN | lv.STATE_DEFAULT)
        grid_bg.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)

        #- Add gesture events to grid -#
        grid_bg.add_event_cb(/obj, evt -> self.on_touch_start(obj, evt), lv.EVENT_PRESSED, 0)
        grid_bg.add_event_cb(/obj, evt -> self.on_touch_end(obj, evt), lv.EVENT_RELEASED, 0)

        #- Create empty tile placeholders -#
        var row = 0
        while row < 4
            var col = 0
            while col < 4
                var placeholder = lv.obj(self.scr)
                placeholder.set_size(self.tile_size, self.tile_size)
                var x = self.grid_start_x + self.grid_padding + col * (self.tile_size + self.grid_padding)
                var y = self.grid_start_y + self.grid_padding + row * (self.tile_size + self.grid_padding)
                placeholder.set_pos(x, y)
                placeholder.set_style_bg_color(lv.color(0xCDC1B4), lv.PART_MAIN | lv.STATE_DEFAULT)
                placeholder.set_style_radius(3, lv.PART_MAIN | lv.STATE_DEFAULT)
                placeholder.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)
                placeholder.clear_flag(lv.OBJ_FLAG_CLICKABLE)
                col += 1
            end
            row += 1
        end

    end

    #- Handle touch start -#
    def on_touch_start(obj, evt)
        var indev = lv.indev_active()
        if indev == nil return end

        var point = lv.point()
        indev.get_point(point)

        self.touch_start_x = point.x
        self.touch_start_y = point.y
        self.touch_active = true
    end

    #- Handle touch end (swipe detection) -#
    def on_touch_end(obj, evt)
        if !self.touch_active return end

        var indev = lv.indev_active()
        if indev == nil return end

        var point = lv.point()
        indev.get_point(point)

        var dx = point.x - self.touch_start_x
        var dy = point.y - self.touch_start_y

        #- Calculate absolute differences -#
        var abs_dx = dx < 0 ? -dx : dx
        var abs_dy = dy < 0 ? -dy : dy

        #- Minimum swipe distance -#
        var min_swipe = 30

        if abs_dx > min_swipe || abs_dy > min_swipe
            #- Determine swipe direction -#
            if abs_dx > abs_dy
                #- Horizontal swipe -#
                if dx > 0
                    self.move_right()
                else
                    self.move_left()
                end
            else
                #- Vertical swipe -#
                if dy > 0
                    self.move_down()
                else
                    self.move_up()
                end
            end
        end

        self.touch_active = false
    end

    #- Get tile color based on value -#
    def get_tile_color(value)
        if value == 2 return 0xEEE4DA
        elif value == 4 return 0xEDE0C8
        elif value == 8 return 0xF2B179
        elif value == 16 return 0xF59563
        elif value == 32 return 0xF67C5F
        elif value == 64 return 0xF65E3B
        elif value == 128 return 0xEDCF72
        elif value == 256 return 0xEDCC61
        elif value == 512 return 0xEDC850
        elif value == 1024 return 0xEDC53F
        elif value == 2048 return 0xEDC22E
        else return 0x3C3A32
        end
    end

    #- Get text color based on value -#
    def get_text_color(value)
        if value <= 4 return 0x776E65
        else return 0xF9F6F2
        end
    end

    #- Update display -#
    def update_display()
        #- Clear old tiles -#
        var i = 0
        while i < size(self.tiles)
            self.tiles[i].delete()
            i += 1
        end
        self.tiles = []

        #- Create tiles -#
        var row = 0
        while row < 4
            var col = 0
            while col < 4
                var value = self.grid[row][col]
                if value > 0
                    var tile = lv.obj(self.scr)
                    tile.set_size(self.tile_size, self.tile_size)
                    var x = self.grid_start_x + self.grid_padding + col * (self.tile_size + self.grid_padding)
                    var y = self.grid_start_y + self.grid_padding + row * (self.tile_size + self.grid_padding)
                    tile.set_pos(x, y)
                    tile.set_style_bg_color(lv.color(self.get_tile_color(value)), lv.PART_MAIN | lv.STATE_DEFAULT)
                    tile.set_style_radius(3, lv.PART_MAIN | lv.STATE_DEFAULT)
                    tile.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)

                    var label = lv.label(tile)
                    var font_size = value >= 1000 ? 14 : (value >= 100 ? 14 : 20)
                    var font = lv.montserrat_font(font_size)
                    if font != nil label.set_style_text_font(font, lv.PART_MAIN | lv.STATE_DEFAULT) end
                    label.set_text(str(value))
                    label.center()
                    label.set_style_text_color(lv.color(self.get_text_color(value)), lv.PART_MAIN | lv.STATE_DEFAULT)

                    self.tiles.push(tile)
                end
                col += 1
            end
            row += 1
        end

        #- Update score -#
        self.score_label.set_text(str(self.score))
        if self.score > self.best_score
            self.best_score = self.score
            self.best_label.set_text(str(self.best_score))
        end
    end

    #- Add random tile (2 or 4) -#
    def add_random_tile()
        var empty = []
        var row = 0
        while row < 4
            var col = 0
            while col < 4
                if self.grid[row][col] == 0
                    empty.push({"row": row, "col": col})
                end
                col += 1
            end
            row += 1
        end

        if size(empty) > 0
            import crypto
            var random = crypto.random(2)
            var idx = random[0] % size(empty)
            var pos = empty[idx]
            var value = (random[1] % 10) < 9 ? 2 : 4
            self.grid[pos['row']][pos['col']] = value
            return true
        end
        return false
    end

    #- Check if game is over -#
    def check_game_over()
        #- Check for empty cells -#
        var row = 0
        while row < 4
            var col = 0
            while col < 4
                if self.grid[row][col] == 0 return false end
                col += 1
            end
            row += 1
        end

        #- Check for possible merges -#
        row = 0
        while row < 4
            var col = 0
            while col < 3
                if self.grid[row][col] == self.grid[row][col + 1] return false end
                col += 1
            end
            row += 1
        end

        var col = 0
        while col < 4
            row = 0
            while row < 3
                if self.grid[row][col] == self.grid[row + 1][col] return false end
                row += 1
            end
            col += 1
        end

        return true
    end

    #- Move left -#
    def move_left()
        if self.game_over return end

        var moved = false
        var row = 0
        while row < 4
            #- Compress -#
            var new_row = []
            var col = 0
            while col < 4
                if self.grid[row][col] != 0
                    new_row.push(self.grid[row][col])
                end
                col += 1
            end

            #- Merge -#
            var merged = []
            var i = 0
            while i < size(new_row)
                if i < size(new_row) - 1 && new_row[i] == new_row[i + 1]
                    merged.push(new_row[i] * 2)
                    self.score += new_row[i] * 2
                    i += 2
                else
                    merged.push(new_row[i])
                    i += 1
                end
            end

            #- Fill with zeros -#
            while size(merged) < 4
                merged.push(0)
            end

            #- Check if changed -#
            col = 0
            while col < 4
                if self.grid[row][col] != merged[col]
                    moved = true
                end
                self.grid[row][col] = merged[col]
                col += 1
            end

            row += 1
        end

        if moved
            self.add_random_tile()
            self.update_display()
        end
        if self.check_game_over()
            self.game_over = true
            print("Game Over! Final score:", self.score)
        end
    end

    #- Move right -#
    def move_right()
        if self.game_over return end

        var moved = false
        var row = 0
        while row < 4
            #- Compress from right -#
            var new_row = []
            var col = 3
            while col >= 0
                if self.grid[row][col] != 0
                    new_row.push(self.grid[row][col])
                end
                col -= 1
            end

            #- Merge -#
            var merged = []
            var i = 0
            while i < size(new_row)
                if i < size(new_row) - 1 && new_row[i] == new_row[i + 1]
                    merged.push(new_row[i] * 2)
                    self.score += new_row[i] * 2
                    i += 2
                else
                    merged.push(new_row[i])
                    i += 1
                end
            end

            #- Fill with zeros on left -#
            while size(merged) < 4
                merged.push(0)
            end

            #- Reverse and check if changed -#
            col = 0
            while col < 4
                if self.grid[row][3 - col] != merged[col]
                    moved = true
                end
                self.grid[row][3 - col] = merged[col]
                col += 1
            end

            row += 1
        end

        if moved
            self.add_random_tile()
            self.update_display()
        end
        if self.check_game_over()
            self.game_over = true
            print("Game Over! Final score:", self.score)
        end
    end

    #- Move up -#
    def move_up()
        if self.game_over return end

        var moved = false
        var col = 0
        while col < 4
            #- Compress -#
            var new_col = []
            var row = 0
            while row < 4
                if self.grid[row][col] != 0
                    new_col.push(self.grid[row][col])
                end
                row += 1
            end

            #- Merge -#
            var merged = []
            var i = 0
            while i < size(new_col)
                if i < size(new_col) - 1 && new_col[i] == new_col[i + 1]
                    merged.push(new_col[i] * 2)
                    self.score += new_col[i] * 2
                    i += 2
                else
                    merged.push(new_col[i])
                    i += 1
                end
            end

            #- Fill with zeros -#
            while size(merged) < 4
                merged.push(0)
            end

            #- Check if changed -#
            row = 0
            while row < 4
                if self.grid[row][col] != merged[row]
                    moved = true
                end
                self.grid[row][col] = merged[row]
                row += 1
            end

            col += 1
        end

        if moved
            self.add_random_tile()
            self.update_display()
        end
        if self.check_game_over()
            self.game_over = true
            print("Game Over! Final score:", self.score)
        end
    end

    #- Move down -#
    def move_down()
        if self.game_over return end

        var moved = false
        var col = 0
        while col < 4
            #- Compress from bottom -#
            var new_col = []
            var row = 3
            while row >= 0
                if self.grid[row][col] != 0
                    new_col.push(self.grid[row][col])
                end
                row -= 1
            end

            #- Merge -#
            var merged = []
            var i = 0
            while i < size(new_col)
                if i < size(new_col) - 1 && new_col[i] == new_col[i + 1]
                    merged.push(new_col[i] * 2)
                    self.score += new_col[i] * 2
                    i += 2
                else
                    merged.push(new_col[i])
                    i += 1
                end
            end

            #- Fill with zeros on top -#
            while size(merged) < 4
                merged.push(0)
            end

            #- Reverse and check if changed -#
            row = 0
            while row < 4
                if self.grid[3 - row][col] != merged[row]
                    moved = true
                end
                self.grid[3 - row][col] = merged[row]
                row += 1
            end

            col += 1
        end

        if moved
            self.add_random_tile()
            self.update_display()
        end
        if self.check_game_over()
            self.game_over = true
            print("Game Over! Final score:", self.score)
        end
    end

    #- New game -#
    def new_game()
        self.score = 0
        self.game_over = false

        #- Reset grid -#
        var row = 0
        while row < 4
            var col = 0
            while col < 4
                self.grid[row][col] = 0
                col += 1
            end
            row += 1
        end

        self.add_random_tile()
        self.add_random_tile()
        self.update_display()
        print("New game started!")
    end
end

#- Start the game -#
game2048 = Game2048()
print("2048 game loaded! Swipe to play.")
