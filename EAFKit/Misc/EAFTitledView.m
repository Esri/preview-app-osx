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
#import "EAFTitledView.h"
#import "EAFGradientView.h"
#import "EAFCGUtils.h"
#import "EAFHyperlinkButton.h"

@interface EAFTitledView ()
@property (nonatomic, strong) NSTextField *titleTextField;
@property (nonatomic, strong) NSTextField *pageInfoTextField;
@property (nonatomic, strong, readwrite) EAFHyperlinkButton *prevButton;
@property (nonatomic, strong, readwrite) EAFHyperlinkButton *nextButton;
@property (nonatomic, strong, readwrite) EAFRoundedView *titleBarView;
@property (nonatomic, strong, readwrite) EAFRoundedView *contentView;
@property (nonatomic, strong) NSView *lineSeparatorView;
@property (nonatomic, strong) NSArray *pagingInfoConstraints;
@end

@implementation EAFTitledView

- (void)sharedInit {
    self.currentPage = 1;
//    self.showPageInfo = YES;
    self.cornerRadius = 5.0;
    self.cornerFlags = NSBezierPathRoundedCornerBottomLeft | NSBezierPathRoundedCornerBottomRight | NSBezierPathRoundedCornerTopLeft | NSBezierPathRoundedCornerTopRight;
    self.titleBarView = [[EAFRoundedView alloc] initWithFrame:NSZeroRect];
    self.titleBarView.cornerFlags = NSBezierPathRoundedCornerTopLeft | NSBezierPathRoundedCornerTopRight;
    self.titleBarView.cornerRadius = self.cornerRadius;
    //
    // we want our title view to expand horizontally, but be fixed to the top of the view
    self.titleBarView.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [self addSubview:self.titleBarView];
    
    //
    // add our title text field to the view so when people add a view to the titleView, it will be on top of it
    self.titleTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    [self.titleTextField setAlignment:NSLeftTextAlignment];
    [self.titleTextField setDrawsBackground:NO];
    [self.titleTextField setTextColor:[NSColor darkGrayColor]];
    [self.titleTextField setFont:[NSFont boldSystemFontOfSize:14.0]];
    [self.titleTextField setBordered:NO];
    [self.titleTextField setEditable:NO];
    [self.titleTextField setBezeled:NO];
    self.titleTextField.translatesAutoresizingMaskIntoConstraints = NO;
    //EAFDebugStrokeBorder(self.titleTextField, 1.0, [NSColor blueColor]);
    
    [self.titleTextField setStringValue:@"My Title"];
    [[self.titleTextField cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [self.titleTextField setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
    [self addSubview:self.titleTextField];

    // add prev button
    self.prevButton = [[EAFHyperlinkButton alloc] initWithFrame:NSZeroRect];
    [self.prevButton setAutoresizingMask:NSViewMinYMargin];
    [self.prevButton setTitle:@"prev"];
    [self.prevButton setFont:[NSFont systemFontOfSize:10.0]];
    [self.prevButton setEnabled:NO];
    [self.prevButton setHidden:YES];
    //[self addSubview:self.prevButton];
//    EAFDebugStrokeBorder(self.prevButton, 1.0, [NSColor blueColor]);
    
        
    // add next button
    self.nextButton = [[EAFHyperlinkButton alloc] initWithFrame:NSZeroRect];
    [self.nextButton setAutoresizingMask:NSViewMinYMargin];
    [self.nextButton setTitle:@"next"];
    [self.nextButton setFont:[NSFont systemFontOfSize:10.0]];
    [self.nextButton setEnabled:NO];
    [self.nextButton setHidden:YES];
    //[self addSubview:self.nextButton];
//    EAFDebugStrokeBorder(self.nextButton, 1.0, [NSColor blueColor]);
    
    //
    // page info text field
    self.pageInfoTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    [self.pageInfoTextField setDrawsBackground:NO];
    [self.pageInfoTextField setBordered:NO];
    [self.pageInfoTextField setEditable:NO];
    [self.pageInfoTextField setBezeled:NO];
    [self.pageInfoTextField setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
    [self.pageInfoTextField setTextColor:[NSColor darkGrayColor]];
    [self.pageInfoTextField setHidden:YES];
    //[self addSubview:self.pageInfoTextField];
//    EAFDebugStrokeBorder(self.pageInfoTextField, 1.0, [NSColor blueColor]);
    
    //
    // content view
    self.contentView = [[EAFRoundedView alloc] initWithFrame:NSZeroRect];
    self.contentView.cornerFlags = NSBezierPathRoundedCornerBottomLeft | NSBezierPathRoundedCornerBottomRight;
    //
    // we want our content view stuck below the title view
    self.contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable | NSViewMinXMargin | NSViewMinYMargin | NSViewMaxXMargin;
    self.contentView.cornerRadius = self.cornerRadius;
    [self addSubview:self.contentView];
    
    self.separatorColor = [NSColor lightGrayColor];
    self.separatorWidth = 1.0f;

    self.lineSeparatorView = [[NSView alloc] initWithFrame:NSZeroRect];
    self.lineSeparatorView.autoresizingMask = NSViewWidthSizable;
    [self.lineSeparatorView setWantsLayer:YES];
    self.lineSeparatorView.layer.borderColor = [self.separatorColor CGColor];
    self.lineSeparatorView.layer.borderWidth = self.separatorWidth;
    [self addSubview:self.lineSeparatorView];
    
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable | NSViewMinXMargin | NSViewMinYMargin | NSViewMaxXMargin | NSViewMaxYMargin;
    
    NSMutableArray *pagingConstraints = [NSMutableArray array];

    //
    // next button constraints
    self.nextButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nextButton setAlignment:NSCenterTextAlignment];
    NSLayoutConstraint *nextBtnCenterY = [NSLayoutConstraint constraintWithItem:self.nextButton
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.titleBarView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1.0
                                                                       constant:0.0];
    [self addConstraint:nextBtnCenterY];
    [pagingConstraints addObject:nextBtnCenterY];
    
    NSLayoutConstraint *nextBtnRightPad = [NSLayoutConstraint constraintWithItem:self.nextButton
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.titleBarView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:-5.0];
    [self addConstraint:nextBtnRightPad];
    [pagingConstraints addObject:nextBtnRightPad];
    
    //
    // page info constraints
    self.pageInfoTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.pageInfoTextField setAlignment:NSCenterTextAlignment];
    NSLayoutConstraint *pageInfoRightPad = [NSLayoutConstraint constraintWithItem:self.pageInfoTextField
                                                                        attribute:NSLayoutAttributeTrailing
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.nextButton
                                                                        attribute:NSLayoutAttributeLeading
                                                                       multiplier:1.0
                                                                         constant:-5.0];
    [self addConstraint:pageInfoRightPad];
    [pagingConstraints addObject:pageInfoRightPad];
    
    NSLayoutConstraint *pageInfoCenterY = [NSLayoutConstraint constraintWithItem:self.pageInfoTextField
                                                                       attribute:NSLayoutAttributeCenterY
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.titleBarView
                                                                       attribute:NSLayoutAttributeCenterY
                                                                      multiplier:1.0
                                                                        constant:0.0];
    [self addConstraint:pageInfoCenterY];
    [pagingConstraints addObject:pageInfoCenterY];

    //
    // prev button constraints
    self.prevButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.prevButton setAlignment:NSCenterTextAlignment];
    NSLayoutConstraint *prevBtnCenterY = [NSLayoutConstraint constraintWithItem:self.prevButton
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.titleBarView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1.0
                                                                       constant:0.0];
    [self addConstraint:prevBtnCenterY];
    [pagingConstraints addObject:prevBtnCenterY];
    
    NSLayoutConstraint *prevBtnRightPad = [NSLayoutConstraint constraintWithItem:self.prevButton
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.pageInfoTextField
                                                                       attribute:NSLayoutAttributeLeading
                                                                      multiplier:1.0
                                                                        constant:-5.0];
    [self addConstraint:prevBtnRightPad];
    [pagingConstraints addObject:prevBtnRightPad];
    
    self.titleTextField.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *centerConstraint = [NSLayoutConstraint constraintWithItem:self.titleTextField
                                                                        attribute:NSLayoutAttributeCenterY
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.titleBarView
                                                                        attribute:NSLayoutAttributeCenterY
                                                                       multiplier:1.0
                                                                         constant:0.0];
    [self addConstraint:centerConstraint];
    NSLayoutConstraint *leftPadConstraint = [NSLayoutConstraint constraintWithItem:self.titleTextField
                                                                         attribute:NSLayoutAttributeLeading
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.titleBarView
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:10.0];
    [self addConstraint:leftPadConstraint];
    
    NSLayoutConstraint *rightPadConstraint = [NSLayoutConstraint constraintWithItem:self.titleTextField
                                                                          attribute:NSLayoutAttributeTrailing
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.prevButton
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0
                                                                           constant:-5.0];
//    rightPadConstraint.priority = 600;
    [self addConstraint:rightPadConstraint];
    [pagingConstraints addObject:rightPadConstraint];
    
    NSLayoutConstraint *rightPadConstraint2 = [NSLayoutConstraint constraintWithItem:self.titleTextField
                                                                          attribute:NSLayoutAttributeTrailing
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.titleBarView
                                                                          attribute:NSLayoutAttributeTrailing
                                                                         multiplier:1.0
                                                                           constant:-5.0];
    rightPadConstraint2.priority = 500;
    [self addConstraint:rightPadConstraint2];
    
    [self.titleTextField setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    self.pagingInfoConstraints = pagingConstraints;
    self.showPageInfo = YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self sharedInit];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect titleViewHeight:(CGFloat)tvHeight {
    if (self = [super initWithFrame:frameRect]) {
        [self sharedInit];
        
        NSRect tvFrameRect = NSMakeRect(0, CGRectGetHeight(frameRect) - tvHeight, CGRectGetWidth(frameRect), tvHeight);
        self.titleBarView.frame = tvFrameRect;

        NSRect cvFrame = NSMakeRect(0, 0, CGRectGetWidth(frameRect), CGRectGetHeight(frameRect) - tvHeight);
        self.contentView.frame = cvFrame;
        
        self.titleTextField.frame = EAFCGRectInsetEdges(tvFrameRect, 5, 5, 0, 5);

        self.lineSeparatorView.frame = EAFCGRectInsetMaxY(tvFrameRect, CGRectGetHeight(tvFrameRect) - 1);

        self.prevButton.frame = NSMakeRect(CGRectGetWidth(tvFrameRect) - 70, CGRectGetMinY(tvFrameRect) - 6, 38, 39);
        self.nextButton.frame = NSMakeRect(CGRectGetWidth(tvFrameRect) - 38, CGRectGetMinY(tvFrameRect) - 6, 38, 39);
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    return [self initWithFrame:frame titleViewHeight:31.0];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    NSRect rect = [self bounds];
    NSBezierPath *path = [NSBezierPath ags_bezierPathWithRoundedRect:rect
                                                        cornerRadius:self.cornerRadius
                                                         cornerFlags:self.cornerFlags];
    [path addClip];

    CGPathRef maskedPath = AGSCGPathCreateFromBezier(path);
    self.maskLayer.path = maskedPath;
    CGPathRelease(maskedPath);
    
    [self.titleBarView drawRect:dirtyRect];
    [self.contentView drawRect:dirtyRect];
    [self.titleTextField drawRect:dirtyRect];
    [self.lineSeparatorView drawRect:dirtyRect];
    //[super drawRect:dirtyRect];
}


- (void)updatePageInfo {
    if (self.showPageInfo) {
        [self.nextButton setHidden:NO];
        [self.titleBarView addSubview:self.nextButton];
        [self.prevButton setHidden:NO];
        [self.titleBarView addSubview:self.prevButton];
        [self.pageInfoTextField setHidden:NO];
        [self.titleBarView addSubview:self.pageInfoTextField];
        [self.pageInfoTextField setStringValue:[NSString stringWithFormat:@"%ld/%ld", self.currentPage, self.totalPages]];
        
        if (self.pagingInfoConstraints) {
            [self addConstraints:self.pagingInfoConstraints];
        }
    }
    else {
        [self.nextButton removeFromSuperview];
        [self.nextButton setHidden:YES];
        [self.prevButton setHidden:YES];
        [self.prevButton removeFromSuperview];
        [self.pageInfoTextField setHidden:YES];
        [self.pageInfoTextField removeFromSuperview];
        if (self.pagingInfoConstraints) {
            [self removeConstraints:self.pagingInfoConstraints];
        }
    }

}

#pragma mark -
#pragma mark Setters

- (void)setShowPageInfo:(BOOL)showPageInfo {
    _showPageInfo = showPageInfo;
    [self updatePageInfo];
}

- (void)setCurrentPage:(NSInteger)currentPage {
    _currentPage = currentPage;
    [self updatePageInfo];
}

- (void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    NSRect tvFrameRect = self.titleBarView.frame;
    self.lineSeparatorView.frame = EAFCGRectInsetMaxY(tvFrameRect, CGRectGetHeight(tvFrameRect) - 1);
}

- (void)setSeparatorColor:(NSColor *)separatorColor {
    _separatorColor = separatorColor;
    self.lineSeparatorView.layer.borderColor = [_separatorColor CGColor];
    [self setNeedsDisplay:YES];
}

- (void)setSeparatorWidth:(CGFloat)separatorWidth {
    _separatorWidth = separatorWidth;
    self.lineSeparatorView.layer.borderWidth = _separatorWidth;
    [self setNeedsDisplay:YES];
}

- (void)setOutlineColor:(NSColor *)outlineColor {
    _outlineColor = outlineColor;
    self.layer.borderColor = [_outlineColor CGColor];
    [self setNeedsDisplay:YES];
}

- (void)setOutlineWidth:(CGFloat)outlineWidth {
    _outlineWidth = outlineWidth;
    self.layer.borderWidth = _outlineWidth;
    [self setNeedsDisplay:YES];
}

- (void)setTitle:(NSString *)title {
    _title = [title stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    [self.titleTextField setStringValue:_title];
}

- (void)setTitleFont:(NSFont *)titleFont {
    _titleFont = titleFont;
    [self.titleTextField setFont:_titleFont];
}

- (void)setTotalPages:(NSInteger)totalPages {
    _totalPages = totalPages;
    //
    // update the paging info visibility based
    // on number of pages
    if (_totalPages <= 1) {
        self.showPageInfo = NO;
    }
    else {
        self.showPageInfo = YES;
    }
}
@end
