#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include "berry.h"
#include "be_object.h"
#include "be_func.h"
#include "be_vm.h"
#include "be_gc.h"
#include "be_module.h"
#include <stdint.h>
#include <emscripten/html5.h>
#include <emscripten/wget.h>
#include <emscripten/console.h>
#include <string.h>

const char kTypeError[] = "type_error";
const char kInternalError[] = "internal_error";
#define nullptr NULL

// tasmota wasm class

extern void tasmota_loop_pause(void);
extern void tasmota_loop_resume(void);

static int32_t l_delay(struct bvm *vm) {
  int32_t top = be_top(vm);
  if (top == 2 && be_isint(vm, 2)) {
    int ms = be_toint(vm, 2);
    if (ms > 0) {
      tasmota_loop_pause();
      emscripten_sleep(ms);
      tasmota_loop_resume();
    }
    be_return_nil(vm);
  }
  be_raise(vm, kTypeError, nullptr);
}

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
  if (top >= 2 && be_isstring(vm, 2)) {
    const char* msg = be_tostring(vm, 2);
    int32_t level = 3;   // LOG_LEVEL_INFO default
    if (top >= 3 && be_isint(vm, 3)) {
      level = be_toint(vm, 3);
    }
    switch (level) {
      case 1: emscripten_console_error(msg); break;
      case 2: emscripten_console_warn(msg); break;
      default: emscripten_console_log(msg); break;
    }
    be_return(vm);
  }
  be_raise(vm, kTypeError, nullptr);
}


static int32_t l_add_module_path(struct bvm *vm) {
  if (be_top(vm) >= 2 && be_isstring(vm, 2)) {
    be_module_path_set(vm, be_tostring(vm, 2));
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

// Berry: tasmota.save(filename:string, closure) -> bool
static int32_t l_save(struct bvm *vm) {
  if (be_top(vm) >= 3 && be_isstring(vm, 2)) {
    const char *filename = be_tostring(vm, 2);
    int res = be_savecode(vm, filename);
    be_pushbool(vm, res == BE_OK);
    be_return(vm);
  }
  be_raise(vm, kTypeError, nullptr);
}

#if !BE_USE_PRECOMPILED_OBJECT
void be_load_tasmotawasmlib(bvm *vm)
{
    static const bnfuncinfo members[] = {
        { "millis", l_millis },
        { "add_module_path", l_add_module_path },
        { "save", l_save },
        { NULL, NULL }
    };
    be_regclass(vm, "tasmota_wasm", members);
}
#else
/* @const_object_info_begin
class be_class_tasmota_wasm (scope: global, name: tasmota_wasm) {
    millis, func(l_millis)
    time_reached, func(l_timereached)
    delay, func(l_delay)
    fast_loop, func(l_dummy)
    add_fast_loop, func(l_dummy)
    remove_fast_loop, func(l_dummy)
    set_millis, func(l_dummy)
    log, func(l_log)
    led_buffer, func(l_led_buffer)
    urlfetch,func(l_urlfetch)
    add_module_path, func(l_add_module_path)
    save, func(l_save)
}
@const_object_info_end */
#include "../generate/be_fixed_be_class_tasmota_wasm.h"
#endif

#endif