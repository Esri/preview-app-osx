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

#import "EAFRoundedImageView.h"

@implementation EAFRoundedImageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
//        [self setImageScaling:NSImageScaleProportionallyUpOrDown];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect rect2draw = dirtyRect;
    
    // Drawing code here.
    //[super drawRect:dirtyRect];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect2draw, 1, 1) xRadius:self.xRadius yRadius:self.yRadius];
    
    //[path setLineWidth:4.0];
    [path addClip];

    [self.image drawAtPoint: NSZeroPoint
                   fromRect:rect2draw
                  operation:NSCompositeSourceOver
                   fraction: 1.0];
    
    [super drawRect:rect2draw];
    
    //NSColor *strokeColor = [NSColor blackColor];
    
    //[strokeColor set];
    //[NSBezierPath setDefaultLineWidth:4.0];
    //[[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rect2draw, 2, 2) xRadius:self.xRadius yRadius:self.yRadius] stroke];
}

@end
