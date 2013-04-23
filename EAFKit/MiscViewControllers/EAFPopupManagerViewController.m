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

#import "EAFPopupManagerViewController.h"
#import "EAFStatusViewController.h"
#import "NSViewController+EAFAdditions.h"
#import "EAFAppContext.h"

@interface EAFPopupManagerViewController () <AGSPopupsContainerDelegate, AGSInfoTemplateDelegate, AGSWebMapDelegate>{
    AGSPopupsContainerViewController *_popupsVC;
    EAFStatusViewController *_popupsStatusVC;
    AGSPopup *_currentPopup;
    AGSGraphicsLayer *_highlightLayer;
    AGSPoint *_lastPopupFetchPoint;
    NSMutableArray *_mediaWindowArray;
}

@end

@implementation EAFPopupManagerViewController

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(id)init{
    return [self initWithNibName:@"EAFPopupManagerViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(webMapDidFetchPopups:) name:AGSWebMapDidFetchPopupsNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(webMapDidFinishFetchingPopups:) name:AGSWebMapDidFinishFetchingPopupsNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(windowClosed:) name:NSWindowWillCloseNotification object:nil];
        
        _mediaWindowArray = [NSMutableArray array];
    }
    return self;
}

-(void)activate{
}

-(void)deactivate{
    _highlightLayer.visible = NO;
}

-(void)loadView{
    self.view = [[NSView alloc]initWithFrame:CGRectZero];
    
    _popupsStatusVC = [[EAFStatusViewController alloc]init];
    [_popupsStatusVC view]; // load the view so we can set the props
    [_popupsStatusVC eaf_addToAndCenterInContainer:self.view];
    
    [self showDefaultStatus];
}

-(void)showFetchingPopups{
    [self performSelector:@selector(doShowFetchingPopups) withObject:nil afterDelay:.25f];
//    [self doShowFetchingPopups];
}

-(void)doShowFetchingPopups{
    _popupsStatusVC.messageLabel.stringValue = @"Fetching Information...";
    [_popupsStatusVC.activityIndicator startAnimation:nil];
    [_popupsStatusVC.view setHidden:NO];
    [_popupsVC.view setHidden:YES];
}

-(void)showNoPopupsFound{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doShowFetchingPopups) object:nil];
    _popupsStatusVC.messageLabel.stringValue = @"No Feature Information Found";
    [_popupsStatusVC.activityIndicator stopAnimation:nil];
    [_popupsStatusVC.view setHidden:NO];
    [_popupsVC.view setHidden:YES];
}

-(void)showDefaultStatus{
    _popupsStatusVC.messageLabel.stringValue = @"Click on a feature for information";
    [_popupsStatusVC.activityIndicator stopAnimation:nil];
    [_popupsStatusVC.view setHidden:NO];
    [_popupsVC.view setHidden:YES];
}

-(NSArray*)popups{
    return [_popupsVC.popups copy];
}

-(void)showPopups:(NSArray*)popups{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doShowFetchingPopups) object:nil];
    if (!_popupsVC){
        _popupsVC = [[AGSPopupsContainerViewController alloc]initWithPopups:popups];
        _popupsVC.delegate = self;
        [_popupsVC eaf_addToContainerWithConstraints:self.view insetX:15 insetY:15];
        [_popupsVC.view setHidden:NO];
        if (popups.count){
            [self popupsContainer:_popupsVC didChangeToCurrentPopup:[popups objectAtIndex:0]];
        }
    }
    else{
        [_popupsVC showAdditionalPopups:popups];
    }
    
    [_popupsStatusVC.view setHidden:YES];
}

-(void)clearAllPopups{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doShowFetchingPopups) object:nil];
    [_popupsVC clearAllPopups];
    _popupsVC = nil;
    _highlightLayer.visible = NO;
    [_highlightLayer clearSelection];
    [_highlightLayer removeAllGraphics];
    _currentPopup = nil;
    [_popupsStatusVC.view setHidden:YES];
}

