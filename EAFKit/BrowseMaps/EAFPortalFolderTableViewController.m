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

#import "EAFPortalContentViewController.h"
#import "EAFPortalContentViewController+Internal.h"
#import "EAFPortalContentTableViewController.h"
#import "EAFPortalFolderTableViewController.h"
#import "EAFHyperlinkButton.h"

@interface EAFPortalFolderTableViewController ()

@end

@implementation EAFPortalFolderTableViewController

- (id)initWithTitle:(NSString *)title portal:(AGSPortal *)portal {
    return [super initWithTitle:title contentType:EAFPortalContentTypeFolders portal:portal queryParams:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.queryOp = [self.portal.user fetchContent];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foundFolders:) name:AGSPortalDidFetchPortalUserContentNotification object:self.portal.user];
}

- (void)foundFolders:(NSNotification*)note {
    NSDictionary *userInfo = [note userInfo];
    NSOperation *op = [userInfo valueForKey:@"operation"];
    if (self.queryOp == op) {
        NSArray *folders = [userInfo ags_safeValueForKey:@"folders"];
        
        self.totalResults = folders.count;
        
        [self addPortalContent:folders];
        [self updateVisibleItems];
    }
}

#pragma mark -
#pragma mark NSTableViewDelegate

- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // do this to make table view always 10 rows
    if (row >= self.visibleItems.count) {
        return nil;
    }
    EAFHyperlinkButton *btn = [[EAFHyperlinkButton alloc] initWithFrame:[[tableView cell] bounds]];
    [btn setTarget:self];
    [btn setTag:row];
    [btn setLineBreakMode:NSLineBreakByTruncatingTail];

    AGSPortalFolder *folder = [self.visibleItems objectAtIndex:row];
    [btn setTitle:folder.title];

    [[btn cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [btn setAction:@selector(cellClicked:)];
    return btn;
}

- (void)cellClicked:(id)sender {
    NSButton *btn = (NSButton*)sender;
    AGSPortalFolder *folder = self.visibleItems[btn.tag];
    if ([self.delegate respondsToSelector:@selector(pftvc:wantsToOpenPortalFolder:)]) {
        [self.delegate pftvc:self wantsToOpenPortalFolder:folder];
    }
    
    //This is called to get around folder/group staying highlighted when on main gallery page and a cell is clicked
    [self reloadData];
}
@end
