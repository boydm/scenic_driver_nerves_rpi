/*
#  Created by Boyd Multerer on 05/17/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
*/

#include <unistd.h>

#include <stdio.h>
// #include <stdlib.h>
#include <string.h>
#include <poll.h>
#include <stdint.h>
#include <assert.h>

#include <bcm_host.h>

#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <EGL/egl.h>
#include <EGL/eglext.h>

#define NANOVG_GLES2_IMPLEMENTATION
#include "nanovg/nanovg.h"
#include "nanovg/nanovg_gl.h"

#include "types.h"
#include "comms.h"
#include "render_script.h"

#define STDIN_FILENO 0

#define DEFAULT_SCREEN    0

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

#define   MSG_OUT_PUTS              0x02

//---------------------------------------------------------
// setup the video core
void init_video_core( egl_data_t* p_data, int debug_mode ) {
  int screen_width, screen_height;

  // initialize the bcm_host from broadcom
  bcm_host_init();

  // query the monitor attached to HDMI
  if ( graphics_get_display_size( DEFAULT_SCREEN, &screen_width, &screen_height) < 0 ) {
    send_puts("RPI driver error: Unable to query the default screen on HDMI");
    return;
  }
  p_data->screen_width = screen_width;
  p_data->screen_height = screen_height;


  //-----------------------------------
  // get an EGL display connection
  EGLBoolean result;

  // get a handle to the display
  EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if ( display == EGL_NO_DISPLAY ) {
    send_puts("RPI driver error: Unable get handle to the default screen on HDMI");
    return;
  }
  p_data->display = display;


  // initialize the EGL display connection
  EGLint major_version;
  EGLint minor_version;
  // returns a pass/fail boolean
  if ( eglInitialize(display, &major_version, &minor_version) == EGL_FALSE ) {
    send_puts("RPI driver error: Unable initialize EGL");
    return;
  }
  p_data->major_version = major_version;
  p_data->minor_version = minor_version;


  // prepare an appropriate EGL frame buffer configuration request
  static const EGLint attribute_list[] = {
    EGL_RED_SIZE, 8,
    EGL_GREEN_SIZE, 8,
    EGL_BLUE_SIZE, 8,
    EGL_ALPHA_SIZE, 8,
    EGL_STENCIL_SIZE, 1,
    EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
    EGL_NONE
  };
  static const EGLint context_attributes[] = {
     EGL_CONTEXT_CLIENT_VERSION, 2,
     EGL_NONE
   };
  EGLConfig config;
  EGLint num_config;


   // get an appropriate EGL frame buffer configuration
  if ( eglChooseConfig(display, attribute_list, &config, 1, &num_config) == EGL_FALSE ) {
    send_puts("RPI driver error: Unable to get usable display config");
    return;
  }
  p_data->config = config;


  // use open gl es
  if ( eglBindAPI(EGL_OPENGL_ES_API) == EGL_FALSE ) {
    send_puts("RPI driver error: Unable to bind to GLES");
    return;
  }


  // create an EGL graphics context
  EGLContext context = eglCreateContext(display, config, EGL_NO_CONTEXT, context_attributes);
  if ( context == EGL_NO_CONTEXT ) {
    send_puts("RPI driver error: Failed to create EGL context");
    return;
  }
  p_data->context = context;


  //-------------------
  // create the native window and bind it

  static EGL_DISPMANX_WINDOW_T nativewindow;
  DISPMANX_UPDATE_HANDLE_T dispman_update;
  VC_RECT_T dst_rect;
  VC_RECT_T src_rect;

  dst_rect.x = 0;
  dst_rect.y = 0;
  if ( debug_mode ) {
    dst_rect.width = screen_width / 2;
    dst_rect.height = screen_height / 2;
  } else {
    dst_rect.width = screen_width;
    dst_rect.height = screen_height;    
  }

  src_rect.x = 0;
  src_rect.y = 0;
  src_rect.width = screen_width << 16;
  src_rect.height = screen_height << 16;

  // start the display manager
  DISPMANX_DISPLAY_HANDLE_T dispman_display = vc_dispmanx_display_open(0 /* LCD */);
  dispman_update = vc_dispmanx_update_start(0 /* LCD */);


  // create the screen element (will be full-screen)
  VC_DISPMANX_ALPHA_T alpha =
  {
      DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS, 
      255, /*alpha 0->255*/
      0
  };
  DISPMANX_ELEMENT_HANDLE_T dispman_element = vc_dispmanx_element_add (dispman_update, dispman_display,
  0/*layer*/, &dst_rect, 0/*src*/,
  &src_rect, DISPMANX_PROTECTION_NONE, &alpha, 0/*clamp*/, 0/*transform*/);
  result = vc_dispmanx_update_submit_sync(dispman_update);
  if (result != 0) {
    send_puts("RPI driver error: Unable to start dispmanx element");
    return;
  }


  // create the native window surface
  nativewindow.element = dispman_element;
  nativewindow.width = screen_width;
  nativewindow.height = screen_height;
  EGLSurface surface = eglCreateWindowSurface(display, config, &nativewindow, NULL);
  if (surface == EGL_NO_SURFACE) {
    send_puts("RPI driver error: Unable create the native window surface");
    return;
  }
  p_data->surface = surface;

  // connect the context to the surface and make it current
  if ( eglMakeCurrent(display, surface, surface, context) == EGL_FALSE ) {
    send_puts("RPI driver error: Unable make the surface current");
    return;
  }


  //-------------------
  // config gles

  // set the view port to the new size passed in
  glViewport(0, 0, screen_width, screen_height);

  // This turns on/off depth test.
  // With this ON, whatever we draw FIRST is 
  // "on top" and each subsequent draw is BELOW 
  // the draw calls before it.
  // With this OFF, whatever we draw LAST is
  // "on top" and each subsequent draw is ABOVE
  // the draw calls before it.
  glDisable(GL_DEPTH_TEST);

  // Probably need this on, enables Gouraud Shading
  // glShadeModel(GL_SMOOTH);

  // Turn on Alpha Blending
  // There are some efficiencies to be gained by ONLY
  // turning this on when we have a primitive with a
  // style that has an alpha channel != 1.0f but we
  // don't have code to detect that.  Easy to do if we need it!
  glEnable (GL_BLEND); 
  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);


  //-------------------
  // initialize nanovg

  p_data->p_ctx = nvgCreateGLES2(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG);
  if (p_data->p_ctx == NULL) {
    send_puts("RPI driver error: failed nvgCreateGLES2");
    return;
  }
}



