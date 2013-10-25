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

#import "MapViewController.h"
#import "EAFKit.h"
#import "SidePanelViewController.h"

#define EAFMinMapWidth 300


@interface MapViewController () <AGSWebMapDelegate, AGSMapViewTouchDelegate, NSSplitViewDelegate, SidePanelViewControllerDelegate, NSMenuDelegate>{
    AGSPortalItem *_portalItem;
    AGSWebMap *_webMap;
    SidePanelViewController *_sidePanelVC;
    EAFWebMapLayerCredentialsViewController *_webMapLayerCredVC;
    NSSet *_webMapFeatureLayers;
    NSWindow *_compassWindow;
    EAFImageView *_compassIv;
//    BOOL _sidePanelCollapsed;
    CGFloat _lastSliderPosition;
}
@property (nonatomic, strong) NSViewAnimation *currentAnimation;
@end

@implementation MapViewController

-(id)init{
    return [self initWithNibName:@"MapViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
//        [AGSApplication ags_setNetworkActivityDelegate:self];
        _findVC = [[EAFFindPlacesViewController alloc]init];
//        _sidePanelVC = [[SidePanelViewController alloc]init];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)awakeFromNib{
    _mapView.allowRotationByPinching = YES;
    _mapView.showMagnifierOnTapAndHold = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapZoomed:) name:AGSMapViewDidEndZoomingNotification object:_mapView];
    
    [_mapView addObserver:self forKeyPath:@"rotationAngle" options:NSKeyValueObservingOptionNew context:nil];
    _mapView.backgroundColor = [NSColor eaf_darkGrayBlueColor];
    _mapView.gridLineWidth = 1.0f;
    _mapView.gridLineColor = [NSColor eaf_grayBlueColor];
    
    [_leftContainer setWantsLayer:YES];
    _leftContainer.layer.backgroundColor = [NSColor eaf_lighterGrayColor].CGColor;
//    [_sidePanelVC addToContainer:_leftContainer];
    
    NSWindow *wnd = [NSApplication sharedApplication].mainWindow;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parentWindowResized:) name:NSWindowDidResizeNotification object:wnd];
    
    
    [self.copyrightBtn setTitle:@"Attribution"];
    self.copyrightBtn.font = [NSFont systemFontOfSize:10];
    [self.copyrightBtn setTextColor:[NSColor blackColor]];
    [self.copyrightBtn setTextHoverColor:[NSColor eaf_darkGrayBlueColor]];
    [self.copyrightBtn setAlignment:NSRightTextAlignment];
    [self.copyrightBtn setTarget:self];
    [self.copyrightBtn setAction:@selector(copyrightClicked:)];
}

-(void)compassClicked:(id)sender{
    [_mapView setRotationAngle:0.0f animated:YES];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"rotationAngle"]){
        _compassIv.angle = _mapView.rotationAngle;
        [_compassIv setHidden:(_mapView.rotationAngle == 0)];
    }
}

-(void)parentWindowResized:(id)obj{
    NSWindow *wnd = _compassWindow.parentWindow;
    
    CGRect f = wnd.frame;
    f = CGRectMake(f.origin.x + f.size.width, f.origin.y + f.size.height, 25, 25);
    f = CGRectOffset(f, -42, -90);
    [_compassWindow setFrame:f display:YES];
}

-(void)mapZoomed:(NSNotification*)note{
    [self performSelectorOnMainThread:@selector(mapZoomedMT) withObject:nil waitUntilDone:NO];
}

-(void)mapZoomedMT{
    NSNumberFormatter *nf = [[NSNumberFormatter alloc]init];
    nf.maximumFractionDigits = 0;
    nf.usesGroupingSeparator = YES;
    nf.groupingSize = 3;
    self.mapScaleLabel.stringValue = [NSString stringWithFormat:@"Map Scale  -  1 : %@", [nf stringFromNumber:@(_mapView.mapScale)]];
}

-(void)setSearchContainerView:(NSView *)searchContainerView{
    _searchContainerView = searchContainerView;
    [_findVC.view removeFromSuperview];
    [_findVC eaf_addToAndCenterInContainer:_searchContainerView];
}

-(void)setCollectFeatureButton:(NSPopUpButton *)collectFeatureButton{
    _collectFeatureButton = collectFeatureButton;
    [_collectFeatureButton setTarget:self];
    [_collectFeatureButton setAction:@selector(didSelectFeatureType:)];
    [[_collectFeatureButton menu] setDelegate:self];
    [self showCollectFeatureButtonIfNecessary];
    [self populateCollectFeatureButton];
}

