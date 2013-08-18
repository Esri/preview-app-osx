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

#import "EAFTableRowView.h"
#import "NSColor+EAFAdditions.h"

@implementation EAFTableRowView

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.alternatingRowColor = [NSColor eaf_lighterGrayColor];
    }
    return self;
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    if (self.row % 2) {
        [self.alternatingRowColor set];
    }
    else {
        [self.backgroundColor set];
    }
    NSRectFill(dirtyRect);
}

@end
