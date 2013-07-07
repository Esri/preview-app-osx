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
#import "EAFRoundedView.h"
#import "EAFTitledView.h"
#import "EAFHyperlinkButton.h"
#import "EAFAppContext.h"
#import "EAFStack.h"

@interface EAFPortalContentTableViewController ()<NSTableViewDataSource, NSTableViewDelegate, AGSPortalItemDelegate>
@property (nonatomic, strong) NSTableView *tableView;
@end

@implementation EAFPortalContentTableViewController

- (id)initWithTitle:(NSString *)title portal:(AGSPortal *)portal {
    return [self initWithTitle:title contentType:EAFPortalContentTypeGeneric portal:portal queryParams:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    [super awakeFromNib];
        
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view.frame = NSMakeRect(self.view.frame.origin.x, self.view.frame.origin.y, 200, 235);

    
    // use zero rect since we will add constraints to the table view for sizing
    self.tableView = [[NSTableView alloc] initWithFrame:NSZeroRect];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setColumnAutoresizingStyle:NSTableViewNoColumnAutoresizing];
    [self.tableView setAllowsColumnResizing:NO];


    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"ColumnIdentifier"];
    [column setMaxWidth:187];
    [column setMinWidth:187];
    [column setResizingMask:NSTableColumnAutoresizingMask];
    [self.tableView addTableColumn:column];

    [self.titledView.contentView addSubview:self.tableView];
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    //
    // pad our table view by 5 pixels on all sides
    NSTableView *tv = self.tableView;   
    [self.titledView.contentView addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"|-5-[tv]-5-|" options:0 metrics:nil
                               views:NSDictionaryOfVariableBindings(tv)]];
    [self.titledView.contentView addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-5-[tv]-5-|" options:0 metrics:nil
                               views:NSDictionaryOfVariableBindings(tv)]];


    self.titledView.titleFont = [NSFont boldSystemFontOfSize:12.0f];
    [self.titledView.nextButton setTitle:@">"];
    [self.titledView.prevButton setTitle:@"<"];
    self.titledView.showPageInfo = NO;
    
}

#pragma mark -
#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    // do this to make table view always 10 rows
    return self.visibleItems.count < self.maxVisibleItems ? self.maxVisibleItems : self.visibleItems.count;
}

#pragma mark -
#pragma mark NSTableViewDelegate

- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // do this to make table view always 'maxVisibleItems' rows
    if (row >= self.visibleItems.count) {
        return nil;
    }
    EAFHyperlinkButton *btn = [[EAFHyperlinkButton alloc] initWithFrame:[[tableView cell] bounds]];
    [btn setTarget:self];
    [btn setTag:row];
    [btn setLineBreakMode:NSLineBreakByTruncatingTail];

    [btn setTitle:@"default"];
    
    [[btn cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    [btn setAction:@selector(cellClicked:)];
    return btn;
}

#pragma mark -
#pragma mark Actions

- (void)cellClicked:(id)sender {
    //This is called to get around folder/group staying highlighted when on main gallery page and a cell is clicked
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Overrides

- (void)reloadData {
    [self.tableView reloadData];
}

@end
