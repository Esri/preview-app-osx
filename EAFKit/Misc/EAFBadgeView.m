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
#import "EAFBadgeView.h"
#import "NSView+EAFAdditions.h"
#import "NSColor+EAFAdditions.h"

@interface EAFBadgeView (){
    NSTextField *_numLabel;
    EAFRoundedView *_rv;
    NSInteger _num;
}

@end

@implementation EAFBadgeView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setWantsLayer:YES];
        
        _numLabel = [[NSTextField alloc]initWithFrame:CGRectZero];

        _numLabel.font = [NSFont systemFontOfSize:8];
//        _numLabel.font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]];
        _numLabel.textColor = [NSColor whiteColor];
        [_numLabel setAlignment:NSCenterTextAlignment];
        [_numLabel setEditable:NO];
        [_numLabel setBezeled:NO];
        [_numLabel setDrawsBackground:NO];
        [_numLabel setSelectable:NO];
        
        _rv = [[EAFRoundedView alloc]initWithFrame:CGRectZero];
        _rv.backgroundColor = [[NSColor eaf_orangeColor]colorWithAlphaComponent:.3];
        _rv.cornerRadius = 5;
        _rv.cornerFlags = NSBezierPathRoundedCornerTopLeft | NSBezierPathRoundedCornerTopRight | NSBezierPathRoundedCornerBottomLeft | NSBezierPathRoundedCornerBottomRight;
        _rv.layer.borderWidth = 0;
        _rv.layer.borderColor = [NSColor eaf_orangeColor].CGColor;

        [self eaf_addSubview:_rv inset:CGSizeZero];
        [_rv eaf_addSubview:_numLabel inset:CGSizeMake(0, -1)]; // inset y so it is vertically centered...
    }
    
    return self;
}

-(NSInteger)numberOfItems{
    return _num;
}

-(void)setNumberOfItems:(NSInteger)num animated:(BOOL)animated{
    _num = num;
//    _numLabel.integerValue = num;
    _numLabel.stringValue = [NSString stringWithFormat:@"%lu", num];
    
    [self setHidden:(_num <= 0)];
  
    CGRect f = self.frame;
    
//    CABasicAnimation *a1 = [CABasicAnimation animationWithKeyPath:@"frame"];
//    a1.fromValue = [NSValue valueWithRect:f];
//    a1.toValue = [NSValue valueWithRect:CGRectMake(f.origin.x, f.origin.y, 0, f.size.height)];
//    a1.duration = .25;
//    [self.layer addAnimation:a1 forKey:@"a1"];

    [[NSAnimationContext currentContext]setDuration:.2];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [self.animator setFrameSize:CGSizeMake(f.size.width, self.frame.size.height)];
    }];
        [self.animator setFrameSize:CGSizeMake(0, self.frame.size.height)];
    [NSAnimationContext endGrouping];
    
//    if (animated){
//        [self.animator setFrameSize:CGSizeMake(0, self.frame.size.height)];
//    }
    
}

//- (void)drawRect:(NSRect)dirtyRect{
//    
//}

@end
