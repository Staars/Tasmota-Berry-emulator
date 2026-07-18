# Tasmota-Berry-emulator Enhancement Specification

## Phase 1: LED Strip Configuration UI

### 1.1 Current State
- Canvas renders LED strip/matrix as colored rectangles
- Single slider for matrix width (1-64)
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
| `docs/index.html` | Restructure layout: side panel + canvas + controls. Add all new UI elements. |
| `docs/style.css` (new) | Extract inline styles for maintainability |
| `docs/ui.js` (new) | UI control logic, localStorage persistence |

---

## Phase 2: LVGL Display UI Mockup

### 2.1 Purpose
Design and build the UI layout for a future LVGL display area. This is purely frontend work - HTML/CSS/JS only. No LVGL C code, no WASM changes. The goal is to validate the UI design before committing to the implementation phase.

### 2.2 LVGL Display Area

**What it is**: A second canvas element on the page that will eventually show LVGL-rendered content. For now it shows a placeholder/grid to validate sizing, positioning, and resolution controls.

**Display resolution controls:**

| Control | Type | Range/Options | Default |
|---------|------|---------------|---------|
| Resolution | Dropdown | 240x135, 240x240, 320x240, 320x480, 480x320, 480x480, Custom | 320x240 |
| Custom width | Number input | 80-800 | 320 |
| Custom height | Number input | 80-800 | 240 |
| Orientation | Dropdown | Portrait, Landscape | Portrait |

**Behavior**: Canvas resizes to match selected resolution. Aspect ratio maintained visually (canvas element scaled to fit available space while keeping pixel-perfect rendering via CSS `image-rendering: pixelated`).

### 2.3 Mode Switching

The page supports two display modes:

| Mode | Canvas shown | Config panel | Description |
|------|-------------|--------------|-------------|
| LED | LED canvas | LED strip config | Current functionality |
| LVGL | LVGL display canvas | Display resolution config | Placeholder for LVGL |

**Switching**: Toggle button or tabs above the canvas area. Mode persists in `localStorage`.

### 2.4 Touch Cursor Visualization

When in LVGL mode, mouse interactions on the canvas show a touch indicator:
- Small circle at mouse position on press/drag
- Different visual for press vs release
- Coordinates displayed in a label below the canvas

This validates the touch coordinate mapping that will be needed in Phase 3.

### 2.5 Page Layout (both modes)

```
+------------------+------------------------+
| Config Panel     | Canvas Area            |
| (LED settings    | (LED or LVGL display)  |
|  or display      |                        |
|  settings)       |                        |
|                  |                        |
|                  +------------------------+
|                  | Status/Info bar        |
+------------------+------------------------+
| REPL textarea                                |
+----------------------------------------------+
```

### 2.6 Files to Create/Modify

| File | Changes |
|------|---------|
| `docs/index.html` | Add LVGL canvas, mode toggle, resolution controls, touch cursor |
| `docs/style.css` | Extend with LVGL mode styles, canvas scaling |
| `docs/ui.js` | LVGL mode logic, resolution controls, mode switching, touch visualization |

---

## Phase 3: LVGL Browser Emulation

### 3.1 Current State
- Zero LVGL code in the repository
- `Driver.display` is a stub variable in `classes_for_emulation.be`
- Callback infrastructure in `be_cb_module.c` already anticipates LVGL patterns
- `be_mapping.h` provides the FFI infrastructure (`BE_FUNC_CTYPE_DECLARE`, `be_call_c_func`) that LVGL Berry bindings use
- `be_modtab.c` already has `#ifdef USE_LVGL` sections for module/class registration

### 3.2 Goals
Run the same Tasmota Berry LVGL code in the browser that runs on a physical device. Full widget parity, including HASPmota. Touchscreen emulation via mouse on canvas.

### 3.3 Target Versions
- **LVGL**: 9.5.0 (matching current Tasmota main branch)
- **Berry bindings**: Auto-generated C files from Tasmota's `lib/libesp32_lvgl/lv_binding_berry/`

### 3.4 Architecture

```
Berry LVGL code -> Berry VM (WASM) -> LVGL 9.5.0 (WASM) -> flush callback -> EM_JS -> Canvas ImageData
Touch events -> JS event listener -> EM_JS callback -> LVGL indev driver
```

All LVGL integration happens at the C level, following the same pattern as `be_crypto_module.c`:
- Binding C files go into `emu_src/`
- Module registered in `be_modtab.c` via `be_extern_native_module(lv)`
- No `.be` wrapper files needed - users simply `import lv`

