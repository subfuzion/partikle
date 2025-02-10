#
# Partikle Runtime
#
# Copyright (c) 2017-2021 Fabrice Bellard
# Copyright (c) 2017-2021 Charlie Gordon
# Copyright (c) 2025 Tony Pujals
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

###############################################################################
# optional settings

# installation directory
PREFIX?=/usr/local

# include the code for BigFloat/BigDecimal and math mode
CONFIG_BIGNUM=y

# consider warnings as errors
#CONFIG_WERROR=y

# use link time optimization (smaller and faster executables but slower build)
#CONFIG_LTO=y

# use the gprof profiler
#CONFIG_PROFILE=y

# use address sanitizer
#CONFIG_ASAN=y

# use memory sanitizer
#CONFIG_MSAN=y

# use UB sanitizer
#CONFIG_UBSAN=y

###############################################################################
# configuration

ifeq ($(shell uname -s),Darwin)
  CONFIG_DARWIN=y
endif
ifeq ($(shell uname -s),FreeBSD)
  CONFIG_FREEBSD=y
endif

OBJDIR=.obj

ifdef CONFIG_ASAN
  OBJDIR:=$(OBJDIR)/asan
endif
ifdef CONFIG_MSAN
  OBJDIR:=$(OBJDIR)/msan
endif
ifdef CONFIG_UBSAN
  OBJDIR:=$(OBJDIR)/ubsan
endif

ifdef CONFIG_DARWIN
  # use clang instead of gcc
  CONFIG_CLANG=y
  CONFIG_DEFAULT_AR=y
endif
ifdef CONFIG_FREEBSD
  # use clang instead of gcc
  CONFIG_CLANG=y
  CONFIG_DEFAULT_AR=y
  CONFIG_LTO=
endif

ifdef CONFIG_CLANG
  CC=clang
  C23=-std=c2x
  CFLAGS+=$(C23)
  CFLAGS+=-g -Wall -MMD -MF $(OBJDIR)/$(@F).d
  CFLAGS+=-Wextra
  CFLAGS+=-Wno-sign-compare
  CFLAGS+=-Wno-missing-field-initializers
  CFLAGS+=-Wundef -Wuninitialized
  CFLAGS+=-Wunused -Wno-unused-parameter
  CFLAGS+=-Wwrite-strings
  CFLAGS+=-Wchar-subscripts -funsigned-char
  CFLAGS+=-MMD -MF $(OBJDIR)/$(@F).d
  CFLAGS+=-Wno-unknown-warning-option
  ifdef CONFIG_DEFAULT_AR
    AR=ar
  else
    ifdef CONFIG_LTO
      AR=llvm-ar
    else
      AR=ar
    endif
  endif
  LIB_FUZZING_ENGINE ?= "-fsanitize=fuzzer"
else
  CC=gcc
  C23=-std=c2x
  CFLAGS+=$(C23)
  CFLAGS+=-g -Wall -MMD -MF $(OBJDIR)/$(@F).d
  CFLAGS+=-Wno-array-bounds -Wno-format-truncation
  ifdef CONFIG_LTO
    AR=gcc-ar
  else
    AR=ar
  endif
endif
STRIP?=strip
CFLAGS+=-fwrapv # ensure that signed overflows behave as expected
ifdef CONFIG_WERROR
CFLAGS+=-Werror
endif

DEFINES:=-D_GNU_SOURCE
ifdef CONFIG_BIGNUM
DEFINES+=-DCONFIG_BIGNUM
endif
ifeq ($(shell $(CC) -o /dev/null compat/test-closefrom.c 2>/dev/null && echo 1),1)
DEFINES+=-DHAVE_CLOSEFROM
endif

CFLAGS+=$(DEFINES)
CFLAGS_DEBUG=$(CFLAGS) -O0
CFLAGS_SMALL=$(CFLAGS) -Os
CFLAGS_OPT=$(CFLAGS) -O2
CFLAGS_NOLTO:=$(CFLAGS_OPT)
LDFLAGS+=-g
ifdef CONFIG_LTO
CFLAGS_SMALL+=-flto
CFLAGS_OPT+=-flto
LDFLAGS+=-flto
endif
ifdef CONFIG_PROFILE
CFLAGS+=-p
LDFLAGS+=-p
endif
ifdef CONFIG_ASAN
CFLAGS+=-fsanitize=address -fno-omit-frame-pointer
LDFLAGS+=-fsanitize=address -fno-omit-frame-pointer
endif
ifdef CONFIG_MSAN
CFLAGS+=-fsanitize=memory -fno-omit-frame-pointer
LDFLAGS+=-fsanitize=memory -fno-omit-frame-pointer
endif
ifdef CONFIG_UBSAN
CFLAGS+=-fsanitize=undefined -fno-omit-frame-pointer
LDFLAGS+=-fsanitize=undefined -fno-omit-frame-pointer
endif

