#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include "berry.h"
#include "be_object.h"
#include "be_func.h"
#include "be_vm.h"
#include "be_gc.h"
#include <stdint.h>
#include <emscripten/html5.h>

const char kTypeError[] = "type_error";
const char kInternalError[] = "internal_error";
#define nullptr NULL

struct BrStruct{
  bvm *vm;                    // berry vm
  int32_t timeout;                 // Berry heartbeat timeout, preventing code to run for too long. `0` means not enabled
  bbool rules_busy;              // are we already processing rules, avoid infinite loop
  bbool web_add_handler_done;    // did we already sent `web_add_handler` event
  bbool autoexec_donee;           // do we still need to load 'autoexec.be'
  bbool repl_active;             // is REPL running (activates log recording)
  // output log is stored as a LinkedList of buffers
  // and active only when a REPL command is running
  // BerryLog log;
  long interValID;
};
struct BrStruct berry = {nullptr,0,bfalse,bfalse,bfalse,bfalse,0};

void checkBeTop(void) {
  int32_t top = be_top(berry.vm);
  if (top != 0) {
    be_pop(berry.vm, top);   // TODO should not be there
  }
}

void be_error_pop_all(bvm *vm) {
  // if (vm->obshook != NULL) (*vm->obshook)(vm, BE_OBS_PCALL_ERROR); // TODO
  be_pop(vm, be_top(vm));       // clear Berry stack
}

// call the event dispatcher from Tasmota object
// if data_len is non-zero, the event is also sent as raw `bytes()` object because the string may lose data
int32_t callBerryEventDispatcher(const char *type, const char *cmd, int32_t idx, const char *payload, uint32_t data_len) {
  int32_t ret = 0;
  bvm *vm = berry.vm;

  if (nullptr == vm) { return ret; }
  checkBeTop();
  be_getglobal(vm, ("tasmota"));
  if (!be_isnil(vm, -1)) {
    be_getmethod(vm, -1, ("event"));
    if (!be_isnil(vm, -1)) {
      be_pushvalue(vm, -2); // add instance as first arg
      be_pushstring(vm, type != nullptr ? type : "");
      be_pushstring(vm, cmd != nullptr ? cmd : "");
      be_pushint(vm, idx);
      be_pushstring(vm, payload != nullptr ? payload : "");  // empty json
      // BrTimeoutStart();
      if (data_len > 0) {
        be_pushbytes(vm, payload, data_len);    // if data_len is set, we also push raw bytes
        ret = be_pcall(vm, 6);   // 6 arguments
        be_pop(vm, 1);
      } else {
        ret = be_pcall(vm, 5);   // 5 arguments
      }
      // BrTimeoutReset();
      if (ret != 0) {
        be_error_pop_all(berry.vm);             // clear Berry stack
        return ret;
      }
      be_pop(vm, 5);
      if (be_isint(vm, -1) || be_isbool(vm, -1)) {
        if (be_isint(vm, -1)) { ret = be_toint(vm, -1); }
        if (be_isbool(vm, -1)) { ret = be_tobool(vm, -1); }
      }
    }
    be_pop(vm, 1);  // remove method
  }
  be_pop(vm, 1);  // remove instance object
  checkBeTop();
  return ret;
}

void callBerryFastLoop(bbool every_5ms) {

  bvm *vm = berry.vm;
  if (nullptr == vm) { return; }

  // TODO - can we make this dereferencing once for all?
  if (be_getglobal(vm, "tasmota")) {
    if (be_getmethod(vm, -1, "fast_loop")) {
      be_pushvalue(vm, -2); // add instance as first arg
      int32_t ret = be_pcall(vm, 1);
      if (ret != 0) {
        be_error_pop_all(berry.vm);             // clear Berry stack
      }
      be_pop(vm, 1);
    }
    be_pop(vm, 1);  // remove method
  }
  be_pop(vm, 1);  // remove instance object
  be_pop(vm, be_top(vm));   // clean
}

void tasmota_run_loop(void *userData){
  static uint32_t now = 0;
  callBerryFastLoop(btrue);
  if(now%50 == 0){
    callBerryEventDispatcher(("every_50ms"), nullptr, 0, nullptr,0);
  }
  if(now%100 == 0){
    callBerryEventDispatcher(("every_100ms"), nullptr, 0, nullptr,0);
  }
  if(now%250 == 0){
    callBerryEventDispatcher(("every_250ms"), nullptr, 0, nullptr,0);
  }
  if(now%1000 == 0){
    callBerryEventDispatcher(("every_second"), nullptr, 0, nullptr,0);
  }
  now += 5;
}

void tasmota_emulator_init(bvm *vm){
  berry.vm = vm;
  berry.interValID = emscripten_set_interval(tasmota_run_loop,5,(void*)0); // fastloop of 5ms is our tick
  emscripten_console_log("Did init Tasmota emulator");
}

// tasmota class

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

static int32_t l_log(struct bvm *vm) {
  int32_t top = be_top(vm); // Implement later or never
  if (top == 2 && be_isstring(vm, 2)) {
    const char* msg = be_tostring(vm, 2);
    emscripten_console_log(msg);
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
}
@const_object_info_end */
#include "../generate/be_fixed_be_class_tasmota_wasm.h"
#endif

#endif