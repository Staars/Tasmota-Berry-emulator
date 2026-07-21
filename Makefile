# WASM build only — targets: clean, web, clangd
CC          = emcc
CXX         = em++
CFLAGS      = -Wall -Wextra -std=gnu99 -Wno-empty-translation-unit -O3 -Wno-zero-length-array
CXXFLAGS    = -Wall -Wextra -std=c++11 -Wno-empty-translation-unit -O3 -Wno-zero-length-array
LIBS        = -lm -ldl
LFLAGS      = -s WASM=1 -s ASYNCIFY \
              -s 'ASYNCIFY_IMPORTS=["_js_readbuffer"]' \
              -sEMULATE_FUNCTION_POINTER_CASTS=1 \
              -O1 -s SINGLE_FILE=1
TARGET      = docs/berry.js
EMBED_FILES = --preload-file tasmota_env --preload-file demos --preload-file env.be@/env.be
MKDIR       = mkdir

# Source directories
SRCPATH     = src default re1.5 emu_src
INCPATH     = src default re1.5 emu_src generate $(LVGL_INCS)

# LVGL core
LVGL_DIR    = LVGL/lvgl
LVGL_INCS   = $(LVGL_DIR) $(LVGL_DIR)/src LVGL LVGL/binding/src LVGL/binding/generate LVGL/binding/stubs
LVGL_SRCS   = $(shell find $(LVGL_DIR)/src -name "*.c" \
  -not -path "*/drivers/*" \
  -not -path "*/debugging/*" \
  -not -path "*/draw/dma2d/*" \
  -not -path "*/draw/espressif/*" \
  -not -path "*/draw/eve/*" \
  -not -path "*/draw/nanovg/*" \
  -not -path "*/draw/nema_gfx/*" \
  -not -path "*/draw/nxp/*" \
  -not -path "*/draw/opengles/*" \
  -not -path "*/draw/renesas/*" \
  -not -path "*/draw/sdl/*" \
  -not -path "*/draw/snapshot/*" \
  -not -path "*/draw/vg_lite/*" \
  -not -path "*/draw/convert/helium/*" \
  -not -path "*/draw/convert/neon/*" \
  -not -path "*/draw/sw/arm2d/*" \
  -not -path "*/draw/sw/helium/*" \
  -not -path "*/draw/sw/neon/*" \
  -not -path "*/draw/sw/riscv_v/*" \
  -not -path "*/libs/bmp/*" \
  -not -path "*/libs/ffmpeg/*" \
  -not -path "*/libs/freetype/*" \
  -not -path "*/libs/frogfs/*" \
  -not -path "*/libs/FT800*" \
  -not -path "*/libs/gif/*" \
  -not -path "*/libs/gltf/*" \
  -not -path "*/libs/gstreamer/*" \
  -not -path "*/libs/libjpeg*" \
  -not -path "*/libs/libpng/*" \
  -not -path "*/libs/libwebp/*" \
  -not -path "*/libs/lodepng/*" \
  -not -path "*/libs/lz4/*" \
  -not -path "*/libs/nanovg/*" \
  -not -path "*/libs/rlottie/*" \
  -not -path "*/libs/rle/*" \
  -not -path "*/libs/svg/*" \
  -not -path "*/libs/thorvg/*" \
  -not -path "*/libs/tiny_ttf/*" \
  -not -path "*/libs/tjpgd/*" \
  -not -path "*/libs/vg_lite*" \
  -not -path "*/others/*" \
  -not -path "*/osal/lv_pthread*" \
  -not -path "*/osal/lv_freertos*" \
  -not -path "*/osal/lv_cmsis*" \
  -not -path "*/osal/lv_rtthread*" \
  -not -path "*/osal/lv_linux*" \
  -not -path "*/osal/lv_sdl2*" \
  -not -path "*/osal/lv_mqx*" \
  -not -path "*/osal/lv_windows*" \
  -not -path "*/stdlib/builtin/*" \
  -not -path "*/stdlib/micropython/*" \
  -not -path "*/stdlib/rtthread/*" \
  -not -path "*/stdlib/uefi/*")
