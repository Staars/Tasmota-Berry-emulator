/**
 * @file lv_freetype_stub.h
 * 
 * Stub definitions for FreeType constants when LV_USE_FREETYPE is disabled.
 * This allows Berry bindings to compile without FreeType support while
 * maintaining API compatibility.
 */

#ifndef LV_FREETYPE_STUB_H
#define LV_FREETYPE_STUB_H

#ifdef __cplusplus
extern "C" {
#endif

/* Only provide stubs when FreeType is disabled */
#if !LV_USE_FREETYPE

/**
 * FreeType font style constants (stub values)
 * These constants are exposed to Berry but have no effect when FreeType is disabled.
 */
#define FT_FONT_STYLE_NORMAL 0
#define FT_FONT_STYLE_ITALIC 1
#define FT_FONT_STYLE_BOLD   2

#endif /* !LV_USE_FREETYPE */

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* LV_FREETYPE_STUB_H */
