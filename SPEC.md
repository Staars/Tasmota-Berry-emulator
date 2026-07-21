# Tasmota-Berry-emulator Enhancement Specification

## Phase 1: LED Strip Configuration UI — DONE

### 1.1 Current State
- Canvas renders LED strip/matrix as colored rectangles
- Single slider for matrix width (1-<number of pixel>)
- Basic REPL textarea with minimal styling
- No device configuration persistence

### 1.2 Goals
Replace the minimal UI with a proper virtual device configuration panel that gives users full control over their emulated LED hardware. All UI is about configuration of virtual devices.

### 1.3 LED Strip Configuration Panel

**Layout**: Side panel (left or collapsible) next to the canvas area.

**Controls:**

| Control | Type | Range/Options | Default |
|---------|------|---------------|---------|
| Pixel count | Number input + slider | 1-300 | 64 |
| Pixel type | Dropdown | WS2812 (RGB), SK6812 (RGBW) | WS2812 |
| Matrix width | Number input + slider | 1-64 | 32 |
| Brightness | Slider | 0-255 | 127 |
| Gamma correction | Toggle | on/off | on |
| Layout | Dropdown | Linear, Matrix row-by-row, Matrix serpentine, Circular | Linear |
| Pixel size (display) | Slider | 8-48 px | 23 |

**Behavior**: Changing any control updates the virtual strip object and triggers a re-render. Settings persist in `localStorage`.

### 1.4 REPL Improvements
- Auto-resize textarea on multi-line input
- Command history with up/down arrows (partially exists)
- Display Berry error tracebacks with clickable references

### 1.5 Files to Modify

| File | Changes |
|------|---------|
| `docs/index.html` | Restructure layout: side panel + canvas + controls. Add all new UI elements. UI control logic and localStorage persistence implemented inline. |
| `docs/style.css` (new) | Extract inline styles for maintainability |

---

## Phase 2: LVGL Display UI Mockup

### 2.1 Purpose
Design and build the UI layout for a future LVGL display area. This is purely frontend work - HTML/CSS/JS only. No LVGL C code, no WASM changes. The goal is to validate the UI design before committing to the implementation phase.

### 2.2 LVGL Display Area

**What it is**: A second canvas element on the page that will eventually show LVGL-rendered content. For now it shows a placeholder/grid to validate sizing, positioning, and resolution controls.

**Display configuration controls:**

| Control | Type | Range/Options | Default |
|---------|------|---------------|---------|
| Resolution | Dropdown | 128x64, 128x128, 135x240, 240x240, 240x320, 320x240, 320x480, 480x320, 480x480, Custom | 320x240 |
| Custom width | Number input | 80-800 | 320 |
| Custom height | Number input | 80-800 | 240 |
| Color depth | Dropdown | 1-bit (mono), 16-bit (color) | 16-bit |
| Rotation | Dropdown | 0, 90, 180, 270 | 0 |

**Resolution presets** are derived from common Tasmota display descriptors (SSD1306 128x64, ST7789 240x320, ILI9341 240x320, etc.).

**Behavior**: Canvas resizes to match selected resolution. Aspect ratio maintained visually (canvas element scaled via CSS `image-rendering: pixelated` to fit available space while keeping pixel-perfect rendering). Custom width/height inputs appear only when "Custom" is selected in the resolution dropdown.

### 2.3 Display Config Lifecycle

The display configuration (resolution, color depth) is mutable **before** `lv.start()` is called. Once `lv.start()` runs, the config is frozen until page reload.

```
Page load → UI config panel active (resolution, color depth, rotation editable)
  ↓
JS stores config in lvgl_config object (localStorage)
  ↓
Berry code runs → calls lv.start()
  ↓
C calls EM_JS to read display size → lv_display_create(w, h)
  ↓
Config frozen → display dimensions locked (display_started = true)
```

This mirrors Tasmota's behavior where `display.ini` is loaded once at boot and the display dimensions are fixed afterward.

**Vanilla Berry compatibility**: The emulator must support existing Tasmota Berry LVGL code unchanged. Example:

```berry
lv.start()
hres = lv.get_hor_res()   # returns configured width
vres = lv.get_ver_res()   # returns configured height
scr = lv.scr_act()
```

No custom API. No extra parameters. `lv.start()`, `lv.get_hor_res()`, `lv.get_ver_res()` all work as on real hardware.

