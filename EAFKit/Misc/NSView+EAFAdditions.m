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

#import "NSView+EAFAdditions.h"

@implementation NSView (EAFAdditions)

- (void)eaf_addSubview:(NSView*)subview inset:(CGSize)insetSize {
    subview.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:subview];
    NSLayoutConstraint *lc1 = [NSLayoutConstraint constraintWithItem:subview
                                                           attribute:NSLayoutAttributeLeading
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeLeading
                                                          multiplier:1.0
                                                            constant:insetSize.width];
    [self addConstraint:lc1];
    NSLayoutConstraint *lc2 = [NSLayoutConstraint constraintWithItem:subview
                                                           attribute:NSLayoutAttributeTrailing
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeTrailing
                                                          multiplier:1.0
                                                            constant:-insetSize.width];
    [self addConstraint:lc2];
    NSLayoutConstraint *lc3 = [NSLayoutConstraint constraintWithItem:subview
                                                           attribute:NSLayoutAttributeTop
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeTop
                                                          multiplier:1.0
                                                            constant:insetSize.height];
    [self addConstraint:lc3];
    NSLayoutConstraint *lc4 = [NSLayoutConstraint constraintWithItem:subview
                                                           attribute:NSLayoutAttributeBottom
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self
                                                           attribute:NSLayoutAttributeBottom
                                                          multiplier:1.0
                                                            constant:-insetSize.height];
    [self addConstraint:lc4];
}
@end
