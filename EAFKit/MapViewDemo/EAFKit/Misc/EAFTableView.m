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

#import "EAFTableView.h"
#import "NSColor+EAFAdditions.h"

@implementation EAFTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.customAlternatingBGColor = [NSColor eaf_lighterGrayColor];
    }
    
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self){
        self.customAlternatingBGColor = [NSColor eaf_lighterGrayColor];
    }
    return self;
}

- (void)drawRow:(NSInteger)row clipRect:(NSRect)clipRect{
    // this is one way to do a custom alternating color
    // this way will not draw alternating colors for blank cells
    if (row != [self selectedRow] && self.customAlternatingBGColor){
        
        //
        // this checks to see if we want to highlight odd rows or even
        if (row % 2 == (int)self.colorEvenRows){
            [self.customAlternatingBGColor setFill];
        }
        else{
            [[NSColor whiteColor] setFill];
        }
        NSRectFill([self rectOfRow:row]);
    }
    [super drawRow:row clipRect:clipRect];
}

//- (void)highlightSelectionInClipRect:(NSRect)clipRect
//{
//    NSColor *evenColor = self.customAlternatingBGColor;
//    NSColor *oddColor  = [NSColor whiteColor];
//    
//    float rowHeight = [self rowHeight] + [self intercellSpacing].height;
//    NSRect visibleRect = [self visibleRect];
//    NSRect highlightRect;
//    
//    highlightRect.origin = NSMakePoint(
//                                       NSMinX(visibleRect),
//                                       (int)(NSMinY(clipRect)/rowHeight)*rowHeight);
//    highlightRect.size = NSMakeSize(
//                                    NSWidth(visibleRect),
//                                    rowHeight - [self intercellSpacing].height);
//    
//    while (NSMinY(highlightRect) < NSMaxY(clipRect))
//    {
//        NSRect clippedHighlightRect
//        = NSIntersectionRect(highlightRect, clipRect);
//        int row = (int)
//        ((NSMinY(highlightRect)+rowHeight/2.0)/rowHeight);
//        NSColor *rowColor
//        = (0 == row % 2) ? evenColor : oddColor;
//        [rowColor set];
//        NSRectFill(clippedHighlightRect);
//        highlightRect.origin.y += rowHeight;
//    }
//    
//    [super highlightSelectionInClipRect: clipRect];
//}

@end