-(NSArray *)editableFeatureLayers {
    NSMutableArray *editableFeatureLayers = [NSMutableArray array];
    for (AGSFeatureLayer *featureLayer in [_webMapFeatureLayers allObjects]) {
        //make sure the feature layer is editable and visible.
        //if not, don't display the feature types from that layer
        if (featureLayer.canCreate && [self featureLayerIsVisible:featureLayer]) {
            [editableFeatureLayers addObject:featureLayer];
        }
    }
    
    return [NSArray arrayWithArray:editableFeatureLayers];
}

-(void)activate{
    [_findVC.view setHidden:NO];
    
    if (!_compassWindow){
        NSWindow *wnd = [NSApplication sharedApplication].mainWindow;
        
        CGRect compassRect = CGRectMake(0, 0, 25, 25);
        _compassIv = [[EAFImageView alloc]initWithFrame:compassRect];
        _compassIv.image = [NSImage imageNamed:@"compass25x25"];
        [_compassIv setTarget:self];
        [_compassIv setAction:@selector(compassClicked:)];
        //    [_compassIv setWantsLayer:YES];
        [_compassIv setHidden:(_mapView.rotationAngle == 0)];
        
        _compassWindow = [[NSWindow alloc]initWithContentRect:compassRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        _compassWindow.title = @"Test window";
        _compassWindow.backgroundColor = [NSColor clearColor];
        [_compassWindow setOpaque:NO];
        [_compassWindow.contentView addSubview:_compassIv];
        [wnd addChildWindow:_compassWindow ordered:NSWindowAbove];
        [_compassWindow setParentWindow:wnd];
        
        // position the compass window
        [self parentWindowResized:self];
    }
    
    [_collectFeatureButton setHidden:[[self editableFeatureLayers] count] <= 0];
}

-(void)deactivate{
    [_findVC clearSearch];
    [_findVC.view setHidden:YES];
    [[NSApplication sharedApplication].mainWindow removeChildWindow:_compassWindow];
    [_compassWindow setReleasedWhenClosed:NO];
    [_compassWindow close];
    _compassWindow = nil;
    [_collectFeatureButton setHidden:YES];
}

-(void)openWebMapPortalItem:(AGSPortalItem*)item{
    //
    // when the split view gets created from the NIB -[NSSplitView adjustSubviews]
    // gets called on it, which expands the subviews proportionally and makes
    // our left panel very large, which looks weird.
    //
    // So we set a default position for the divider when the portal item is to be
    // opened
    //[self.splitView setPosition:350 ofDividerAtIndex:0];
    

    [_webMap cancelOpen];
    
    [_sidePanelVC.view removeFromSuperview];
    _sidePanelVC = nil;
    
    [EAFAppContext sharedAppContext].mapView = nil;
    
    _webMap = [AGSWebMap webMapWithPortalItem:item];
    _webMap.delegate = self;
    [_webMap openIntoMapView:_mapView];
    [_mapView enableWrapAround];

}

-(void)didSelectFeatureType:(id)sender {
    NSMenuItem *item = (NSMenuItem *)sender;
//    NSLog(@"menu Item = %@", item.title);
    
    AGSFeatureTemplate *fTemplate = (AGSFeatureTemplate *)[item representedObject];
    NSMenuItem *parentMenuItem = item.parentItem;
    AGSFeatureLayer *fLayer = (AGSFeatureLayer *)[parentMenuItem representedObject];
    AGSGraphic *newFeature = [fLayer featureWithTemplate:fTemplate];
    
    //add new graphic to layer before creating new popup
    [fLayer addGraphic:newFeature];
    
    //Find the popup info associated with the selected feature layer
    AGSPopupInfo *pi =[_webMap popupInfoForFeatureLayer:fLayer];
    //if a specific one doesn't exist, create a default popup
    if (!pi) {
        pi = [AGSPopupInfo popupInfoForGraphic:newFeature];
    }
    
    AGSPopup *popup = [[AGSPopup alloc] initWithGraphic:newFeature popupInfo:pi];
    [_sidePanelVC showPopup:popup editing:YES];
}

-(BOOL)featureLayerIsVisible:(AGSFeatureLayer *)fl
{
    AGSMapView *mapView = _mapView;
    //Check if it observes the minimum scale dependency
    BOOL isVisibleInCurrentScale = ((fl.minScale == 0) ||            //either the layers min scale is 0
                                    (mapView.mapScale <= fl.minScale));  //or the mapview's scale is less than or equal to the minScale
    
    //finally check it is observes the max scale dependency
    isVisibleInCurrentScale = isVisibleInCurrentScale && ((fl.maxScale == 0) ||                //either the layers min scale is 0
                                                          (mapView.mapScale >= fl.maxScale));  //or the mapview's scale is greater than or equal to the minScale
    
    return isVisibleInCurrentScale && fl.visible;
}

-(void)showCollectFeatureButtonIfNecessary {
    //hide button if there are no visible feature layers to edit
    NSArray *editableFeatureLayers = [self editableFeatureLayers];
    [_collectFeatureButton setHidden:[editableFeatureLayers count] <= 0];
}

-(void)populateCollectFeatureButton{
    NSMenuItem *firstItem = [[_collectFeatureButton menu] itemAtIndex:0];
    [_collectFeatureButton removeAllItems];
    [[_collectFeatureButton menu] addItem:firstItem];
    
    if ([_sidePanelVC isEditingPopup]) {
        return;
    }

    NSArray *editableFeatureLayers = [self editableFeatureLayers];
    for (AGSFeatureLayer *featureLayer in editableFeatureLayers)
    {
        if (![self featureLayerIsVisible:featureLayer]) {
            //don't display not visible feature layers
            continue;
        }
        [_collectFeatureButton addItemWithTitle:featureLayer.name];
        NSMenuItem *lastItem = [_collectFeatureButton lastItem];
        [lastItem setRepresentedObject:featureLayer];
        NSMenu *subMenu = [[NSMenu alloc] init];
        NSInteger nTypesCount = featureLayer.types.count;
        if (nTypesCount > 0)
        {
            for (AGSFeatureType *ft in featureLayer.types){
                for (AGSFeatureTemplate *fTemplate in ft.templates) {
                    NSMenuItem *mItem = [[NSMenuItem alloc] initWithTitle:fTemplate.name action:@selector(didSelectFeatureType:) keyEquivalent:@""];
                    [mItem setRepresentedObject:fTemplate];
                    [mItem setTarget:self];
                    [subMenu addItem:mItem];
                }
            }
        }
        else {
            //we have no feature types, # of rows is the template count
            for (AGSFeatureTemplate *fTemplate in featureLayer.templates) {
                NSMenuItem *mItem = [[NSMenuItem alloc] initWithTitle:fTemplate.name action:@selector(didSelectFeatureType:) keyEquivalent:@""];
                [mItem setRepresentedObject:fTemplate];
                [mItem setTarget:self];
                [subMenu addItem:mItem];
            }
        }
        
        if ([subMenu.itemArray count] > 0) {
            //if we have sub items, add the submenu
            [lastItem setSubmenu:subMenu];
        }
    }
}

#pragma menu item validation

- (void)menuNeedsUpdate:(NSMenu *)menu {
    
    [self populateCollectFeatureButton];
}

#pragma mark WebMap Delegate

-(NSString *)bingAppIdForWebMap:(AGSWebMap *)webMap{
#warning RETURN BING ID HERE
    return nil;
}

-(void)webMapDidLoad:(AGSWebMap *)webMap{
}

-(void)webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error{
    
}

-(void)didOpenWebMap:(AGSWebMap *)webMap intoMapView:(AGSMapView *)mapView{

    AGSSpatialReference *sr = mapView.spatialReference;
    NSLog(@"map sr: %@", mapView.spatialReference);
    if (!sr && mapView.mapLayers.count){
        AGSLayer *lyr = [mapView.mapLayers objectAtIndex:0];
        sr = lyr.spatialReference;
        NSLog(@"lyr sr: %@", lyr.spatialReference);
    }
    
    // cache a reference to fls
    NSMutableSet *webMapFLs = [NSMutableSet set];
    for (AGSLayer *l in mapView.mapLayers){
        if ([l isKindOfClass:[AGSFeatureLayer class]]){
            //
            // we don't want the callout to be shown automatically for us,
            // we will display it when we want it
            [(AGSFeatureLayer*)l setAllowCallout:NO];
            [webMapFLs addObject:l];
        }
    }
    _webMapFeatureLayers = [webMapFLs copy];
    
    [EAFAppContext sharedAppContext].webMap = webMap;
    [EAFAppContext sharedAppContext].mapView = mapView;
    mapView.touchDelegate = self;
    
    // if _sidePanelVC is not nil then we don't need to create it. This can occur
    // when it wasn't this view controller that opened the map, but another view,
    // for example the basemaps vc
    if (!_sidePanelVC){
        _sidePanelVC = [[SidePanelViewController alloc]init];
        _sidePanelVC.delegate = self;
        [_sidePanelVC eaf_addToContainer:_leftContainer];
        
        [self showCollectFeatureButtonIfNecessary];
        [self populateCollectFeatureButton];
    }
}

-(void)webMap:(AGSWebMap *)webMap
didFailToLoadLayer:(AGSWebMapLayerInfo *)layerInfo
    baseLayer:(BOOL)baseLayer
    federated:(BOOL)federated
    withError:(NSError *)error{
    
    if (federated && [error ags_isAuthenticationError]) {
        
        if (webMap.credential.username.length > 0){
            // if user IS signed in, skip layer
            //  this is the single sign on experience
            [webMap continueOpenAndSkipCurrentLayer];
        }
        else{
            // if user is NOT signed in, then...
            // ask user if they want to sign in or skip layer
            NSAlert *alert = [NSAlert alertWithMessageText:@"Credentials Required"
                                             defaultButton:@"Login"
                                           alternateButton:@"Skip"
                                               otherButton:nil
                                 informativeTextWithFormat:@"Credentials are required to access the resource:\r\n\r\n%@\r\n\r\nWould you like to login or skip this resource?", [layerInfo.URL absoluteString]];
            
            [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(federatedAndAuthErrorAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        }
    }
    else if ([error ags_isAuthenticationError]) {
        // get credentials from user
        _webMapLayerCredVC = [[EAFWebMapLayerCredentialsViewController alloc]init];
        _webMapLayerCredVC.message = [NSString stringWithFormat:@"Credentials are required to access the resource:\r\n\r\n%@\r\n\r\nWould you like to provie credentials or skip this resource?", [layerInfo.URL absoluteString]];
        _webMapLayerCredVC.target = self;
        _webMapLayerCredVC.action = @selector(webMapLayerCredsVCAction:);
        
        NSPanel *panel = [[NSPanel alloc]initWithContentRect:_webMapLayerCredVC.view.bounds styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:YES];
        panel.contentView = _webMapLayerCredVC.view;
        [NSApp beginSheet:panel modalForWindow:self.view.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
    else if ([error code] == NSURLErrorServerCertificateUntrusted) {
        // ask user if they want to trust host
        NSString *host = [layerInfo.URL host];
        NSAlert *alert = [NSAlert alertWithMessageText:@"Untrusted Host"
                                         defaultButton:@"Skip"
                                       alternateButton:@"Trust"
                                           otherButton:nil
                             informativeTextWithFormat:@"A resource in the Web Map is directed to a host (%@) that is not trusted. Would you like to trust this host (not recommended) or skip the resource (recommended)?", host];
        
        [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(untrustedHostAlertDidEnd:returnCode:contextInfo:) contextInfo:(__bridge_retained void*)host];
    }
    else {
        //skip this layer.
        [webMap continueOpenAndSkipCurrentLayer];
    }
}

-(void)webMapLayerCredsVCAction:(EAFWebMapLayerCredentialsViewController*)credVC{
    if (!credVC.credential){
        // user wants to skip
        [_webMap continueOpenAndSkipCurrentLayer];
    }
    else{
        // user wants to open the layer
        [_webMap continueOpenWithCredential:credVC.credential];
    }
    // clean up the sheet
    [NSApp endSheet:credVC.view.window returnCode:NSOKButton];
    [credVC.view.window orderOut:nil];
    [credVC.view.window close];
    _webMapLayerCredVC = nil;
}

-(void)federatedAndAuthErrorAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
    
    [[alert window]orderOut:nil];
    
    if (returnCode == NSAlertDefaultReturn){
        // user is currently anonymous but has chosen to sign in
        // we cancel, then have them log into the portal (our delegate takes care of that)
        // then eventually the webmap will be re-opened
        [_webMap cancelOpen];
        if ([self.delegate respondsToSelector:@selector(mapViewController:wantsToLoginAndReOpenWebMap:)]){
            [self.delegate mapViewController:self wantsToLoginAndReOpenWebMap:_webMap];
        }
    }
    else if (returnCode == NSAlertAlternateReturn){
        //if skip, [webMap continueOpenAndSkipCurrentLayer]
        [_webMap continueOpenAndSkipCurrentLayer];
    }
}

-(void)untrustedHostAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
    
    [[alert window]orderOut:nil];
    
    if (returnCode == NSAlertDefaultReturn){
        // do not trust, skip
        [_webMap continueOpenAndSkipCurrentLayer];
    }
    else if (returnCode == NSAlertAlternateReturn){
        //if wants to trust
        NSString *host = (__bridge_transfer NSString*)(contextInfo);
        if (host){
            [[NSURLConnection ags_trustedHosts]addObject:host];
        }
        [_webMap continueOpenWithCredential:nil];
    }
}


#pragma mark mapview touch delegate

-(void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics{

    // don't fetch if showing callout for graphics layers
    if (!self.mapView.callout.hidden){
        return;
    }
    
    [_sidePanelVC fetchPopupsForPoint:mappoint];
}

#pragma mark -
#pragma mark NSSplitViewDelegate

//
// constrain the left view to the width of the sidebar plus a small margin
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return CGRectGetWidth(_sidePanelVC.sidebar.bounds) + 5;
}

//
// constrain the right view to be AT LEAST EAFMinMapWidth so it's always visible
- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    return CGRectGetWidth(self.view.bounds) - EAFMinMapWidth;
}

//
// determine whether or not to adjust the size of the subview based on our minimum desired map width
// and our left view
- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
    NSView *leftView = [[splitView subviews] objectAtIndex:0];
    NSView *rightView = [[splitView subviews] objectAtIndex:1];
    //
    // if the view to adjust is the left one and our right one is at least EAFMinMapWidth then DO NOT resize
    if (view == leftView && CGRectGetWidth(rightView.bounds) > EAFMinMapWidth) {
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark SidePanelViewControllerDelegate

- (void)sidePanelViewControllerWantsToSetWidth:(CGFloat)width{
    CGRect f = _leftContainer.frame;
    f.size.width = width;
    [_leftContainer setFrame:f];
}

-(void)sidePanelViewControllerWantsToExpand:(SidePanelViewController *)sidePanelVC {
    if (self.currentAnimation.isAnimating) {
        [self.currentAnimation stopAnimation];
    }
//    [_copyrightBtn setHidden:YES];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        NSMutableDictionary *expandAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [expandAnimationDict setObject:_leftContainer forKey:NSViewAnimationTargetKey];
        NSRect newContainerFrame = _leftContainer.frame;
        newContainerFrame.size.width = _lastSliderPosition == 0 ? 350 : _lastSliderPosition;
        [expandAnimationDict setObject:[NSValue valueWithRect:newContainerFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSViewAnimation *expandAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:expandAnimationDict, nil]];
        [expandAnimation setDuration:0.25f];
        [expandAnimation setAnimationBlockingMode:NSAnimationBlocking];
        [expandAnimation startAnimation];
        self.currentAnimation = expandAnimation;
    } completionHandler:^{
        self.currentAnimation = nil;
        sidePanelVC.collapsed = NO;
//        [_copyrightBtn setHidden:NO];
    }];
}

- (void)sidePanelViewControllerWantsToCollapse:(SidePanelViewController *)sidePanelVC {
    if (self.currentAnimation.isAnimating) {
        [self.currentAnimation stopAnimation];
    }
//    [_copyrightBtn setHidden:YES];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        CGFloat containerWidth = CGRectGetWidth(_leftContainer.bounds);
        _lastSliderPosition = containerWidth < 180 ? 180 : containerWidth;
        NSMutableDictionary *collapseAnimationDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [collapseAnimationDict setObject:_leftContainer forKey:NSViewAnimationTargetKey];
        NSRect newContainerFrame = _leftContainer.frame;
        newContainerFrame.size.width =  CGRectGetWidth(_sidePanelVC.sidebar.bounds) + 5;
        [collapseAnimationDict setObject:[NSValue valueWithRect:newContainerFrame] forKey:NSViewAnimationEndFrameKey];
        
        NSViewAnimation *expandAnimation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:collapseAnimationDict, nil]];
        [expandAnimation setDuration:0.25f];
        [expandAnimation setAnimationBlockingMode:NSAnimationBlocking];
        
        [expandAnimation startAnimation];
        self.currentAnimation = expandAnimation;
    } completionHandler:^{
        self.currentAnimation = nil;
        sidePanelVC.collapsed = YES;
        [sidePanelVC.contentView setNeedsDisplay:YES];
//        [_copyrightBtn setHidden:NO];
    }];
}

- (void)copyrightClicked:(EAFHyperlinkButton*)sender {
    EAFMapCopyrightViewController *mapCopyrightVC = [[EAFMapCopyrightViewController alloc]init];
    
    NSPopover *copyrightPopover = [[NSPopover alloc]init];
    [copyrightPopover setBehavior:NSPopoverBehaviorTransient];
    copyrightPopover.contentViewController = mapCopyrightVC;
    CGRect bnds = sender.bounds;
    CGRect pasteRect = CGRectMake(CGRectGetMaxX(bnds) - 15, 0, 2, bnds.size.height);
    [copyrightPopover showRelativeToRect:pasteRect ofView:sender preferredEdge:NSMinYEdge];
}

@end











