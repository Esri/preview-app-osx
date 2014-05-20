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

#import "EAFBookmarksViewController.h"
#import "EAFAppContext.h"
#import "EAFDefines.h"
#import "EAFStatusViewController.h"
#import "EAFBookmarkItemCellView.h"
#import "EAFTableRowView.h"
#import "AGSGeometryEngine+EAFAdditions.h"
#import "NSColor+EAFAdditions.h"
#import "NSViewController+EAFAdditions.h"

@interface EAFBookmarksViewController () <NSTableViewDelegate, NSTableViewDataSource, AGSLayerCalloutDelegate>{
    NSArray *_bookmarks;
    AGSWebMapBookmark *_selectedBookmark;
    id __unsafe_unretained _target;
    SEL _action;
    AGSGraphicsLayer *_bookmarksLayer;
    AGSWebMap *_webMap;
    BOOL _activated;
    EAFStatusViewController *_statusVC;
}
@end

@implementation EAFBookmarksViewController

-(void)dealloc{
    [[EAFAppContext sharedAppContext] removeObserver:self forKeyPath:@"userBookmarks"];
}

-(id)init{
    return [self initWithNibName:@"EAFBookmarksViewController" bundle:nil];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[EAFAppContext sharedAppContext] addObserver:self forKeyPath:@"userBookmarks" options:NSKeyValueObservingOptionNew context:nil];
        _bookmarksLayer = [AGSGraphicsLayer graphicsLayer];
        _bookmarksLayer.name = @"Bookmarks";
        _bookmarksLayer.visible = NO;
        [[EAFAppContext sharedAppContext].mapView addMapLayer:_bookmarksLayer];
        
//        NSMutableSet *exclude = [NSMutableSet setWithSet:[EAFAppContext sharedAppContext].mapContentsTree.excludeList];
//        [exclude addObject:_bookmarksLayer.name];
//        [EAFAppContext sharedAppContext].mapContentsTree.excludeList = exclude;
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"userBookmarks"]){
        [self refreshBookmarks];
    }
}

-(void)refreshBookmarks{
    NSArray *webmapBookmarks = [EAFAppContext sharedAppContext].webMap.bookmarks;
    NSArray *userBookmarks = [EAFAppContext sharedAppContext].userBookmarks;
    NSMutableArray *bookmarks = [NSMutableArray arrayWithArray:webmapBookmarks];
    [bookmarks addObjectsFromArray:userBookmarks];
    _bookmarks = [bookmarks copy];
    
    [self addBookmarksAsGraphics];
    [self.tableView reloadData];
}

-(void)setupUI{
    
    // no results show status vc
    if (!_bookmarks.count){
        [self showStatusVC];
        return;
    }

    // if results show table view
    [_statusVC.view setHidden:YES];
    [self.tableView setHidden:NO];
}

-(void)showStatusVC{
    if (!_statusVC){
        _statusVC = [[EAFStatusViewController alloc]init];
        [_statusVC view];
        [_statusVC eaf_addToAndCenterInContainer:self.view];
    }
    _statusVC.messageLabel.stringValue = @"There are no bookmarked locations";
    [_statusVC.view setHidden:NO];
    [self.tableView setHidden:YES];
}

-(void)addBookmarkAsGraphic:(AGSWebMapBookmark*)bkmk sym:(AGSSymbol*)sym{
    AGSGraphic *g = [AGSGraphic graphicWithGeometry:bkmk.extent.center symbol:sym attributes:nil];
    [g setAttribute:bkmk.name forKey:@"name"];
    NSString *locString = [AGSGeometryEngine eaf_DMSForPoint:bkmk.extent.center];
    //        AGSPoint *wgs84Point = (AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:g.geometry toSpatialReference:[AGSSpatialReference wgs84SpatialReference]];
    //        NSString *locString = [NSString stringWithFormat:@"%.3f, %.3f", wgs84Point.x, wgs84Point.y];
    [g setAttribute:locString forKey:@"location"];
    [_bookmarksLayer addGraphic:g];
    _bookmarksLayer.calloutDelegate = self;
}

-(void)addBookmarksAsGraphics{
    [_bookmarksLayer removeAllGraphics];
    AGSPictureMarkerSymbol *sym = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[NSImage imageNamed:@"pin-bookmark21x34"]];
    sym.offset = CGPointMake(0, 15);
    for (AGSWebMapBookmark *bkmk in [EAFAppContext sharedAppContext].webMap.bookmarks){
        [self addBookmarkAsGraphic:bkmk sym:sym];
    }
    for (AGSWebMapBookmark *bkmk in [EAFAppContext sharedAppContext].userBookmarks){
        [self addBookmarkAsGraphic:bkmk sym:sym];
    }
}

-(void)activate{
    _activated = YES;

    // we have to do this in case somebody adds bookmarks to the webmap
    // from within the app, without changing the app:
    [self refreshBookmarks];
    // now just make the layer visible
    _bookmarksLayer.visible = YES;
    
    [self setupUI];
}

-(void)deactivate{
    _activated = NO;
    _bookmarksLayer.visible = NO;
    [[EAFAppContext sharedAppContext].mapView.callout dismiss];
}

-(NSArray*)bookmarks{
    return _bookmarks;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return _bookmarks.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row >= _bookmarks.count){
        return nil;
    }
    if (_bookmarks.count == 0){
        return nil;
    }
    
    EAFBookmarkItemCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if (!result) {
        result = [[EAFBookmarkItemCellView alloc] initWithFrame:NSMakeRect(0, 0, 100, 50)];
        result.identifier = tableColumn.identifier;
    }
    
    result.bookmark = [_bookmarks objectAtIndex:row];
    
    return result;
}

- (NSTableRowView*)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    EAFTableRowView *trv = [[EAFTableRowView alloc] initWithFrame:NSZeroRect];
    trv.row = row;
    return trv;
}

-(IBAction)tableViewAction:(id)sender{
    
    if (self.tableView.selectedRow >= _bookmarks.count){
        return;
    }
    
    self.selectedBookmark = [_bookmarks objectAtIndex:self.tableView.selectedRow];
    EAFSuppressClangPerformSelectorLeakWarning([self.target performSelector:self.action withObject:self]);
    
    [[EAFAppContext sharedAppContext].mapView zoomToEnvelope:self.selectedBookmark.extent animated:YES];
    AGSGraphic *graphic = [_bookmarksLayer.graphics objectAtIndex:self.tableView.selectedRow];
    [[EAFAppContext sharedAppContext].mapView.callout showCalloutAtPoint:self.selectedBookmark.extent.center forFeature:graphic layer:graphic.layer animated:YES];
}

#pragma mark AGSLayerCalloutDelegate

-(BOOL)callout:(AGSCallout *)callout willShowForFeature:(id<AGSFeature>)feature layer:(AGSLayer<AGSHitTestable> *)layer mapPoint:(AGSPoint *)mapPoint {
    callout.title = [(AGSGraphic*)feature attributeAsStringForKey:@"name"];
    callout.detail = [(AGSGraphic*)feature attributeAsStringForKey:@"location"];
    return YES;
}

@end
