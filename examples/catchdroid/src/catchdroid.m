#include <jni.h>
#include <errno.h>

#include <android/log.h>

#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

#import "Engine.h"
#import "Texture.h"
#import "Page.h"
#import "Character.h"
#import "Scene.h"
#import "Font.h"
#import "TextContainer.h"

static Engine * currentEngine = nil;

@implementation Engine
+ (Engine *) currentEngine
{
    return currentEngine;
}

/**
 * Initialize an EGL context for the current display.
 */
-(int)setupDisplay
{
    // initialize OpenGL ES and EGL

    /*
     * Here specify the attributes of the desired configuration.
     * Below, we select an EGLConfig with at least 8 bits per color
     * component compatible with on-screen windows
     */
    const EGLint attribs[] = {
            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_NONE
    };
    EGLint w, h, dummy, format;
    EGLint numConfigs;
    EGLConfig config;
    EGLSurface surface;
    EGLContext context;

    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);

    eglInitialize(display, 0, 0);

    /* Here, the application chooses the configuration it desires. In this
     * sample, we have a very simplified selection process, where we pick
     * the first EGLConfig that matches our criteria */
    eglChooseConfig(display, attribs, &config, 1, &numConfigs);

    /* EGL_NATIVE_VISUAL_ID is an attribute of the EGLConfig that is
     * guaranteed to be accepted by ANativeWindow_setBuffersGeometry().
     * As soon as we picked a EGLConfig, we can safely reconfigure the
     * ANativeWindow buffers to match, using EGL_NATIVE_VISUAL_ID. */
    eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &format);

    ANativeWindow_setBuffersGeometry(self->app->window, 0, 0, format);

    surface = eglCreateWindowSurface(display, config, self->app->window, NULL);
    context = eglCreateContext(display, config, NULL, NULL);

    if (eglMakeCurrent(display, surface, surface, context) == EGL_FALSE) {
        LOGW("Unable to eglMakeCurrent");
        return -1;
    }

    eglQuerySurface(display, surface, EGL_WIDTH, &w);
    eglQuerySurface(display, surface, EGL_HEIGHT, &h);

    self->display = display;
    self->context = context;
    self->surface = surface;
    self->width = w;
    self->height = h;
    self->state.angle = 0;

    // Initialize GL state.
    glEnable(GL_CULL_FACE);
    glShadeModel(GL_SMOOTH);
    glDisable(GL_DEPTH_TEST);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    if(w > h)
      glOrthof(0, 8, 0, ((float)h)/w * 8, -1, 1);
    else
      glOrthof(0, ((float)w)/h * 8, 0, 8, -1, 1);
    glTranslatef(8/2 - 1 - 0.5, 8/2 - 0.5, 0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    _controls = [Texture textureWithPath: @"controls.png"];
    [_controls retain];

    _scene = [Scene new];

    //[self showToast: @"Tap to begin"];

    return 0;
}

/**
 * Just the current frame in the display.
 */
-(void)drawFrame
{
    if (self->display == NULL) {
        // No display.
        return;
    }

    // Just fill the screen with a color.
#if 0
    glClearColor(
        ((float)self->state.x)/self->width,
        self->state.angle,
        ((float)self->state.y)/self->height,
        1);
#else
    glClearColor(0,0,0,1);
#endif
    glClear(GL_COLOR_BUFFER_BIT);

    ////////////////////////

    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    [_scene draw];
    glPopMatrix();
    ////////////////////////

    glPushMatrix();    
    glScalef(4.9, 9.7, 1);
    glTranslatef(-0.01, 0, 0);
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);

    glBindTexture(GL_TEXTURE_2D, [_controls textureId]);
    GLfloat vertices[] = {
      -0.5, -0.5,
       0.5, -0.5,
       0.5, 0.5,

       0.5, 0.5,
      -0.5, 0.5,
      -0.5, -0.5,
    };
    GLfloat textures[] = {
      0, 1,
      1, 1,
      1, 0,

      1, 0,
      0, 0,
      0, 1
    };
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glTexCoordPointer(2, GL_FLOAT, 0, textures);
    glDrawArrays(GL_TRIANGLES, 0, 6);

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);

    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
    //////////////////

    eglSwapBuffers(self->display, self->surface);
}