LVGL_OBJS   = $(patsubst $(LVGL_DIR)/src/%.c, build/lvgl/%.o, $(LVGL_SRCS))
LVGL_CFLAGS = -DLV_CONF_INCLUDE_SIMPLE -Wno-macro-redefined -Wno-unused-function -Wno-unused-parameter \
              -DBE_LV_WIDGET_OBJ -DBE_LV_WIDGET_ARC -DBE_LV_WIDGET_ARCLABEL -DBE_LV_WIDGET_BAR \
              -DBE_LV_WIDGET_BTN -DBE_LV_WIDGET_BUTTON -DBE_LV_WIDGET_BTNMATRIX -DBE_LV_WIDGET_BUTTONMATRIX \
              -DBE_LV_WIDGET_CANVAS -DBE_LV_WIDGET_CHECKBOX -DBE_LV_WIDGET_DROPDOWN \
              -DBE_LV_WIDGET_IMG -DBE_LV_WIDGET_IMAGE -DBE_LV_WIDGET_LABEL -DBE_LV_WIDGET_LINE \
              -DBE_LV_WIDGET_ROLLER -DBE_LV_WIDGET_SLIDER -DBE_LV_WIDGET_SWITCH -DBE_LV_WIDGET_TABLE \
              -DBE_LV_WIDGET_COLORWHEEL -DBE_LV_WIDGET_STRIPES -DBE_LV_WIDGET_ANIMIMG -DBE_LV_WIDGET_CHART \
              -DBE_LV_WIDGET_IMGBTN -DBE_LV_WIDGET_IMAGEBUTTON -DBE_LV_WIDGET_LED -DBE_LV_WIDGET_LIST \
              -DBE_LV_WIDGET_METER -DBE_LV_WIDGET_MSGBOX -DBE_LV_WIDGET_QRCODE \
              -DBE_LV_WIDGET_SCALE -DBE_LV_WIDGET_SCALE_SECTION -DBE_LV_WIDGET_SPINNER \
              -DBE_LV_WIDGET_SPANGROUP -DBE_LV_WIDGET_SPAN -DBE_LV_WIDGET_TABVIEW

