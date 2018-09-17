# Variables to override
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_INCLUDE_DIR include path to ei.h (Required for crosscompile)
# ERL_EI_LIBDIR path to libei.a (Required for crosscompile)
# LDFLAGS	linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries

DEFAULT_TARGETS ?= priv priv/scenic_driver_nerves_rpi
# fonts

# Look for the EI library and header files
# For crosscompiled builds, ERL_EI_INCLUDE_DIR and ERL_EI_LIBDIR must be
# passed into the Makefile.
ifeq ($(ERL_EI_INCLUDE_DIR),)
ERL_ROOT_DIR = $(shell erl -eval "io:format(\"~s~n\", [code:root_dir()])" -s init stop -noshell)
ifeq ($(ERL_ROOT_DIR),)
   $(error Could not find the Erlang installation. Check to see that 'erl' is in your PATH)
endif
ERL_EI_INCLUDE_DIR = "$(ERL_ROOT_DIR)/usr/include"
ERL_EI_LIBDIR = "$(ERL_ROOT_DIR)/usr/lib"
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei

#-L/opt/vc/lib -lVCOS
# LDFLAGS += -lbcm_host -lmnl -lEGL -lGLESv2 -lm-lvcos
LDFLAGS += -lGLESv2 -lEGL -lm -lbcm_host -lvchostif

CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter -pedantic

# Enable for debug messages
# CFLAGS += -DDEBUG

CFLAGS += -std=gnu99

SRCS = c_src/main.c c_src/comms.c c_src/nanovg/nanovg.c \
	c_src/render_script.c c_src/tx.c c_src/utils.c


.PHONY: all clean

all: $(DEFAULT_TARGETS)

%.o: %.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

priv:
	mkdir -p priv

priv/scenic_driver_nerves_rpi: priv $(SRCS)
	$(CC) $(CFLAGS) -o $@ $(SRCS) $(LDFLAGS)

# fonts: priv/
# 	rsync -rupE fonts priv/

clean:
	$(RM) -rf priv/dev priv/test priv/prod src/*.o
