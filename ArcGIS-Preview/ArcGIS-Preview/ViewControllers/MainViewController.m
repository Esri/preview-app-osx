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

#import "MainViewController.h"
#import "EAFKit.h"
#import "MapViewController.h"

const NSInteger kPortalComponentIndex = 0;
const NSInteger kGalleryComponentIndex = 1;
const NSInteger kSubGalleryComponentIndex = 2;
const NSInteger kMapComponentIndex = 3;

@interface MainViewController () <EAFWebMapGalleryDelegate, AGSPortalDelegate, NSPathControlDelegate, MapViewControllerDelegate, AGSNetworkActivityDelegate, NSPopoverDelegate>{
    MapViewController *_mapVC;
    EAFWebMapGalleryViewController *_galleryVC;
    AGSPortal *_portal;
    EAFPortalLoginViewController *_loginVC;
    BOOL _displayingSubGalleryInBreadCrumb;
    BOOL _galleryCurrentlyShowingSubGallery;
    AGSWebMap *_reopenWebMap;
    EAFPortalAccountViewController *_accountVC;
    NSPopover *_accountVCPopover;
}

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

-(void)awakeFromNib{
    _breadCrumb.target = self;
    _breadCrumb.action = @selector(pathbarAction:);
    [AGSApplication ags_setNetworkActivityDelegate:self];
    
    [self.lineView setWantsLayer:YES];
    self.lineView.layer.backgroundColor = [NSColor eaf_darkGrayBlueColor].CGColor;
    
    //
    // when our app's main view loads, see if we have a saved portal url and
    // credential to use
    AGSPortal *lastPortal = [[EAFAppContext sharedAppContext] loadLastPortal];
    if (lastPortal) {
        //
        // we don't need to show the login since we have a portal login saved
        _portal = lastPortal;
        _portal.delegate = self;
    }
    else {
        // we have to show this after a delay or else it won't show up as a sheet correctly
        [self performSelector:@selector(showPortalLogin) withObject:nil afterDelay:0];
    }
}

-(NSInteger)portalComponentIndex{
    return kPortalComponentIndex;
}

-(NSInteger)galleryComponentIndex{
    return kGalleryComponentIndex;
}

-(NSInteger)subGalleryComponentIndex{
    if (_displayingSubGalleryInBreadCrumb){
        return kSubGalleryComponentIndex;
    }
    else{
        return -1;
    }
}

-(NSInteger)mapComponentIndex{
    if (_displayingSubGalleryInBreadCrumb){
        return kMapComponentIndex;
    }
    else{
        return kMapComponentIndex - 1;
    }
}

-(void)pathbarAction:(EAFBreadCrumbView*)pathbar{
    NSInteger index = [self.breadCrumb selectedIndex];
    
    if (index == [self portalComponentIndex]){
        if (![EAFAppContext sharedAppContext].tryingItNow){
            // if signed in
            _accountVC = [[EAFPortalAccountViewController alloc]init];
            [_accountVC setPortal:_portal];
            
            // load the view
            _accountVC.target = self;
            _accountVC.action = @selector(accountVCAction:);
            _accountVCPopover = [[NSPopover alloc]init];
            [_accountVCPopover setBehavior:NSPopoverBehaviorTransient];
            _accountVCPopover.contentViewController = _accountVC;
            _accountVCPopover.delegate = self;
            [_accountVCPopover showRelativeToRect:[_breadCrumb frameForItemAtIndex:0] ofView:_breadCrumb preferredEdge:NSMinYEdge];
        }
        else{
            // if not signed in then we show the portal login vc
            [self showPortalLogin];
        }
    }
    else if (index == [self galleryComponentIndex]){
        // this must happen before calling showGalleryVC which
        // sets the selected index on the breadCrumb
        _galleryCurrentlyShowingSubGallery = NO;
        [self showGalleryVC];
        [_galleryVC showMainGallery];
    }
    else if (index == [self subGalleryComponentIndex]){
        // this must happen before calling showGalleryVC which
        // sets the selected index on the breadCrumb
        _galleryCurrentlyShowingSubGallery = YES;
        [self showGalleryVC];
        [_galleryVC showSubGallery];
    }
    else if (index == [self mapComponentIndex]){
        [self showMapVC];
    }
}

- (void)popoverDidClose:(NSNotification *)notification{
    if (_breadCrumb.selectedIndex == kPortalComponentIndex){
        [_breadCrumb setSelectedIndex:_breadCrumb.previousSelectedIndex];
    }
}

-(void)signOut{
    //
    // this needs to be done before we clear out the portal
    [[EAFAppContext sharedAppContext] clearLastUserAndPortal];
    
    // clear out the portal
    _portal = nil;
    [EAFAppContext sharedAppContext].portal = nil;
    
    [self showPortalLogin];
}

-(void)accountVCAction:(EAFPortalAccountViewController*)pavc{
    
    [_accountVCPopover close];
    
    // This is one place where user signs out
    [self signOut];
}

