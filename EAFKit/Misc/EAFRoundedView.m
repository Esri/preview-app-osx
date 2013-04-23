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

@implementation EAFRoundedView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // make our view layer-backed
        [self setWantsLayer:YES];
        
        self.backgroundColor = [NSColor controlBackgroundColor];
        
        // create our mask layer that will help clip subviews, if needed
        self.maskLayer = [[CAShapeLayer alloc] init];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect rect = [self bounds];
    NSBezierPath *path = [NSBezierPath ags_bezierPathWithRoundedRect:rect
                                                        cornerRadius:self.cornerRadius
                                                         cornerFlags:self.cornerFlags];
    [path addClip];
    CGPathRef maskedPath = AGSCGPathCreateFromBezier(path);
    self.maskLayer.path = maskedPath;
    CGPathRelease(maskedPath);
    [self.backgroundColor set];
    NSRectFill(dirtyRect);
}

#pragma mark -
#pragma mark Overrides for Subviews

- (void)addSubview:(NSView *)aView {
    [super addSubview:aView];
    [aView setWantsLayer:YES];
    [aView.layer setMask:self.maskLayer];
}

- (void)addSubview:(NSView *)aView positioned:(NSWindowOrderingMode)place relativeTo:(NSView *)otherView {
    [super addSubview:aView positioned:place relativeTo:otherView];
    [aView setWantsLayer:YES];
    [aView.layer setMask:self.maskLayer];
}

#pragma mark -
#pragma mark Setters

- (void)setBackgroundColor:(NSColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    self.layer.backgroundColor = [_backgroundColor CGColor];
    [self setNeedsDisplay:YES];
}

- (void)setCornerFlags:(NSUInteger)cornerFlags {
    _cornerFlags = cornerFlags;
    [self setNeedsDisplay:YES];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = _cornerRadius;
    [self setNeedsDisplay:YES];
}

@end
