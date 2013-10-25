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

@interface EAFPopupManagerViewController () <AGSPopupsContainerDelegate, AGSLayerCalloutDelegate, AGSWebMapDelegate, AGSMapViewTouchDelegate, AGSFeatureLayerEditingDelegate, AGSAttachmentManagerDelegate>{
    AGSPopupsContainerViewController *_popupsVC;
    EAFStatusViewController *_popupsStatusVC;
    AGSPopup *_currentPopup;
    AGSGraphicsLayer *_highlightLayer;
    AGSPoint *_lastPopupFetchPoint;
    NSMutableArray *_mediaWindowArray;
    AGSSketchGraphicsLayer *_sketchLayer;
    id<AGSMapViewTouchDelegate> _previousMapViewTouchDelegate;
    AGSPopup *_currentEditingPopup;
    NSDictionary *_originalFeatureAttributes;
    AGSGeometry *_originalGeometry;
    BOOL _activated;
    BOOL _formerTrackMouseMovement;
    AGSMapView *_mv;
    __weak id<AGSMapViewTouchDelegate> _formerTouchDelegate;
}

@end

@implementation EAFPopupManagerViewController

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(id)init{
    return [self initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(webMapDidFetchPopups:) name:AGSWebMapDidFetchPopupsNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(webMapDidFinishFetchingPopups:) name:AGSWebMapDidFinishFetchingPopupsNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(windowClosed:) name:NSWindowWillCloseNotification object:nil];
        
        _mediaWindowArray = [NSMutableArray array];
        _activated = NO;
        
        _mv = [EAFAppContext sharedAppContext].mapView;
    }
    return self;
}

-(void)activate{
    
    if (_activated){
        return;
    }
    _activated = YES;
    
    //
    // if we are re-activated and previously had been showing
    // a callout/selected graphic, we should restore that
    if (_currentPopup.graphic.geometry && _lastPopupFetchPoint) {
        _highlightLayer.visible = YES;
        //
        // reshow the callout at the last point
        [_mv.callout showCalloutAtPoint:_lastPopupFetchPoint forFeature:_currentPopup.graphic layer:_currentPopup.featureLayer animated:YES];
    }
    
    if (_popupsVC.inEditingMode) {
        _formerTrackMouseMovement = _mv.trackMouseMovement;
        _mv.trackMouseMovement = YES;
        _formerTouchDelegate = _mv.touchDelegate;
        _mv.touchDelegate = self;
        _sketchLayer.visible = YES;
        _mv.showMagnifierOnTapAndHold = YES;
        if (_sketchLayer.undoManager) {
            [[EAFAppContext sharedAppContext] pushUndoManager:_sketchLayer.undoManager];
        }
    }
}

-(void)deactivate{
    
    if (!_activated){
        return;
    }
    
    _activated = NO;
    _highlightLayer.visible = NO;
    
    if (_popupsVC.inEditingMode) {
        _mv.trackMouseMovement = _formerTrackMouseMovement;
        _mv.touchDelegate = _formerTouchDelegate;
        _sketchLayer.visible = NO;
        
        if ([EAFAppContext sharedAppContext].currentUndoManager == _sketchLayer.undoManager) {
            [[EAFAppContext sharedAppContext] popupUndoManager];
        }
    }
}

-(BOOL)isEditing {
    return (_popupsVC && _popupsVC.inEditingMode);
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

-(void)startEditingCurrentPopup {
    if (!_popupsVC) {
        return;
    }
    
    if ([[self popups] count] <= 0) {
        return;
    }
    
    [_popupsVC startEditingCurrentPopup];
}

-(void)clearAllPopups{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doShowFetchingPopups) object:nil];
    [_popupsVC clearAllPopups];
    _popupsVC = nil;
    _highlightLayer.visible = NO;
    [_highlightLayer clearSelection];
    [_highlightLayer removeAllGraphics];
    _currentPopup = nil;
    _lastPopupFetchPoint = nil;
    [_popupsStatusVC.view setHidden:YES];
}

