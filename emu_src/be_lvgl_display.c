#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include "berry.h"
#include "be_object.h"
#include "be_func.h"
#include "be_vm.h"
#include "lvgl.h"
#include "be_mapping.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define nullptr NULL

/* Display config — read from JS once at lv.start(), then immutable */
static int32_t display_width = 320;
static int32_t display_height = 240;
static bbool display_started = bfalse;
static lv_display_t *display_ref = NULL;

/* Touch state — updated from JS mouse events */
static int32_t touch_x = 0;
static int32_t touch_y = 0;
static bbool touch_pressed = bfalse;

extern const lv_font_t seg7_8;
extern const lv_font_t seg7_10;
extern const lv_font_t seg7_12;
extern const lv_font_t seg7_14;
extern const lv_font_t seg7_16;
extern const lv_font_t seg7_18;
extern const lv_font_t seg7_20;
extern const lv_font_t seg7_24;
extern const lv_font_t seg7_28;
extern const lv_font_t seg7_36;
extern const lv_font_t seg7_48;

/* Framebuffer — allocated by lv0_start */
static uint8_t *framebuf = NULL;

/* Conversion buffer — RGB565 to RGBA8888 */
static uint8_t *convbuf = NULL;
static uint32_t convbuf_size = 0;

/* ---------- EM_JS: read display config from JS globals ---------- */
EM_JS(int, emscripten_lvgl_get_width, (), {
    if (typeof getLvglDisplaySize === 'function') {
        var s = getLvglDisplaySize();
        return s.w;
    }
    return 320;
});

EM_JS(int, emscripten_lvgl_get_height, (), {
    if (typeof getLvglDisplaySize === 'function') {
        var s = getLvglDisplaySize();
        return s.h;
    }
    return 240;
});

/* ---------- EM_JS: push RGBA pixels to canvas ---------- */
EM_JS(void, emscripten_lvgl_push_pixels, (uint8_t *data, int x, int y, int w, int h), {
    if (typeof lvgl_canvas_ctx === 'undefined' || !lvgl_canvas_ctx) {
        console.log('LVGL push_pixels: canvas context NOT available');
        return;
    }
    if (typeof push_count === 'undefined') window.push_count = 0;
    window.push_count++;
    if (window.push_count <= 5) {
        var src = HEAPU8.subarray(data, data + 16);
        console.log('LVGL push_pixels #' + window.push_count + ': x=' + x + ' y=' + y + ' w=' + w + ' h=' + h + ' first_rgba=[' + src[0] + ',' + src[1] + ',' + src[2] + ',' + src[3] + ']');
    }
    var src = HEAPU8.subarray(data, data + w * h * 4);
    var rgba = new Uint8ClampedArray(src);
    var imgData = new ImageData(rgba, w, h);
    lvgl_canvas_ctx.putImageData(imgData, x, y);
});

/* ---------- EM_JS: touch state getters ---------- */
EM_JS(int, emscripten_lvgl_get_touch_x, (), {
    if (typeof lvgl_touch_x !== 'undefined') return lvgl_touch_x;
    return 0;
});

EM_JS(int, emscripten_lvgl_get_touch_y, (), {
    if (typeof lvgl_touch_y !== 'undefined') return lvgl_touch_y;
    return 0;
});

EM_JS(int, emscripten_lvgl_get_touch_pressed, (), {
    if (typeof lvgl_touch_pressed !== 'undefined') return lvgl_touch_pressed;
    return 0;
});

/* ---------- Tick callback: emscripten_get_now() → uint32_t ms ---------- */
static uint32_t emscripten_tick_cb(void) {
    return (uint32_t)emscripten_get_now();
}

/* ---------- RGB565 → RGBA8888 conversion helper ---------- */
static inline uint8_t rgb565_r(uint16_t c) { return (uint8_t)(((c >> 11) & 0x1F) * 255 / 31); }
static inline uint8_t rgb565_g(uint16_t c) { return (uint8_t)(((c >> 5) & 0x3F) * 255 / 63); }
static inline uint8_t rgb565_b(uint16_t c) { return (uint8_t)((c & 0x1F) * 255 / 31); }

