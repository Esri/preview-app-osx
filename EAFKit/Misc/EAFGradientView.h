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


#import <Cocoa/Cocoa.h>

@class EAFRoundedView;

@interface EAFGradientView : NSView

@property (nonatomic, strong) NSGradient *startGradient;
@property (nonatomic, strong) NSGradient *endGradient;
@property (nonatomic, assign) CGFloat angle;

//
// one gradient will just draw a single gradient from bottom up
- (id)initWithStartGradient:(NSGradient*)startGradient;

//
// start and end will draw start gradient from bottom to halfway up view
// then end gradient from halfway up to the top
- (id)initWithStartGradient:(NSGradient*)startGradient endGradient:(NSGradient*)endGradient;
@end