### 2.4 Toolbar

A persistent toolbar sits below the heading and is always visible, regardless of section toggles. It provides quick access to key controls and status.

**Current controls:**

| Element | Type | Description |
|---------|------|-------------|
| LED toggle | Checkbox | Show/hide the LED config panel and canvas |
| LVGL toggle | Checkbox | Show/hide the LVGL section (controls `#lvgl_controls` + `#lvgl_canvas`) |
| Berry status | Label | "● running" / "○ stopped" — always visible, updates when Berry VM state changes |

**Extensible**: The toolbar is designed to grow. Future additions may include virtual sensors, GPIO buttons, display power toggle, etc. New controls are appended to the flex row.

**Why a toolbar**: Toggle controls placed inside collapsible sections disappear when the section is hidden, making it impossible to re-enable. The toolbar ensures critical controls are always accessible.

### 2.5 Touch Cursor Visualization

When the LVGL section is visible, mouse interactions on the LVGL canvas update a touch indicator:
- Coordinates displayed in a label below the LVGL canvas (e.g., "touch: x=150, y=120")
- Coordinates reset to 0,0 on mouse leave

This validates the touch coordinate mapping that will be needed in Phase 3.

### 2.6 Page Layout

The toolbar is always visible below the heading. Both LED and LVGL sections are stacked vertically below it. The LVGL section can be toggled on/off via the toolbar.

```
+----------------------------------------------+
| Header: "Berry in a Browser"                 |
+----------------------------------------------+
| Toolbar (always visible)                      |
| [✓] LED   [✓] LVGL   | ● Berry running      |
+----------------------------------------------+
| LED Config Panel (hidden when LED toggle off) |
| [Pixel size] [Preset] [Columns] [Serpentine] |
+----------------------------------------------+
| LED Canvas (hidden when LED toggle off)       |
+----------------------------------------------+
| LVGL Config Panel (hidden when LVGL off)     |
| [Resolution] [Custom W/H] [BPP] [Rotation]  |
+----------------------------------------------+
| LVGL Canvas                                   |
| Touch coordinates: x=0, y=0                  |
+----------------------------------------------+
| REPL output                                  |
+----------------------------------------------+
| REPL textarea + Run button                   |
+----------------------------------------------+
```

### 2.7 Files to Modify

| File | Changes |
|------|---------|
| `docs/index.html` | Add persistent toolbar below heading (LVGL toggle + Berry status), move LVGL toggle from section to toolbar, update toggle handler to target LVGL controls/canvas only |

---

## Phase 3: LVGL Browser Emulation

### 3.1 Current State
- LVGL 9.5.0 source in `LVGL/lvgl/` (clean upstream copy)
- LVGL compiles cleanly with Emscripten to WASM (463 C files → 462 .o files)
- Berry-LVGL bindings compiled and linked: 78 widget classes, LVGL module with all constants/functions
- Solidified Berry headers generated (lv_module_init, LVGL_glob class, lv_extra)
- `be_modtab.c` registers lv, lv_extra, lv_tasmota modules + color/font classes
- `docs/berry.js` builds at 3.2MB (WASM single-file with ASYNCIFY)
- ✅ Display bridge implemented: `lv.start()` → canvas flush via `be_lvgl_display.c`
- ✅ Touch input implemented: mouse events → LVGL indev driver
- ✅ LVGL tick driver: `lv_tick_set_cb()` with `emscripten_get_now()`
- `Driver.display` is a stub variable in `classes_for_emulation.be`
- Callback infrastructure in `be_cb_module.c` already anticipates LVGL patterns
- `be_mapping.h` provides the FFI infrastructure (`BE_FUNC_CTYPE_DECLARE`, `be_call_c_func`) that LVGL Berry bindings use

### 3.2 Goals
Run the same Tasmota Berry LVGL code in the browser that runs on a physical device. **Vanilla Berry compatibility** — no API changes. Code like `lv.start()`, `lv.get_hor_res()`, `lv.get_ver_res()` works as-is. Full widget parity. Touchscreen emulation via mouse on canvas.

### 3.3 Target Versions
- **LVGL**: 9.5.0 (matching current Tasmota main branch)
- **Berry bindings**: Auto-generated C files from Tasmota's `lib/libesp32_lvgl/lv_binding_berry/`

### 3.4 Architecture

