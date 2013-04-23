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
@class EAFGradientView;
@class EAFHyperlinkButton;

@interface EAFTitledView : EAFRoundedView

@property (nonatomic, copy) NSString *title;

@property (nonatomic, strong) NSFont *titleFont;

@property (nonatomic, assign) BOOL showPageInfo;

@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) NSInteger totalPages;

@property (nonatomic, strong, readonly) EAFHyperlinkButton *prevButton;

@property (nonatomic, strong, readonly) EAFHyperlinkButton *nextButton;

// top left/right corners will be rounded by default
@property (nonatomic, strong, readonly) EAFRoundedView *titleBarView;

// bottom left/right corners will be rounded by default.
@property (nonatomic, strong, readonly) EAFRoundedView *contentView;

@property (nonatomic, strong) NSColor *outlineColor;

@property (nonatomic, assign) CGFloat outlineWidth;

//
// color of the thin line separating the titleBarView from the contentView
@property (nonatomic, strong) NSColor *separatorColor;

//
// width of the thin line separating the titleBarView from the contentView
@property (nonatomic, assign) CGFloat separatorWidth;

//
// designated initializer is still initWithFrame:
// it will just call this passing NSZeroRect for tvFrameRect
- (id)initWithFrame:(NSRect)frameRect titleViewHeight:(CGFloat)tvHeight;

@end