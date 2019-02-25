#import <Foundation/Foundation.h>
#import "Character.h"

@class Scene;

@interface NPC : Character
{
  NSArray * _lines;
  int _nextLine;
}
@property (nonatomic, retain) NSArray * lines;
- (void) buttonARisesInScene: (Scene *)scene
             playerDirection: (int)direction;
@end

