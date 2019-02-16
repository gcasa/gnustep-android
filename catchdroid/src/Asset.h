#import <Foundation/Foundation.h>

struct AAsset;

@interface Asset : NSObject
{
  struct AAsset * _asset;
  // TODO(ivucica): consider exposing as NSData instead
}
@property (assign) struct AAsset* asset;
@property (readonly, assign) void* buffer;
@property (readonly, assign) size_t length;
+ (Asset *) assetWithPath: (NSString*)path;
- (id) initWithPath: (NSString*)relativePath;
- (NSString *) string;
@end

