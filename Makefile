CFLAGS      = -Wall -Wextra -std=c99 -O2 -Wno-zero-length-array -Wno-empty-translation-unit
DEBUG_FLAGS = -O0 -g -DBE_DEBUG
TEST_FLAGS  = $(DEBUG_FLAGS) --coverage -fno-omit-frame-pointer -fsanitize=address -fsanitize=undefined
LIBS        = -lm
TARGET      = docs/berry.js
CC          = clang # install clang!! gcc seems to produce a defect berry binary
MKDIR       = mkdir
LFLAGS      =
PREFIX      = /usr/local
BINDIR      = $(PREFIX)/bin

INCPATH     = src default re1.5 emu_src
SRCPATH     = src default re1.5 emu_src
GENERATE    = generate
CONFIG      = default/berry_conf.h
COC         = tools/coc/coc
CONST_TAB   = $(GENERATE)/be_const_strtab.h
EMBED_FILES =

ifeq ($(OS), Windows_NT) # Windows
    CFLAGS    += -Wno-format -DTASMOTA # for "%I64d" warning, mimick Tasmota env with 32 bits int and 32 bits float
    LFLAGS    += -Wl,--out-implib,berry.lib # export symbols lib for dll linked
    TARGET    := $(TARGET).exe
    PYTHON    ?= python # only for windows and need python3
    COC       := $(PYTHON) $(COC)
else
    CFLAGS    += -DUSE_READLINE_LIB
    LIBS      += -lreadline -ldl
    OS        := $(shell uname)
    ifeq ($(OS), Linux)
        LFLAGS += -Wl,--export-dynamic
    endif
endif

ifneq ($(V), 1)
    Q=@
    MSG=@echo
else
    MSG=@true
endif

SRCS     = $(foreach dir, $(SRCPATH), $(wildcard $(dir)/*.c))
OBJS     = $(patsubst %.c, %.o, $(SRCS))
DEPS     = $(patsubst %.c, %.d, $(SRCS))
INCFLAGS = $(foreach dir, $(INCPATH), -I"$(dir)")

.PHONY : clean

all: $(TARGET)

web: CFLAGS    = -Wall -Wextra -std=gnu99 -Wno-empty-translation-unit -O3 -Wno-zero-length-array
web: LIBS      = -lm -ldl
web: LFLAGS.   =
web: TARGET    = berry.js
web: CC        = emcc
web: EMBED_FILES    = --preload-file tasmota_env --preload-file demos  --preload-file env.be@/env.be
web: LFLAGS    = -s WASM=1 -s ASYNCIFY \
            	 -s 'ASYNCIFY_IMPORTS=["_js_readbuffer"]'\
				 -O3 -s SINGLE_FILE=1

web: all

debug: CFLAGS += $(DEBUG_FLAGS)
debug: all

test: CFLAGS += $(TEST_FLAGS)
test: LFLAGS += $(TEST_FLAGS)
test: all
	$(MSG) [Run Testcases...]
	$(Q) ./testall.be
	$(Q) $(RM) */*.gcno */*.gcda

$(TARGET): $(OBJS)
	$(MSG) [Linking...]
	$(Q) $(CC) $(OBJS) $(LFLAGS) $(LIBS) -o $@ $(EMBED_FILES)
	$(MSG) done

$(OBJS): %.o: %.c
	$(MSG) [Compile] $<
	$(Q) $(CC) -MM $(CFLAGS) $(INCFLAGS) -MT"$*.d" -MT"$(<:.c=.o)" $< > $*.d
	$(Q) $(CC) $(CFLAGS) $(INCFLAGS) -c $< -o $@

sinclude $(DEPS)

$(OBJS): $(CONST_TAB)

$(CONST_TAB): $(GENERATE) $(SRCS) $(CONFIG)
	$(MSG) [Prebuild] generate resources
	$(Q) $(COC)  -o $(GENERATE) $(SRCPATH) -c $(CONFIG)

$(GENERATE):
	$(Q) $(MKDIR) $(GENERATE)

install:
	mkdir -p $(DESTDIR)$(BINDIR)
	cp $(TARGET) $(DESTDIR)$(BINDIR)/$(TARGET)

uninstall:
	$(RM) $(DESTDIR)$(BINDIR)/$(TARGET)

prebuild: $(GENERATE)
	$(MSG) [Prebuild] generate resources
	$(Q) $(COC) -o $(GENERATE) $(SRCPATH) -c $(CONFIG)
	$(MSG) done

clean:
	$(MSG) [Clean...]
	$(Q) $(RM) $(OBJS) $(DEPS) $(GENERATE)/* berry.lib
	$(MSG) done
