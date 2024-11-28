#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include "berry.h"
#include "be_object.h"
#include "be_func.h"
#include "be_vm.h"
#include <stdint.h>
#include <emscripten/html5.h>

const char kTypeError[] = "type_error";
const char kInternalError[] = "internal_error";
#define nullptr NULL

// changeUIntScale
// Change a value for range a..b to c..d, using only unsigned int math
//
// New version, you don't need the "to_min < to_max" precondition anymore
//
// PRE-CONDITIONS (if not satisfied, returns the smallest between to_min and to_max')
//    from_min < from_max  (checked)
//    from_min <= num <= from_max  (checked)
// POST-CONDITIONS
//    to_min <= result <= to_max
//
uint16_t changeUIntScale(uint16_t inum, uint16_t ifrom_min, uint16_t ifrom_max,
                                       uint16_t ito_min, uint16_t ito_max) {
  // guard-rails
  if (ifrom_min >= ifrom_max) {
    return (ito_min > ito_max ? ito_max : ito_min);  // invalid input, return arbitrary value
  }
  // convert to uint31, it's more verbose but code is more compact
  uint32_t num = inum;
  uint32_t from_min = ifrom_min;
  uint32_t from_max = ifrom_max;
  uint32_t to_min = ito_min;
  uint32_t to_max = ito_max;

  // check source range
  num = (num > from_max ? from_max : (num < from_min ? from_min : num));

  // check to_* order
  if (to_min > to_max) {
    // reverse order
    num = (from_max - num) + from_min;
    to_min = ito_max;
    to_max = ito_min;
  }

  // short-cut if limits to avoid rounding errors
  if (num == from_min) return to_min;
  if (num == from_max) return to_max;

  uint32_t result;
  if ((num - from_min) < 0x8000L) {   // no overflow possible
    if (to_max - to_min > from_max - from_min) {
      uint32_t numerator = (num - from_min) * (to_max - to_min) * 2;
      result = ((numerator / (from_max - from_min)) + 1 ) / 2 + to_min;
    } else {
      uint32_t numerator = ((num - from_min) * 2 + 1) * (to_max - to_min + 1);
      result = numerator / ((from_max - from_min + 1) * 2) + to_min;
    }
  } else {    // no pre-rounding since it might create an overflow
    uint32_t numerator = (num - from_min) * (to_max - to_min + 1);
    result = numerator / (from_max - from_min) + to_min;
  }

  return (uint32_t) (result > to_max ? to_max : (result < to_min ? to_min : result));
}

