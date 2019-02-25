#import <Foundation/Foundation.h>
#import <GLES/gl.h>
@class Texture;

#define PAGE_WIDTH 8
#define PAGE_HEIGHT 8
@interface Page : NSObject
{
  Texture * _tileset;
  int _pageX, _pageY;

  int _tiles[PAGE_WIDTH*PAGE_HEIGHT];
  GLfloat _textureCoordinates[2 * 6 * PAGE_WIDTH * PAGE_HEIGHT];
  NSDictionary * _actions;
  NSMutableArray * _characters;
}
@property (nonatomic, retain) Texture * tileset;
- (id) initWithPageX: (int)pageX 
               pageY: (int)pageY;
- (BOOL) loadFromFile: (NSString*) path;
- (void) draw;
- (void) update: (float)dt;
- (id) characterAtMapX: (int)x
                  mapY: (int)y;
- (BOOL) isTileTypePassable: (int) tileType;
- (BOOL) isTilePassableAtX: (int)x
                         y: (int)y;
- (NSDictionary*) actionForX: (int)x
                           y: (int)y;
@end
