#import "Font.h"
#import "Texture.h"

@implementation Font
@synthesize texture=_texture;
@synthesize charWidth=_charWidth;
@synthesize charHeight=_charHeight;
@synthesize charsPerRow=_charsPerRow;
- (id) initWithPath: (NSString *)path
          charWidth: (int)charWidth
         charHeight: (int)charHeight
        charsPerRow: (int)charsPerRow
{
  self = [super init];
  if (!self)
    return nil;

  _texture = [[Texture textureWithPath: path] retain];
  _charWidth = charWidth;
  _charHeight = charHeight;
  _charsPerRow = charsPerRow;

  return self;
}
- (void) dealloc
{
  [_texture release];
  [super dealloc];
}
- (void) drawText: (NSString *)text
{
  // TODO(ivucica): instead of drawing character by character,
  // we should pre-bake a mesh.
  
  glPushMatrix();    

  glEnable(GL_TEXTURE_2D);
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);

  glBindTexture(GL_TEXTURE_2D, [_texture textureId]);

  for(int i = 0; i < [text length]; i++)
  {
    unichar c = [text characterAtIndex: i];
    glTranslatef(1, 0, 0);
    [self drawCharacter: c];
  }

  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_TEXTURE_COORD_ARRAY);

  glDisable(GL_TEXTURE_2D);
  glPopMatrix();
}
- (void) drawCharacter: (unichar)c
{
  c -= 32; // first character in a font is 32
  int col = c % _charsPerRow;
  int row = c / _charsPerRow;
  int x = col * _charWidth;
  int y = row * _charHeight;
  GLfloat x1 = ((GLfloat)x) / _texture.textureWidth;
  GLfloat y1 = ((GLfloat)y) / _texture.textureHeight;
  GLfloat x2 = ((GLfloat)x+_charWidth) / _texture.textureWidth;
  GLfloat y2 = ((GLfloat)y+_charHeight) / _texture.textureHeight;
  
  GLfloat vertices[] = {
    -0.5, -0.5,
     0.5, -0.5,
     0.5, 0.5,

     0.5, 0.5,
    -0.5, 0.5,
    -0.5, -0.5,
  };
  GLfloat textures[] = {
    x1, y2,
    x2, y2,
    x2, y1,

    x2, y1,
    x1, y1,
    x1, y2
  };
  glVertexPointer(2, GL_FLOAT, 0, vertices);
  glTexCoordPointer(2, GL_FLOAT, 0, textures);
  glDrawArrays(GL_TRIANGLES, 0, 6);
}
@end

@implementation NSString (CatchdroidFont)
- (void) drawWithCDFont: (Font *)font
{
  [font drawText: self];
}
@end
