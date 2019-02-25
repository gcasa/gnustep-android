#import "Page.h"
#import "Texture.h"
#import "Asset.h"
#import "Character.h"
#import "Engine.h"

#include <android/log.h>
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

#define TILESET_WIDTH 8
#define TILESET_HEIGHT 8

static GLfloat gridVertices[(2) * // x,y
                            (6) * // 6 vertices per quad
                            PAGE_WIDTH * PAGE_HEIGHT
                           ];

static BOOL tileTypePassable[] = {
  YES, YES, YES, NO,  NO,  NO,  NO,  NO,
  NO,  NO,  NO,  NO,  NO,  NO,  NO,  NO,
  NO,  NO,  YES,  NO,  NO,  NO,  NO,  NO
};

@implementation Page
@synthesize tileset=_tileset;
+ (void) load
{
  [super load];

  for(int j = 0; j < PAGE_HEIGHT; j++)
  {
    for(int i = 0; i < PAGE_WIDTH; i++)
    {
      static const GLfloat vertices[] = {
        -0.5, -0.5,
         0.5, -0.5,
         0.5, 0.5,

         0.5, 0.5,
        -0.5, 0.5,
        -0.5, -0.5,
      };

      for(int k = 0; k < 6; k++)
      {
        gridVertices[2 * 6 * PAGE_WIDTH * j +
                     2 * 6 * i +
                     2 * k + 0] = (i + vertices[2 * k + 0]);
        gridVertices[2 * 6 * PAGE_WIDTH * j +
                     2 * 6 * i +
                     2 * k + 1] = (j + vertices[2 * k + 1]);
      }
    }
  }

}
- (id) initWithPageX: (int)pageX 
               pageY: (int)pageY
{
  self = [super init];
  if (!self) return nil;

  BOOL success = [self loadFromFile: [NSString stringWithFormat: @"pages/%d-%d", pageX, pageY]];
  if (!success)
  {
    NSString * repeatingTile = @"63 ";
    NSString * map = [@"" stringByPaddingToLength:PAGE_WIDTH*PAGE_HEIGHT * [repeatingTile length] withString: repeatingTile startingAtIndex: 0];
    success = [self loadFromString: map];
    if (!success)
    {
      [self release];
      return nil;
    }
  }
  
  success = [self loadActionsFromFile: [NSString stringWithFormat: @"pages/%d-%d.actions", pageX, pageY]];
  if (!success)
  {
    // ignore
  }

  _characters = [NSMutableArray new];
  success = [self loadCharactersFromFile: [NSString stringWithFormat: @"pages/%d-%d.characters", pageX, pageY]];
  if (!success)
  {
    // ignore
  } 

  return self;
}
- (void) dealloc
{
  [_characters release];
  [_actions release];
  [_tileset release];
  [super dealloc];
}

- (BOOL) loadFromFile: (NSString*) path
{
  Asset * asset = [Asset assetWithPath: path];
  if (!asset)
  {
    LOGW("Could not load asset %s", [path UTF8String]);
    return NO;
  }

  NSString * s = [[asset string] stringByReplacingOccurrencesOfString: @"\n" withString: @" "];
  return [self loadFromString: s];
}
- (BOOL) loadFromString: (NSString*) s
{
  NSArray * tiles = [s componentsSeparatedByString: @" "];
  int i = 0;
  for(NSString * tile in tiles)
  {
    if(sscanf([tile UTF8String], "%d", &_tiles[i]) != 1)
      break;

    int x = i % PAGE_WIDTH;
    int y = PAGE_HEIGHT-1 - i / PAGE_WIDTH;

    static const GLfloat textures[] = {
      0, 1,
      1, 1,
      1, 0,

      1, 0,
      0, 0,
      0, 1
    };
    for(int k = 0; k < 6; k++)
    {
      int a = (2 * 6 * PAGE_WIDTH * y) +
              (2 * 6 * x) + 
              (2 * k + 0);
      int b = (2 * 6 * PAGE_WIDTH * y) +
              (2 * 6 * x) + 
              (2 * k + 1);
      _textureCoordinates[a] = (_tiles[i] % (TILESET_WIDTH) + textures[2*k + 0]) / ((GLfloat)TILESET_WIDTH);
      _textureCoordinates[b] = (_tiles[i] / (TILESET_WIDTH) + textures[2*k + 1]) / ((GLfloat)TILESET_HEIGHT); 
    }

    i++;
    if(i >= 16*16) break;
  }
  [self setTileset: [Texture textureWithPath: @"tiles1.png"]]; 
  return YES;
}
- (BOOL) loadActionsFromFile: (NSString *)path
{
  Asset * asset = [Asset assetWithPath: path];
  if (!asset)
  {
    return NO;
  }

  return [self loadActionsFromString: [asset string]];
}
- (BOOL) loadActionsFromString: (NSString *)source
{
  NSData* plistData = [source dataUsingEncoding:NSUTF8StringEncoding];
  NSString *error = nil;
  NSPropertyListFormat format = 0;
  NSDictionary* plist = [NSPropertyListSerialization propertyListFromData: plistData
                                                         mutabilityOption: NSPropertyListImmutable
                                                                   format: &format
                                                         errorDescription: &error];
  NSLog(@"Loading actions from %@: %@", source, plist);
  if (error)
  {
    NSLog(@"Error loading actions: %@", error);
    return NO;
  }
  _actions = [plist retain];
  return YES;
}

