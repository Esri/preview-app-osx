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

//
// This view, if given a corner radius and corner flags, will clip it's
// subviews to the path of the rounded corners. It will also make the subviews
// layer backed when they are added as a subviews to this view
@interface EAFRoundedView : NSView

/** Sets the background color for the layer.
 */
@property (nonatomic, strong) NSColor *backgroundColor;

/** Expects 1 or more NSBezierPathRoundedCorner flags that can be bitwise-OR'd together.
 */
@property (nonatomic, assign) NSUInteger cornerFlags;

/** Specifies the corner radius for the corners specified in 
 cornerFlags.
 */
@property (nonatomic, assign) CGFloat cornerRadius;

// holds on to our clipping path
@property (nonatomic, strong) CAShapeLayer *maskLayer;
@end
