#import <Foundation/Foundation.h>
#import <GLES/gl.h>

@class Asset;

@interface Texture : NSObject
{
  GLuint _id;
  Asset * _asset;
  NSString * _path;
  int _textureWidth, _textureHeight;
}
@property (nonatomic, retain) Asset * asset;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, assign) GLuint textureId;
@property (nonatomic, assign) int textureWidth;
@property (nonatomic, assign) int textureHeight;
+ (Texture *) textureWithPath: (NSString *)path;
- (id) initWithPath: (NSString *)path;
@end
