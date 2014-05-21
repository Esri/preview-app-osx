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

#import "EAFBasemapsViewController.h"
#import "EAFBasemapItemCellView.h"
#import "EAFAppContext.h"
#import "EAFDefines.h"
#import "EAFRoundedView.h"
#import "EAFGradientView.h"
#import "NSGradient+EAFAdditions.h"
#import "NSColor+EAFAdditions.h"
#import "EAFTableRowView.h"

@interface EAFBasemapsViewController ()<NSTableViewDelegate, NSTableViewDataSource, AGSWebMapDelegate>{
    AGSPortal *_portal;
    NSOperation *_basemapGalleryGroupQueryOp;
    NSOperation *_basemapItemsQueryOp;
    NSMutableArray *_extraLayers;
    AGSPoint *_center;
    double _res;
    double _angle;
    NSMutableDictionary *_itemsToBasemaps;
}

@property (nonatomic, strong) AGSWebMap *selectedBasemapWebmap;

@end

@implementation EAFBasemapsViewController

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(id)init{
    return [self initWithNibName:@"EAFBasemapsViewController" bundle:nil];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // get process started
        [self portalDidChange:nil];
    }
    
    return self;
}

-(void)awakeFromNib{
}

-(void)portalDidChange:(NSNotification*)note{
    
    if (_portal != [EAFAppContext sharedAppContext].portal){
        _portal = [EAFAppContext sharedAppContext].portal;
        
        // remove self as observer then re-add all notifications
        [[NSNotificationCenter defaultCenter]removeObserver:self];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(portalDidChange:) name:EAFAppContextDidChangePortal object:[EAFAppContext sharedAppContext]];
        
        // cancel any ops
        [_basemapGalleryGroupQueryOp cancel];
        [_basemapItemsQueryOp cancel];
        
        // add notifications
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(portalDidFindGroups:) name:AGSPortalDidFindGroupsNotification object:_portal];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(portalDidFindItems:) name:AGSPortalDidFindItemsNotification object:_portal];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(portalDidFailToFindGroups:) name:AGSPortalDidFailToFindGroupsNotification object:_portal];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(portalDidFailToFindItems:) name:AGSPortalDidFailToFindItemsNotification object:_portal];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(webMapOpenedIntoMap:) name:AGSWebMapDidOpenIntoMapViewNotification object:nil];
        
        // kick off query
        if (_portal.loaded){
            _basemapGalleryGroupQueryOp = [_portal findGroupsWithQueryParams:[AGSPortalQueryParams queryParamsWithQuery:_portal.portalInfo.basemapGalleryGroupQuery]];
        }
        else{
            // otherwise wait until it loads
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(portalDidLoad:) name:AGSPortalDidLoadNotification object:_portal];
        }
    }
    else if (!_portal && ![EAFAppContext sharedAppContext].portal){
        // remove self as observer then re-add all notifications
        [[NSNotificationCenter defaultCenter]removeObserver:self];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(portalDidChange:) name:EAFAppContextDidChangePortal object:[EAFAppContext sharedAppContext]];
    }
}

-(void)portalDidLoad:(NSNotification*)note{
    _basemapGalleryGroupQueryOp = [_portal findGroupsWithQueryParams:[AGSPortalQueryParams queryParamsWithQuery:_portal.portalInfo.basemapGalleryGroupQuery]];
}

#pragma mark portal notifications

-(void)portalDidFindGroups:(NSNotification*)note{
    NSOperation *op = [note.userInfo valueForKey:@"operation"];
    if (op == _basemapGalleryGroupQueryOp){
        AGSPortalQueryResultSet *resultSet = [note.userInfo valueForKey:@"resultSet"];
        AGSPortalGroup *group = [resultSet.results objectAtIndex:0];
        AGSPortalQueryParams *qp = [AGSPortalQueryParams queryParamsForItemsOfType:AGSPortalItemTypeWebMap inGroup:group.groupId];
        qp.limit = 20;
        _basemapItemsQueryOp = [_portal findItemsWithQueryParams:qp];
    }
}

-(void)portalDidFindItems:(NSNotification*)note{

    NSOperation *op = [note.userInfo valueForKey:@"operation"];
    if (op == _basemapItemsQueryOp){
        _itemsToBasemaps = [NSMutableDictionary dictionary];
        
        AGSPortalQueryResultSet *resultSet = [note.userInfo valueForKey:@"resultSet"];
        _basemaps = resultSet.results;
        
        AGSWebMapBaseMap *currentWebMapBaseMap = [EAFAppContext sharedAppContext].webMap.baseMap;
        int idx = 0;
        int selectedIndex = -1;
        for (AGSPortalItem *portalItem in _basemaps) {
            if ([portalItem.title isEqualToString:currentWebMapBaseMap.title]) {
                // found the current basemap
                selectedIndex = idx;
                break;
            }
            idx++;
        }
        [self.tableView reloadData];
        
        //
        // if the current webmap is using one of our basemaps, let's select it
        if (selectedIndex > -1) {
            NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:selectedIndex];
            [self.tableView selectRowIndexes:indexSet byExtendingSelection:NO];
        }
    }
}

-(void)portalDidFailToFindGroups:(NSNotification*)note{
}

-(void)portalDidFailToFindItems:(NSNotification*)note{
}


#pragma mark table view

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return _basemaps.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row >= _basemaps.count){
        return nil;
    }
    if (_basemaps.count == 0){
        return nil;
    }
    
    EAFBasemapItemCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if (!result) {
        result = [[EAFBasemapItemCellView alloc] initWithFrame:NSMakeRect(0, 0, 100, 50)];
        result.identifier = tableColumn.identifier;
    }

    AGSPortalItem *item = [_basemaps objectAtIndex:row];
    result.portalItem = item;    
    return result;
}

//
// implement this so we can have alternating row colors and still allow selection
- (NSTableRowView*)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    EAFTableRowView *trv = [[EAFTableRowView alloc] initWithFrame:NSZeroRect];
    trv.row = row;
    return trv;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    
    self.selectedBasemap = [_basemaps objectAtIndex:_tableView.selectedRow];
    
    self.selectedBasemapWebmap = _itemsToBasemaps[self.selectedBasemap.itemId];
    if (self.selectedBasemapWebmap){
        [self switchToSelectedBasemap];
    }
    else{
        self.selectedBasemapWebmap = [AGSWebMap webMapWithPortalItem:self.selectedBasemap];
        self.selectedBasemapWebmap.delegate = self;
    }
    
    EAFSuppressClangPerformSelectorLeakWarning([_target performSelector:_action withObject:self]);
}

-(void)webMapDidLoad:(AGSWebMap *)webMap{
    // cache it so we don't have to reload it every time
    _itemsToBasemaps[webMap.portalItem.itemId] = webMap;
    
    if (webMap != self.selectedBasemapWebmap){
        return;
    }
    
    [self switchToSelectedBasemap];
}

-(void)switchToSelectedBasemap{
    [[EAFAppContext sharedAppContext].webMap switchBaseMapOnMapView:self.selectedBasemapWebmap.baseMap];
}

@end