- (void)finishEditingPopup:(AGSPopup *)popup {
    
    _currentEditingPopup = popup;
    
    //reset mapview touch delegate
    [EAFAppContext sharedAppContext].mapView.touchDelegate = _previousMapViewTouchDelegate;
    
    //set the feature layer editing delegate to ourself
    popup.featureLayer.editingDelegate = self;
    
    // simplify the geometry, this will take care of self intersecting polygons and
	popup.graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine]simplifyGeometry:popup.graphic.geometry];
    
    //normalize the geometry, this will take care of geometries that extend beyone the dateline
    //(if wraparound was enabled on the map)
	popup.graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine]normalizeCentralMeridianOfGeometry:popup.graphic.geometry];
	
    AGSFeatureLayer *_activeFeatureLayer = (AGSFeatureLayer*)popup.graphic.layer;
	long long oid = [_activeFeatureLayer objectIdForFeature:popup.graphic];
	
	if (oid > 0){
		//feature has a valid objectid, this means it exists on the server
        //and we simply update the exisiting feature
		[_activeFeatureLayer updateFeatures:[NSArray arrayWithObject:popup.graphic]];
	} else {
		//objectid does not exist, this means we need to add it as a new feature
		[_activeFeatureLayer addFeatures:[NSArray arrayWithObject:popup.graphic]];
	}
}

-(void)cancelEditing {
    
    //reset popup attributes and geometry
    [_currentEditingPopup.graphic setAttributes:_originalFeatureAttributes];
    _currentEditingPopup.graphic.geometry = _originalGeometry;
    [_currentEditingPopup.featureLayer refresh];
    
    _currentEditingPopup = nil;
    [_sketchLayer clear];
    [EAFAppContext sharedAppContext].mapView.touchDelegate = _previousMapViewTouchDelegate;
}

-(void)refreshSelection {
    
    if (!_highlightLayer){
        _highlightLayer = [AGSGraphicsLayer graphicsLayer];
        _highlightLayer.name = @"Popup Highlight Layer";
        _highlightLayer.allowLayerConsolidation = NO;
        _highlightLayer.allowCallout = NO;
        
        //        NSMutableSet *exclude = [NSMutableSet setWithSet:[EAFAppContext sharedAppContext].mapContentsTree.excludeList];
        //        [exclude addObject:_highlightLayer.name];
        //        [EAFAppContext sharedAppContext].mapContentsTree.excludeList = exclude;
        
        _highlightLayer.selectionColor = [NSColor cyanColor];
        [[EAFAppContext sharedAppContext].mapView addMapLayer:_highlightLayer];
    }
    
    _highlightLayer.visible = NO;
    [_highlightLayer clearSelection];
    [_highlightLayer removeAllGraphics];
    
    AGSGraphic *hlGraphic = [_currentPopup.graphic copy];
    if (hlGraphic.geometry) {
        // workaround
        AGSSymbol *s = hlGraphic.symbol;
        if (!s){
            s = [_currentPopup.featureLayer.renderer symbolForFeature:hlGraphic timeExtent:[EAFAppContext sharedAppContext].mapView.timeExtent];
        }
        hlGraphic.symbol = s;
        
        // this too is causing a crash, we need to look into it, workaround above
        //    _highlightLayer.renderer = [popup.featureLayer.renderer copy];
        
        // [BUG] Graphics do not get highlighted in weather warnings map
        // the above bug is because the renderer is reporting a nil symbol for some reason
        // we can work around it here
        // we also work around for when fill symbols don't have an outline here...
        //    AGSSymbol *s = [popup.featureLayer.renderer symbolForGraphic:hlGraphic timeExtent:nil];
        
        AGSMapView *mapView = [EAFAppContext sharedAppContext].mapView;
        if ((!s && _currentPopup.featureLayer.geometryType == AGSGeometryTypePolygon) ||
            [s isKindOfClass:[AGSSimpleFillSymbol class]]){
            hlGraphic.symbol = [AGSSimpleFillSymbol simpleFillSymbolWithColor:[NSColor clearColor] outlineColor:[NSColor whiteColor]];
        }
        
        [_highlightLayer addGraphic:hlGraphic];
        [_highlightLayer setSelected:YES forGraphic:hlGraphic];
        _highlightLayer.visible = YES;
        
        AGSPoint *location = nil;
        if (!mapView.callout.hidden) {
            // if graphic center not in extent, then pan to it
            AGSMutablePoint *calloutLocation;
            calloutLocation = [mapView.callout.mapLocation mutableCopy];
            [calloutLocation normalizeToEnvelope:mapView.visibleAreaEnvelope];
            location = calloutLocation;
        }
        else {
            location = hlGraphic.geometry.envelope.center;
        }
        
        if (location && ![mapView.visibleAreaEnvelope containsPoint:location]){
            //NSLog(@"panning...");
            [mapView centerAtPoint:location animated:YES];
        }

    }
}