```
JS config panel stores resolution → getLvglDisplaySize() returns it
                                      ↓
Berry: lv.start() → C calls EM_JS to read display size → lv_display_create(w, h) → flush callback → EM_JS → Canvas
Berry: lv.get_hor_res() → returns display_width
Berry: lv.get_ver_res() → returns display_height
Touch events → JS event listener → JS globals → EM_JS getters → LVGL indev driver
```

**Display config lifecycle**: JS stores config in `lvgl_config` object (persisted in localStorage). C reads config via EM_JS when `lv.start()` is called. Once `display_started = true`, further config changes from JS are ignored. This mirrors Tasmota's `display.ini` loaded once at boot.

### 3.4a LVGL Folder Structure

All LVGL-related code lives in the `LVGL/` folder, separate from the rest of the emulator:

```
LVGL/
├── lv_conf.h                          # Browser-appropriate LVGL config (LV_STDLIB_CLIB, LV_OS_NONE)
├── lvgl/                              # Clean LVGL 9.5.0 source (unmodified upstream)
│   ├── src/
│   │   ├── core/                      # LVGL core: objects, display, indev, draw, tick, event
│   │   ├── draw/                      # Software rendering (SW renderer only)
│   │   ├── font/                      # Built-in fonts (Montserrat, misc)
│   │   ├── misc/                      # Utilities, alloc, cache, math, color
│   │   ├── widgets/                   # All built-in widgets
│   │   └── libs/                      # Third-party libs (disabled in lv_conf.h)
│   └── themes/                        # Default, Mono, Simple themes
├── binding/
│   ├── generate/                      # Auto-generated C binding files (from Tasmota Phase 2)
│   │   ├── be_lvgl_module.c           # LVGL C functions registered as Berry module
│   │   ├── be_lv_c_mapping.h          # Type definitions + struct mappings
│   │   └── be_lvgl_widgets_lib.c      # Widget class registration tables
│   ├── src/                           # Hand-written binding files
│   │   ├── lv_berry.c                 # lv.start(), lv.get_hor_res(), lv.get_ver_res()
│   │   ├── lv_berry.h                 # Declarations for hand-written bindings
│   │   ├── be_lvgl_ctypes_definitions.c  # Ctypes struct definitions
│   │   ├── be_ctypes.c                # Ctypes implementation
│   │   ├── be_lvgl_glob_lib.c         # LVGL glob library
│   │   ├── be_lv_extra.c              # lv_extra module implementation
│   │   ├── lv_colorwheel.c            # Color wheel widget
│   │   ├── lv_stripes.c               # Stripes widget
│   │   ├── lv_tasmota_logo.c          # Tasmota logo widget
│   │   └── embedded/                  # Berry scripts (loaded at runtime in browser)
│   │       ├── lv.be                  # Main Berry LVGL module
│   │       ├── lvgl_extra.be          # Extra Berry functions
│   │       └── lvgl_glob.be           # Global LVGL state
│   │   └── solidify/                  # Generated Berry → C headers (via native berry -s -g)
│   │       ├── solidified_lv.h         # lv_module_init closure
│   │       ├── solidified_lvgl_glob.h  # LVGL_glob class
│   │       └── solidified_lvgl_extra.h # lv_extra module
│   ├── mapping/                       # Mapping metadata (not directly compiled)
│   │   ├── lv_enum.h                  # LVGL enums → Berry constants
│   │   └── lv_funcs.h                 # LVGL functions → Berry function names
│   └── stubs/                         # Tasmota dependency stubs (no-ops for browser)
│       ├── be_ctypes.h                # Ctypes types from berry_tasmota
│       ├── lv_theme_haspmota.h        # Theme stub (returns NULL/false)
│       ├── tasmota_lv_stdlib.h        # Custom allocator stub (no-op)
│       └── lv_freetype_stub.h         # FreeType stub (compiled out)
└── assets/
    ├── fonts/                         # Extra fonts (DSEG7, RobotoCondensed, icons, pixel_perfect, Symbols)
    └── src/                           # Compiled font C files and theme assets
        ├── fonts/                     # Compiled font sources (seg7, montserrat, icons, roboto)
        ├── lv_theme_haspmota.c        # Haspmota theme
        └── tasmota_lvgl_assets.h      # Asset declarations
```

