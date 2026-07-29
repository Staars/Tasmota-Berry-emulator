#ifdef __EMSCRIPTEN__

#include "berry.h"
#include "be_constobj.h"
#include "unishox.h"
#include <stdlib.h>
#include <string.h>

static Unishox compressor;

extern "C" int be_ntv_unishox_compress(bvm *vm) {
    if (be_top(vm) == 1 && be_isstring(vm, 1)) {
        const char *input = be_tostring(vm, 1);
        size_t input_len = strlen(input);
        int32_t output_len = compressor.unishox_compress(input, input_len, NULL, 0);
        if (output_len < 0) {
            be_raise(vm, "internal_error", NULL);
        }
        if (output_len == 0) {
            be_pushbytes(vm, NULL, 0);
        } else {
            /* The codec can touch four bytes beyond its reported size while
             * completing the final word, so use explicitly padded storage. */
            char *output = static_cast<char *>(malloc(output_len + 5));
            if (output == NULL) {
                be_raise(vm, "memory_error", NULL);
            }
            int32_t result = compressor.unishox_compress(
                input, input_len, output, output_len + 5);
            if (result < 0 || result != output_len) {
                free(output);
                be_raise(vm, "internal_error", NULL);
            }
            be_pushbytes(vm, output, output_len);
            free(output);
        }
        be_return(vm);
    }
    be_raise(vm, "type_error", NULL);
}

extern "C" int be_ntv_unishox_decompress(bvm *vm) {
    if (be_top(vm) == 1 && be_isbytes(vm, 1)) {
        size_t input_len;
        const void *input = be_tobytes(vm, 1, &input_len);
        if (input_len == 0) {
            be_pushstring(vm, "");
        } else {
            int32_t output_len = compressor.unishox_decompress(
                static_cast<const char *>(input), input_len, NULL, 0);
            if (output_len < 0) {
                be_raise(vm, "internal_error", NULL);
            }
            if (output_len == 0) {
                be_pushstring(vm, "");
            } else {
                void *output = be_pushbuffer(vm, output_len);
                int32_t result = compressor.unishox_decompress(
                    static_cast<const char *>(input), input_len,
                    static_cast<char *>(output), output_len);
                if (result < 0 || result != output_len) {
                    be_raise(vm, "internal_error", NULL);
                }
                be_pushnstring(vm, static_cast<const char *>(output), output_len);
            }
        }
        be_return(vm);
    }
    be_raise(vm, "type_error", NULL);
}

/* @const_object_info_begin
module unishox (scope: global) {
    decompress, func(be_ntv_unishox_decompress)
    compress, func(be_ntv_unishox_compress)
}
@const_object_info_end */
#include "../generate/be_fixed_unishox.h"

#endif /* __EMSCRIPTEN__ */