# LVGL Berry binding sources
LVGL_BIND_DIR1 = LVGL/binding/src
LVGL_BIND_DIR2 = LVGL/binding/generate
LVGL_BIND_DIR3 = LVGL/binding/src/solidify
LVGL_ASSETS_DIR = LVGL/assets
LVGL_ASSETS_FONTS = $(wildcard $(LVGL_ASSETS_DIR)/src/fonts/*.c) \
                    $(wildcard $(LVGL_ASSETS_DIR)/src/fonts/montserrat/*.c) \
                    $(wildcard $(LVGL_ASSETS_DIR)/src/fonts/icons/*.c) \
                    $(wildcard $(LVGL_ASSETS_DIR)/src/fonts/roboto-latin1/*.c)
LVGL_BIND_SRCS = $(wildcard $(LVGL_BIND_DIR1)/*.c) $(wildcard $(LVGL_BIND_DIR2)/*.c) $(wildcard $(LVGL_ASSETS_DIR)/*.c) $(LVGL_ASSETS_FONTS)
LVGL_BIND_OBJS = $(patsubst %.c, %.o, $(LVGL_BIND_SRCS))

# Berry code generation
GENERATE    = generate
CONFIG      = default/berry_conf.h
COC         = tools/coc/coc
CONST_TAB   = $(GENERATE)/be_const_strtab.h

# Berry source objects
SRCS_C      = $(foreach dir, $(SRCPATH), $(wildcard $(dir)/*.c))
SRCS_CPP    = $(foreach dir, $(SRCPATH), $(wildcard $(dir)/*.cpp))
OBJS_C      = $(patsubst %.c, %.o, $(SRCS_C))
OBJS_CPP    = $(patsubst %.cpp, %.o, $(SRCS_CPP))
OBJS        = $(OBJS_C) $(OBJS_CPP)
DEPS        = $(patsubst %.c, %.d, $(SRCS_C)) $(patsubst %.cpp, %.d, $(SRCS_CPP))
INCFLAGS    = $(foreach dir, $(INCPATH), -I"$(dir)")

ifneq ($(V), 1)
Q=@
MSG=@echo
else
MSG=@true
endif

.PHONY: clean

# ---- Default target: build WASM ----
web: $(TARGET)

$(TARGET): $(OBJS) $(LVGL_OBJS) $(LVGL_BIND_OBJS) $(CONST_TAB)
	$(MSG) [Linking...]
	$(Q) $(CXX) $(OBJS) $(LVGL_OBJS) $(LVGL_BIND_OBJS) $(LFLAGS) $(LIBS) -o $@ $(EMBED_FILES)
	$(MSG) done

# ---- Berry source compilation ----
$(OBJS_C): %.o: %.c
	$(MSG) [Compile C] $<
	$(Q) $(CC) -MM $(CFLAGS) $(INCFLAGS) -MT"$*.d" -MT"$(<:.c=.o)" $< > $*.d
	$(Q) $(CC) $(CFLAGS) $(INCFLAGS) -c $< -o $@

$(OBJS_CPP): %.o: %.cpp
	$(MSG) [Compile C++] $<
	$(Q) $(CXX) -MM $(CXXFLAGS) $(INCFLAGS) -MT"$*.d" -MT"$(<:.cpp=.o)" $< > $*.d
	$(Q) $(CXX) $(CXXFLAGS) $(INCFLAGS) -c $< -o $@

# ---- LVGL core compilation ----
$(LVGL_OBJS): build/lvgl/%.o: $(LVGL_DIR)/src/%.c
	$(MSG) [Compile LVGL] $<
	$(Q) mkdir -p $(dir $@)
	$(Q) $(CC) $(CFLAGS) $(INCFLAGS) $(LVGL_CFLAGS) $(foreach dir, $(LVGL_INCS), -I"$(dir)") -c $< -o $@

# ---- LVGL Berry binding compilation ----
$(LVGL_BIND_OBJS): %.o: %.c
	$(MSG) [Compile LVGL binding] $<
	$(Q) $(CC) $(CFLAGS) $(INCFLAGS) $(LVGL_CFLAGS) $(foreach dir, $(LVGL_INCS), -I"$(dir)") -c $< -o $@

# ---- Berry string table generation ----
$(CONST_TAB): $(GENERATE) $(SRCS_C) $(LVGL_BIND_SRCS) $(CONFIG)
	$(MSG) [Prebuild] generate string table
	$(Q) $(COC) -o $(GENERATE) $(SRCPATH) $(LVGL_BIND_DIR1) $(LVGL_BIND_DIR2) $(LVGL_BIND_DIR3) -c $(CONFIG)

$(GENERATE):
	$(Q) $(MKDIR) $(GENERATE)

$(OBJS) $(LVGL_BIND_OBJS): $(CONST_TAB)

sinclude $(DEPS)

# ---- clangd compile_commands.json ----
clangd: $(CONST_TAB)
	$(Q) echo '[' > compile_commands.json
	$(Q) first=true; \
	for src in $(SRCS_C); do \
		if $$first; then first=false; else echo ',' >> compile_commands.json; fi; \
		printf '  {"directory":"%s","command":"%s -target wasm32-unknown-emscripten -Wall -Wextra -std=gnu99 -Wno-empty-translation-unit -O3 -Wno-zero-length-array -D__EMSCRIPTEN__ -isystem %s %s -c %s -o %s","file":"%s"}' \
			"$(CURDIR)" "$(CC)" "$(EMSCRIPTEN_INC)" "$(INCFLAGS)" \
			"$$src" "$${src%.c}.o" "$$src" >> compile_commands.json; \
	done; \
	for src in $(SRCS_CPP); do \
		if $$first; then first=false; else echo ',' >> compile_commands.json; fi; \
		printf '  {"directory":"%s","command":"%s -target wasm32-unknown-emscripten -Wall -Wextra -std=c++11 -Wno-empty-translation-unit -O3 -Wno-zero-length-array -D__EMSCRIPTEN__ -isystem %s %s -c %s -o %s","file":"%s"}' \
			"$(CURDIR)" "$(CXX)" "$(EMSCRIPTEN_INC)" "$(INCFLAGS)" \
			"$$src" "$${src%.cpp}.o" "$$src" >> compile_commands.json; \
	done; \
	echo '' >> compile_commands.json; echo ']' >> compile_commands.json

# ---- Clean ----
clean:
	$(MSG) [Clean...]
	$(Q) $(RM) $(OBJS) $(DEPS) $(GENERATE)/* $(LVGL_BIND_OBJS)
	$(Q) $(RM) -rf build/lvgl $(TARGET)
	$(MSG) done
