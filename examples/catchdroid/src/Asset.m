#import <jni.h>
#import <android/asset_manager_jni.h>
#import "Asset.h"

#include <android/log.h>
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

static AAssetManager* assetManager = NULL;
JNIEXPORT void JNICALL Java_net_vucica_catchdroid_IVNativeActivity_initAssetManager(JNIEnv * env, jclass jclazz, jobject java_asset_manager)
{
  assetManager = AAssetManager_fromJava(env, java_asset_manager);
}

@implementation Asset
@synthesize asset=_asset;

+ (Asset *) assetWithPath: (NSString*)path
{
  Asset * ret = [[[self alloc] initWithPath: path] autorelease];
  LOGI("Returning asset %p", ret);
  return ret;
}

- (id) initWithPath: (NSString*)relativePath
{
  self = [super init];
  if (!self)
    return nil;

  if(!relativePath)
  {
    [self release];
    return nil;
  }
  
  if (!assetManager)
  {
    [self release];
    return nil;
  }

  LOGI("Opening asset using manager %p at path %s", assetManager, [relativePath UTF8String]);
  AAsset* asset = 
      AAssetManager_open(assetManager, [relativePath UTF8String], AASSET_MODE_STREAMING);
  LOGI("Done");
  LOGI("Asset  is %p", asset);
  if(!asset)
  {
    [self release];
    return nil;
  }

  LOGI("Remembering asset");
  [self setAsset: asset];
  LOGI("Done");

  return self;
}
- (size_t) length
{
  return AAsset_getLength(_asset);
}
- (void *) buffer
{
  return AAsset_getBuffer(_asset);
}
- (void) dealloc
{
  if(_asset)
    AAsset_close(_asset);
  [super dealloc];
}

- (NSString *) string
{
  return [[[NSString alloc] initWithBytes: [self buffer]
                                   length: [self length]
                                 encoding: NSUTF8StringEncoding] autorelease];
}
@end