/* ---------- Flush callback: RGB565 framebuffer → RGBA8888 canvas ---------- */
static int flush_count = 0;
static void flush_cb(lv_display_t *disp, const lv_area_t *area, uint8_t *px_map) {
    int32_t w = lv_area_get_width(area);
    int32_t h = lv_area_get_height(area);
    int32_t total = w * h;

    /* Log first few flushes */
    if (flush_count < 5) {
        uint16_t first_px = ((uint16_t *)px_map)[0];
        emscripten_log(EM_LOG_CONSOLE, "flush_cb #%d: area=(%d,%d)-(%d,%d) size=%dx%d first_px=0x%04x",
            flush_count, area->x1, area->y1, area->x2, area->y2, w, h, first_px);
        flush_count++;
    }

    /* Ensure conversion buffer is large enough for this flush area. */
    uint32_t needed = (uint32_t)total * 4;
    if (needed > convbuf_size) {
        uint8_t *new_convbuf = realloc(convbuf, needed);
        if (new_convbuf == NULL) {
            emscripten_log(EM_LOG_CONSOLE, "flush_cb: realloc FAILED for %u bytes", needed);
            lv_display_flush_ready(disp);
            return;
        }
        convbuf = new_convbuf;
        convbuf_size = needed;
    }

    /* Convert RGB565 (2 bytes/pixel) → RGBA8888 (4 bytes/pixel) */
    uint16_t *src = (uint16_t *)px_map;
    uint8_t *dst = convbuf;
    for (int32_t i = 0; i < total; i++) {
        uint16_t px = src[i];
        dst[i * 4 + 0] = rgb565_r(px);
        dst[i * 4 + 1] = rgb565_g(px);
        dst[i * 4 + 2] = rgb565_b(px);
        dst[i * 4 + 3] = 0xFF;
    }

    /* Log first few converted pixels */
    if (flush_count <= 5) {
        emscripten_log(EM_LOG_CONSOLE, "flush_cb: converted first pixel R=%d G=%d B=%d A=%d",
            convbuf[0], convbuf[1], convbuf[2], convbuf[3]);
    }

    /* Push to canvas */
    emscripten_lvgl_push_pixels(convbuf, area->x1, area->y1, w, h);

    lv_display_flush_ready(disp);
}

/* ---------- Input device read callback ---------- */
static void indev_read_cb(lv_indev_t *indev, lv_indev_data_t *data) {
    data->point.x = emscripten_lvgl_get_touch_x();
    data->point.y = emscripten_lvgl_get_touch_y();
    data->state = emscripten_lvgl_get_touch_pressed() ? LV_INDEV_STATE_PRESSED : LV_INDEV_STATE_RELEASED;
}

/* ---------- Berry: lv.start() ---------- */
int lv0_start(bvm *vm) {
    if (display_started) {
        be_return(vm);
    }

    emscripten_log(EM_LOG_CONSOLE, "lv0_start: BEGIN");

    /* Read display size from JS config — immutable from here */
    display_width = emscripten_lvgl_get_width();
    display_height = emscripten_lvgl_get_height();
    emscripten_log(EM_LOG_CONSOLE, "lv0_start: display %dx%d", display_width, display_height);

    /* Set tick source */
    lv_tick_set_cb(emscripten_tick_cb);

    /* Create display */
    display_ref = lv_display_create(display_width, display_height);
    emscripten_log(EM_LOG_CONSOLE, "lv0_start: display created=%p", (void*)display_ref);

    /* Allocate framebuffer (full screen, single-buffered, partial render mode) */
    uint32_t stride = lv_draw_buf_width_to_stride(display_width, LV_COLOR_FORMAT_NATIVE);
    uint32_t buf_size = stride * display_height;
    framebuf = malloc(buf_size);
    emscripten_log(EM_LOG_CONSOLE, "lv0_start: framebuf=%p stride=%u buf_size=%u", (void*)framebuf, stride, buf_size);
    lv_display_set_buffers(display_ref, framebuf, NULL, buf_size, LV_DISPLAY_RENDER_MODE_PARTIAL);

    /* Set flush callback */
    lv_display_set_flush_cb(display_ref, flush_cb);

    /* Create pointer input device */
    lv_indev_t *indev = lv_indev_create();
    lv_indev_set_type(indev, LV_INDEV_TYPE_POINTER);
    lv_indev_set_read_cb(indev, indev_read_cb);

    /* Force immediate first render */
    lv_refr_now(NULL);
    emscripten_log(EM_LOG_CONSOLE, "lv0_start: lv_refr_now done, flush_count=%d", flush_count);

    display_started = btrue;
    be_return(vm);
}