#pragma mark popups container delegate

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer didChangeToCurrentPopup:(AGSPopup *)popup{
    
    _currentPopup = popup;
    
    popup.graphic.infoTemplateDelegate = self;
    
    AGSMapView *mapView = [EAFAppContext sharedAppContext].mapView;
    [mapView.callout showCalloutAtPoint:_lastPopupFetchPoint forGraphic:popup.graphic animated:YES];
    
    
    if (!_highlightLayer){
        _highlightLayer = [AGSGraphicsLayer graphicsLayer];
        _highlightLayer.name = @"Popup Highlight Layer";
        _highlightLayer.allowLayerConsolidation = NO;
        
//        NSMutableSet *exclude = [NSMutableSet setWithSet:[EAFAppContext sharedAppContext].mapContentsTree.excludeList];
//        [exclude addObject:_highlightLayer.name];
//        [EAFAppContext sharedAppContext].mapContentsTree.excludeList = exclude;
        
        _highlightLayer.selectionColor = [NSColor cyanColor];
        [[EAFAppContext sharedAppContext].mapView addMapLayer:_highlightLayer];
    }
    
    _highlightLayer.visible = NO;
    [_highlightLayer clearSelection];
    [_highlightLayer removeAllGraphics];
    
    AGSGraphic *hlGraphic = [popup.graphic copy];
    
    
    // workaround
    AGSSymbol *s = hlGraphic.symbol;
    if (!s){
        s = [popup.featureLayer.renderer symbolForGraphic:hlGraphic timeExtent:[EAFAppContext sharedAppContext].mapView.timeExtent];
    }
    hlGraphic.symbol = s;
    
    // this too is causing a crash, we need to look into it, workaround above
//    _highlightLayer.renderer = [popup.featureLayer.renderer copy];
    
    // [BUG] Graphics do not get highlighted in weather warnings map
    // the above bug is because the renderer is reporting a nil symbol for some reason
    // we can work around it here
    // we also work around for when fill symbols don't have an outline here...
//    AGSSymbol *s = [popup.featureLayer.renderer symbolForGraphic:hlGraphic timeExtent:nil];
    if ((!s && popup.featureLayer.geometryType == AGSGeometryTypePolygon) ||
        [s isKindOfClass:[AGSSimpleFillSymbol class]]){
        hlGraphic.symbol = [AGSSimpleFillSymbol simpleFillSymbolWithColor:[NSColor clearColor] outlineColor:[NSColor whiteColor]];
    }
    
    [_highlightLayer addGraphic:hlGraphic];
    [_highlightLayer setSelected:YES forGraphic:hlGraphic];
    _highlightLayer.visible = YES;
    
    // if graphic center not in extent, then pan to it
    AGSMutablePoint *calloutLocation = [mapView.callout.mapLocation mutableCopy];
    [calloutLocation normalizeToEnvelope:mapView.visibleAreaEnvelope];
    if (![mapView.visibleAreaEnvelope containsPoint:calloutLocation]){
        //NSLog(@"panning...");
        [mapView centerAtPoint:calloutLocation animated:YES];
    }
}

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer didShowWindow:(NSWindow *)window forPopup:(AGSPopup *)popup {

    //if we have a window, add it to our array so it stays around until the user closes it.
    if (window) {
        [_mediaWindowArray addObject:window];
    }
}

//window has been closed, remove from array
-(void)windowClosed:(NSNotification*)note{
    
    NSWindow *window = note.object;
    if (window) {
        [_mediaWindowArray removeObject:window];
    }
}

#pragma mark popup info template delegate

- (NSString *)titleForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint{
    NSString *title = _currentPopup.title;
    if (!title.length){
        title = [NSString stringWithFormat:@"%lu of %lu", ([_popupsVC.popups indexOfObject:_currentPopup] + 1), _popupsVC.popups.count];
    }
    return title;
}

- (NSString *)detailForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint{
    return nil;
}

#pragma mark fetching code

-(BOOL)fetchPopupsForPoint:(AGSPoint*)point{
    
    AGSMutablePoint *mp = [point mutableCopy];
    [mp normalize];
    
    _lastPopupFetchPoint = point;
    double tolerance = 12 * [AGSScreen mainScreenScale] * [EAFAppContext sharedAppContext].mapView.resolution;
    AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:mp.x - tolerance
                                                ymin:mp.y - tolerance
                                                xmax:mp.x + tolerance
                                                ymax:mp.y + tolerance
                                    spatialReference:mp.spatialReference];
    [self clearAllPopups];
    BOOL fetching = [[EAFAppContext sharedAppContext].webMap fetchPopupsForExtent:env];
    if (fetching){
        [self showFetchingPopups];
    }
    else{
        [self showDefaultStatus];
    }
    return fetching;
}

-(void)webMapDidFetchPopups:(NSNotification*)note{
    NSArray *popups = [note.userInfo valueForKey:@"popups"];
    [self showPopups:popups];
}

-(void)webMapDidFinishFetchingPopups:(NSNotification*)note{
    if (!_popupsVC.popups.count){
        [self showNoPopupsFound];
    }
}

@end
