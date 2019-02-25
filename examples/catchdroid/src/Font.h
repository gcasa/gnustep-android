#import <Foundation/Foundation.h>
@class Texture;

@interface Font : NSObject
{
  Texture * _texture;
  int _charWidth;
  int _charHeight;
  int _charsPerRow;
}
@property (retain) Texture * texture;
@property (assign) int charWidth;
@property (assign) int charHeight;
@property (assign) int charsPerRow;
- (id) initWithPath: (NSString *)path
          charWidth: (int)charWidth
         charHeight: (int)charHeight
        charsPerRow: (int)charsPerRow;
- (void) drawText: (NSString *)text;
@end

@interface NSString (CatchdroidFont)
- (void) drawWithCDFont: (Font *)font;
@end
