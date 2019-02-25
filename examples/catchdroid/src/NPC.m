#import "NPC.h"
#import "Scene.h"
#import "TextContainer.h"

@implementation NPC
@synthesize lines=_lines;
- (void) buttonARisesInScene: (Scene *)scene
             playerDirection: (int)direction
{
  if(scene.textContainer.visible)
    return;

  NSString * text = [_lines objectAtIndex: _nextLine];
  [scene.textContainer enqueueText: text];

  [self setDirection: (direction+2) % 4];

  _nextLine++;
  _nextLine %= [_lines count];
}
@end
