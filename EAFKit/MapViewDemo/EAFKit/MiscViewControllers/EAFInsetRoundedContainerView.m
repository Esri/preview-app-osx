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

#import "EAFInsetRoundedContainerView.h"
#import "NSColor+EAFAdditions.h"
#import "EAFRoundedView.h"
#import "NSView+EAFAdditions.h"

@interface EAFInsetRoundedContainerView (){
    EAFRoundedView *_containerView;
}
@end

@implementation EAFInsetRoundedContainerView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    
        [self setWantsLayer:YES];
        self.layer.backgroundColor = [NSColor eaf_lighterGrayColor].CGColor;
        
        EAFRoundedView *rv = [[EAFRoundedView alloc]initWithFrame:CGRectZero];
        rv.cornerRadius = 4;
        rv.cornerFlags = NSBezierPathRoundedCornerTopLeft | NSBezierPathRoundedCornerTopRight | NSBezierPathRoundedCornerBottomLeft | NSBezierPathRoundedCornerBottomRight;
        rv.layer.borderWidth = 1;
        rv.layer.borderColor = [NSColor lightGrayColor].CGColor;
        _containerView = rv;
        [self eaf_addSubview:rv inset:CGSizeMake(15, 15)];
        
//        // Test code only
//        NSView *rv = [[NSView alloc]initWithFrame:CGRectInset(self.bounds, 15, 15)];
//        [rv setWantsLayer:YES];
//        rv.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
//        rv.layer.borderWidth = 1;
//        rv.layer.borderColor = [NSColor lightGrayColor].CGColor;
//        _containerView = rv;
//        [self addSubview:rv];

    }
    return self;
}

-(EAFRoundedView*)containerView{
    return _containerView;
}

@end
