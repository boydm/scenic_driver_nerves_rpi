/*
#  Created by Boyd Multerer on 12/05/17.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#
*/

// one unified place for the various structures

#pragma once

#ifndef bool
#include <stdbool.h>
#endif

#ifndef NANOVG_H
#include "nanovg/nanovg.h"
#endif

// #include <EGL/egl.h>


#ifndef PACK
  #ifdef _MSC_VER
    #define PACK( __Declaration__ ) \
        __pragma( pack(push, 1) ) __Declaration__ __pragma( pack(pop) )
  #elif defined(__GNUC__)
    #define PACK( __Declaration__ ) __Declaration__ __attribute__((__packed__))
  #endif
#endif

typedef unsigned char byte;

//---------------------------------------------------------
PACK(typedef struct Vector2f
{
  float x;
  float y;
}) Vector2f;


//---------------------------------------------------------
// the data pointed to by the window private data pointer
typedef struct {
  bool              keep_going;
  uint32_t          input_flags;
  float             last_x;
  float             last_y;
  int               root_script;
  void*             p_tx_ids;
  void*             p_fonts;
  NVGcontext*       p_ctx;
} driver_data_t;

typedef struct {
  EGLDisplay display;
  EGLConfig config;
  EGLSurface surface;
  EGLContext context;
  int screen_width;
  int screen_height;
  int major_version;
  int minor_version;
  NVGcontext* p_ctx;
} egl_data_t;
