#include "berry.h"
#include "be_constobj.h"
#include <stdlib.h>

static int c_random(bvm *vm) {
    int n = 1;
    if (be_top(vm) >= 1 && be_isint(vm, 1)) {
        n = be_toint(vm, 1);
        if (n < 1) n = 1;
    }
    be_pushbytes(vm, NULL, n);
    uint8_t *buf = (uint8_t *)be_tobytes(vm, -1, NULL);
    for (int i = 0; i < n; i++) {
        buf[i] = (uint8_t)(rand() & 0xFF);
    }
    be_return(vm);
}

/* @const_object_info_begin
module crypto (scope: global) {
    random, func(c_random)
}
@const_object_info_end */
#include "../generate/be_fixed_crypto.h"
