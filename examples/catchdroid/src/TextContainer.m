#import "TextContainer.h"
#import "Font.h"
#import "Texture.h"

#define CD_MIN(x,y) ((x) < (y) ? (x) : (y))

@implementation TextContainer
@synthesize buttonA=_buttonA;

- (id) initWithFont: (Font *)font
{
  self = [super init];
  if (!self)
    return nil;

  _queue = [NSMutableArray new];
  _texture = [[Texture textureWithPath: @"textcontainer.png"] retain];
  _font = [font retain];

  return self;
}
- (void) dealloc
{
  [_font release];
  [_texture release];
  [_queue release];
  [super dealloc];
}
- (void) enqueueText: (NSString *)text
{
  [_queue addObjectsFromArray: [text componentsSeparatedByString: @"\n"]];
}
- (BOOL) isVisible
{
  return [_queue count];
}
- (void) update: (float)dt
{
  if (![_queue count])
    return;
  if(_buttonA)
    dt *= 2;
  _progress += dt;
}
- (void) draw
{
  if (![_queue count])
    return;

  glPushMatrix();    
  glEnable(GL_TEXTURE_2D);
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);

  glBindTexture(GL_TEXTURE_2D, [_texture textureId]);
  glScalef(15, 7, 1);
  glTranslatef(0.4875 + 0.0375, 0.1, 0);
  GLfloat vertices[] = {
    -0.5, -0.5,
     0.5, -0.5,
     0.5, 0.5,

     0.5, 0.5,
    -0.5, 0.5,
    -0.5, -0.5,
  };
  GLfloat textures[] = {
    0, 1,
    1, 1,
    1, 0,

    1, 0,
    0, 0,
    0, 1
  };
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  glTexCoordPointer(2, GL_FLOAT, 0, textures);
  glDrawArrays(GL_TRIANGLES, 0, 6);

  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);

  glDisable(GL_TEXTURE_2D);

  glPopMatrix();

  glPushMatrix();
  glScalef(0.7, 0.7, 1);
  glTranslatef(0.5, 0.5, 0);
  NSString * line1 = [_queue objectAtIndex: 0];
  line1 = [line1 substringToIndex: CD_MIN([line1 length], [line1 length] * _progress * 2)];
  [line1 drawWithCDFont: _font];

  if(_progress > 0.5 && [_queue count] >= 2)
  {
    glTranslatef(0, -1, 0);
    NSString * line2 = [_queue objectAtIndex: 1];
    line2 = [line2 substringToIndex: CD_MIN([line2 length], [line2 length] * (_progress-0.5) * 2)];
    [line2 drawWithCDFont: _font];
  }
  glPopMatrix();

  glPushMatrix();
  glTranslatef(0.5, 0.5, 0);
  if(_progress > 1)
  {
    struct timeval currentTimeVal;
    gettimeofday(&currentTimeVal, NULL);
  
    double currentTime = 0;
    currentTime = currentTimeVal.tv_sec + ((double)currentTimeVal.tv_usec) / 1000000;
    if(fmod(currentTime * 4, 2) < 1)
    {
      glTranslatef(12, -3, 0);
      [@"*" drawWithCDFont: _font];
    }
  }
  glPopMatrix();
}
- (void) setButtonA: (BOOL)buttonA
{
  if(buttonA && !_buttonA)
  {
    [self buttonARises];
  }
  _buttonA = buttonA;
}
- (void) buttonARises
{
  if(![_queue count])
    return;

  if(_progress >= 1)
  {
    if([_queue count]) [_queue removeObjectAtIndex:0];
    if([_queue count]) [_queue removeObjectAtIndex:0];
    _progress = 0;
  }
}
@end
