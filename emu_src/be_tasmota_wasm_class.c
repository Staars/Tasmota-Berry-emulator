#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include "berry.h"
#include "be_object.h"
#include "be_func.h"
#include "be_vm.h"
#include "be_gc.h"
#include <stdint.h>
#include <emscripten/html5.h>
#include <emscripten/wget.h>
#include <string.h>

const char kTypeError[] = "type_error";
const char kInternalError[] = "internal_error";
#define nullptr NULL

// tasmota wasm class

static int32_t l_millis(struct bvm *vm) {
  int32_t top = be_top(vm); // Get the number of arguments
  if (top == 1 || (top == 2 && be_isint(vm, 2))) {  // only 1 argument of type string accepted
    uint32_t delay = 0;
    if (top == 2) {
      delay = be_toint(vm, 2);
    }
    uint32_t ret_millis = emscripten_performance_now() + delay;
    be_pushint(vm, ret_millis);
    be_return(vm); // Return
  }
  be_raise(vm, kTypeError, nullptr);
}

static int32_t l_dummy(struct bvm *vm) {
  //int32_t top = be_top(vm); // Implement later or never
  // if (top == 1) {
    be_pushbool(vm, btrue);
    be_return(vm);
  //}
  //be_raise(vm, kTypeError, nullptr);
}


// Berry: tasmota.time_reached(timer:int) -> bool
//
static int32_t l_timereached(struct bvm *vm) {
  int32_t top = be_top(vm); // Get the number of arguments
  if (top == 2 && be_isint(vm, 2)) {  // only 1 argument of type string accepted
    uint32_t timer = be_toint(vm, 2);
    bbool reached = (timer <= emscripten_performance_now());
    be_pushbool(vm, reached);
    be_return(vm); // Return
  }
  be_raise(vm, kTypeError, nullptr);
}

static int32_t l_urlfetch(struct bvm *vm) {
  int32_t top = be_top(vm);
  if (top >= 2 && be_isstring(vm, 2)) {
    const char* url = be_tostring(vm, 2);
    char* file = (char*)url;
    if (top == 3 && be_isstring(vm, 3)) {
      file = (char*)be_tostring(vm, 3);
    }
    int error =  emscripten_wget(url, (const char*) file);
    be_pushbool(vm, (error == 0));
    be_return(vm);
  }
  be_raise(vm, kTypeError, nullptr);
}

static int32_t l_log(struct bvm *vm) {
  int32_t top = be_top(vm);
  if (top == 2 && be_isstring(vm, 2)) {
    const char* msg = be_tostring(vm, 2);
    emscripten_console_log(msg);
    be_return(vm);
  }
  be_raise(vm, kTypeError, nullptr);
}


extern void be_writeEmulatorbuffer(const char *buffer, size_t length);
static int32_t l_led_buffer(struct bvm *vm) {
  int32_t top = be_top(vm); 
  if (top == 2 && be_isstring(vm, 2)) {
    const char* msg = be_tostring(vm, 2);
    be_writeEmulatorbuffer(msg, strlen(msg));
    be_return(vm);
  }
  be_raise(vm, kTypeError, nullptr);
}


#if !BE_USE_PRECOMPILED_OBJECT
void be_load_tasmotawasmlib(bvm *vm)
{
    static const bnfuncinfo members[] = {
        { "millis", l_millis },
        { NULL, NULL }
    };
    be_regclass(vm, "tasmota_wasm", members);
}
#else
/* @const_object_info_begin
class be_class_tasmota_wasm (scope: global, name: tasmota_wasm) {
    millis, func(l_millis)
    time_reached, func(l_timereached)
    fast_loop, func(l_dummy)
    add_fast_loop, func(l_dummy)
    remove_fast_loop, func(l_dummy)
    set_millis, func(l_dummy)
    log, func(l_log)
    led_buffer, func(l_led_buffer)
    urlfetch,func(l_urlfetch)
}
@const_object_info_end */
#include "../generate/be_fixed_be_class_tasmota_wasm.h"
#endif

#endif