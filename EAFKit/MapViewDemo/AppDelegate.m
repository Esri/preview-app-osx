// Copyright 2013 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm

#import "AppDelegate.h"
#import "EAFKit.h"

@interface AppDelegate () <AGSPortalDelegate, AGSWebMapDelegate, AGSMapViewTouchDelegate>{
    AGSPortal *_portal;
    AGSWebMap *_webmap;
    EAFTOCViewController *_tocVC;
    NSViewController *_lastVCShown;
    EAFPopupManagerViewController *_popupMgrVC;
    EAFBasemapsViewController *_basemapsVC;
    NSPopover *_popover;
    EAFFindPlacesViewController *_findVC;
    EAFFindPlacesResultsViewController *_findResultsVC;
    EAFMeasureViewController *_measureVC;
}
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void)awakeFromNib{
    [EAFAppContext sharedAppContext].mapView = _mapView;
    _mapView.touchDelegate = self;
    
    _portal = [[AGSPortal alloc]initWithURL:[NSURL URLWithString:@"http://www.arcgis.com"] credential:nil];
    _portal.delegate = self;
    
    _findVC = [[EAFFindPlacesViewController alloc]init];
    [_findVC eaf_addToContainerWithConstraints:_findContainer];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didFindPlaces:) name:EAFFindPlacesViewControllerDidFindPlacesNotification object:_findVC];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didClearSearch:) name:EAFFindPlacesViewControllerDidClearSearchNotification object:_findVC];
}

#pragma mark notification handlers

-(void)didFindPlaces:(NSNotification*)note{
    if (!_findResultsVC){
        _findResultsVC = [[EAFFindPlacesResultsViewController alloc]init];
    }
    _findResultsVC.results = _findVC.results;
    [self showInLeftContainer:_findResultsVC];
}

-(void)didClearSearch:(NSNotification*)note{
    _findResultsVC.results = nil;
}

#pragma mark view swapping

-(void)showInLeftContainer:(NSViewController*)vc{
    if ([_lastVCShown respondsToSelector:@selector(deactivate)]){
        id deac = _lastVCShown;
        [deac deactivate];
    }
    if (_lastVCShown){
        [_lastVCShown.view removeFromSuperview];
    }
    _lastVCShown = vc;
    if ([_lastVCShown respondsToSelector:@selector(activate)]){
        id activ = _lastVCShown;
        [activ activate];
    }
    [vc eaf_addToContainerWithConstraints:_leftContainer];
}

#pragma mark portal delegate

-(void)portalDidLoad:(AGSPortal *)portal{
    [EAFAppContext sharedAppContext].portal = _portal;
    _webmap = [AGSWebMap webMapWithItemId:@"1966ef409a344d089b001df85332608f" portal:_portal];
    _webmap.delegate = self;
}

#pragma mark webmap delegate

-(void)webMapDidLoad:(AGSWebMap *)webMap{
    [EAFAppContext sharedAppContext].webMap = _webmap;
    [_webmap openIntoMapView:_mapView];
}

-(void)didOpenWebMap:(AGSWebMap *)webMap intoMapView:(AGSMapView *)mapView{
    [self contentsAction:nil];
}

#pragma mark mapview touch delegate

-(void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics{
    
    if (![_webmap hasPopupsDefined]){
        return;
    }
    
    if (!_popupMgrVC){
        _popupMgrVC  = [[EAFPopupManagerViewController alloc]init];
    }
    
    if (![_popupMgrVC fetchPopupsForPoint:mappoint]){
        return;
    }
    
    [self showInLeftContainer:_popupMgrVC];
}

#pragma mark actions

- (IBAction)contentsAction:(id)sender {
    if (!_tocVC){
        _tocVC = [[EAFTOCViewController alloc]init];
    }
    [self showInLeftContainer:_tocVC];
}

- (IBAction)basemapsAction:(NSButton *)sender {
    if (!_basemapsVC){
        _basemapsVC = [[EAFBasemapsViewController alloc]init];
    }
    _popover = [[NSPopover alloc]init];
    _popover.behavior = NSPopoverBehaviorTransient;
    _popover.contentViewController = _basemapsVC;
    [_popover showRelativeToRect:sender.bounds ofView:sender preferredEdge:NSMaxYEdge];
}

- (IBAction)measureAction:(id)sender {
    if (!_measureVC){
        _measureVC = [[EAFMeasureViewController alloc]init];
    }
    [self showInLeftContainer:_measureVC];
}

@end


