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

#import "EAFHyperlinkButton.h"

@interface EAFHyperlinkButton ()
@property (nonatomic, assign, getter = isHovering) BOOL hovering;
@end

@implementation EAFHyperlinkButton

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        _textHoverColor = [NSColor blackColor];
        _textColor = [NSColor blackColor];
        self.cursor = [NSCursor pointingHandCursor];
        self.alignment = NSLeftTextAlignment;
        self.underlineOnHoverOnly = YES;
        
        [self setBordered:NO];
        [self setBezelStyle:NSInlineBezelStyle];
        [self setButtonType:NSMomentaryChangeButton];
        [self setFont:[NSFont systemFontOfSize:10.0]];
        [self setTitle:@"default text"];
        //
        // with the specified options, our tracking area will always be the bounds of the view
        NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingCursorUpdate | NSTrackingActiveInKeyWindow | NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
    }
    return self;
}


- (void)updateAttributedTitle {
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:self.title];
    NSRange range = NSMakeRange(0, [attrString length]);
    
    [attrString beginEditing];
    
    //
    // set font
    [attrString addAttribute:NSFontAttributeName value:self.font range:range];
    
    // set text color based on whether we are hovering or now
    [attrString addAttribute:NSForegroundColorAttributeName value:self.isHovering ? self.textHoverColor : self.textColor range:range];
    
    //
    // underline if not onHover only OR if we are actually currently hovering
    if (self.isEnabled && (self.isHovering || !self.underlineOnHoverOnly)) {
        // next make the text appear with an underline
        [attrString addAttribute:
         NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
    }
    
    //
    // add our text alignment
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setAlignment:self.alignment];
    [paragraphStyle setLineBreakMode:self.lineBreakMode];
    [attrString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
    
    [attrString endEditing];
    
    [self setAttributedTitle:attrString];
}

- (void)setEnabled:(BOOL)flag {
    [super setEnabled:flag];
    [self updateAttributedTitle];
    
    //
    // if we are disabling this button and the cursor
    // is already hovering, we need to get back to the
    // default cursor.
    //
    // this can happen when you are paging and hit the last
    // page: you disable the 'next' button but the curor is
    // still pointing hand
    if (!flag) {
        [[NSCursor arrowCursor] set];
    }
}



//
// the mouse has entered our tracking area, update the cursor
- (void)cursorUpdate:(NSEvent *)event {
    if (self.isEnabled) {
        [self.cursor set];
    }
}

//
// set the attributed text
- (void)mouseEntered:(NSEvent *)theEvent {
    [super mouseEntered:theEvent];
    self.hovering = YES;
    [self updateAttributedTitle];
}

//
// revert back to standard text
- (void)mouseExited:(NSEvent *)theEvent {
    [super mouseExited:theEvent];
    self.hovering = NO;
    [self updateAttributedTitle];
}

#pragma mark - 
#pragma mark Setters

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode {
    _lineBreakMode = lineBreakMode;
    [[self cell] setLineBreakMode:NSLineBreakByTruncatingTail];
}

- (void)setFont:(NSFont *)fontObj {
    [super setFont:fontObj];
    [self updateAttributedTitle];
}

- (void)setTextHoverColor:(NSColor *)textHoverColor {
    _textHoverColor = textHoverColor;
    [self updateAttributedTitle];
}

- (void)setUnderlineOnHoverOnly:(BOOL)underlineOnHoverOnly {
    _underlineOnHoverOnly = underlineOnHoverOnly;
    [self updateAttributedTitle];
}

- (void)setTextColor:(NSColor *)textColor {
    _textColor = textColor;
    [self updateAttributedTitle];
}

//
// override so we can update attributed text
- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    [self updateAttributedTitle];
}

- (void)setAlignment:(NSTextAlignment)mode {
    [super setAlignment:mode];
    [self updateAttributedTitle];
}


@end
