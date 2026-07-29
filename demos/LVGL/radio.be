#- Web Radio Player UI for Tasmota LVGL -#
#- Beautiful interface for streaming internet radio -#

class WebRadioPlayer
    var scr
    var hres
    var vres
    var stations
    var current_station_idx
    var volume
    var is_muted
    var is_playing

    #- UI Elements -#
    var station_label
    var bitrate_label
    var info_label
    var volume_label
    var volume_slider
    var volume_arc
    var play_btn
    var play_icon
    var mute_btn
    var mute_icon
    var prev_btn
    var next_btn
    var station_dropdown

    def init()
        lv.start()
        self.hres = lv.get_hor_res()
        self.vres = lv.get_ver_res()

        #- Player state -#
        self.current_station_idx = 0
        self.volume = 70
        self.is_muted = false
        self.is_playing = false

        #- Radio stations list -#
        self.stations = [
            {
                "name": "BBC Radio 1",
                "url": "http://stream.live.vc.bbcmedia.co.uk/bbc_radio_one",
                "bitrate": "128 kbps",
                "genre": "Pop Music"
            },
            {
                "name": "Classic FM",
                "url": "http://media-ice.musicradio.com/ClassicFMMP3",
                "bitrate": "128 kbps",
                "genre": "Classical"
            },
            {
                "name": "Jazz FM",
                "url": "http://edge-baueraudio-01-gos2.sharp-stream.com/jazz.mp3",
                "bitrate": "128 kbps",
                "genre": "Jazz"
            },
            {
                "name": "Smooth Radio",
                "url": "http://media-ice.musicradio.com/SmoothMP3",
                "bitrate": "128 kbps",
                "genre": "Easy Listening"
            },
            {
                "name": "Absolute Radio",
                "url": "http://icy-e-bz-06-gos.sharp-stream.com/absoluteradio.mp3",
                "bitrate": "128 kbps",
                "genre": "Rock & Pop"
            },
            {
                "name": "Heart FM",
                "url": "http://media-ice.musicradio.com/HeartMP3",
                "bitrate": "128 kbps",
                "genre": "Hit Music"
            },
            {
                "name": "Radio Paradise",
                "url": "http://stream.radioparadise.com/aac-320",
                "bitrate": "320 kbps",
                "genre": "Eclectic"
            },
            {
                "name": "SomaFM Groove Salad",
                "url": "http://ice1.somafm.com/groovesalad-128-mp3",
                "bitrate": "128 kbps",
                "genre": "Ambient/Downtempo"
            }
        ]

        self.create_ui()
        self.update_station_info()

        print("Web Radio Player loaded!")
    end

    #- Create UI -#
    def create_ui()
        self.scr = lv.scr_act()

        #- Background gradient -#
        self.scr.set_style_bg_color(lv.color(0x1A1A2E), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.scr.set_style_bg_grad_color(lv.color(0x16213E), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.scr.set_style_bg_grad_dir(lv.GRAD_DIR_VER, lv.PART_MAIN | lv.STATE_DEFAULT)

        var y_pos = 10

        #- Title -#
        var title = lv.label(self.scr)
        var f16 = lv.montserrat_font(16)
        if f16 != nil title.set_style_text_font(f16, lv.PART_MAIN | lv.STATE_DEFAULT) end
        title.set_text(lv.SYMBOL_AUDIO + " Web Radio")
        title.set_pos(10, y_pos)
        title.set_style_text_color(lv.color(0xE94560), lv.PART_MAIN | lv.STATE_DEFAULT)

        y_pos += 30

        #- Station Display Card -#
        var station_card = lv.obj(self.scr)
        var card_h = 100
        station_card.set_size(self.hres - 20, card_h)
        station_card.set_pos(10, y_pos)
        station_card.set_style_bg_color(lv.color(0x0F3460), lv.PART_MAIN | lv.STATE_DEFAULT)
        station_card.set_style_radius(12, lv.PART_MAIN | lv.STATE_DEFAULT)
        station_card.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        station_card.set_style_shadow_width(8, lv.PART_MAIN | lv.STATE_DEFAULT)
        station_card.set_style_shadow_color(lv.color(0x000000), lv.PART_MAIN | lv.STATE_DEFAULT)
        station_card.set_style_shadow_opa(100, lv.PART_MAIN | lv.STATE_DEFAULT)
        station_card.set_style_pad_all(12, lv.PART_MAIN | lv.STATE_DEFAULT)

        #- Station icon -#
        var station_icon = lv.label(station_card)
        var f20 = lv.montserrat_font(20)
        if f20 != nil station_icon.set_style_text_font(f20, lv.PART_MAIN | lv.STATE_DEFAULT) end
        station_icon.set_text(lv.SYMBOL_AUDIO)
        station_icon.set_pos(5, 10)
        station_icon.set_style_text_color(lv.color(0xE94560), lv.PART_MAIN | lv.STATE_DEFAULT)

        #- Station name -#
        self.station_label = lv.label(station_card)
        if f16 != nil self.station_label.set_style_text_font(f16, lv.PART_MAIN | lv.STATE_DEFAULT) end
        self.station_label.set_text("Station Name")
        self.station_label.set_pos(40, 8)
        self.station_label.set_style_text_color(lv.color(0xFFFFFF), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.station_label.set_width(self.hres - 80)
        self.station_label.set_long_mode(lv.LABEL_LONG_SCROLL_CIRCULAR)

        #- Bitrate -#
        self.bitrate_label = lv.label(station_card)
        var f12 = lv.montserrat_font(12)
        if f12 != nil self.bitrate_label.set_style_text_font(f12, lv.PART_MAIN | lv.STATE_DEFAULT) end
        self.bitrate_label.set_text("128 kbps")
        self.bitrate_label.set_pos(40, 32)
        self.bitrate_label.set_style_text_color(lv.color(0x53D2DC), lv.PART_MAIN | lv.STATE_DEFAULT)

        #- Genre info -#
        self.info_label = lv.label(station_card)
        if f12 != nil self.info_label.set_style_text_font(f12, lv.PART_MAIN | lv.STATE_DEFAULT) end
        self.info_label.set_text("Genre: Music")
        self.info_label.set_pos(40, 50)
        self.info_label.set_style_text_color(lv.color(0xAAAAAA), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.info_label.set_width(self.hres - 80)
        self.info_label.set_long_mode(lv.LABEL_LONG_SCROLL_CIRCULAR)

        #- Status indicator -#
        var status_dot = lv.obj(station_card)
        status_dot.set_size(8, 8)
        status_dot.set_pos(5, card_h - 18)
        status_dot.set_style_bg_color(lv.color(0x808080), lv.PART_MAIN | lv.STATE_DEFAULT)
        status_dot.set_style_radius(4, lv.PART_MAIN | lv.STATE_DEFAULT)
        status_dot.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)

        y_pos += card_h + 15

        #- Station Selector -#
        var selector_label = lv.label(self.scr)
        if f12 != nil selector_label.set_style_text_font(f12, lv.PART_MAIN | lv.STATE_DEFAULT) end
        selector_label.set_text("Select Station:")
        selector_label.set_pos(15, y_pos)
        selector_label.set_style_text_color(lv.color(0xCCCCCC), lv.PART_MAIN | lv.STATE_DEFAULT)

        y_pos += 20

        #- Station dropdown (simulated with buttons) -#
        var dropdown_container = lv.obj(self.scr)
        dropdown_container.set_size(self.hres - 20, 45)
        dropdown_container.set_pos(10, y_pos)
        dropdown_container.set_style_bg_color(lv.color(0x0F3460), lv.PART_MAIN | lv.STATE_DEFAULT)
        dropdown_container.set_style_radius(8, lv.PART_MAIN | lv.STATE_DEFAULT)
        dropdown_container.set_style_border_width(1, lv.PART_MAIN | lv.STATE_DEFAULT)
        dropdown_container.set_style_border_color(lv.color(0x53D2DC), lv.PART_MAIN | lv.STATE_DEFAULT)
        dropdown_container.set_style_pad_all(0, lv.PART_MAIN | lv.STATE_DEFAULT)

        #- Previous station button -#
        self.prev_btn = lv.btn(dropdown_container)
        self.prev_btn.set_size(45, 45)
        self.prev_btn.set_pos(0, 0)
        self.prev_btn.set_style_bg_color(lv.color(0x1A5490), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.prev_btn.set_style_radius(8, lv.PART_MAIN | lv.STATE_DEFAULT)
        self.prev_btn.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        var prev_icon = lv.label(self.prev_btn)
        if f16 != nil prev_icon.set_style_text_font(f16, lv.PART_MAIN | lv.STATE_DEFAULT) end
        prev_icon.set_text(lv.SYMBOL_LEFT)
        prev_icon.center()
        self.prev_btn.add_event_cb(/obj, evt -> self.prev_station(), lv.EVENT_CLICKED, 0)

        #- Station name button -#
        var station_btn = lv.btn(dropdown_container)
        station_btn.set_size(self.hres - 110, 45)
        station_btn.set_pos(45, 0)
        station_btn.set_style_bg_color(lv.color(0x0F3460), lv.PART_MAIN | lv.STATE_DEFAULT)
        station_btn.set_style_radius(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        station_btn.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        self.station_dropdown = lv.label(station_btn)
        var f14 = lv.montserrat_font(14)
        if f14 != nil self.station_dropdown.set_style_text_font(f14, lv.PART_MAIN | lv.STATE_DEFAULT) end
        self.station_dropdown.set_text("Station")
        self.station_dropdown.center()
        self.station_dropdown.set_style_text_color(lv.color(0xFFFFFF), lv.PART_MAIN | lv.STATE_DEFAULT)

        #- Next station button -#
        self.next_btn = lv.btn(dropdown_container)
        self.next_btn.set_size(45, 45)
        self.next_btn.set_pos(self.hres - 65, 0)
        self.next_btn.set_style_bg_color(lv.color(0x1A5490), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.next_btn.set_style_radius(8, lv.PART_MAIN | lv.STATE_DEFAULT)
        self.next_btn.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        var next_icon = lv.label(self.next_btn)
        if f16 != nil next_icon.set_style_text_font(f16, lv.PART_MAIN | lv.STATE_DEFAULT) end
        next_icon.set_text(lv.SYMBOL_RIGHT)
        next_icon.center()
        self.next_btn.add_event_cb(/obj, evt -> self.next_station(), lv.EVENT_CLICKED, 0)

        y_pos += 60

        #- Volume Control Section -#
        var vol_label = lv.label(self.scr)
        if f12 != nil vol_label.set_style_text_font(f12, lv.PART_MAIN | lv.STATE_DEFAULT) end
        vol_label.set_text("Volume Control:")
        vol_label.set_pos(15, y_pos)
        vol_label.set_style_text_color(lv.color(0xCCCCCC), lv.PART_MAIN | lv.STATE_DEFAULT)

        y_pos += 25

        #- Volume container -#
        var vol_container = lv.obj(self.scr)
        vol_container.set_size(self.hres - 20, 80)
        vol_container.set_pos(10, y_pos)
        vol_container.set_style_bg_color(lv.color(0x0F3460), lv.PART_MAIN | lv.STATE_DEFAULT)
        vol_container.set_style_radius(12, lv.PART_MAIN | lv.STATE_DEFAULT)
        vol_container.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        vol_container.set_style_pad_all(10, lv.PART_MAIN | lv.STATE_DEFAULT)

        #- Volume slider -#
        self.volume_slider = lv.slider(vol_container)
        self.volume_slider.set_size(self.hres - 60, 15)
        self.volume_slider.set_pos(10, 15)
        self.volume_slider.set_range(0, 100)
        self.volume_slider.set_value(self.volume, lv.ANIM_OFF)
        self.volume_slider.set_style_bg_color(lv.color(0x1A1A2E), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.volume_slider.set_style_bg_color(lv.color(0xE94560), lv.PART_INDICATOR | lv.STATE_DEFAULT)
        self.volume_slider.set_style_bg_color(lv.color(0xFF6B8A), lv.PART_KNOB | lv.STATE_DEFAULT)
        self.volume_slider.add_event_cb(/obj, evt -> self.volume_changed(obj), lv.EVENT_VALUE_CHANGED, 0)

        #- Volume label -#
        self.volume_label = lv.label(vol_container)
        if f16 != nil self.volume_label.set_style_text_font(f16, lv.PART_MAIN | lv.STATE_DEFAULT) end
        self.volume_label.set_text(f"{self.volume}%")
        self.volume_label.set_pos(10, 40)
        self.volume_label.set_style_text_color(lv.color(0xFFFFFF), lv.PART_MAIN | lv.STATE_DEFAULT)

        #- Volume down button -#
        var vol_down = lv.btn(vol_container)
        vol_down.set_size(50, 50)
        vol_down.set_pos(self.hres - 175, 25)
        vol_down.set_style_bg_color(lv.color(0x1A5490), lv.PART_MAIN | lv.STATE_DEFAULT)
        vol_down.set_style_radius(25, lv.PART_MAIN | lv.STATE_DEFAULT)
        vol_down.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        var vol_down_icon = lv.label(vol_down)
        if f20 != nil vol_down_icon.set_style_text_font(f20, lv.PART_MAIN | lv.STATE_DEFAULT) end
        vol_down_icon.set_text("-")
        vol_down_icon.center()
        vol_down.add_event_cb(/obj, evt -> self.volume_down(), lv.EVENT_CLICKED, 0)

        #- Volume up button -#
        var vol_up = lv.btn(vol_container)
        vol_up.set_size(50, 50)
        vol_up.set_pos(self.hres - 120, 25)
        vol_up.set_style_bg_color(lv.color(0x1A5490), lv.PART_MAIN | lv.STATE_DEFAULT)
        vol_up.set_style_radius(25, lv.PART_MAIN | lv.STATE_DEFAULT)
        vol_up.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        var vol_up_icon = lv.label(vol_up)
        if f20 != nil vol_up_icon.set_style_text_font(f20, lv.PART_MAIN | lv.STATE_DEFAULT) end
        vol_up_icon.set_text("+")
        vol_up_icon.center()
        vol_up.add_event_cb(/obj, evt -> self.volume_up(), lv.EVENT_CLICKED, 0)

        #- Mute button -#
        self.mute_btn = lv.btn(vol_container)
        self.mute_btn.set_size(50, 50)
        self.mute_btn.set_pos(self.hres - 65, 25)
        self.mute_btn.set_style_bg_color(lv.color(0xE94560), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.mute_btn.set_style_radius(25, lv.PART_MAIN | lv.STATE_DEFAULT)
        self.mute_btn.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        self.mute_icon = lv.label(self.mute_btn)
        if f16 != nil self.mute_icon.set_style_text_font(f16, lv.PART_MAIN | lv.STATE_DEFAULT) end
        self.mute_icon.set_text(lv.SYMBOL_VOLUME_MAX)
        self.mute_icon.center()
        self.mute_btn.add_event_cb(/obj, evt -> self.toggle_mute(), lv.EVENT_CLICKED, 0)

        y_pos += 95

        #- Play/Pause Controls -#
        var controls_y = self.vres - 75

        #- Play/Pause button -#
        self.play_btn = lv.btn(self.scr)
        self.play_btn.set_size(70, 70)
        self.play_btn.set_pos(int(self.hres / 2) - 35, controls_y)
        self.play_btn.set_style_bg_color(lv.color(0xE94560), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.play_btn.set_style_radius(35, lv.PART_MAIN | lv.STATE_DEFAULT)
        self.play_btn.set_style_border_width(0, lv.PART_MAIN | lv.STATE_DEFAULT)
        self.play_btn.set_style_shadow_width(10, lv.PART_MAIN | lv.STATE_DEFAULT)
        self.play_btn.set_style_shadow_color(lv.color(0xE94560), lv.PART_MAIN | lv.STATE_DEFAULT)
        self.play_btn.set_style_shadow_opa(80, lv.PART_MAIN | lv.STATE_DEFAULT)
        self.play_icon = lv.label(self.play_btn)
        var f24 = lv.montserrat_font(24)
        if f24 != nil self.play_icon.set_style_text_font(f24, lv.PART_MAIN | lv.STATE_DEFAULT) end
        self.play_icon.set_text(lv.SYMBOL_PLAY)
        self.play_icon.center()
        self.play_btn.add_event_cb(/obj, evt -> self.toggle_play(), lv.EVENT_CLICKED, 0)
    end

    #- Update station info -#
    def update_station_info()
        var station = self.stations[self.current_station_idx]

        self.station_label.set_text(station['name'])
        self.bitrate_label.set_text(station['bitrate'])
        self.info_label.set_text(f"Genre: {station['genre']}")
        self.station_dropdown.set_text(f"{self.current_station_idx + 1}/{size(self.stations)}: {station['name']}")

        print(f"Station: {station['name']}")
        print(f"URL: {station['url']}")
        print(f"Bitrate: {station['bitrate']}")
    end

    #- Previous station -#
    def prev_station()
        self.current_station_idx -= 1
        if self.current_station_idx < 0
            self.current_station_idx = size(self.stations) - 1
        end
        self.update_station_info()
    end

    #- Next station -#
    def next_station()
        self.current_station_idx += 1
        if self.current_station_idx >= size(self.stations)
            self.current_station_idx = 0
        end
        self.update_station_info()
    end

    #- Volume changed -#
    def volume_changed(slider)
        self.volume = slider.get_value()
        self.volume_label.set_text(f"{self.volume}%")

        if self.is_muted
            self.is_muted = false
            self.mute_icon.set_text(lv.SYMBOL_VOLUME_MAX)
            self.mute_btn.set_style_bg_color(lv.color(0xE94560), lv.PART_MAIN | lv.STATE_DEFAULT)
        end

        print(f"Volume: {self.volume}%")
    end

    #- Volume up -#
    def volume_up()
        self.volume += 5
        if self.volume > 100 self.volume = 100 end
        self.volume_slider.set_value(self.volume, lv.ANIM_ON)
        self.volume_label.set_text(f"{self.volume}%")

        if self.is_muted
            self.is_muted = false
            self.mute_icon.set_text(lv.SYMBOL_VOLUME_MAX)
            self.mute_btn.set_style_bg_color(lv.color(0xE94560), lv.PART_MAIN | lv.STATE_DEFAULT)
        end

        print(f"Volume: {self.volume}%")
    end

    #- Volume down -#
    def volume_down()
        self.volume -= 5
        if self.volume < 0 self.volume = 0 end
        self.volume_slider.set_value(self.volume, lv.ANIM_ON)
        self.volume_label.set_text(f"{self.volume}%")

        print(f"Volume: {self.volume}%")
    end

    #- Toggle mute -#
    def toggle_mute()
        self.is_muted = !self.is_muted

        if self.is_muted
            self.mute_icon.set_text(lv.SYMBOL_MUTE)
            self.mute_btn.set_style_bg_color(lv.color(0xFF6B6B), lv.PART_MAIN | lv.STATE_DEFAULT)
            print("Muted")
        else
            self.mute_icon.set_text(lv.SYMBOL_VOLUME_MAX)
            self.mute_btn.set_style_bg_color(lv.color(0xE94560), lv.PART_MAIN | lv.STATE_DEFAULT)
            print("Unmuted")
        end
    end

    #- Toggle play/pause -#
    def toggle_play()
        self.is_playing = !self.is_playing

        if self.is_playing
            self.play_icon.set_text(lv.SYMBOL_PAUSE)
            print(f"Playing: {self.stations[self.current_station_idx]['name']}")
            print(f"Stream URL: {self.stations[self.current_station_idx]['url']}")
        else
            self.play_icon.set_text(lv.SYMBOL_PLAY)
            print("Stopped")
        end
    end
end

#- Create radio player -#
radio = WebRadioPlayer()
print("Web Radio Player UI loaded!")
