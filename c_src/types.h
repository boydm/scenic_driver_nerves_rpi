/*
#  Created by Boyd Multerer on 12/05/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#
*/

// one unified place for the various structures


#ifndef RENDER_DRIVER_TYPES
#define RENDER_DRIVER_TYPES

#ifndef bool
#include <stdbool.h>
#endif

#ifndef NANOVG_H
#include "nanovg/nanovg.h"
#endif

typedef unsigned char byte;

//---------------------------------------------------------
typedef struct __attribute__((__packed__))
{
  float x;
  float y;
} Vector2f;

//---------------------------------------------------------
// the data pointed to by the window private data pointer
typedef struct {
  bool              keep_going;
  uint32_t          input_flags;
  float             last_x;
  float             last_y;
  void**            p_scripts;
  int               root_script;
  int               num_scripts;
  void*             p_tx_ids;
  void*             p_fonts;
  NVGcontext*       p_ctx;
  int               screen_width;
  int               screen_height;
} driver_data_t;


#endif