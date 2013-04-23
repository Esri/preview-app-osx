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

#import "EAFBreadCrumbView.h"
#import "EAFGradientView.h"
#import "EAFHyperlinkButton.h"
#import "NSGradient+EAFAdditions.h"
#import "EAFDefines.h"
#import "EAFBreadCrumbEndCap.h"
#import "EAFBreadCrumbComponent.h"
#import "EAFCGUtils.h"

const NSInteger kEAFBreadCrumbButtonTagBase = 1000;
const NSInteger kEAFJumbBarBottomLineHeight = 0;

@interface EAFBreadCrumbView(){
    NSMutableArray *_mutableItems;
    NSMutableArray *_comps;
}

@end

@implementation EAFBreadCrumbView

- (id)initWithFrame:(NSRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _mutableItems = [NSMutableArray array];
        
        EAFGradientView *gradientView = [[EAFGradientView alloc] initWithStartGradient:[NSGradient eaf_breadCrumbGradient]];
        gradientView.frame = EAFCGRectInsetMinY(self.bounds, kEAFJumbBarBottomLineHeight);
        gradientView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        gradientView.angle = 90.0f;
        [self addSubview:gradientView];
        
        [self setWantsLayer:YES];
        self.layer.backgroundColor = [NSColor darkGrayColor].CGColor;
        
        [self loadUI];
    }
    
    return self;
}


-(CGRect)frameForItemAtIndex:(NSUInteger)index{
    if (index >= _comps.count){
        return CGRectZero;
    }
    NSView *v = [_comps objectAtIndex:index];
    return v.frame;
}

//- (void)drawRect:(NSRect)dirtyRect{
//    [super drawRect:dirtyRect];
//    
//    CGRect bounds = self.bounds;
//    CGFloat h = bounds.size.height;
//    CGFloat t = bounds.origin.y;
//    CGFloat b = t + h;
//    CGFloat l = bounds.origin.x;
//    CGFloat w = bounds.size.width;
//    CGFloat r = l + w;
////    CGFloat cy = (b + t) / 2;
//    
//    NSGraphicsContext *context = [NSGraphicsContext currentContext];
//    [context saveGraphicsState];
//	[context setShouldAntialias:YES];
//    
//    NSBezierPath *bp = [[NSBezierPath alloc]init];
//    [bp moveToPoint:CGPointMake(l, b-1)];
//    [bp lineToPoint:CGPointMake(r, b-1)];
//    [[NSColor redColor]set];
//    [bp stroke];
//    
//    [context restoreGraphicsState];
//}

-(EAFBreadCrumbEndCapStyle)endCapStyleForCompAtIndex:(NSUInteger)index{
    
    EAFBreadCrumbEndCapStyle style = EAFBreadCrumbEndCapStyleNoneSelected;
    if (index == _mutableItems.count - 1){
        // add last object separator
        style = EAFBreadCrumbEndCapStyleEnd;
        if (index == _selectedIndex){
            style = EAFBreadCrumbEndCapStyleSelectedEnd;
        }
    }
    else{
        // add normal separator
        style = EAFBreadCrumbEndCapStyleNoneSelected;
        if (index == _selectedIndex){
            style = EAFBreadCrumbEndCapStyleLeftSelected;
        }
        if (_selectedIndex == (index + 1)){
            style = EAFBreadCrumbEndCapStyleRightSelected;
        }
    }
    return style;
}

-(void)loadUI{
    NSArray *compsCopy = [_comps copy];
    for (NSView *v in compsCopy){
        [v removeFromSuperview];
    }
    
    _comps = [NSMutableArray arrayWithCapacity:_mutableItems.count];
    NSArray *items = [_mutableItems copy];
    EAFBreadCrumbComponent *previous = nil;
    NSInteger tag = kEAFBreadCrumbButtonTagBase;
    for (NSString *item in items){
        NSInteger index = tag - kEAFBreadCrumbButtonTagBase;
        
        EAFBreadCrumbComponent *comp = [[EAFBreadCrumbComponent alloc]initWithFrame:CGRectMake(0, 0, 10, self.bounds.size.height)];
        comp.text = item;
        comp.target = self;
        comp.action = @selector(itemAction:);
        comp.tag = tag;
        comp.selected = (_selectedIndex == index);
        
        comp.style = [self endCapStyleForCompAtIndex:index];
        
        [self addSubview:comp];
        [_comps addObject:comp];
        
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(comp);
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[comp]-%lu-|", kEAFJumbBarBottomLineHeight]
                                                                       options:NSLayoutAttributeCenterY
                                                                       metrics:nil
                                                                         views:viewsDictionary];
        [self addConstraints:constraints];
        
        if (!previous){
            NSDictionary *viewsDictionary2 = NSDictionaryOfVariableBindings(comp);
            NSArray *constraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"|[comp]"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:viewsDictionary2];
            [self addConstraints:constraints2];        }
        else{
            NSDictionary *viewsDictionary2 = NSDictionaryOfVariableBindings(comp, previous);
            NSArray *constraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"[previous][comp]"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:viewsDictionary2];
            [self addConstraints:constraints2];
        }
        
        previous = comp;
        tag++;
    }
    
}

-(void)itemAction:(EAFBreadCrumbComponent*)comp{
    NSInteger index = comp.tag - kEAFBreadCrumbButtonTagBase;
    self.selectedIndex = index;
    EAFSuppressClangPerformSelectorLeakWarning([self.target performSelector:self.action withObject:self]);
}

#pragma mark item management

-(NSArray*)items{
    return [_mutableItems copy];
}

-(void)addItem:(NSString*)item{
    [_mutableItems addObject:item];
    [self loadUI];
}

-(void)insertItem:(NSString*)item atIndex:(NSUInteger)index{
    [_mutableItems insertObject:item atIndex:index];
    [self loadUI];
}

-(void)removeItem:(NSString*)item{
    [_mutableItems removeObject:item];
    [self loadUI];
}

-(void)removeItemAtIndex:(NSUInteger)index{
    if (index >= _mutableItems.count){
        return;
    }
    [_mutableItems removeObjectAtIndex:index];
    [self loadUI];
}

-(void)removeAllItems{
    [_mutableItems removeAllObjects];
    [self loadUI];
}

-(void)setSelectedIndex:(NSInteger)selectedIndex{
    _previousSelectedIndex = _selectedIndex;
    _selectedIndex = selectedIndex;
    for (NSUInteger index=0; index<_mutableItems.count; index++){
        EAFBreadCrumbComponent *comp = [_comps objectAtIndex:index];
        comp.style = [self endCapStyleForCompAtIndex:index];
        comp.selected = index == _selectedIndex;
    }
}

@end
