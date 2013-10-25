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


#import "EAFRoundedView.h"
#import "EAFGradientView.h"

@implementation EAFGradientView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        _angle = 90.0;
        _startGradient = [[NSGradient alloc] initWithColors:@[[NSColor lightGrayColor], [NSColor whiteColor]]];
    }
    
    return self;
}

- (id)initWithStartGradient:(NSGradient*)startGradient {
    return [self initWithStartGradient:startGradient endGradient:nil];
}

- (id)initWithStartGradient:(NSGradient*)startGradient endGradient:(NSGradient*)endGradient {
    if (self = [super initWithFrame:NSZeroRect]) {
        self.startGradient = startGradient;
        self.endGradient = endGradient;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    NSRect top = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y + height/2, width, height/2);
    NSRect bottom = NSMakeRect(self.bounds.origin.x, self.bounds.origin.y, width, height/2);
    
    if (self.startGradient && self.endGradient) {
        [self.startGradient drawFromPoint:bottom.origin toPoint:top.origin options:NSGradientDrawsAfterEndingLocation];
        [self.endGradient drawInRect:top angle:_angle];
    }
    else {
        [self.startGradient drawInRect:self.bounds angle:_angle];
    }
}

- (void)setStartGradient:(NSGradient *)startGradient {
    _startGradient = startGradient;
    [self setNeedsDisplay:YES];
}

- (void)setEndGradient:(NSGradient *)endGradient {
    _endGradient = endGradient;
    [self setNeedsDisplay:YES];
}

- (void)setAngle:(CGFloat)angle {
    _angle = angle;
    [self setNeedsDisplay:YES];
}

@end