- (void) warnUserOfErrorWithMessage:(NSString*) message {
    //Display an alert to the user
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Try Again"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Error"];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(featureEditingErrorAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    
    //this is handled by finishEditingPopup in the featureEditingErrorAlertDidEnd method, below...
    //
    //Restart editing the popup so that the user can attempt to save again
//    [_popupsVC startEditingCurrentPopup];
}

-(void)featureEditingErrorAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
    
    [[alert window]orderOut:nil];
    
    if (returnCode == NSAlertFirstButtonReturn){
        
        //try again to post edits
        [self finishEditingPopup:_currentEditingPopup];
    }
    else if (returnCode == NSAlertSecondButtonReturn){
        
        //cancel editing/posting edits
        [self cancelEditing];
        
        //This is so the popup VC knows something happened to cancel the editing process
        //and redraw itself and the current popup vc accordingly
        [_popupsVC cancelEditingCurrentPopup];
    }
}

-(void)deleteFeatureErrorAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
    
    [[alert window]orderOut:nil];
    
    if (returnCode == NSAlertFirstButtonReturn){
        //delete the feature...
        AGSFeatureLayer *_activeFeatureLayer = (AGSFeatureLayer*)_currentPopup.graphic.layer;
        
        //Call method on feature layer to delete the feature
        NSNumber* number = [NSNumber numberWithInteger: [_activeFeatureLayer objectIdForFeature:_currentPopup.graphic]];
        NSArray* oids = [NSArray arrayWithObject: number];
        [_activeFeatureLayer deleteFeaturesWithObjectIds:oids ];
        [_activeFeatureLayer refresh];
        [self clearAllPopups];
    }
}

#pragma mark AGSMapViewTouchDelegate

-(void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
    [_sketchLayer mapView:mapView didClickAtPoint:screen mapPoint:mappoint features:features];
}

-(void)mapView:(AGSMapView *)mapView didTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
    [_sketchLayer mapView:mapView didTapAndHoldAtPoint:screen mapPoint:mappoint features:features];
}

-(void)mapView:(AGSMapView *)mapView didEndTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
    [_sketchLayer mapView:mapView didEndTapAndHoldAtPoint:screen mapPoint:mappoint features:features];
}

-(BOOL)mapView:(AGSMapView *)mapView didMouseDownAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
    return [_sketchLayer mapView:mapView didMouseDownAtPoint:screen mapPoint:mappoint features:features];
}

-(void)mapView:(AGSMapView *)mapView didMouseDragToPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint{
    [_sketchLayer mapView:mapView didMouseDragToPoint:screen mapPoint:mappoint];
}

-(void)mapView:(AGSMapView *)mapView didMouseUpAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint{
    [_sketchLayer mapView:mapView didMouseUpAtPoint:screen mapPoint:mappoint];
}