/* ---------- Berry: lv.montserrat_font(size) ---------- */
int lv0_load_montserrat_font(bvm *vm) {
    int argc = be_top(vm);
    if (argc >= 1 && be_isint(vm, 1)) {
        int32_t size = be_toint(vm, 1);
        const lv_font_t *font = NULL;

        switch (size) {
            case 10:  font = &lv_font_montserrat_tasmota_10;  break;
            case 14:  font = &lv_font_montserrat_tasmota_14;  break;
            case 20:  font = &lv_font_montserrat_tasmota_20;  break;
            case 28:  font = &lv_font_montserrat_tasmota_28;  break;
            default:  font = NULL; break;
        }

        if (font != NULL) {
            be_find_global_or_module_member(vm, "lv.lv_font");
            be_pushcomptr(vm, (void*)font);
            be_call(vm, 1);
            be_pop(vm, 1);
            be_return(vm);
        }
    }
    be_return_nil(vm);
}

/* ---------- Berry: lv.seg7_font(size) ---------- */
int lv0_load_seg7_font(bvm *vm) {
    int argc = be_top(vm);
    if (argc >= 1 && be_isint(vm, 1)) {
        const lv_font_t *font = NULL;

        switch (be_toint(vm, 1)) {
            case 8:  font = &seg7_8;  break;
            case 10: font = &seg7_10; break;
            case 12: font = &seg7_12; break;
            case 14: font = &seg7_14; break;
            case 16: font = &seg7_16; break;
            case 18: font = &seg7_18; break;
            case 20: font = &seg7_20; break;
            case 24: font = &seg7_24; break;
            case 28: font = &seg7_28; break;
            case 36: font = &seg7_36; break;
            case 48: font = &seg7_48; break;
            default: break;
        }

        if (font != NULL) {
            be_find_global_or_module_member(vm, "lv.lv_font");
            be_pushcomptr(vm, (void*)font);
            be_call(vm, 1);
            be_pop(vm, 1);
            be_return(vm);
        }
    }
    be_return_nil(vm);
}

/* ---------- Berry: lv.get_hor_res() / lv.get_ver_res() already work via lv_func[] ---------- */

/* ---------- lv_tasmota Berry module ---------- */
#if !BE_USE_PRECOMPILED_OBJECT
void be_load_lv_tasmotalib(bvm *vm) {
    static const bnfuncinfo members[] = {
        { "start", lv0_start },
        { "font_montserrat", lv0_load_montserrat_font },
        { "montserrat_font", lv0_load_montserrat_font },
        { "seg7_font", lv0_load_seg7_font },
        { NULL, NULL }
    };
    be_regclass(vm, "lv_tasmota", members);
}
#else
/* @const_object_info_begin
module lv_tasmota (scope: global, strings: weak) {
    start, func(lv0_start)
    font_montserrat, func(lv0_load_montserrat_font)
    montserrat_font, func(lv0_load_montserrat_font)
    seg7_font, func(lv0_load_seg7_font)
}
@const_object_info_end */
#include "be_fixed_lv_tasmota.h"
#endif

#endif /* __EMSCRIPTEN__ */
