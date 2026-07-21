// Stub for lv_theme_haspmota.h
// HASPmota theme is not included in browser build
#ifndef LV_THEME_HASPMOTA_H
#define LV_THEME_HASPMOTA_H
#include "lvgl.h"
#ifdef __cplusplus
extern "C" {
#endif
// Stub declarations - actual implementation not linked in browser build
static inline lv_theme_t * lv_theme_haspmota_init(lv_display_t * disp, lv_color_t * colors, const lv_font_t * font_small, const lv_font_t * font_normal, const lv_font_t * font_large) { (void)disp; (void)colors; (void)font_small; (void)font_normal; (void)font_large; return NULL; }
static inline bool lv_theme_haspmota_is_inited(void) { return false; }
#ifdef __cplusplus
}
#endif
#endif