- (void) update
{
  struct timeval currentTimeVal;
  gettimeofday(&currentTimeVal, NULL);
  
  double currentTime = 0;
  currentTime = currentTimeVal.tv_sec + ((double)currentTimeVal.tv_usec) / 1000000;
  if(_previousFrameTime != 0)
  {
    double deltaT = currentTime - _previousFrameTime;
    if(deltaT < 0)
    {
      LOGW("Negative delta t: %g -- midnight rollover?", deltaT);
      _previousFrameTime = currentTime;
      return; 
    }
    if(deltaT > 0.1)
      deltaT = 0.1;

    // update all objects
    [_scene update: deltaT];
  }
  _previousFrameTime = currentTime;

}

/**
 * Tear down the EGL context currently associated with the display.
 */
-(void)terminateDisplay
{
    LOGI("Terminating display");
    [_controls release];
    _controls = nil;
    [_scene release];
    _scene = nil;

    if (self->display != EGL_NO_DISPLAY) {
        eglMakeCurrent(self->display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (self->context != EGL_NO_CONTEXT) {
            eglDestroyContext(self->display, self->context);
        }
        if (self->surface != EGL_NO_SURFACE) {
            eglDestroySurface(self->display, self->surface);
        }
        eglTerminate(self->display);
    }
    self->animating = 0;
    self->display = EGL_NO_DISPLAY;
    self->context = EGL_NO_CONTEXT;
    self->surface = EGL_NO_SURFACE;
}
- (void) dealloc
{
   [self terminateDisplay];
   [super dealloc];
}
- (int32_t) handleInput: (AInputEvent *) event
{
   if (AInputEvent_getType(event) == AINPUT_EVENT_TYPE_MOTION) {
        self->animating = 1;
        self->state.x = AMotionEvent_getX(event, 0);
        self->state.y = AMotionEvent_getY(event, 0);
        int action = AMotionEvent_getAction(event) & AMOTION_EVENT_ACTION_MASK;
        
        static const int MAXIMUM_TOUCHES = 2;
        switch(action)
        {
          case AMOTION_EVENT_ACTION_POINTER_DOWN:
          case AMOTION_EVENT_ACTION_DOWN: 
          case AMOTION_EVENT_ACTION_MOVE: 
          { 
            int index = (action & AMOTION_EVENT_ACTION_POINTER_INDEX_MASK) 
              >> AMOTION_EVENT_ACTION_POINTER_INDEX_SHIFT; 
            int pid = AMotionEvent_getPointerId(event, index); 
            if (pid > MAXIMUM_TOUCHES) 
              break; 
            float x = AMotionEvent_getX(event, index); 
            float y = AMotionEvent_getY(event, index); 

            float pressure = AMotionEvent_getPressure(event, index); 

            if(x / (float)width < 0.10)
              [_scene setDirection: @selector(movePlayerLeft)];
            else if(x / (float)width > 0.26 && x / (float)width < 0.5)
              [_scene setDirection: @selector(movePlayerRight)];
            else if(x / (float)width >= 0.5 && x / (float)width < 0.75)
              [_scene setButtonA: YES];
            else if(x / (float)width > 0.75)
              {}
            else if(y / (float)height < 0.72)
              [_scene setDirection: @selector(movePlayerUp)];
            else if(y / (float)height > 0.85)
              [_scene setDirection: @selector(movePlayerDown)];

            if([_scene.textContainer isVisible])
              [_scene setDirection: NULL];
            LOGI("Engine %g %g action %d", x / (float)width, y / (float)height, action);
            break;
          }
          case AMOTION_EVENT_ACTION_POINTER_UP: 
          case AMOTION_EVENT_ACTION_UP: 
            [_scene setDirection: NULL];
            [_scene setButtonA: NO];
            break;
          default:
          LOGI("New action");
        }
        return 1;
    }
    return 0;
}
- (void)showToast:(NSString*)text
{
  if (!text || ![text length])
  {
    LOGW("Empty string passed to showToast");
    return;
  }
  JNIEnv* env = self->app->activity->env;
  JavaVM * vm = self->app->activity->vm;
  jint rtn = (*vm)->AttachCurrentThread(vm, &env, NULL);
  jobject context = self->app->activity->clazz; // clazz is actually an instance of the java Activity class
  jstring txt = (*env)->NewStringUTF(env, [text UTF8String]);

  if(!context)
  {
    LOGW("Context is nil in showToast");
    (*vm)->DetachCurrentThread(vm);
    return;
  }
  if(!txt)
  {
    LOGW("Txt is nil in showToast");
    (*vm)->DetachCurrentThread(vm);
  }

  // adapted from:
  // https://github.com/chisun-joung/NDK/blob/master/workspace/JNIToast/jni/com_example_jnitoast_MainActivity.c
  jclass Toast = NULL;
  jobject toast = NULL;
  jmethodID makeText = NULL;
  jmethodID show = NULL;

  Toast = (*env)->FindClass(env, "android/widget/Toast");
  if(NULL == Toast)
  {
    LOGW("showToast: FindClass failed");
    (*vm)->DetachCurrentThread(vm);
    return;
  }

  makeText = (*env)->GetStaticMethodID(env, Toast,"makeText", "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;");
  if( NULL == makeText )
  {
    LOGW("showToast: FindStaticMethod failed");
    (*vm)->DetachCurrentThread(vm);
    return;
  }

  toast = (*env)->CallStaticObjectMethod(env, Toast, makeText, context, txt, /*time*/0);
  if( NULL == toast )
  {
    LOGW("showToast: callstaticobjectmethod failed");
    (*vm)->DetachCurrentThread(vm);
    return;
  }

  show = (*env)->GetMethodID(env,Toast,"show","()V");
  if ( NULL == show )
  {
    LOGI("showToast: GetMethodID Failed");
    (*vm)->DetachCurrentThread(vm);
    return;
  }

  (*env)->CallVoidMethod(env,toast,show);

  (*env)->DeleteLocalRef(env, txt);

  (*vm)->DetachCurrentThread(vm);

}
@end
/**
 * Process the next input event.
 */
static int32_t engine_handle_input(struct android_app* app, AInputEvent* event) {
    Engine * engine = (Engine *)app->userData;
    return [engine handleInput: event];
}

/**
 * Process the next main command.
 */
static void engine_handle_cmd(struct android_app* app, int32_t cmd) {
    Engine * engine = (Engine *)app->userData;

    Engine * oldCurrentEngine = [currentEngine retain];
    currentEngine = [engine retain];
    [oldCurrentEngine release];

    switch (cmd) {
        case APP_CMD_SAVE_STATE:
            LOGI("Saving state");
            // The system has asked us to save our current state.  Do so.
            engine->app->savedState = malloc(sizeof(struct saved_state));
            *((struct saved_state*)engine->app->savedState) = engine->state;
            engine->app->savedStateSize = sizeof(struct saved_state);
            break;
        case APP_CMD_INIT_WINDOW:
            LOGI("Initing window");
            // The window is being shown, get it ready.
            if (engine->app->window != NULL) {
                [engine setupDisplay];
                [engine drawFrame];
            }
            break;
        case APP_CMD_TERM_WINDOW:
            LOGI("Terminating window");
            // The window is being hidden or closed, clean it up.
            [engine terminateDisplay];
            break;
        case APP_CMD_GAINED_FOCUS:
            LOGI("Gaining focus");
            // When our app gains focus, we start monitoring the accelerometer.
            if (engine->accelerometerSensor != NULL) {
                ASensorEventQueue_enableSensor(engine->sensorEventQueue,
                        engine->accelerometerSensor);
                // We'd like to get 60 events per second (in us).
                ASensorEventQueue_setEventRate(engine->sensorEventQueue,
                        engine->accelerometerSensor, (1000L/60)*1000);
            }
            engine->animating = 1;
            break;
        case APP_CMD_LOST_FOCUS:
            LOGI("Losing focus");
            // When our app loses focus, we stop monitoring the accelerometer.
            // This is to avoid consuming battery while not being used.
            if (engine->accelerometerSensor != NULL) {
                ASensorEventQueue_disableSensor(engine->sensorEventQueue,
                        engine->accelerometerSensor);
            }
            // Also stop animating.
            engine->animating = 0;
            [engine drawFrame];
            break;
    }

    [currentEngine release];
    currentEngine = nil;
}

/**
 * This is the main entry point of a native application that is using
 * android_native_app_glue.  It runs in its own thread, with its own
 * event loop for receiving input events and doing other things.
 */
void android_main(struct android_app* app) {
    // Make sure glue isn't stripped.
    app_dummy();

    // Very low tech way to initialize the GNUStep multithreaded system
    // TODOANDROID: isMainThread is false here we need to add a method to NSThread like GSSetThisThreadMainThread();
    //NSThread* init = [[NSThread alloc] initWithTarget:nil selector:nil object:nil]; // cannot call before GSInitializeProcess()
    //[init start];

    // maybe we want AndroidCore_setMainThreadJNIEnv(env);

    NSAutoreleasePool * arp = [NSAutoreleasePool new];

    NSString * cmdline = [NSString stringWithContentsOfFile: [NSString stringWithFormat: @"/proc/%d/cmdline", getpid()]];
    NSString * identifier = [[cmdline componentsSeparatedByString: @" "] objectAtIndex: 0];
    NSString * home = [NSString stringWithFormat: @"/data/data/%@", identifier];
    NSString * exe = [NSString stringWithFormat: @"%@/exe", home];
    FILE * f = fopen([exe UTF8String], "w"); if(f) fclose(f);

    NSString * path = [NSString stringWithFormat: @"PATH=%@", home];
    NSString * home2 = [NSString stringWithFormat: @"HOME=%@", home];

    const char* argv[1] = { [exe UTF8String] };
    const char* env[4] = { "USER=android", [home2 UTF8String], [path UTF8String], NULL };
    
    GSInitializeProcess(1, argv, env);
    //[[NSUserDefaults standardUserDefaults] readFromPath:userDefaultsPath()]; 
    LOGI("Preparing display");
    Engine * engine = [Engine new];
    [arp release];
    app->userData = engine;
    app->onAppCmd = engine_handle_cmd;
    app->onInputEvent = engine_handle_input;
    engine->app = app;

    // Prepare to monitor accelerometer
    LOGI("Initializing sensors");
    engine->sensorManager = ASensorManager_getInstance();
    engine->accelerometerSensor = ASensorManager_getDefaultSensor(engine->sensorManager,
            ASENSOR_TYPE_ACCELEROMETER);
    engine->sensorEventQueue = ASensorManager_createEventQueue(engine->sensorManager,
            app->looper, LOOPER_ID_USER, NULL, NULL);

    if (app->savedState != NULL) {
        // We are starting with a previous saved state; restore from it.
        engine->state = *(struct saved_state*)app->savedState;
    }

    // loop waiting for stuff to do.
    LOGI("Looping");

    while (1) {
        // Read all pending events.
        int ident;
        int events;
        struct android_poll_source* source;

        NSAutoreleasePool * arp = [NSAutoreleasePool new];
        // If not animating, we will block forever waiting for events.
        // If animating, we loop until all events are read, then continue
        // to draw the next frame of animation.
        while ((ident=ALooper_pollAll(engine->animating ? 0 : -1, NULL, &events,
                (void**)&source)) >= 0) {

            // Process this event.
            if (source != NULL) {
                source->process(app, source);
            }

            // If a sensor has data, process it now.
            if (ident == LOOPER_ID_USER) {
                if (engine->accelerometerSensor != NULL) {
                    ASensorEvent event;
                    while (ASensorEventQueue_getEvents(engine->sensorEventQueue,
                            &event, 1) > 0) {
                        //LOGI("accelerometer: x=%f y=%f z=%f",
                        //        event.acceleration.x, event.acceleration.y,
                        //        event.acceleration.z);
                    }
                }
            }

            // Check if we are exiting.
            if (app->destroyRequested != 0) {
                Engine * oldCurrentEngine = [currentEngine retain];
                currentEngine = [engine retain];
                [oldCurrentEngine release];

                [engine terminateDisplay];

                [currentEngine release];
                currentEngine = nil;
                return;
            }
        }

        if (engine->animating) {
            // Done with events; draw next animation frame.
            engine->state.angle += .01f;
            if (engine->state.angle > 1) {
                engine->state.angle = 0;
            }

            // Drawing is throttled to the screen update rate, so there
            // is no need to do timing here.
            Engine * oldCurrentEngine = [currentEngine retain];
            currentEngine = [engine retain];
            [oldCurrentEngine release];

            [engine drawFrame];
            [engine update];

            [currentEngine release];
            currentEngine = nil;
        }
        [arp release];
    }
}