- (BOOL) loadCharactersFromFile: (NSString *)path
{
  Asset * asset = [Asset assetWithPath: path];
  if (!asset)
  {
    return NO;
  }

  return [self loadCharactersFromString: [asset string]];
}
- (BOOL) loadCharactersFromString: (NSString *)source
{
  NSData* plistData = [source dataUsingEncoding:NSUTF8StringEncoding];
  NSString *error = nil;
  NSPropertyListFormat format = 0;
  NSArray* plist = [NSPropertyListSerialization propertyListFromData: plistData
                                                    mutabilityOption: NSPropertyListImmutable
                                                              format: &format
                                                    errorDescription: &error];
  NSLog(@"Loading characters from %@: %@", source, plist);
  if (error)
  {
    NSLog(@"Error loading actions: %@", error);
    return NO;
  }

  for(NSDictionary * dict in plist)
  {
    Class cls = NSClassFromString([dict objectForKey: @"class"]);
    NSLog(@" (%@)", cls);
    id chr = [[cls alloc] initWithTexturePath: [dict objectForKey: @"texturePath"]];
    for(NSString * key in [dict allKeys])
    {
      if([key isEqual: @"class"]) continue;
      if([key isEqual: @"texturePath"]) continue;
      id val = [dict objectForKey: key];
      [chr setValue: val forKey: key];
      [_characters addObject: chr];
    }
  }
  return YES;
}

- (void) draw
{
  glEnable(GL_TEXTURE_2D);
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  
  glBindTexture(GL_TEXTURE_2D, [_tileset textureId]);
  glVertexPointer(2, GL_FLOAT, 0, gridVertices);
  glTexCoordPointer(2, GL_FLOAT, 0, _textureCoordinates);
  glDrawArrays(GL_TRIANGLES, 0, 6 * (PAGE_WIDTH * PAGE_HEIGHT));
  glBindTexture(GL_TEXTURE_2D, 0);
    
  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisable(GL_TEXTURE_2D);

  for(id chr in _characters)
  {
    glPushMatrix();
    glTranslatef([chr mapX] % PAGE_WIDTH,
                 PAGE_HEIGHT - [chr mapY] % PAGE_HEIGHT - 1,
                 0);
    [chr draw];
    glPopMatrix();
  }
}
- (void) update: (float)dt
{
  for(id chr in _characters)
  {
    [chr update: dt];
  }
}

- (BOOL) isTileTypePassable: (int) tileType
{
  if(!(tileType < sizeof(tileTypePassable) / sizeof(tileTypePassable[0])))
    return NO;

  return tileTypePassable[tileType];
}
- (BOOL) isTilePassableAtX: (int)x y: (int)y
{
  if([self characterAtMapX: x mapY: y])
    return NO;
  return [self isTileTypePassable: _tiles[y * PAGE_WIDTH + x]];
}
- (id) characterAtMapX: (int)x mapY: (int)y
{
  for(id chr in _characters)
  {
    if([chr mapX] % PAGE_WIDTH == x % PAGE_WIDTH && 
       [chr mapY] % PAGE_HEIGHT == y % PAGE_HEIGHT)
      return chr;
  }
  return nil;
}
- (NSDictionary*) actionForX: (int)x y: (int)y
{
  NSString * actionKey = [NSString stringWithFormat: @"%d-%d", x, y];
  NSDictionary * action = [_actions objectForKey: actionKey];
  return action;
}
@end
