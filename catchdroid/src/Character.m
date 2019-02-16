#import "Character.h"
#import "Texture.h"
#import <GLES/gl.h>

#import <android/log.h>
#define LOGI(...) ((void)__android_log_print(ANDROID_LOG_INFO, "native-activity", __VA_ARGS__))
#define LOGW(...) ((void)__android_log_print(ANDROID_LOG_WARN, "native-activity", __VA_ARGS__))

static const GLfloat vertices[] = {
  -0.5, -0.5,
   0.5, -0.5,
   0.5, 0.5,

   0.5, 0.5,
  -0.5, 0.5,
  -0.5, -0.5,
};
@implementation Character
@synthesize texture=_texture;
@synthesize direction=_direction;
@synthesize progress=_progress;
@synthesize mapX=_mapX;
@synthesize mapY=_mapY;
- (id) initWithTexturePath: (NSString *)texturePath
{
  self = [super init];
  if (!self) return nil;

  self.texture = [Texture textureWithPath: texturePath];
  if (!_texture)
  {
    [self release];
    return nil;
  }

  return self;  
}

- (void) dealloc
{
  [_texture release];
  [super dealloc];
}

- (void) draw
{
  GLfloat textureCoordinates[] = {
    0, 1,
    1, 1,
    1, 0,

    1, 0,
    0, 0,
    0, 1
  };
  for(int i = 0 ; i < sizeof(textureCoordinates)/sizeof(textureCoordinates[0]); i++)
  {

    switch(i % 2)
    {
      case 0: // x coord: determined based on progress
      if(_progress < 0.5)
        textureCoordinates[i] += 1 + ((_mapX + _mapY) % 2);
      break;
      case 1: // y coord: determined based on direction
      textureCoordinates[i] += _direction;
      break;
    }

    // characters are in a 4x4 grid; reducing coordinates to just topleft corner
    textureCoordinates[i] /= 4; 
  }

  glEnable(GL_TEXTURE_2D);
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  
  glEnable(GL_BLEND);
  glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  glBindTexture(GL_TEXTURE_2D, [_texture textureId]);
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  glTexCoordPointer(2, GL_FLOAT, 0, textureCoordinates);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  glBindTexture(GL_TEXTURE_2D, 0);
    
  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisable(GL_TEXTURE_2D);

}
- (void) translateWithMultiplier: (int)multiplier
{
  GLfloat progress = _progress;
  if (progress > 1.0)
    progress = 1.0;

  if (progress != 1.0)
  {
    switch(_direction)
    {
      case 0: // face up
      glTranslatef(0, -(1.0 - progress) * multiplier, 0);
      break;
      case 1: // face right
      glTranslatef(-(1.0 - progress) * multiplier, 0, 0);
      break;
      case 2: // face down
      glTranslatef(0, (1.0 - progress) * multiplier, 0);
      break;
      case 3: // face left
      glTranslatef((1.0 - progress) * multiplier, 0, 0);
      break;
    }
  }
}

- (void) update: (float) dt
{
  if(_progress >= 1)
  {
    _progress = 1;
    return;
  }
  _progress += dt * 4; // cca 250ms for a step

  // for one frame, _progress can be > 1 so if player is trying
  // to make another step the animation is smooth.
  // (whatever is drawing the character can use this information
  // usefully to start the next step of the animation not from
  // non-zero.)

  // draw will take care not to actually draw as if _progress
  // was > 1.
}

@end

