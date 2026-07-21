/**
 * @file lv_tasmota_logo.c
 * 
 * Tasmota logo helper functions for LVGL image widgets
 */

#include "lv_berry.h"
#include "lvgl.h"

/* External logo image descriptors from assets */
extern const lv_image_dsc_t TASMOTA_Symbol_64;
extern const lv_image_dsc_t TASMOTA_Symbol_36_white;

/**
 * Set Tasmota 64x64 logo to an image widget
 * @param img pointer to an image object
 */
void lv_image_set_tasmota_logo(lv_obj_t * img) {
    lv_image_set_src(img, &TASMOTA_Symbol_64);
}

/**
 * Set Tasmota 36x36 logo to an image widget  
 * @param img pointer to an image object
 */
void lv_image_set_tasmota_logo36(lv_obj_t * img) {
    lv_image_set_src(img, &TASMOTA_Symbol_36_white);
}
