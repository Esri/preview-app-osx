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

#import "EAFBookmarkItemCellView.h"
#import "EAFAppContext.h"

@implementation EAFBookmarkItemCellView

-(void)awakeFromNib{
}

-(void)setBookmark:(AGSWebMapBookmark *)bookmark{
    _bookmark = bookmark;
    if (!_bookmark){
        return;
    }
    self.titleTextField.stringValue = _bookmark.name;
    self.locationTextField.stringValue = [_bookmark.extent.center degreesMinutesSecondsStringWithNumDigits:2];
    self.thumbImageView.image = [NSImage imageNamed:@"pin-bookmark21x34"];
    
    if ([[EAFAppContext sharedAppContext].userBookmarks containsObject:_bookmark]){
        [self.deleteButton setHidden:NO];
    }
    else{
        [self.deleteButton setHidden:YES];
    }
}

-(void)deleteButtonClicked:(id)sender{
    NSMutableArray *bookmarks = [NSMutableArray arrayWithArray:[EAFAppContext sharedAppContext].userBookmarks];
    [bookmarks removeObject:_bookmark];
    [EAFAppContext sharedAppContext].userBookmarks = bookmarks;
}

@end
