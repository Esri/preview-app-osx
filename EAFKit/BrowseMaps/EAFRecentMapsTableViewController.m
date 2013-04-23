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
#import "EAFRecentMapsTableViewController.h"
#import "EAFHyperlinkButton.h"
#import "EAFAppContext.h"
#import "EAFStack.h"

@interface EAFRecentMapsTableViewController ()<AGSPortalItemDelegate>
@property (nonatomic, strong) AGSPortalItem *recentPortalItem;
@end

@implementation EAFRecentMapsTableViewController


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithTitle:(NSString *)title portal:(AGSPortal *)portal {
    self = [super initWithTitle:title contentType:EAFPortalContentTypeRecentMaps portal:portal queryParams:nil];
    if (self) {
        NSArray *visibleItems = [[[EAFAppContext sharedAppContext] recentMaps] allObjects];
        [self addPortalContent:visibleItems];
        [self updateVisibleItems];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recentMapsChanged:) name:EAFAppContextDidChangeRecentMaps object:[EAFAppContext sharedAppContext]];
    }
    return self;
}

#pragma mark -
#pragma mark NSTableViewDelegate

- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // do this to make table view always have 'maxVisibleItems' rows
    if (row >= self.visibleItems.count) {
        return nil;
    }
    EAFHyperlinkButton *btn = [[EAFHyperlinkButton alloc] initWithFrame:[[tableView cell] bounds]];
    [btn setTarget:self];
    [btn setTag:row];
    [btn setLineBreakMode:NSLineBreakByTruncatingTail];
    
    NSDictionary *iteminfo = self.visibleItems[row];
    NSString *title = [iteminfo objectForKey:@"title"];
    [btn setTitle:title];
    
    [[btn cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [btn setAction:@selector(cellClicked:)];
    return btn;

}

#pragma mark -
#pragma mark Actions

- (void)cellClicked:(id)sender {
    NSButton *btn = (NSButton*)sender;
    NSDictionary *iteminfo = self.visibleItems[btn.tag];
    NSString *itemid = [iteminfo objectForKey:@"itemid"];
    self.recentPortalItem = [[AGSPortalItem alloc] initWithPortal:self.portal itemId:itemid];
    self.recentPortalItem.delegate = self;
}

- (void)recentMapsChanged:(NSNotification*)note {
    //
    // since we just get notified if the recent maps change -- and we only ever have 10
    // just remove the existing content and re-add the current visible items
    //
    // also, since it's possible one item falls off when another is added, we need to
    // explicitly set the current items.
    NSArray *visibleItems = [[[EAFAppContext sharedAppContext] recentMaps] allObjects];
    [self removeAllPortalContent];
    [self addPortalContent:visibleItems];
    [self updateVisibleItems];
}

#pragma mark -
#pragma mark AGSPortalItemDelegate

- (void)portalItem:(AGSPortalItem *)portalItem didFailToLoadWithError:(NSError *)error {
}

- (void)portalItemDidLoad:(AGSPortalItem *)portalItem {
    if ([self.delegate respondsToSelector:@selector(rmtvc:wantsToOpenPortalItem:)]) {
        [self.delegate rmtvc:self wantsToOpenPortalItem:portalItem];
    }

}

@end
