#import "Scene.h"
#import "Page.h"
#import "Character.h"
#import "Font.h"
#import "TextContainer.h"
#import "NPC.h"

#include <android/log.h>
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

@implementation Scene
@synthesize pages=_pages;
@synthesize player=_player;
@synthesize playerX=_playerX;
@synthesize playerY=_playerY;
@synthesize direction=_direction;
@synthesize buttonA=_buttonA;
@synthesize textContainer=_textContainer;

- (id) init
{
  self = [super init];
  if(!self) return nil;

  _pages = [NSMutableDictionary new];
  _player = [[Character alloc] initWithTexturePath: @"player.png"];

  self.playerX = 16*8 + 3;
  self.playerY = 16*8 + 4;

  _font = [[Font alloc] initWithPath: @"font-hand-24x32.png"
                           charWidth: 24
                          charHeight: 32
                         charsPerRow: 16];
  _textContainer = [[TextContainer alloc] initWithFont: _font];
  [_textContainer enqueueText: @"     Welcome to\n"
                                " *** CATCHDROID ***"];

  return self;
}

- (void) dealloc
{
  [_font release];
  [_textContainer release];
  [_player release];
  [_pages release];
  [super dealloc];
}

- (void) movePlayerUp
{
  if(_player.progress < 1) return;
  [_player setDirection: 0];
  if(![[self pageForMapX: self.playerX mapY: self.playerY - 1] isTilePassableAtX: (self.playerX) % PAGE_WIDTH y: (self.playerY - 1) % PAGE_HEIGHT])
    return;
  self.playerY--;
}
- (void) movePlayerRight
{
  if(_player.progress < 1) return;
  [_player setDirection: 1];
  if(![[self pageForMapX: self.playerX + 1 mapY: self.playerY] isTilePassableAtX: (self.playerX + 1) % PAGE_WIDTH y: (self.playerY) % PAGE_HEIGHT])
    return;
  self.playerX++;
}
- (void) movePlayerDown
{
  if(_player.progress < 1) return;
  [_player setDirection: 2];
  if(![[self pageForMapX: self.playerX mapY: self.playerY + 1] isTilePassableAtX: (self.playerX) % PAGE_WIDTH y: (self.playerY + 1) % PAGE_HEIGHT])
    return;
  self.playerY++;
}
- (void) movePlayerLeft
{
  if(_player.progress < 1) return;
  [_player setDirection: 3];
  if(![[self pageForMapX: self.playerX - 1 mapY: self.playerY] isTilePassableAtX: (self.playerX - 1) % PAGE_WIDTH y: (self.playerY) % PAGE_HEIGHT])
    return;
  self.playerX--;
}

- (void) setPlayerX: (int)playerX
{
  _playerX = playerX;
  _player.progress-=1.;
  if(_player.progress < 0) _player.progress = 0;
  _player.mapX = _playerX;
}
- (void) setPlayerY: (int)playerY
{
  _playerY = playerY;
  _player.progress-=1.;
  if(_player.progress < 0) _player.progress = 0;
  _player.mapY = _playerY;
}

