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

#import "NSViewController+EAFAdditions.h"

@implementation NSViewController (EAFAdditions)

- (void)eaf_addToContainerWithConstraints:(NSView*)container{
    [self eaf_addToContainerWithConstraints:container insetX:0 insetY:0];
}

- (void)eaf_addToContainerWithConstraints:(NSView*)container insetX:(CGFloat)dX insetY:(CGFloat)dY{
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:self.view];
    NSLayoutConstraint *lc1 = [NSLayoutConstraint constraintWithItem:self.view
                                                           attribute:NSLayoutAttributeLeading
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:container
                                                           attribute:NSLayoutAttributeLeading
                                                          multiplier:1.0
                                                            constant:dX];
    [container addConstraint:lc1];
    NSLayoutConstraint *lc2 = [NSLayoutConstraint constraintWithItem:self.view
                                                           attribute:NSLayoutAttributeTrailing
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:container
                                                           attribute:NSLayoutAttributeTrailing
                                                          multiplier:1.0
                                                            constant:-dX];
    [container addConstraint:lc2];
    NSLayoutConstraint *lc3 = [NSLayoutConstraint constraintWithItem:self.view
                                                           attribute:NSLayoutAttributeTop
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:container
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0
                                                            constant:dY];
    [container addConstraint:lc3];
    NSLayoutConstraint *lc4 = [NSLayoutConstraint constraintWithItem:self.view
                                                           attribute:NSLayoutAttributeBottom
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:container
                                                           attribute:NSLayoutAttributeBottom
                                                          multiplier:1.0
                                                            constant:-dY];
    [container addConstraint:lc4];
    
}

-(void)eaf_addToContainer:(NSView*)container{
    self.view.frame = container.bounds;
    self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [container addSubview:self.view];
}

-(void)eaf_addToContainer:(NSView*)container insetX:(CGFloat)dX insetY:(CGFloat) dY{
    NSRect insetFrame = NSInsetRect(container.bounds, dX, dY);
    self.view.frame = insetFrame;
    self.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [container addSubview:self.view];
}

-(void)eaf_addToAndCenterInContainer:(NSView*)container{
    [self.view setFrameOrigin:NSMakePoint(
                                          (NSWidth([container bounds]) - NSWidth([self.view frame])) / 2,
                                          (NSHeight([container bounds]) - NSHeight([self.view frame])) / 2
                                          )];
    [self.view setAutoresizingMask:NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin];
    [container addSubview:self.view];
}

@end