ifdef DEBUG
DEFINES+=-DCONFIG_VERSION=\"$(shell cat VERSION).debug\"
LDEXPORT=
else
DEFINES+=-DCONFIG_VERSION=\"$(shell cat VERSION)\"
LDEXPORT=-rdynamic
endif
DEFINES+=-DCC=\"$(CC)\"

ifndef CONFIG_DARWIN
CONFIG_SHARED_LIBS=y
endif

###############################################################################
# targets

ifdef CONFIG_LTO
  LTOEXT=.lto
else
  LTOEXT=
endif

PTKL=ptkl
PTKLC=ptklc
LIBPTKL=libptkl$(LTOEXT).a
DEFINES+=-DPTKL=\"$(PTKL)\"

TARGETS=$(PTKL) $(PTKLC) $(LIBPTKL) run-test262

# examples
ifndef $(or CONFIG_ASAN, CONFIG_MSAN, CONFIG_UBSAN)
      TARGETS+=examples/hello examples/hello_module examples/test_fib
      ifdef CONFIG_SHARED_LIBS
        TARGETS+=examples/fib.so examples/point.so
      endif
endif

###############################################################################
# rules

all: $(OBJDIR) $(OBJDIR)/quickjs.check.o $(OBJDIR)/ptkl.check.o $(TARGETS)

PTKL_LIB_OBJS=$(OBJDIR)/quickjs.o $(OBJDIR)/libregexp.o $(OBJDIR)/libunicode.o $(OBJDIR)/cutils.o $(OBJDIR)/quickjs-libc.o $(OBJDIR)/libbf.o

PTKL_OBJS=$(OBJDIR)/ptkl.o $(OBJDIR)/ptklc.o $(OBJDIR)/repl.o $(OBJDIR)/ptklcli.o $(PTKL_LIB_OBJS)
#PTKL_OBJS=$(OBJDIR)/ptkl.o $(OBJDIR)/ptklc.o $(OBJDIR)/repl.o $(OBJDIR)/ptklcli.o $(LIBPTKL)

LIBS=-lm -ldl -lpthread
LIBS+=$(EXTRA_LIBS)

.PHONY: bump-version
bump-version:
	date -I > VERSION

$(OBJDIR):
	mkdir -p $(OBJDIR) $(OBJDIR)/examples $(OBJDIR)/tests

$(PTKL): $(PTKL_OBJS)
#$(PTKL): $(LIBPTKL)
	$(CC) $(LDFLAGS) $(LDEXPORT) -o $@ $^ $(LIBS)

ptkl-debug: $(patsubst %.o, %.debug.o, $(PTKL_OBJS))
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

$(PTKLC): $(OBJDIR)/ptklc_main.o $(OBJDIR)/ptklcli.o $(OBJDIR)/ptklc.o $(PTKL_LIB_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

ptkl-new-release: clean bump-version
	make $(PTKL)

ptkl-new-debug: clean bump-version
	DEBUG=1 make $(PTKL)

fuzz_eval: $(OBJDIR)/fuzz_eval.o $(OBJDIR)/fuzz_common.o libquickjs.fuzz.a
	$(CC) $(CFLAGS_OPT) $^ -o fuzz_eval $(LIB_FUZZING_ENGINE)

fuzz_compile: $(OBJDIR)/fuzz_compile.o $(OBJDIR)/fuzz_common.o libquickjs.fuzz.a
	$(CC) $(CFLAGS_OPT) $^ -o fuzz_compile $(LIB_FUZZING_ENGINE)

fuzz_regexp: $(OBJDIR)/fuzz_regexp.o $(OBJDIR)/libregexp.fuzz.o $(OBJDIR)/cutils.fuzz.o $(OBJDIR)/libunicode.fuzz.o
	$(CC) $(CFLAGS_OPT) $^ -o fuzz_regexp $(LIB_FUZZING_ENGINE)

libfuzzer: fuzz_eval fuzz_compile fuzz_regexp

ifdef CONFIG_LTO
$(LIBPTKL): $(patsubst %.o, %.nolto.o, $(PTKL_LIB_OBJS))
	$(AR) rcs $@ $^
else
$(LIBPTKL): $(PTKL_LIB_OBJS)
	$(AR) rcs $@ $^
endif

libquickjs.fuzz.a: $(patsubst %.o, %.fuzz.o, $(PTKL_LIB_OBJS))
	$(AR) rcs $@ $^

repl.c: $(PTKLC) repl.js
	./$(PTKLC) -c -o $@ -m repl.js

# unicode
ifneq ($(wildcard unicode/UnicodeData.txt),)

UNICODE_OBJS = libunicode.o libunicode.nolto.o

$(OBJDIR)/$(UNICODE_OBJS): libunicode-table.h

libunicode-table.h: unicode_gen
	./unicode_gen unicode $@
endif

run-test262: $(OBJDIR)/run-test262.o $(PTKL_LIB_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

run-test262-debug: $(patsubst %.o, %.debug.o, $(OBJDIR)/run-test262.o $(PTKL_LIB_OBJS))
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

$(OBJDIR)/%.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS_OPT) -c -o $@ $<

$(OBJDIR)/fuzz_%.o: fuzz/fuzz_%.c | $(OBJDIR)
	$(CC) $(CFLAGS_OPT) -c -I. -o $@ $<

$(OBJDIR)/%.pic.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS_OPT) -fPIC -DJS_SHARED_LIBRARY -c -o $@ $<

