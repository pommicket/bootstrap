#
# Makefile for musl (requires GNU make)
#
# This is how simple every makefile should be...
# No, I take that back - actually most should be less than half this size.
#
# Use config.mak to override any of the following variables.
# Do not make changes here.
#

CC = ../tcc-0.9.27/tcc0
exec_prefix = ../musl-bootstrapU
bindir = $(exec_prefix)/bin

prefix = /usr/local/musl-bootstrap
includedir = $(prefix)/include
libdir = $(prefix)/lib

SRCS = $(sort $(wildcard src/*/*.c))
OBJS = $(SRCS:.c=.o) src/alloca86_64-bt.o src/alloca86_64.o src/libtcc1.o src/va_list.o src/syscall.o
LOBJS = $(OBJS:.o=.lo)
GENH = include/bits/alltypes.h

CFLAGS  = -Os -nostdinc -ffreestanding -std=c99 -D_XOPEN_SOURCE=700 -pipe
LDFLAGS = -nostdlib -shared -Wl,-Bsymbolic
INC     = -I./include -I./src/internal -I./arch/$(ARCH)
PIC     = -fPIC
AR      = $(CC) -ar
RANLIB  =
OBJCOPY =

ALL_INCLUDES = $(sort $(wildcard include/*.h include/*/*.h) $(GENH))

EMPTY_LIB_NAMES = m rt pthread crypt util xnet resolv
EMPTY_LIBS = $(EMPTY_LIB_NAMES:%=lib/lib%.a)
CRT_LIBS = lib/crt1.o lib/crti.o lib/crtn.o
LIBC_LIBS = lib/libc.a
ALL_LIBS = $(LIBC_LIBS) $(CRT_LIBS)

ALL_TOOLS = tools/musl-gcc

-include config.mak

all: $(ALL_LIBS) $(ALL_TOOLS)

install: $(ALL_LIBS:lib/%=$(DESTDIR)$(libdir)/%) $(ALL_INCLUDES:include/%=$(DESTDIR)$(includedir)/%) $(ALL_TOOLS:tools/%=$(DESTDIR)$(bindir)/%)

src/syscall.o: src/syscall.s
	$(CC) -c -o $@ $<
src/%.o: ../tcc-0.9.27/lib/%.o
	cp $< $@
clean:
	rm -f crt/*.o
	rm -f $(OBJS)
	rm -f $(LOBJS)
	rm -f $(ALL_LIBS) lib/*.[ao] lib/*.so
	rm -f $(ALL_TOOLS)
	rm -f $(GENH) 
	rm -f include/bits

include/bits:
	@test "$(ARCH)" || { echo "Please set ARCH in config.mak before running make." ; exit 1 ; }
	ln -sf ../arch/$(ARCH)/bits $@

include/bits/alltypes.h.sh: include/bits

include/bits/alltypes.h: include/bits/alltypes.h.sh
	sh $< > $@

%.o: $(ARCH)/%.s
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

%.o: %.c $(GENH)
	$(CC) $(CFLAGS) $(INC) -c -o $@ $<

%.lo: $(ARCH)/%.s
	$(CC) $(CFLAGS) $(INC) $(PIC) -c -o $@ $<

%.lo: %.c $(GENH)
	$(CC) $(CFLAGS) $(INC) $(PIC) -c -o $@ $<

lib/libc.so: $(LOBJS)
	$(CC) $(LDFLAGS) -o $@ $(LOBJS) -lgcc
	$(OBJCOPY) --weaken $@

lib/libc.a: $(OBJS)
	mkdir -p lib
	$(AR) rc $@ $(OBJS)
	# $(RANLIB) $@

$(EMPTY_LIBS):
	rm -f $@
	$(AR) rc $@

lib/%.o: crt/%.o
	cp $< $@

tools/musl-gcc: tools/gen-musl-gcc.sh config.mak
	sh $< "$(prefix)" > $@ || { rm -f $@ ; exit 1 ; }
	chmod +x $@

$(DESTDIR)$(bindir)/%: tools/%
	install -D $< $@

$(DESTDIR)$(prefix)/%: %
	install -D -m 644 $< $@

.PRECIOUS: $(CRT_LIBS:lib/%=crt/%)

.PHONY: all clean install
