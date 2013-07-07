/*
 Copyright 2013 Esri
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "EAFImageView.h"
#import "EAFDefines.h"

@implementation EAFImageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    
    return self;
}

-(void)setAngle:(CGFloat)angle{
    _angle = angle;
    [self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)dirtyRect{

    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    
    [context saveGraphicsState];
    
    NSAffineTransform* transform = [NSAffineTransform transform] ;
    
    // In order to avoid clipping the image, translate
    // the coordinate system to its center
    [transform translateXBy:self.bounds.size.width/2
                        yBy:self.bounds.size.height/2] ;
    // then rotate
    [transform rotateByDegrees:_angle];
    
    // Then translate the origin system back to
    // the bottom left
    [transform translateXBy:-self.bounds.size.width * .5
                        yBy:-self.bounds.size.height * .5] ;
    
    [transform concat];
    [_image drawAtPoint:NSMakePoint(0,0)
             fromRect:NSZeroRect
            operation:NSCompositeCopy
             fraction:1.0];
    
    [context restoreGraphicsState];
}

-(void)mouseDown:(NSEvent *)theEvent{
    [super mouseDown:theEvent];
}

-(void)mouseUp:(NSEvent *)theEvent{
    [super mouseUp:theEvent];
    EAFSuppressClangPerformSelectorLeakWarning([self.target performSelector:self.action withObject:self]);
}

@end






















