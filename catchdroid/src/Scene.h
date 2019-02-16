#import <Foundation/Foundation.h>

@class Character;
@class Page;
@class TextContainer;
@class Font;

@interface Scene : NSObject
{
  NSMutableDictionary * _pages;
  int _playerX, _playerY;
  Character * _player;
  TextContainer * _textContainer;
  Font * _font;

  SEL _direction;
  BOOL _buttonA;

  float _fadeProgress;
}
@property (retain) NSMutableDictionary * pages;
@property (assign, nonatomic) int playerX;
@property (assign, nonatomic) int playerY;
@property (retain) Character * player;

@property (assign) SEL direction;
@property (nonatomic, assign) BOOL buttonA;

@property (retain) TextContainer * textContainer;

- (void) draw;
- (void) update: (float)dt;
- (void) movePlayerUp;
- (void) movePlayerDown;
- (void) movePlayerLeft;
- (void) movePlayerRight;

- (Page *) playerPage;
- (Page *) pageForMapX: (int)mapX
                  mapY: (int)mapY;
- (Page *) pageForPageX: (int)pageX
                  pageY: (int)pageY;
- (id) characterAtMapX: (int)x
                  mapY: (int)y;
- (void) buttonARises;
@end