//
// changeIntScale
// Change a value for range a..b to c..d, for signed ints (16 bits max to avoid overflow)
//
// PRE-CONDITIONS (if not satisfied, returns the smallest between to_min and to_max')
//    from_min < from_max  (checked)
//    from_min <= num <= from_max  (checked)
// POST-CONDITIONS
//    to_min <= result <= to_max
//
int16_t changeIntScale(int16_t num, int16_t from_min, int16_t from_max,
                                    int16_t to_min, int16_t to_max) {

  // guard-rails
  if (from_min >= from_max) {
    return (to_min > to_max ? to_max : to_min);  // invalid input, return arbitrary value
  }
  int32_t from_offset = 0;
  if (from_min < 0) {
    from_offset = - from_min;
  }
  int32_t to_offset = 0;
  if (to_min < 0) {
    to_offset = - to_min;
  }
  if (to_max < (- to_offset)) {
    to_offset = - to_max;
  }

  return changeUIntScale(num + from_offset, from_min + from_offset, from_max + from_offset, to_min + to_offset, to_max + to_offset) - to_offset;
}

  /*
  Implements the 5-order polynomial approximation to sin(x).
  @param i   angle (with 2^15 units/circle)
  @return    16 bit fixed point Sine value (4.12) (ie: +4096 = +1 & -4096 = -1)

  The result is accurate to within +- 1 count. ie: +/-2.44e-4.
  */
  int16_t fpsin(int16_t i)
  {
      /* Convert (signed) input to a value between 0 and 8192. (8192 is pi/2, which is the region of the curve fit). */
      /* ------------------------------------------------------------------- */
      i <<= 1;
      uint8_t c = i<0; //set carry for output pos/neg

      if(i == (i|0x4000)) // flip input value to corresponding value in range [0..8192)
          i = (1<<15) - i;
      i = (i & 0x7FFF) >> 1;
      /* ------------------------------------------------------------------- */

      /* The following section implements the formula:
      = y * 2^-n * ( A1 - 2^(q-p)* y * 2^-n * y * 2^-n * [B1 - 2^-r * y * 2^-n * C1 * y]) * 2^(a-q)
      Where the constants are defined as follows:
      */
      // enum {A1=3370945099UL, B1=2746362156UL, C1=292421UL};
      // enum {n=13, p=32, q=31, r=3, a=12};

      uint32_t y = (292421UL*((uint32_t)i))>>13;
      y = 2746362156UL - (((uint32_t)i*y)>>3);
      y = (uint32_t)i * (y>>13);
      y = (uint32_t)i * (y>>13);
      y = 3370945099UL - (y>>(32-31));
      y = (uint32_t)i * (y>>13);
      y = (y+(1UL<<(31-12-1)))>>(31-12); // Rounding

      return c ? -y : y;
  }
  
  
  // Berry: tasmota.millis([delay:int]) -> int
  //
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

  // Berry: tasmota.scale_uint(int * 5) -> int
  //
  int32_t l_scaleuint(struct bvm *vm) {
    int32_t top = be_top(vm); // Get the number of arguments
    if (top == 5 && be_isint(vm, 1) && be_isint(vm, 2) && be_isint(vm, 3) && be_isint(vm, 4) && be_isint(vm, 5)) {
      int32_t val = be_toint(vm, 1);
      int32_t from_min = be_toint(vm, 2);
      int32_t from_max = be_toint(vm, 3);
      int32_t to_min = be_toint(vm, 4);
      int32_t to_max = be_toint(vm, 5);
      int32_t scaled = changeUIntScale(val, from_min, from_max, to_min, to_max);
      be_pushint(vm, scaled);
      be_return(vm);
    }
    be_raise(vm, kTypeError, nullptr);
  }

  // Berry: tasmota.scale_int(int * 5) -> int
  //

  int32_t l_scaleint(struct bvm *vm) {
    int32_t top = be_top(vm); // Get the number of arguments
    if (top == 5 && be_isint(vm, 1) && be_isint(vm, 2) && be_isint(vm, 3) && be_isint(vm, 4) && be_isint(vm, 5)) {
      int32_t val = be_toint(vm, 1);
      int32_t from_min = be_toint(vm, 2);
      int32_t from_max = be_toint(vm, 3);
      int32_t to_min = be_toint(vm, 4);
      int32_t to_max = be_toint(vm, 5);
      int32_t scaled = changeIntScale(val, from_min, from_max, to_min, to_max);
      be_pushint(vm, scaled);
      be_return(vm);
    }
    be_raise(vm, kTypeError, nullptr);
  }

    
  // Berry: tasmota.sine_int(int) -> int
  //
  // Input: 8192 is pi/2
  // Output: -4096 is -1, 4096 is +1
  //
  // https://www.nullhardware.com/blog/fixed-point-sine-and-cosine-for-embedded-systems/

  int32_t l_sineint(struct bvm *vm) {
    int32_t top = be_top(vm); // Get the number of arguments
    if (top == 1 && be_isint(vm, 1)) {
      int32_t val = be_toint(vm, 1);

      be_pushint(vm, fpsin(val));
      be_return(vm);
    }
    be_raise(vm, kTypeError, nullptr);
  }


#if !BE_USE_PRECOMPILED_OBJECT
void be_load_tasmotalib(bvm *vm)
{
    static const bnfuncinfo members[] = {
        { "millis", l_millis },
        { NULL, NULL }
    };
    be_regclass(vm, "tasmota", members);
}
#else
/* @const_object_info_begin
class be_class_tasmota (scope: global, name: tasmota) {
    millis, func(l_millis)
    scale_uint, func(l_scaleuint)
    scale_int, func(l_scaleint)
    sine_int, func(l_sineint)
}
@const_object_info_end */
#include "../generate/be_fixed_be_class_tasmota.h"
#endif

#endif