-(void)mapView:(AGSMapView *)mapView didKeyDown:(NSEvent *)event{
    if (event.keyCode == 51){
        [_sketchLayer removeSelectedVertex];
    }
}

#pragma mark popups container delegate

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer didChangeToCurrentPopup:(AGSPopup *)popup{

    _currentPopup = popup;
    
    popup.featureLayer.calloutDelegate = self;
    
    AGSMapView *mapView = [EAFAppContext sharedAppContext].mapView;

    AGSPoint *centerPoint = _lastPopupFetchPoint;
    if (!centerPoint) {
        centerPoint = [[mapView visibleAreaEnvelope] center];
    }

    if (popup.graphic.geometry) {
        [mapView.callout showCalloutAtPoint:centerPoint forFeature:popup.graphic layer:popup.featureLayer animated:YES];
    }
    
    [self refreshSelection];
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

-(AGSGeometry*)popupsContainer:(id<AGSPopupsContainer>)popupsContainer wantsNewMutableGeometryForPopup:(AGSPopup*)popup {

    //Return an empty mutable geometry of the type that our feature layer uses
    return AGSMutableGeometryFromType(((AGSFeatureLayer*)popup.graphic.layer).geometryType, [EAFAppContext sharedAppContext].mapView.spatialReference);
}

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer readyToEditGraphicGeometry:(AGSGeometry*)geometry forPopup:(AGSPopup*)popup {
    
    AGSMapView *mapView = [EAFAppContext sharedAppContext].mapView;
    
    if (!_sketchLayer) {
        _sketchLayer = [[AGSSketchGraphicsLayer alloc] init];
        [[EAFAppContext sharedAppContext].mapView addMapLayer:_sketchLayer withName:@"Sketch Layer"];
    }
    
    //register self for receiving notifications from the sketch layer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:_sketchLayer];

    //make sure this isn't pushed more than once
    if ([EAFAppContext sharedAppContext].currentUndoManager != _sketchLayer.undoManager) {
        [[EAFAppContext sharedAppContext] pushUndoManager:_sketchLayer.undoManager];
    }
    
    [[EAFAppContext sharedAppContext].currentUndoManager removeAllActions];

    //Prepare the current view controller for sketch mode
    //save previous touch delegate
    _previousMapViewTouchDelegate = mapView.touchDelegate;
    mapView.touchDelegate = self; //activate ourself
    mapView.callout.hidden = YES;
    
    //Assign the sketch layer the geometry that is being passed to us for
    //the active popup's graphic. This is the starting point of the sketch
    _sketchLayer.geometry = geometry;
    
    //zoom to the existing feature's geometry
    AGSEnvelope* env = nil;
    AGSGeometryType geoType = AGSGeometryTypeForGeometry(_sketchLayer.geometry);
    if (geoType == AGSGeometryTypePolygon) {
        env = ((AGSPolygon*)_sketchLayer.geometry).envelope;
    } else if (geoType == AGSGeometryTypePolyline) {
        env = ((AGSPolyline*)_sketchLayer.geometry).envelope ;
    }
    
    if (env != nil) {
        AGSMutableEnvelope* mutableEnv  = [env mutableCopy];
        [mutableEnv expandByFactor:1.4];
        [mapView zoomToEnvelope:mutableEnv animated:YES];
    }
    
    //replace the button in the navigation bar to allow a user to
    //indicate that the sketch is done
//	_popupsVC.doneButton = self.sketchCompleteButton;
//	self.navigationItem.rightBarButtonItem = self.sketchCompleteButton;
//    self.sketchCompleteButton.enabled = NO;
}

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer didStartEditingGraphicForPopup:(AGSPopup*)popup {
    
    _originalFeatureAttributes = [popup.graphic allAttributes];
    _originalGeometry = [popup.graphic.geometry mutableCopy];
}

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer didFinishEditingGraphicForPopup:(AGSPopup*)popup {
    
    //make sure this isn't popped more than once
    if ([EAFAppContext sharedAppContext].currentUndoManager == _sketchLayer.undoManager) {
        [[EAFAppContext sharedAppContext] popupUndoManager];
    }

    [self finishEditingPopup:popup];

    //todo: need to inform users somehow...
    
    //Tell the user edits are being saved int the background
//    self.loadingView = [LoadingView loadingViewInView:self.popupVC.view withText:@"Saving feature details..."];
    
    //we will wait to post attachments till when the updates succeed
}

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer didCancelEditingGraphicForPopup:(AGSPopup*)popup {

    //todo: the following will be handled when we write the create feature code...
    
    long long oid = [popup.featureLayer objectIdForFeature:popup.graphic];
    if (oid <= 0) {
        //it's creating a new feature operation that we're cancelling
//        NSLog(@"Cancelling new feature collection");
        
        [self clearAllPopups];
        _currentEditingPopup = nil;
        [_sketchLayer clear];
        [EAFAppContext sharedAppContext].mapView.touchDelegate = _previousMapViewTouchDelegate;
        [self showNoPopupsFound];
    }
    else {
        _currentEditingPopup = popup;
        [self cancelEditing];
    }

    //if we had begun adding a new feature, remove it from the layer because the user hit cancel.
//    if(self.createdFeature != nil){
//        [self.activeFeatureLayer removeGraphic:self.createdFeature];
//        self.createdFeature = nil;
//    }
    
    //reset any sketch related changes we made to our main view controller

    //make sure this isn't popped more than once
    if ([EAFAppContext sharedAppContext].currentUndoManager == _sketchLayer.undoManager) {
        [[EAFAppContext sharedAppContext] popupUndoManager];
    }
}

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer wantsToDeleteGraphicForPopup:(AGSPopup*)popup {
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setInformativeText:@"This operation cannot be undone."];
    [alert setMessageText:@"Are you sure you want to delete this feature?"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(deleteFeatureErrorAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

#pragma mark feature layer editing delegate

- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFeatureEditsWithResults:(AGSFeatureLayerEditResults *)editResults {
    
//    //Remove the activity indicator
//    [self.loadingView removeView];
    
    //We will assume we have to update the attachments unless
    //1) We were adding a feature and it failed
    //2) We were updating a feature and it failed
    //3) We were deleting a feature
    BOOL _updateAttachments = YES;
    
    //todo: accumulate number of failed features like ios app does and report that to user
    
    NSString *errorMessage = nil;
    if ([editResults.addResults count] > 0) {
        //we were adding a new feature
        AGSEditResult* result = (AGSEditResult*)[editResults.addResults objectAtIndex:0];
        if (!result.success) {
            //Add operation failed. We will not update attachments
            _updateAttachments = NO;
            //Inform user
            errorMessage = [result.error errorDescription];
//            [self warnUserOfErrorWithMessage:@"Could not add feature. Please try again. Error = %@", ];
        }
        
    }else if ([editResults.updateResults count] > 0) {
        //we were updating a feature
        AGSEditResult* result = (AGSEditResult*)[editResults.updateResults objectAtIndex:0];
        if(!result.success){
            //Update operation failed. We will not update attachments
            _updateAttachments = NO;
            //Inform user
            errorMessage = [result.error errorDescription];
//            [self warnUserOfErrorWithMessage:@"Could not update feature. Please try again"];
        }
    }else if ([editResults.deleteResults count] > 0) {
        //we were deleting a feature
        _updateAttachments = NO;
        AGSEditResult* result = (AGSEditResult*)[editResults.deleteResults objectAtIndex:0];
        if(!result.success){
            //Delete operation failed. Inform user
            errorMessage = [result.error errorDescription];
//            [self warnUserOfErrorWithMessage:@"Could not delete feature. Please try again"];
        }
        else {
            //Delete operation succeeded
            //Dismiss the popup view controller and hide the callout which may have been shown for
            //the deleted feature.
            [EAFAppContext sharedAppContext].mapView.callout.hidden = YES;
            _popupsVC = nil;
        }
    }
    
    if ([errorMessage length] > 0) {
        [self warnUserOfErrorWithMessage:errorMessage];
    }

//    //test
//    [self warnUserOfErrorWithMessage:@"Templorary: An error occurred while posting feature edits."];

    //if edits pertaining to the feature were successful...
    if (_updateAttachments) {
        
        [_sketchLayer clear];
        
        //...we post edits to the attachments
		AGSAttachmentManager *attMgr = [featureLayer attachmentManagerForFeature:_currentPopup.graphic];
		attMgr.delegate = self;
        
        if ([attMgr hasLocalEdits]) {
			[attMgr postLocalEditsToServer];
//            self.loadingView = [LoadingView loadingViewInView:self.popupVC.view withText:@"Saving feature attachments..."];
        }
        else {
            //no local edits, so refresh feature layer here
            [_currentEditingPopup.featureLayer refresh];
            [self refreshSelection];
        }
	}
}

- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFailFeatureEditsWithError:(NSError *)error {

    NSLog(@"Could not commit edits because: %@", [error localizedDescription]);

//    [self.loadingView removeView];
    NSString *errorMessage = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"An error occurred while posting feature edits",nil),[error localizedDescription]];
    [self warnUserOfErrorWithMessage:errorMessage];
}

#pragma mark attachment manager delegate

-(void)attachmentManager:(AGSAttachmentManager *)attachmentManager didPostLocalEditsToServer:(NSArray *)attachmentsPosted{
    
//    [self.loadingView removeView];
    
    //loop through all attachments looking for failures
    NSInteger numFailed = 0;
	NSInteger numAttachmentEdits = 0;
    for (AGSAttachment* attachment in attachmentsPosted) {
        if (attachment.networkError != nil || attachment.editResultError != nil) {
            numFailed++;
            NSString* reason = nil;
            if (attachment.networkError != nil)
                reason = [attachment.networkError localizedDescription];
            else if (attachment.editResultError != nil)
                reason = attachment.editResultError.errorDescription;
        
            NSLog(@"Attachment '%@' could not be synced with server because %@",attachment.attachmentInfo.name,reason);
        }

        numAttachmentEdits++;
    }
    
    if (numFailed > 0){
        NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"%d of %d attachment edits failed to post.", nil), numFailed, numAttachmentEdits];
        [self warnUserOfErrorWithMessage:errorMessage];
    }
    else {
        //no errors, so refresh feature layer
        [_currentEditingPopup.featureLayer refresh];
        [self refreshSelection];
    }
}

