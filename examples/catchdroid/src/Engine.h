#import <EGL/egl.h>
#import <GLES/gl.h>

#import <android/sensor.h>

#import "android_native_app_glue.h"

#import <Foundation/NSObject.h>

@class Texture;
@class Scene;
@class Font;
@class TextContainer;

/**
 * Our saved state data.
 */
struct saved_state {
    float angle;
    int32_t x;
    int32_t y;
};

/**
 * Shared state for our app.
 */
@interface Engine : NSObject
{
    @public
    struct android_app* app;

    ASensorManager* sensorManager;
    const ASensor* accelerometerSensor;
    ASensorEventQueue* sensorEventQueue;

    int animating;
    EGLDisplay display;
    EGLSurface surface;
    EGLContext context;
    int32_t width;
    int32_t height;
    struct saved_state state;

    @private
    Texture * _controls;
    double _previousFrameTime;
    Scene * _scene;
}
+(Engine *)currentEngine;
-(int)setupDisplay;
-(void)terminateDisplay;
-(void)drawFrame;
-(void)update;
@end

