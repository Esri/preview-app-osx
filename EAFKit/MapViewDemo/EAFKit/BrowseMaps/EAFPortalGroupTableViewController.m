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
#import "EAFPortalGroupTableViewController.h"
#import "EAFHyperlinkButton.h"

@interface EAFPortalGroupTableViewController ()

@end

@implementation EAFPortalGroupTableViewController

- (id)initWithTitle:(NSString *)title portal:(AGSPortal *)portal {
    return [super initWithTitle:title contentType:EAFPortalContentTypeGroups portal:portal queryParams:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if (self.contentType == EAFPortalContentTypeGroups) {
        NSString *username = self.portal.user.username;
        if (username) {
            self.totalResults = self.portal.user.groups.count;
            [self addPortalContent:self.portal.user.groups];
            [self updateVisibleItems];
        }
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
    
    AGSPortalGroup *group = [self.visibleItems objectAtIndex:row];
    [btn setTitle:group.title];
    
    [[btn cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [btn setAction:@selector(cellClicked:)];
    return btn;
}

#pragma mark -
#pragma mark Actions

- (void)cellClicked:(id)sender {
    NSButton *btn = (NSButton*)sender;
    AGSPortalGroup *portalGroup = self.visibleItems[btn.tag];
    if ([self.delegate respondsToSelector:@selector(pgtvc:wantsToOpenPortalGroup:)]) {
        [self.delegate pgtvc:self wantsToOpenPortalGroup:portalGroup];
    }
    
    //This is called to get around folder/group staying highlighted when on main gallery page and a cell is clicked
    [self reloadData];
}
@end
