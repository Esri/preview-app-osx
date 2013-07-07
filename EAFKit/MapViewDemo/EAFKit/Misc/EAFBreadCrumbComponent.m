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

#import "EAFGradientView.h"
#import "EAFBreadCrumbComponent.h"
#import "EAFHyperlinkButton.h"
#import "EAFBreadCrumbView.h"
#import "EAFBreadCrumbEndCap.h"
#import "EAFDefines.h"
#import "NSGradient+EAFAdditions.h"

@interface EAFBreadCrumbComponent(){
    NSInteger _tag;
    EAFHyperlinkButton *_btn;
    EAFBreadCrumbEndCap *_endCap;
}
@end

@implementation EAFBreadCrumbComponent

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        [self loadUI];
    }
    return self;
}

-(NSInteger)tag{
    return _tag;
}

-(void)setTag:(NSInteger)tag{
    _tag = tag;
}

-(void)setText:(NSString *)text{
    _btn.title = text;
}

-(NSString *)text{
    return _btn.title;
}

-(void)setSelected:(BOOL)selected{
    _selected = selected;
    if (_selected){
        self.startGradient = [NSGradient eaf_breadCrumbSelectedGradient];
    }
    else{
        self.startGradient = [NSGradient eaf_breadCrumbGradient];
    }
    [self setupButtonForSelection];
}

-(void)setStyle:(EAFBreadCrumbEndCapStyle)style{
    _style = style;
    _endCap.style = style;
}

-(void)btnAction:(id)sender{
    EAFSuppressClangPerformSelectorLeakWarning([self.target performSelector:self.action withObject:self]);
}

-(NSView*)selectedBGView{
    EAFGradientView *gradientView = [[EAFGradientView alloc] initWithStartGradient:[NSGradient eaf_breadCrumbSelectedGradient]];
    gradientView.frame = self.bounds;
    gradientView.angle = 90.0f;
    return gradientView;
}

-(NSSize)intrinsicContentSize{
    return NSMakeSize(5 + _btn.frame.size.width + _endCap.frame.size.width, 1);
}

-(void)loadUI{
    
    _btn = [[EAFHyperlinkButton alloc]initWithFrame:self.bounds];
    _btn.alignment = NSCenterTextAlignment;
    _btn.target = self;
    _btn.action = @selector(btnAction:);
    _btn.lineBreakMode = NSLineBreakByTruncatingTail;
    _btn.font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
    _btn.translatesAutoresizingMaskIntoConstraints = NO;
    [self setupButtonForSelection];
    [self addSubview:_btn];
    
    _endCap = [[EAFBreadCrumbEndCap alloc]initWithFrame:CGRectMake(0, 0, 16, self.bounds.size.height) style:_style];
    _endCap.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_endCap];
    
    NSDictionary *viewsDictionaryEndCap = NSDictionaryOfVariableBindings(_btn, _endCap);
    NSArray *constraintsYBtn = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_btn]|"
                                                                          options:NSLayoutAttributeCenterY
                                                                          metrics:nil
                                                                            views:viewsDictionaryEndCap];
    [self addConstraints:constraintsYBtn];
    NSArray *constraintsYEndCap = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_endCap]|"
                                                                          options:NSLayoutAttributeCenterY
                                                                          metrics:nil
                                                                            views:viewsDictionaryEndCap];
    [self addConstraints:constraintsYEndCap];
    
    NSArray *constraintsX = [NSLayoutConstraint constraintsWithVisualFormat:@"|-5-[_btn(<=233)][_endCap(==16)]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:viewsDictionaryEndCap];
    [self addConstraints:constraintsX];
}

-(void)setupButtonForSelection{
    if (_selected){
        _btn.textColor = [NSColor whiteColor];
        _btn.textHoverColor = [NSColor whiteColor];
    }
    else{
        _btn.textHoverColor = [NSColor darkGrayColor];
        _btn.textColor = [NSColor darkGrayColor];
    }
}


@end