$(OBJDIR)/%.nolto.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS_NOLTO) -c -o $@ $<

$(OBJDIR)/%.debug.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS_DEBUG) -c -o $@ $<

$(OBJDIR)/%.fuzz.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS_OPT) -fsanitize=fuzzer-no-link -c -o $@ $<

$(OBJDIR)/%.check.o: %.c | $(OBJDIR)
	$(CC) $(CFLAGS) -DCONFIG_CHECK_JSVALUE -c -o $@ $<

regexp_test: libregexp.c libunicode.c cutils.c
	$(CC) $(LDFLAGS) $(CFLAGS) -DTEST -o $@ libregexp.c libunicode.c cutils.c $(LIBS)

unicode_gen: $(OBJDIR)/unicode_gen.o $(OBJDIR)/cutils.o libunicode.c unicode_gen_def.h
	$(CC) $(LDFLAGS) $(CFLAGS) -o $@ $(OBJDIR)/unicode_gen.o $(OBJDIR)/cutils.o

clean:
	rm -rf $(TARGETS) $(OBJDIR)/ *.dSYM/
	rm -f ptkl-debug
	rm -f examples/*.so tests/*.so
	rm -f examples/test_fib examples/hello examples/hello_module
	rm -f repl.c out.c hello.c test_fib.c
	rm -f *~ unicode_gen regexp_test fuzz_eval fuzz_compile fuzz_regexp
	rm -rf run-test262-debug
	rm -f run_octane run_sunspider_like

install: all
	mkdir -p "$(DESTDIR)$(PREFIX)/bin"
	$(STRIP) $(PTKL)
	install -m755 $(PTKL) "$(DESTDIR)$(PREFIX)/bin"
	mkdir -p "$(DESTDIR)$(PREFIX)/lib/ptkl"
	install -m644 $(LIBPTKL) "$(DESTDIR)$(PREFIX)/lib/ptkl"
ifdef CONFIG_LTO
	install -m644 $(LIBPTKL) "$(DESTDIR)$(PREFIX)/lib/ptkl"
endif
	mkdir -p "$(DESTDIR)$(PREFIX)/include/quickjs"
	install -m644 quickjs.h quickjs-libc.h "$(DESTDIR)$(PREFIX)/include/ptkl"

###############################################################################
# examples

# example of static JS compilation
HELLO_SRCS=examples/hello.js
HELLO_OPTS=-fno-string-normalize -fno-map -fno-promise -fno-typedarray \
           -fno-typedarray -fno-regexp -fno-json -fno-eval -fno-proxy \
           -fno-date -fno-module-loader -fno-bigint

hello.c: $(PTKLC) $(HELLO_SRCS)
	./$(PTKLC) -e $(HELLO_OPTS) -o $@ $(HELLO_SRCS)

examples/hello: $(OBJDIR)/hello.o $(PTKL_LIB_OBJS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

# example of static JS compilation with modules
HELLO_MODULE_SRCS=examples/hello_module.js
HELLO_MODULE_OPTS=-fno-string-normalize -fno-map -fno-typedarray \
           -fno-typedarray -fno-regexp -fno-json -fno-eval -fno-proxy \
           -fno-date -m

examples/hello_module: $(PTKLC) $(LIBPTKL) $(HELLO_MODULE_SRCS)
	./$(PTKLC) $(HELLO_MODULE_OPTS) -o $@ $(HELLO_MODULE_SRCS)

# use of an external C module (static compilation)

test_fib.c: $(PTKLC) examples/test_fib.js
	./$(PTKLC) -e -M examples/fib.so,fib -m -o $@ examples/test_fib.js

examples/test_fib: $(OBJDIR)/test_fib.o $(OBJDIR)/examples/fib.o $(LIBPTKL)
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

examples/fib.so: $(OBJDIR)/examples/fib.pic.o
	$(CC) $(LDFLAGS) -shared -o $@ $^

examples/point.so: $(OBJDIR)/examples/point.pic.o
	$(CC) $(LDFLAGS) -shared -o $@ $^

###############################################################################
# documentation

DOCS=doc/quickjs.pdf doc/quickjs.html doc/jsbignum.pdf doc/jsbignum.html

build_doc: $(DOCS)

clean_doc:
	rm -f $(DOCS) $(EPUB)

doc/%.pdf: doc/%.texi
	texi2pdf --clean -o $@ -q $<

doc/%.html.pre: doc/%.texi
	makeinfo --html --no-headers --no-split --number-sections -o $@ $<

doc/%.html: doc/%.html.pre
	sed -e 's|</style>|</style>\n<meta name="viewport" content="width=device-width, initial-scale=1.0">|' < $< > $@

# Separate from DOCS because of extra dependency required to generate epub:
# Archive::Zip (macports: p5.34-archive-zip)
EPUB=doc/quickjs.epub doc/jsbignum.epub

epub: $(EPUB)

doc/%.epub: doc/%.texi
	texi2any --epub3 -o $@ $<

###############################################################################
# tests

ifdef CONFIG_SHARED_LIBS
test: tests/bjson.so examples/point.so
endif

test: $(PTKL)
	./$(PTKL) tests/test_closure.js
	./$(PTKL) tests/test_language.js
	./$(PTKL) --std tests/test_builtin.js
	./$(PTKL) tests/test_loop.js
	./$(PTKL) tests/test_bignum.js
	./$(PTKL) tests/test_std.js
	./$(PTKL) tests/test_worker.js
ifdef CONFIG_SHARED_LIBS
ifdef CONFIG_BIGNUM
	./$(PTKL) --bignum tests/test_bjson.js
else
	./$(PTKL) tests/test_bjson.js
endif
	./$(PTKL) examples/test_point.js
endif

ifeq ($(wildcard test262o/tests.txt),)
test2o test2o-update:
	@echo test262o tests not installed
else
# ES5 tests (obsolete)
test2o: run-test262
	time ./run-test262 -t -m -c test262o.conf

test2o-update: run-test262
	./run-test262 -t -u -c test262o.conf
endif

ifeq ($(wildcard test262/features.txt),)
test2 test2-update test2-default test2-check:
	@echo test262 tests not installed
else
# Test262 tests
test2-default: run-test262
	time ./run-test262 -t -m -c test262.conf

test2: run-test262
	time ./run-test262 -t -m -c test262.conf -a

test2-update: run-test262
	./run-test262 -t -u -c test262.conf -a

test2-check: run-test262
	time ./run-test262 -t -m -c test262.conf -E -a
endif

testall: all test microbench test2o test2

testall-complete: testall

node-test:
	node tests/test_closure.js
	node tests/test_language.js
	node tests/test_builtin.js
	node tests/test_loop.js
	node tests/test_bignum.js

###############################################################################
# benchmarks

stats: $(PTKL)
	./$(PTKL) -qd

microbench: $(PTKL)
	./$(PTKL) --std tests/microbench.js

node-microbench:
	node tests/microbench.js -s microbench-node.txt
	node --jitless tests/microbench.js -s microbench-node-jitless.txt

bench-v8: $(PTKL)
	make -C tests/bench-v8
	./$(PTKL) -d tests/bench-v8/combined.js

node-bench-v8:
	make -C tests/bench-v8
	node --jitless tests/bench-v8/combined.js

tests/bjson.so: $(OBJDIR)/tests/bjson.pic.o
	$(CC) $(LDFLAGS) -shared -o $@ $^ $(LIBS)

BENCHMARKDIR=../quickjs-benchmarks

run_sunspider_like: $(BENCHMARKDIR)/run_sunspider_like.c
	$(CC) $(CFLAGS) $(LDFLAGS) -DNO_INCLUDE_DIR -I. -o $@ $< $(LIBPTKL) $(LIBS)

run_octane: $(BENCHMARKDIR)/run_octane.c
	$(CC) $(CFLAGS) $(LDFLAGS) -DNO_INCLUDE_DIR -I. -o $@ $< $(LIBPTKL) $(LIBS)

benchmarks: run_sunspider_like run_octane
	./run_sunspider_like $(BENCHMARKDIR)/kraken-1.0/
	./run_sunspider_like $(BENCHMARKDIR)/kraken-1.1/
	./run_sunspider_like $(BENCHMARKDIR)/sunspider-1.0/
	./run_octane $(BENCHMARKDIR)/

-include $(wildcard $(OBJDIR)/*.d)
