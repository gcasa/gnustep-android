#import <Foundation/Foundation.h>
@class Texture;
@class Font;

@interface TextContainer : NSObject
{
  Texture * _texture;
  Font * _font;
  NSMutableArray * _queue;
  float _progress;
  BOOL _buttonA;
}
@property (assign) BOOL buttonA;
@property (readonly, nonatomic, assign, getter=isVisible) BOOL visible;
- (id) initWithFont: (Font *)font;
- (void) enqueueText: (NSString *)text;
- (void) update: (float)dt;
@end
