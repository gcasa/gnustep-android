#import <Foundation/Foundation.h>
@class Texture;
@interface Character : NSObject
{
  Texture * _texture;
  int _direction;
  float _progress;
  int _mapX, _mapY; // used for animating only
}
@property (retain) Texture * texture;
@property (assign) int direction;
@property (assign) float progress;
@property (assign) int mapX;
@property (assign) int mapY;

- (id) initWithTexturePath: (NSString *)texturePath;
- (void) update: (float) dt;
- (void) draw;
- (void) translateWithMultiplier: (int)multiplier;
@end