**Key decisions:**
- `lv_conf.h` uses `LV_USE_STDLIB_MALLOC = LV_STDLIB_CLIB` (standard malloc, no custom allocator needed)
- `lv_conf.h` uses `LV_OS_NONE` (single-threaded in browser)
- All hardware-dependent features disabled (SDL, X11, Wayland, GPU, FreeType, LodePNG, QRCODE, FFMPEG)
- Solidified Berry headers generated via native Berry compiler with `-s -g` (strict + named globals)
- `lv_mem_core_berry.c` is compiled out by `LV_USE_STDLIB_CLIB`

**How the 4-phase Tasmota build system relates:**

| Phase | Tasmota Tool | Output | Browser Status |
|-------|-------------|--------|----------------|
| 1 | `preprocessor.py` | `lv_enum.h`, `lv_funcs.h` | Pre-generated in `binding/mapping/` |
| 2 | `convert.py` | `be_lvgl_module.c`, `be_lv_c_mapping.h`, `be_lvgl_widgets_lib.c` | Pre-generated in `binding/generate/` |
| 3a | Berry `solidify_all.be` | `solidified_lv.h`, `solidified_lvgl_glob.h`, `solidified_lvgl_extra.h` | Generated via native Berry compiler (`-s -g` flags) in `binding/src/solidify/` |
| 3b | `coc` tool | `be_fixed_*.h`, `be_const_strtab.h` | Generated in `generate/` (78 headers) |
| 4 | PlatformIO compile | .a library | Replaced by Emscripten Makefile — compiles to `build/lvgl/`, links into `docs/berry.js` |

All Tasmota-specific headers (`be_ctypes.h`, `lv_theme_haspmota.h`, `tasmota_lv_stdlib.h`, `lv_freetype_stub.h`) are provided as stubs in `binding/stubs/`.

### 3.5 Implementation Steps

#### Step 1: LVGL Library Compilation — DONE
1. ✅ LVGL 9.5.0 source is in `LVGL/lvgl/` (clean, unmodified upstream)
2. ✅ `LVGL/lv_conf.h` configured for browser: `LV_STDLIB_CLIB`, `LV_OS_NONE`, no hardware features
3. ✅ LVGL added to Makefile, compiles to `build/lvgl/` via Emscripten (463 C files, 462 .o files, 2.8MB)
4. ✅ Clean compilation verified

#### Step 2: Display Driver Bridge — DONE
1. ✅ `emu_src/be_lvgl_display.c` created (291 lines):
   - Global state: `display_width`, `display_height`, `display_started`
   - `lv.start()` implementation (`lv0_start()`): reads display size from JS via EM_JS (`emscripten_lvgl_get_width/height()`), calls `lv_display_create(width, height)`, allocates full-screen framebuffer, sets flush callback, sets `display_started = true`
   - `lv.get_hor_res()` → returns `display_width`
   - `lv.get_ver_res()` → returns `display_height`
   - Flush callback (`flush_cb()`): RGB565 → RGBA8888 conversion, pushes to canvas via `emscripten_lvgl_push_pixels()` using `putImageData()`
   - Dirty area optimization (LVGL `LV_DISPLAY_RENDER_MODE_PARTIAL` only flushes changed regions)
   - Font loading: `lv0_load_montserrat_font(size)`, `lv0_load_seg7_font()` for Berry
   - `lv_tasmota` Berry module registered with `start`, `font_montserrat`, `montserrat_font`, `seg7_font`
2. LVGL tick mechanism:
   - `lv_tick_set_cb(emscripten_tick_cb)` — returns `emscripten_get_now()` for millisecond timestamps
   - `lv_timer_handler()` called every 5ms from `tasmota_run_loop()` via `emscripten_set_interval`

#### Step 3: Touch Input Driver — DONE
1. ✅ Touch input implemented in `emu_src/be_lvgl_display.c` (not a separate file):
   - Touch state: `lvgl_touch_x`, `lvgl_touch_y`, `lvgl_touch_pressed` JS globals
   - EM_JS getters: `emscripten_lvgl_get_touch_x/y/pressed()` read JS globals from C
   - `indev_read_cb()`: returns current touch state to LVGL
   - `lv_indev_create()` with `LV_INDEV_TYPE_POINTER` in `lv0_start()`
