CFLAGS      = -Wall -Wextra -std=c99 -O2 -Wno-zero-length-array -Wno-empty-translation-unit
CXXFLAGS    = -Wall -Wextra -std=c++11 -O2 -Wno-zero-length-array -Wno-empty-translation-unit
DEBUG_FLAGS = -O0 -g -DBE_DEBUG
TEST_FLAGS  = $(DEBUG_FLAGS) --coverage -fno-omit-frame-pointer -fsanitize=address -fsanitize=undefined
LIBS        = -lm
TARGET      = docs/berry.js
CC          = clang
CXX         = clang++
MKDIR       = mkdir
LFLAGS      =
PREFIX      = /usr/local
BINDIR      = $(PREFIX)/bin
INCPATH     = src default re1.5 emu_src
SRCPATH     = src default re1.5 emu_src emu_cpp_src
GENERATE    = generate
EMSCRIPTEN_INC = $(shell em-config EMSCRIPTEN_ROOT 2>/dev/null)/system/include
CONFIG      = default/berry_conf.h
COC         = tools/coc/coc
CONST_TAB   = $(GENERATE)/be_const_strtab.h
EMBED_FILES =

ifeq ($(OS), Windows_NT) # Windows
CFLAGS    += -Wno-format -DTASMOTA
CXXFLAGS  += -Wno-format -DTASMOTA
LFLAGS    += -Wl,--out-implib,berry.lib
TARGET    := $(TARGET).exe
PYTHON    ?= python
COC       := $(PYTHON) $(COC)
else
CFLAGS    += -DUSE_READLINE_LIB
CXXFLAGS  += -DUSE_READLINE_LIB
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

# Separate C and C++ source files
SRCS_C   = $(foreach dir, $(SRCPATH), $(wildcard $(dir)/*.c))
SRCS_CPP = $(foreach dir, $(SRCPATH), $(wildcard $(dir)/*.cpp))
OBJS_C   = $(patsubst %.c, %.o, $(SRCS_C))
OBJS_CPP = $(patsubst %.cpp, %.o, $(SRCS_CPP))
OBJS     = $(OBJS_C) $(OBJS_CPP)
DEPS     = $(patsubst %.c, %.d, $(SRCS_C)) $(patsubst %.cpp, %.d, $(SRCS_CPP))
INCFLAGS = $(foreach dir, $(INCPATH), -I"$(dir)")

.PHONY : clean clangd

all: $(TARGET)

web: CFLAGS    = -Wall -Wextra -std=gnu99 -Wno-empty-translation-unit -O3 -Wno-zero-length-array
web: CXXFLAGS  = -Wall -Wextra -std=c++11 -Wno-empty-translation-unit -O3 -Wno-zero-length-array
web: LIBS      = -lm -ldl
web: LFLAGS.   =
web: TARGET    = berry.js
web: CC        = emcc
web: CXX       = em++
web: EMBED_FILES    = --preload-file tasmota_env --preload-file demos  --preload-file env.be@/env.be
web: LFLAGS    = -s WASM=1 -s ASYNCIFY \
                 -s 'ASYNCIFY_IMPORTS=["_js_readbuffer"]'\
                 -O3 -s SINGLE_FILE=1
web: all

debug: CFLAGS += $(DEBUG_FLAGS)
debug: CXXFLAGS += $(DEBUG_FLAGS)
debug: all

test: CFLAGS += $(TEST_FLAGS)
test: CXXFLAGS += $(TEST_FLAGS)
test: LFLAGS += $(TEST_FLAGS)
test: all
	$(MSG) [Run Testcases...]
	$(Q) ./testall.be
	$(Q) $(RM) */*.gcno */*.gcda

$(TARGET): $(OBJS)
	$(MSG) [Linking...]
	$(Q) $(CXX) $(OBJS) $(LFLAGS) $(LIBS) -o $@ $(EMBED_FILES)
	$(MSG) done

# Compile C files
$(OBJS_C): %.o: %.c
	$(MSG) [Compile C] $<
	$(Q) $(CC) -MM $(CFLAGS) $(INCFLAGS) -MT"$*.d" -MT"$(<:.c=.o)" $< > $*.d
	$(Q) $(CC) $(CFLAGS) $(INCFLAGS) -c $< -o $@

# Compile C++ files
$(OBJS_CPP): %.o: %.cpp
	$(MSG) [Compile C++] $<
	$(Q) $(CXX) -MM $(CXXFLAGS) $(INCFLAGS) -MT"$*.d" -MT"$(<:.cpp=.o)" $< > $*.d
	$(Q) $(CXX) $(CXXFLAGS) $(INCFLAGS) -c $< -o $@

sinclude $(DEPS)

$(OBJS): $(CONST_TAB)

$(CONST_TAB): $(GENERATE) $(SRCS_C) $(CONFIG)
	$(MSG) [Prebuild] generate resources
	$(Q) $(COC) -o $(GENERATE) $(SRCPATH) -c $(CONFIG)

$(GENERATE):
	$(Q) $(MKDIR) $(GENERATE)

install:
	mkdir -p $(DESTDIR)$(BINDIR)
	cp $(TARGET) $(DESTDIR)$(BINDIR)/$(TARGET)

uninstall:
	$(RM) $(DESTDIR)$(BINDIR)/$(TARGET)

clangd: $(CONST_TAB)
	$(Q) echo '[' > compile_commands.json
	$(Q) first=true; \
	for src in $(SRCS_C); do \
		if $$first; then first=false; else echo ',' >> compile_commands.json; fi; \
		printf '  {"directory":"%s","command":"%s -target wasm32-unknown-emscripten -Wall -Wextra -std=gnu99 -Wno-empty-translation-unit -O3 -Wno-zero-length-array -D__EMSCRIPTEN__ -isystem %s %s -c %s -o %s","file":"%s"}' \
			"$(CURDIR)" "$(CC)" "$(EMSCRIPTEN_INC)" "$(INCFLAGS)" \
			"$$src" "$${src%.c}.o" "$$src" >> compile_commands.json; \
	done; \
	for src in $(SRCS_CPP); do \
		if $$first; then first=false; else echo ',' >> compile_commands.json; fi; \
		printf '  {"directory":"%s","command":"%s -target wasm32-unknown-emscripten -Wall -Wextra -std=c++11 -Wno-empty-translation-unit -O3 -Wno-zero-length-array -D__EMSCRIPTEN__ -isystem %s %s -c %s -o %s","file":"%s"}' \
			"$(CURDIR)" "$(CXX)" "$(EMSCRIPTEN_INC)" "$(INCFLAGS)" \
			"$$src" "$${src%.cpp}.o" "$$src" >> compile_commands.json; \
	done; \
	echo '' >> compile_commands.json; echo ']' >> compile_commands.json

prebuild: $(GENERATE)
	$(MSG) [Prebuild] generate resources
	$(Q) $(COC) -o $(GENERATE) $(SRCPATH) -c $(CONFIG)
	$(MSG) done

clean:
	$(MSG) [Clean...]
	$(Q) $(RM) $(OBJS) $(DEPS) $(GENERATE)/* berry.lib
	$(MSG) done
