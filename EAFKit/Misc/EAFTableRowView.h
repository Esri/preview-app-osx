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
// this object allows us to set alternating row background colors for view-based table views
@interface EAFTableRowView : NSTableRowView

//
// sets the row so we can determine which color background to draw
@property (nonatomic, assign) NSUInteger row;

//
// default is [NSColor eaf_lighterGrayColor]
@property (nonatomic, strong) NSColor *alternatingRowColor;
@end