-(void)showPortalLogin{
    
    // if already showing return
    if (_loginVC){
        return;
    }
    
    [self.signInOutMenuItem setEnabled:NO];
    
    // clear out the portal
    _portal = nil;
    [EAFAppContext sharedAppContext].portal = nil;

    // clear gallery and map
    [self clearOutGalleryVC];
    [self clearOutMapVC];
    
    // clear jump-bar
    for (NSInteger i = _breadCrumb.items.count - 1; i >= 0; i--){
        [_breadCrumb removeItemAtIndex:i];
    }
    
    _loginVC = [[EAFPortalLoginViewController alloc]init];
    _loginVC.target = self;
    _loginVC.action = @selector(portalLoginVCAction:);
//    _loginVC.allowCancel = (_portal != nil);
    _loginVC.allowCancel = NO;
    [_loginVC.view setWantsLayer:YES];
    _loginVC.view.layer.borderColor = [NSColor eaf_darkGrayBlueColor].CGColor;
    _loginVC.view.layer.borderWidth = 1.0f;
    
    NSView *loginView = _loginVC.view;
    loginView.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:loginView];
    //NSView *loginSuper = _loginVC.view.superview;
    [loginView.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|->=30-[loginView(==450)]->=30-|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(loginView)]];
    [loginView.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=30-[loginView(==459)]->=30-|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(loginView)]];
    
    // Center horizontally
    [loginView.superview addConstraint:[NSLayoutConstraint constraintWithItem:loginView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:loginView.superview attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    
    // Center vertically
    [loginView.superview addConstraint:[NSLayoutConstraint constraintWithItem:loginView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:loginView.superview attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
}

-(void)setPortal:(AGSPortal *)portal{
    _portal = portal;
    [EAFAppContext sharedAppContext].portal = portal;
}

-(void)portalLoginVCAction:(EAFPortalLoginViewController*)lvc{
    
    [_loginVC.view removeFromSuperview];
    
    if (lvc.portal){
        _portal = lvc.portal;
        _portal.delegate = self;
        [self portalDidLoad:_portal];
    }
    else{
        // cancelled
        
        // if no portal and cancelled, then we quit
        if (!_portal){
            [[NSApplication sharedApplication]terminate:self];
            return;
        }
        
        if (!_reopenWebMap){
            // need to select the last selected index
            _breadCrumb.selectedIndex = _breadCrumb.previousSelectedIndex;
        }
        else{
            // if cancelled during a re-open, we need to go straight
            // back to the gallery
            [self showGalleryVC];
            
            // we need to remove the map from the breadCrumb
            NSInteger mapCompIndex = [self mapComponentIndex];
            if (_breadCrumb.items.count == mapCompIndex+1){
                [_breadCrumb removeItemAtIndex:mapCompIndex];
            }
        }
    }
    
    // make sure to set this state back to nil
    _reopenWebMap = nil;
    
    _loginVC = nil;
    
    [self.signInOutMenuItem setEnabled:YES];
}

-(void)showMapVC{
    
    [_galleryVC.view setHidden:YES];
    [_galleryVC deactivate];
    
    if (!_mapVC){
        _mapVC = [[MapViewController alloc]init];
        [_mapVC eaf_addToContainer:_containerView];
        _mapVC.searchContainerView = _searchContainerView;
        _mapVC.collectFeatureButton = _collectButton;
        _mapVC.delegate = self;
    }
    _breadCrumb.selectedIndex = [self mapComponentIndex];
    [_mapVC.view setHidden:NO];
    [_mapVC activate];
}

-(void)clearOutMapVC{
    // clear out the map vc
    [_mapVC deactivate];
    [_mapVC.findVC.view removeFromSuperview];
    [_mapVC.view removeFromSuperview];
    _mapVC = nil;
}


-(void)showGalleryVC{
    
    [_mapVC.view setHidden:YES];
    [_mapVC deactivate];
    
    if (!_galleryVC){
        _galleryVC = [[EAFWebMapGalleryViewController alloc] initWithNibName:@"EAFWebMapGalleryViewController" bundle:nil];
        _galleryVC.delegate = self;
        [_galleryVC eaf_addToContainer:_containerView];
        _galleryVC.searchContainerView = _searchContainerView;
        _galleryCurrentlyShowingSubGallery = NO;
        _galleryVC.bannerImage = [NSImage imageNamed:@"banner1050x300"];
    }
    
    if (!_galleryCurrentlyShowingSubGallery){
        _breadCrumb.selectedIndex = [self galleryComponentIndex];
    }
    else{
        _breadCrumb.selectedIndex = [self subGalleryComponentIndex];
    }
    [_galleryVC.view setHidden:NO];
    [_galleryVC activate];
}

-(void)clearOutGalleryVC{
    // clear out the gallery
    [_galleryVC deactivate];
    [_galleryVC.fwmvc.view removeFromSuperview];
    [_galleryVC.view removeFromSuperview];
    _galleryVC = nil;
}

#pragma mark AGSPortalDelegate

-(void)portal:(AGSPortal *)portal didFailToLoadWithError:(NSError *)error{
    [self showPortalLogin];
}

-(void)portalDidLoad:(AGSPortal *)portal{
    
    [EAFAppContext sharedAppContext].portal = _portal;
    [[EAFAppContext sharedAppContext] loadRecentMaps];
    
    [_breadCrumb removeAllItems];
    _displayingSubGalleryInBreadCrumb = NO;
    _galleryCurrentlyShowingSubGallery = NO;
    
    NSString *portalName = _portal.portalInfo.organizationName ? _portal.portalInfo.organizationName : _portal.portalInfo.portalName;
    
    if (![EAFAppContext sharedAppContext].tryingItNow){
        NSString *portalString = [NSString stringWithFormat:@"Sign Out - %@", portalName];
        [_breadCrumb addItem:portalString];
        self.signInOutMenuItem.title = @"Sign Out";
    }
    else{
//        NSString *portalString = [NSString stringWithFormat:@"Sign in - %@", portalName];
        NSString *portalString = @"Sign In";
        [_breadCrumb addItem:portalString];
        self.signInOutMenuItem.title = @"Sign In";
    }
    
    [_breadCrumb addItem:@"Gallery"];
    
    // clear out the gallery
    [self clearOutGalleryVC];
    
    if (!_reopenWebMap){
        // show gallery if not in the process of a re-open
        [self showGalleryVC];
    }
    else{
        // here is where we re-open the map
        [self webMapGallery:_galleryVC wantsToOpenPortalItem:_reopenWebMap.portalItem];
    }
}

#pragma mark Gallery Delegate

-(void)webMapGallery:(EAFWebMapGalleryViewController *)wmgvc wantsToOpenPortalItem:(AGSPortalItem *)portalItem{
    
    if (!_galleryCurrentlyShowingSubGallery){
        // if gallery isn't showing a sub gallery
        // and this was opened from the main gallery
        // and we have a sub-gallery in the jump bar
        // then we need to remove that
        if (_displayingSubGalleryInBreadCrumb){
            [_breadCrumb removeItemAtIndex:[self subGalleryComponentIndex]];
            _displayingSubGalleryInBreadCrumb = NO;
        }
    }
    
    NSInteger mapCompIndex = [self mapComponentIndex];
    if (_breadCrumb.items.count == mapCompIndex+1){
        [_breadCrumb removeItemAtIndex:mapCompIndex];
    }
    [_breadCrumb addItem:portalItem.title];
    
    [self showMapVC];
    [_mapVC openWebMapPortalItem:portalItem];
}

-(void)webMapGallery:(EAFWebMapGalleryViewController *)wmgvc didSwitchToSubGallery:(NSString *)subGalleryDisplayText{
    
    if (!subGalleryDisplayText.length){
        // ignore if just going back to main gallery
        _galleryCurrentlyShowingSubGallery = NO;
        _breadCrumb.selectedIndex = [self galleryComponentIndex];
        return;
    }
    
    if (_displayingSubGalleryInBreadCrumb){
        // if already showing a subgallery, need to remove everything after that
        [_breadCrumb removeItemAtIndex:[self mapComponentIndex]];
        [_breadCrumb removeItemAtIndex:[self subGalleryComponentIndex]];
    }
    else{
        // if just switched, then just remove the map
        [_breadCrumb removeItemAtIndex:[self mapComponentIndex]];
    }
    
    [_breadCrumb insertItem:subGalleryDisplayText atIndex:kSubGalleryComponentIndex];
    _breadCrumb.selectedIndex = kSubGalleryComponentIndex;
    
    _displayingSubGalleryInBreadCrumb = YES;
    _galleryCurrentlyShowingSubGallery = YES;
}

#pragma mark MapViewControllerDelegate

-(void)mapViewController:(MapViewController*)mapVC wantsToLoginAndReOpenWebMap:(AGSWebMap*)webmap{
    _reopenWebMap = webmap;
    [self showPortalLogin];
}

#pragma mark actions

- (IBAction)signInOutMenuItemAction:(id)sender {
    if (![EAFAppContext sharedAppContext].tryingItNow){
        // if signed in - then sign out
        [self signOut];
    }
    else{
        // otherwise sign in
        [self showPortalLogin];
    }
}

- (IBAction)undo:(id)sender {
    //NSUndoManager *um = [EAFAppContext sharedAppContext].currentUndoManager;
    //NSLog(@"can undo: %d, %@", [um canUndo], [um undoActionName]);
    if ([[EAFAppContext sharedAppContext].currentUndoManager canUndo]){
        [[EAFAppContext sharedAppContext].currentUndoManager undo];
    }
}

- (IBAction)redo:(id)sender {
    [[EAFAppContext sharedAppContext].currentUndoManager redo];
}

#pragma mark activity

-(void)networkActivityInProgress{
    [self.activityIndicator startAnimation:nil];
}

-(void)networkActivityEnded{
    [self.activityIndicator stopAnimation:nil];
}

@end