### 3.5 Implementation Steps

#### Step 1: LVGL Library Compilation
1. Add LVGL 9.5.0 source to `lib/libesp32_lvgl/lvgl/`
2. Create `tasmota_lv_conf.h` with browser-appropriate settings (disable PSRAM, disable filesystem drivers, enable all widgets)
3. Add LVGL to Makefile `SRCPATH` and compile to WASM via Emscripten
4. Verify clean compilation

#### Step 2: Display Driver Bridge
1. Create `emu_src/be_lvgl_display.c`:
   - Implement `lv_display_t` flush callback
   - On flush: copy pixel data from LVGL framebuffer to shared memory
   - Call EM_JS function to push framebuffer to JavaScript
   - Dirty area optimization (only flush changed regions)
2. Connect to the LVGL canvas from Phase 2 via `docs/lvgl_renderer.js`:
   - Receive pixel data from WASM via `HEAPU8` view
   - Render via `CanvasRenderingContext2D.putImageData()`
   - Support color formats: RGB565, RGB888, ARGB8888
3. LVGL tick mechanism:
   - `setInterval` calling `lv_tick_inc(5)` every 5ms
   - `setInterval` calling `lv_task_handler()` every 5ms

#### Step 3: Touch Input Driver
1. Create `emu_src/be_lvgl_indev.c`:
   - Implement `lv_indev_t` read callback
   - Maintain touch state: `{x, y, pressed}`
   - On read: return current touch state from JS
2. Connect to the touch visualization from Phase 2:
   - Reuse existing mouse event handlers on LVGL canvas
   - Forward coordinates to LVGL indev driver via EM_JS

#### Step 4: Berry Bindings (C-level, no .be files)
1. Copy generated C files from `lv_binding_berry/src/` into `emu_src/`
2. Copy mapping headers (`lv_enum.h`, `lv_funcs.h`) into include path
3. Add `be_extern_native_module(lv)` to `be_modtab.c`
4. Add `&be_native_module(lv)` to `be_module_table[]` under `#ifdef USE_LVGL`
5. Add binding C sources to Makefile `SRCPATH`

#### Step 5: Tasmota Integration
1. Implement `Driver.display` in `classes_for_emulation.be` - connect to LVGL display object
2. Update `env.be` to load LVGL support
3. Port HASPmota source files from `lv_haspmota/` and integrate at C level
4. Ensure `tasmota.add_driver(d)` works with display drivers

### 3.6 Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `lib/libesp32_lvgl/lvgl/` | Add | LVGL 9.5.0 source |
| `lib/libesp32_lvgl/lv_binding_berry/` | Add | Berry bindings from Tasmota |
| `tasmota/include/tasmota_lv_conf.h` | Create | LVGL configuration for browser |
| `emu_src/be_lvgl_display.c` | Create | Display flush bridge |
| `emu_src/be_lvgl_indev.c` | Create | Touch input bridge |
| `docs/lvgl_renderer.js` | Modify | Connect Phase 2 canvas to WASM framebuffer |
| `docs/index.html` | Modify | Wire up touch events to LVGL indev |
| `default/be_modtab.c` | Modify | Register `lv` module under `USE_LVGL` |
| `Makefile` | Modify | Add LVGL sources, binding sources, new targets |

### 3.7 Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| LVGL 9.5.0 compilation issues with Emscripten | Start with minimal config, disable optional features, fix incrementally |
| Berry binding files depend on `berry_mapping` library | `be_mapping.h` already provides the needed FFI infrastructure |
| WASM performance for complex LVGL UIs | Enable `LV_USE_PERF_MONITOR`, profile early, optimize buffer sizes |
| LVGL framebuffer memory in WASM | Configure buffer sizes in `lv_conf.h`, leverage Emscripten heap |
| Touch coordinate precision | Handle DPI scaling, test with multiple display resolutions |
| HASPmota has many dependencies | Start with core LVGL widgets, add HASPmota incrementally |

### 3.8 Testing Strategy

1. **Compilation**: Clean build with `make web` succeeds
2. **Smoke test**: `import lv` in REPL, create a basic label, verify renders on canvas
3. **Widget gallery**: Berry script instantiating every widget type, verify all render
4. **Touch test**: Click a button widget, verify `LV_EVENT_CLICKED` fires in Berry
5. **HASPmota test**: Load a HASPmota page, verify full UI renders and is interactive
6. **Comparison test**: Same Berry LVGL code on physical device vs emulator, compare output
