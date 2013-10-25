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

#import "EAFBasemapItemCellView.h"
#import "EAFRoundedImageView.h"

@interface EAFBasemapItemCellView () {
    
}

@end

@implementation EAFBasemapItemCellView

@synthesize portalItem = _portalItem;
@synthesize detailTextField = _detailTextField;

-(void)awakeFromNib{
    //NSLog(@"Imageview: %@", self.imageView);
    EAFRoundedImageView *riv = (EAFRoundedImageView*)self.imageView;
    riv.xRadius = 4;
    riv.yRadius = 4;
    [riv setWantsLayer:YES];
    riv.layer.borderColor = [NSColor lightGrayColor].CGColor;
    riv.layer.borderWidth = 1.0f;
    riv.layer.cornerRadius = 4;
    
    // turn the topline view off for now..
    [self.topLineView setHidden:YES];
//    [self.topLineView setWantsLayer:YES];
//    self.topLineView.layer.backgroundColor = [[NSColor whiteColor] colorWithAlphaComponent:.25].CGColor;
}

-(void)setPortalItem:(AGSPortalItem*)item{
    _portalItem = item;
    
    if (item){
        item.delegate = self;
        self.textField.stringValue = item.title;
        self.imageView.image = item.thumbnail;
        if (!item.thumbnail){
            [item fetchThumbnail];
        }
        if (item.snippet) {
            self.detailTextField.stringValue = item.snippet;
        }
        else {
            self.detailTextField.stringValue = @"";
        }
    }
}

- (void) portalItem:(AGSPortalItem *)	portalItem
          operation:(NSOperation *)	op
  didFetchThumbnail:(NSImage *)	thumbnail	
{
    self.imageView.image = portalItem.thumbnail;
}
- (void)dealloc {
    self.portalItem = nil;
    self.imageView = nil;
    _detailTextField = nil;
}

@end
