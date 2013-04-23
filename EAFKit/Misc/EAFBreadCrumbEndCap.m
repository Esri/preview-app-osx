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

#import "EAFBreadCrumbEndCap.h"
#import "NSGradient+EAFAdditions.h"

@interface EAFBreadCrumbEndCap (){
}

@end

@implementation EAFBreadCrumbEndCap


-(id)initWithFrame:(NSRect)frameRect style:(EAFBreadCrumbEndCapStyle)style;
{
    self = [super initWithFrame:frameRect];
    if (self) {
        _style = style;
    }
    
    return self;
}

-(void)setStyle:(EAFBreadCrumbEndCapStyle)style{
    _style = style;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect{
    
    CGRect bounds = self.bounds;
    CGFloat h = bounds.size.height;
    CGFloat t = bounds.origin.y;
    CGFloat b = t + h;
    CGFloat l = bounds.origin.x;
    CGFloat w = bounds.size.width;
    CGFloat r = l + w;
    CGFloat m = 3;
    CGFloat cy = (b + t) / 2;
    
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
	[context setShouldAntialias:YES];

    if (_style != EAFBreadCrumbEndCapStyleEnd &&
        _style != EAFBreadCrumbEndCapStyleSelectedEnd){
        NSBezierPath *fillPath = [[NSBezierPath alloc]init];
        [fillPath moveToPoint:CGPointMake(l, t)];
        [fillPath lineToPoint:CGPointMake(l+m, t)];
        [fillPath lineToPoint:CGPointMake(r-m, cy)];
        [fillPath lineToPoint:CGPointMake(l+m, b)];
        [fillPath lineToPoint:CGPointMake(l, b)];
        [fillPath closePath];
        
        if (_style == EAFBreadCrumbEndCapStyleLeftSelected){
            [[NSGradient eaf_breadCrumbGradient] drawInRect:self.bounds angle:90];
            [[NSGradient eaf_breadCrumbSelectedGradient] drawInBezierPath:fillPath angle:90];
        }
        else if (_style == EAFBreadCrumbEndCapStyleNoneSelected){
        }
        else if (_style == EAFBreadCrumbEndCapStyleRightSelected){
            [[NSGradient eaf_breadCrumbSelectedGradient] drawInRect:self.bounds angle:90];
            [[NSGradient eaf_breadCrumbGradient] drawInBezierPath:fillPath angle:90];
        }
        
        NSBezierPath *strokePath1 = [[NSBezierPath alloc]init];
        [strokePath1 moveToPoint:CGPointMake(l+m, t)];
        [strokePath1 lineToPoint:CGPointMake(r-m, cy)];
        [strokePath1 lineToPoint:CGPointMake(l+m, b)];
        
        [[[NSColor blackColor]colorWithAlphaComponent:.65]set];
        [strokePath1 stroke];
        
        NSAffineTransform *t2 = [NSAffineTransform transform];
        [t2 translateXBy:2 yBy:0];
        NSBezierPath *strokePath2 = [strokePath1 copy];
        [strokePath2 transformUsingAffineTransform:t2];
        [[[NSColor whiteColor] colorWithAlphaComponent:.4]set];
        [strokePath2 stroke];
        
        NSAffineTransform *t3 = [NSAffineTransform transform];
        [t3 translateXBy:-2 yBy:0];
        NSBezierPath *strokePath3 = [strokePath1 copy];
        [strokePath3 transformUsingAffineTransform:t3];
        [[[NSColor whiteColor] colorWithAlphaComponent:.25]set];
        [strokePath3 stroke];
    }
    else{
        if (_style == EAFBreadCrumbEndCapStyleEnd){
            [[NSGradient eaf_breadCrumbGradient]drawInRect:self.bounds angle:90.0f];
        }
        else if (_style == EAFBreadCrumbEndCapStyleSelectedEnd){
            [[NSGradient eaf_breadCrumbSelectedGradient]drawInRect:self.bounds angle:90.0f];
        }
        
        NSBezierPath *strokePath1 = [[NSBezierPath alloc]init];
        [strokePath1 moveToPoint:CGPointMake(r, t)];
        [strokePath1 lineToPoint:CGPointMake(r, b)];
        
        [[[NSColor blackColor]colorWithAlphaComponent:.65]set];
        [strokePath1 stroke];
        
        NSAffineTransform *t2 = [NSAffineTransform transform];
        [t2 translateXBy:-2 yBy:0];
        NSBezierPath *strokePath2 = [strokePath1 copy];
        [strokePath2 transformUsingAffineTransform:t2];
        [[[NSColor whiteColor] colorWithAlphaComponent:.4]set];
        [strokePath2 stroke];
    }
    
    [context restoreGraphicsState];
}

@end