void test_draw(egl_data_t* p_data) {
  //-----------------------------------
  // Set background color and clear buffers
  // glClearColor(0.15f, 0.25f, 0.35f, 1.0f);
  // glClearColor(0.098f, 0.098f, 0.439f, 1.0f);    // midnight blue
  // glClearColor(0.545f, 0.000f, 0.000f, 1.0f);    // dark red
  // glClearColor(0.184f, 0.310f, 0.310f, 1.0f);       // dark slate gray
  // glClearColor(0.0f, 0.0f, 0.0f, 1.0f);       // black

  // glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

  NVGcontext* p_ctx = p_data->p_ctx;
  int screen_width = p_data->screen_width;
  int screen_height = p_data->screen_height;

  // nvgBeginFrame(p_ctx, screen_width, screen_height, 1.0f);

    // Next, draw graph line
  nvgBeginPath(p_ctx);
  nvgMoveTo(p_ctx, 0, 0);
  nvgLineTo(p_ctx, screen_width, screen_height);
  nvgStrokeColor(p_ctx, nvgRGBA(0, 160, 192, 255));
  nvgStrokeWidth(p_ctx, 3.0f);
  nvgStroke(p_ctx);

  nvgBeginPath(p_ctx);
  nvgMoveTo(p_ctx, screen_width, 0);
  nvgLineTo(p_ctx, 0, screen_height);
  nvgStrokeColor(p_ctx, nvgRGBA(0, 160, 192, 255));
  nvgStrokeWidth(p_ctx, 3.0f);
  nvgStroke(p_ctx);

  nvgBeginPath(p_ctx);
  nvgCircle(p_ctx, screen_width / 2, screen_height / 2, 50);
  nvgFillColor(p_ctx, nvgRGBAf(0.545f, 0.000f, 0.000f, 1.0f));
  nvgFill(p_data->p_ctx);
  nvgStroke(p_ctx);

  // nvgEndFrame(p_ctx);

  // eglSwapBuffers(p_data->display, p_data->surface);
}


//---------------------------------------------------------
// return true if the caller side of the stdin pipe is open and in
// business. If it closes, then return false
// http://pubs.opengroup.org/onlinepubs/7908799/xsh/poll.html
// see https://stackoverflow.com/questions/25147181/pollhup-vs-pollnval-or-what-is-pollhup
bool isCallerDown() 
{
    struct pollfd ufd;
    memset(&ufd, 0, sizeof ufd);
    ufd.fd = STDIN_FILENO;
    ufd.events = POLLIN;
    if ( poll(&ufd, 1, 0) < 0 ) 
        return true;
    return ufd.revents & POLLHUP;
}

//---------------------------------------------------------
int main(int argc, char **argv) {
  driver_data_t     data;
  egl_data_t        egl_data;

  test_endian();

  // super simple arg check
  if ( argc != 3 ) {
    send_puts("Argument check failed!");
    printf("\r\nscenic_driver_rpi should be launched via the Scenic.Driver.Rpi library.\r\n\r\n");
    return 0;
  }
  int num_scripts = atoi(argv[1]);
  int debug_mode = atoi(argv[2]);

  // init graphics
  init_video_core( &egl_data, debug_mode );

  // set up the scripts table
  memset(&data, 0, sizeof(driver_data_t));
  data.p_scripts = malloc( sizeof(void*) * num_scripts );
  memset(data.p_scripts, 0, sizeof(void*) * num_scripts );
  data.keep_going = true;
  data.num_scripts = num_scripts;
  data.p_ctx = egl_data.p_ctx;
  data.screen_width = egl_data.screen_width;
  data.screen_height = egl_data.screen_height;

  // signal the app that the window is ready
  send_ready( 0, egl_data.screen_width, egl_data.screen_height );

  /* Loop until the calling app closes the window */
  while ( data.keep_going && !isCallerDown() ) {

    // check for incoming messages - blocks with a timeout
    if ( handle_stdio_in(&data) ) {

      // clear the buffer
      glClear(GL_COLOR_BUFFER_BIT);

      // render the scene
      nvgBeginFrame( egl_data.p_ctx, egl_data.screen_width, egl_data.screen_height, 1.0f);
      if ( data.root_script >= 0 ) {
        run_script( data.root_script, &data );
      }
      nvgEndFrame(data.p_ctx);

      // Swap front and back buffers
      eglSwapBuffers(egl_data.display, egl_data.surface);
    }

    // wait for events - timeout is in seconds
    // the timeout is the max time the app will stay alive
    // after the host BEAM environment shuts down.
    // glfwWaitEventsTimeout(1.01f);

    // poll for events and return immediately
    // glfwPollEvents();
  }

  return 0;
}