2. JS mouse event handlers in `docs/index.html`:
   - `mousemove` → updates `window.lvgl_touch_x/y` and touch info label
   - `mousedown`/`mouseup` → sets `window.lvgl_touch_pressed`
   - `mouseleave` → resets touch state to 0

#### Step 4: Berry Bindings (C-level, no .be files) — DONE
1. ✅ Pre-generated C files in `LVGL/binding/generate/` (be_lvgl_module.c, be_lv_c_mapping.h, be_lvgl_widgets_lib.c)
2. ✅ Hand-written binding files in `LVGL/binding/src/` (lv_berry.c, be_lvgl_ctypes_definitions.c, etc.)
3. ✅ Mapping headers in `LVGL/binding/mapping/` (lv_enum.h, lv_funcs.h)
4. ✅ Stub headers in `LVGL/binding/stubs/` (be_ctypes.h, lv_theme_haspmota.h, tasmota_lv_stdlib.h, lv_freetype_stub.h)
5. ✅ Solidified Berry headers generated via native Berry compiler (`solidified_lv.h`, `solidified_lvgl_glob.h`, `solidified_lvgl_extra.h`)
6. ✅ `coc` tool generated 78 `be_fixed_*.h` headers + `be_const_strtab.h`
7. ✅ `be_modtab.c` updated with `lv`, `lv_extra`, `lv_tasmota` modules and 40+ widget classes (lv_arc, lv_bar, lv_button, lv_label, lv_slider, lv_switch, etc.) plus `lv_color`, `lv_font`, `LVGL_glob` classes
8. ✅ Binding sources compiled and linked into `docs/berry.js` (3.2MB WASM)

#### Step 5: Tasmota Integration — PARTIALLY DONE
1. ✅ `env.be` loads LVGL support: imports `lv`, `lv_tasmota`, wires `lv.start`, `lv.font_montserrat`, `lv.montserrat_font`, `lv.seg7_font`
2. `Driver.display` in `tasmota_env/classes_for_emulation.be` — exists as a bare var declaration, not yet connected to LVGL display object
3. `tasmota.add_driver(d)` — not yet implemented

### 3.6 Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `LVGL/` | Add | All LVGL-related code (source, bindings, assets) |
| `LVGL/lvgl/` | Add | Clean LVGL 9.5.0 source (unmodified upstream) |
| `LVGL/lv_conf.h` | Create | Browser-appropriate LVGL config (LV_STDLIB_CLIB, LV_OS_NONE) |
| `LVGL/binding/generate/` | Add | Auto-generated Berry-LVGL C bindings |
| `LVGL/binding/src/` | Add | Hand-written binding files |
| `LVGL/binding/stubs/` | Add | Tasmota dependency stubs (no-ops) |
| `LVGL/assets/` | Add | Extra fonts and theme assets |
| `emu_src/be_lvgl_display.c` | Create | Display flush bridge, touch input, font loading, lv_tasmota module |
| `docs/index.html` | Modify | Wire up touch events to LVGL indev, LVGL config controls |
| `default/be_modtab.c` | Modify | Register `lv`, `lv_extra`, `lv_tasmota` modules + widget classes |
| `Makefile` | Modify | Add LVGL sources, binding sources, new targets |

### 3.7 Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| ✅ LVGL 9.5.0 compilation issues with Emscripten | Resolved — minimal config with all hardware disabled compiles cleanly |
| ✅ Berry binding files depend on Tasmota headers | Stubs provided in `LVGL/binding/stubs/` (be_ctypes.h, lv_theme_haspmota.h, tasmota_lv_stdlib.h, lv_freetype_stub.h) |
| ✅ Touch coordinate precision | Working — mouse events mapped to LVGL canvas coordinates via EM_JS |
| WASM performance for complex LVGL UIs | Enable `LV_USE_PERF_MONITOR`, profile early, optimize buffer sizes |
| LVGL framebuffer memory in WASM | Configure buffer sizes in `lv_conf.h`, leverage Emscripten heap |

### 3.8 Testing Strategy

1. **Compilation**: Clean build with `make web` succeeds
2. **Smoke test**: `import lv` in REPL, create a basic label, verify renders on canvas
3. **Widget gallery**: Berry script instantiating every widget type, verify all render
4. **Touch test**: Click a button widget, verify `LV_EVENT_CLICKED` fires in Berry
5. **Comparison test**: Same Berry LVGL code on physical device vs emulator, compare output