#define PAGE_WIDTH 8
#define PAGE_HEIGHT 8
- (void) draw
{
  int playerPageX = _playerX / PAGE_WIDTH;
  int playerPageY = _playerY / PAGE_HEIGHT;

  glPushMatrix();
  glScalef(0.8, 0.8, 1);
  glTranslatef(0, 2, 0);

  glPushMatrix();

  [_player translateWithMultiplier: -1];
  glTranslatef(-(_playerX % PAGE_WIDTH),
               (_playerY % PAGE_HEIGHT),
               0);
  for(int i = -1; i <= 1; i++)
  {
    for(int j = -2; j <= 2; j++)
    {
      int currentPageX = playerPageX + i;
      int currentPageY = playerPageY + j;
      Page * page = [self pageForPageX: currentPageX
                                 pageY: currentPageY];
      if(!page)
        continue;

      glPushMatrix();
      glTranslatef(i * PAGE_WIDTH, (-j-1) * PAGE_HEIGHT + 1, 0);
      [page draw];
      glPopMatrix();
    }
  }
  glPopMatrix();
  // for player character, not doing translation
  // others would have: [ch translateWithMultiplier: 1];
  // (to apply 'progress' animation)
  [_player draw];
  
  glPopMatrix();

  glPushMatrix();
  glScalef(0.3, 0.3, 1.);
  glTranslatef(-8, -1, 0);
  [_textContainer draw];
  glPopMatrix();

  if (_fadeProgress < 1)
  {
    glPushMatrix();
    glDisable(GL_TEXTURE_2D);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    GLfloat colors[] = {
      0, 0, 0, 1.-fabs(_fadeProgress),
      0, 0, 0, 1.-fabs(_fadeProgress),
      0, 0, 0, 1.-fabs(_fadeProgress),
      0, 0, 0, 1.-fabs(_fadeProgress),
      0, 0, 0, 1.-fabs(_fadeProgress),
      0, 0, 0, 1.-fabs(_fadeProgress),
    };
    GLfloat vertices[] = {
      -0.5, -0.5,
       0.5, -0.5,
       0.5, 0.5,

       0.5, 0.5,
      -0.5, 0.5,
      -0.5, -0.5,
    };
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glScalef(16,16,1);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    glPopMatrix();
  }

}

- (void) update: (float)dt
{
  GLfloat oldProgress = [_player progress];
  [_player update: dt];
  if (oldProgress < 1 && [_player progress] > 1)
  {
    // just finished walking.
    NSDictionary * action = [[self playerPage] actionForX: _playerX % PAGE_WIDTH y: _playerY % PAGE_HEIGHT]; 
    if(action)
    {
      if([[action objectForKey: @"type"] isEqual: @"teleport"])
      {
        _fadeProgress = 0;
        self.playerX = [[action objectForKey: @"destinationX"] intValue];
        self.playerY = [[action objectForKey: @"destinationY"] intValue];
      }
    }
  }

  for(Page * pg in [_pages allValues])
  {
    [pg update: dt];
  }
  [_textContainer update: dt];

  _fadeProgress += dt;

  if(_direction)
    [self performSelector: _direction];
}
- (Page *) playerPage
{
  return [self pageForMapX: _playerX
                      mapY: _playerY];
}
- (Page *) pageForMapX: (int)mapX
                  mapY: (int)mapY
{
  int pageX = mapX / PAGE_WIDTH;
  int pageY = mapY / PAGE_HEIGHT;
  return [self pageForPageX: pageX
                      pageY: pageY];
}
- (Page *) pageForPageX: (int)pageX
                  pageY: (int)pageY
{
  NSString * currentPage = [NSString stringWithFormat: @"%d-%d", pageX, pageY];
  Page * page = [_pages objectForKey: currentPage];
  if (!page)
  {
    page = [[[Page alloc] initWithPageX: pageX
                                  pageY: pageY] autorelease];
    if(!page)
      return nil;
    [_pages setObject: page forKey: currentPage];
    if(![_pages objectForKey: currentPage])
      LOGI("Caching the page failed?!");
   }
   return page;
}

- (id) characterAtMapX: (int)x mapY: (int)y
{
   Page * page = [self pageForMapX: x mapY: y];
   NSLog(@"Page %@; x y %d %d", page, x, y);
   return [page characterAtMapX: x mapY: y];
}
- (void) buttonARises
{
  id chr = nil;
  switch([_player direction])
  {
    case 0:
      chr = [self characterAtMapX: _playerX mapY: _playerY-1];
      break;
    case 1:
      chr = [self characterAtMapX: _playerX+1 mapY: _playerY];
      break;
    case 2:
      chr = [self characterAtMapX: _playerX mapY: _playerY+1];
      break;
    case 3:
      chr = [self characterAtMapX: _playerX-1 mapY: _playerY];
      break;
  }

  [chr buttonARisesInScene: self
           playerDirection: _player.direction];
}
- (void) setButtonA: (BOOL)buttonA
{
  if(buttonA && !_buttonA)
  {
    [self buttonARises];
  }
  _buttonA = buttonA;

  [_textContainer setButtonA: buttonA];
}
@end