#pragma mark AGSLayerCalloutDelegate

-(BOOL)callout:(AGSCallout *)callout willShowForFeature:(id<AGSFeature>)feature layer:(AGSLayer<AGSHitTestable> *)layer mapPoint:(AGSPoint *)mapPoint {
    NSString *title = _currentPopup.title;
    if (!title.length){
        title = [NSString stringWithFormat:@"%lu of %lu", ([_popupsVC.popups indexOfObject:_currentPopup] + 1), _popupsVC.popups.count];
    }
    callout.title = title;
    callout.detail = nil;
    return YES;
}

#pragma mark fetching code

-(BOOL)fetchPopupsForPoint:(AGSPoint*)point{
    [self clearAllPopups];
    
    AGSMutablePoint *mp = [point mutableCopy];
    [mp normalize];
    
    _lastPopupFetchPoint = point;
    double tolerance = 12 * [AGSScreen mainScreenScale] * [EAFAppContext sharedAppContext].mapView.resolution;
    AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:mp.x - tolerance
                                                ymin:mp.y - tolerance
                                                xmax:mp.x + tolerance
                                                ymax:mp.y + tolerance
                                    spatialReference:mp.spatialReference];
    
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

#pragma mark sketch graphics layer notifications

- (void)respondToGeomChanged: (NSNotification*) notification {

    //Let the popups VC know that our geomery was updated
    [_popupsVC geometryUpdated];
}

@end
