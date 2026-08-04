#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include "berry.h"
#include "be_object.h"
#include "be_func.h"
#include "be_vm.h"
#include "be_gc.h"
#include <stdint.h>
#include <emscripten/html5.h>
#include <emscripten/console.h>
#include <string.h>
#include "lvgl.h"

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

void callBerryFastLoop() {

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

void tasmota_run_loop([[maybe_unused]] void *userData){
  static uint32_t now = 0;
  lv_timer_handler();
  callBerryFastLoop();
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
  // emscripten_log(EM_LOG_CONSOLE, "%u",now);
  now += 5;
}

// Berry global log(msg [, level]) -> browser console only (mirrors Tasmota log())
static int32_t l_berry_log(struct bvm *vm) {
  if (be_top(vm) >= 1) {
    const char* msg = be_tostring(vm, 1);
    int32_t level = 2;   // LOG_LEVEL_INFO default
    if (be_top(vm) >= 2 && be_isint(vm, 2)) {
      level = be_toint(vm, 2);
    }
    const char* line = be_pushfstring(vm, "BRY: %s", msg);
    switch (level) {
      case 1: emscripten_console_error(line); break;
      default: emscripten_console_log(line); break;
    }
    be_pop(vm, 1);   // remove the formatted string
    be_pushnil(vm);
    be_return(vm);
  }
  be_raise(vm, "type_error", nullptr);
}

void tasmota_emulator_init(bvm *vm){
  berry.vm = vm;
  lv_init();
  // global log(msg [, level]) -> browser console only (mirrors Tasmota log())
  // Prints "BRY: <msg>" via the browser console; level 1=error, 2=info.
  // Keeps the REPL output buffer clean: console lines are not part of emulator output.
  be_regfunc(vm, "log", l_berry_log);
  berry.interValID = emscripten_set_interval(tasmota_run_loop,5,(void*)0); // fastloop of 5ms is our tick
  emscripten_console_log("Did init Tasmota emulator");
}

void tasmota_loop_pause(void) {
  if (berry.interValID) {
    emscripten_clear_interval(berry.interValID);
    berry.interValID = 0;
  }
}

void tasmota_loop_resume(void) {
  if (!berry.interValID) {
    berry.interValID = emscripten_set_interval(tasmota_run_loop, 5, (void*)0);
  }
}

EMSCRIPTEN_KEEPALIVE
int BrREPLRun(const char *source) {
  bvm *vm = berry.vm;
  if (!vm) return -1;

  checkBeTop();

  /* Try as expression first: return (source) */
  const char *expr = be_pushfstring(vm, "return (%s)", source);
  int idx = be_absindex(vm, -1);
  int res = be_loadbuffer(vm, "stdin", expr, strlen(expr));
  be_remove(vm, idx);

  /* If syntax error, try as statement */
  if (res != BE_OK && be_getexcept(vm, res) == BE_SYNTAX_ERROR) {
    be_pop(vm, 2); /* pop exception values */
    res = be_loadbuffer(vm, "stdin", source, strlen(source));
  }

  /* Execute if compiled successfully */
  if (res == BE_OK) {
    res = be_pcall(vm, 0);
    switch (res) {
    case BE_OK:
      if (!be_isnil(vm, -1)) {
        be_dumpvalue(vm, -1);
      }
      be_pop(vm, 1);
      break;
    case BE_EXCEPTION:
      be_dumpexcept(vm);
      be_pop(vm, 1);
      break;
    default:
      return res;
    }
  } else {
    be_dumpexcept(vm);
  }

  checkBeTop();
  return 0;
}

#endif
