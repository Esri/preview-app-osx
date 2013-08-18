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

#import "SidePanelViewController.h"
#import "EAFKit.h"
#import "TocContainerViewController.h"


NSString *const EAFSidePanelContentViewWidthDefaultsKey = @"sidePanelContentViewWidth";

@interface SidePanelViewController () <EDSideBarDelegate>{
    EAFInsetRoundedContainerViewController *_basemapsCVC;
    EAFBasemapsViewController *_basemapsVC;
    EAFInsetRoundedContainerViewController *_bookmarksCVC;
    EAFBookmarksViewController *_bookmarksVC;
    TocContainerViewController *_tocContainerVC;
    EAFInsetRoundedContainerViewController *_resultsCVC;
    EAFFindPlacesResultsViewController *_resultsVC;
    EAFInsetRoundedContainerViewController *_measureCVC;
    EAFMeasureViewController *_measureVC;
    EAFPopupManagerViewController *_popupMgrVC;
    EAFBadgeView *_bookmarksBadge;
    NSInteger _selectedSideBarIndex;
    BOOL _collapsed;
}

@end

@implementation SidePanelViewController

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [[EAFAppContext sharedAppContext].webMap removeObserver:self forKeyPath:@"bookmarks"];
    [[EAFAppContext sharedAppContext] removeObserver:self forKeyPath:@"userBookmarks"];
    
    [[NSUserDefaults standardUserDefaults]setFloat:self.view.frame.size.width forKey:EAFSidePanelContentViewWidthDefaultsKey];
}

-(void)applicationWillTerminate:(NSNotification*)note{
    [[NSUserDefaults standardUserDefaults]setFloat:self.view.frame.size.width forKey:EAFSidePanelContentViewWidthDefaultsKey];
}

-(id)init{
    return [self initWithNibName:@"SidePanelViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(foundPlaces:) name:EAFFindPlacesViewControllerDidFindPlacesNotification object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(findPlacesSearchCleared:) name:EAFFindPlacesViewControllerDidClearSearchNotification object:nil];
        _selectedSideBarIndex = -1;
    }
    
    return self;
}

-(void)awakeFromNib{
    
    [self.view setWantsLayer:YES];
    
	[_sidebar setLayoutMode:ECSideBarLayoutTop];
	_sidebar.animateSelection = YES;
	_sidebar.sidebarDelegate = self;
    

	[_sidebar addButtonWithTitle:@"Layers" image:[NSImage imageNamed:@"tab-layers-active45x45"] alternateImage:[NSImage imageNamed:@"tab-layers45x45"]];
	[_sidebar addButtonWithTitle:@"Basemaps" image:[NSImage imageNamed:@"tab-basemap-active45x45"] alternateImage:[NSImage imageNamed:@"tab-basemap45x45"]];
	[_sidebar addButtonWithTitle:@"Bookmarks" image:[NSImage imageNamed:@"tab-bookmark-active45x45"] alternateImage:[NSImage imageNamed:@"tab-bookmark45x45"]];
	[_sidebar addButtonWithTitle:@"Measure" image:[NSImage imageNamed:@"tab-measure-active45x45"] alternateImage:[NSImage imageNamed:@"tab-measure45x45"]];
	[_sidebar addButtonWithTitle:@"Places" image:[NSImage imageNamed:@"tab-places-active45x45"] alternateImage:[NSImage imageNamed:@"tab-places45x45"]];
    
    if ([[EAFAppContext sharedAppContext].webMap hasPopupsDefined]){
        [_sidebar addButtonWithTitle:@"Features" image:[NSImage imageNamed:@"tab-features-active45x45"] alternateImage:[NSImage imageNamed:@"tab-features45x45"]];
    }
	[_sidebar selectButtonAtRow:0];
    
    //
    // NOTE: we want to add our resultsVC first so that bookmarks sits above them in the map
    //
    // NOTE: we add measure at the end so all sketching is on top of every other layer in the map
    
    if (!_resultsVC){
        _resultsVC = [[EAFFindPlacesResultsViewController alloc]init];
        _resultsVC.bookmarkAnimationView = self.sidebar.matrix;
        _resultsVC.bookmarkAnimationContainerView = self.view;
        CGRect fbm = [_sidebar.matrix cellFrameAtRow:2 column:0];
        CGPoint bal = CGPointMake(CGRectGetMidX(fbm), CGRectGetMidY(fbm));
        _resultsVC.bookmarksAnimationLocation = bal;
        _resultsCVC = [[EAFInsetRoundedContainerViewController alloc]initWithChildViewController:_resultsVC];
        [_resultsCVC.view setHidden:YES];
        [_resultsCVC eaf_addToContainerWithConstraints:_contentView];
    }
    
    _bookmarksVC = [[EAFBookmarksViewController alloc]init];
    _bookmarksCVC = [[EAFInsetRoundedContainerViewController alloc]initWithChildViewController:_bookmarksVC];
    [_bookmarksCVC eaf_addToContainerWithConstraints:_contentView];
    [_bookmarksCVC.view setHidden:YES];
    
    _measureVC = [[EAFMeasureViewController alloc]init];
    _measureCVC = [[EAFInsetRoundedContainerViewController alloc]initWithChildViewController:_measureVC];
    [_measureCVC eaf_addToContainerWithConstraints:_contentView];
    [_measureCVC.view setHidden:YES];


    
    // bookmarks badge
    // upper left corner of cell
//    _bookmarksBadge = [[EAFBadgeView alloc]initWithFrame:CGRectMake(0, 0, 22, 10)];
//    [_bookmarksBadge setFrameOrigin:CGPointMake(5, 512)];
//    _bookmarksBadge.autoresizingMask = NSViewMinYMargin | NSViewMaxXMargin;
//    NSInteger total = [EAFAppContext sharedAppContext].webMap.bookmarks.count + [EAFAppContext sharedAppContext].userBookmarks.count;
//    [_bookmarksBadge setNumberOfItems:total animated:YES];
//    [self.view addSubview:_bookmarksBadge];
    
    // listen for bookmarks to change
    [[EAFAppContext sharedAppContext].webMap addObserver:self forKeyPath:@"bookmarks" options:NSKeyValueObservingOptionNew context:nil];
    [[EAFAppContext sharedAppContext] addObserver:self forKeyPath:@"userBookmarks" options:NSKeyValueObservingOptionNew context:nil];
    
    
    // set width to last content view width
    BOOL defined = ([[NSUserDefaults standardUserDefaults]valueForKey:EAFSidePanelContentViewWidthDefaultsKey] != nil);
    CGFloat w = [[NSUserDefaults standardUserDefaults]floatForKey:EAFSidePanelContentViewWidthDefaultsKey];
    if (!defined){
        w = 350;
    }
    [self.delegate sidePanelViewControllerWantsToSetWidth:w];
    
    // add notification so we know when the window is going to close so we can save the state
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:[NSApplication sharedApplication]];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"bookmarks"] || [keyPath isEqualToString:@"userBookmarks"]){
        NSInteger total = [EAFAppContext sharedAppContext].webMap.bookmarks.count + [EAFAppContext sharedAppContext].userBookmarks.count;
        [_bookmarksBadge setNumberOfItems:total animated:YES];
    }
}

- (void)sideBar:(EDSideBar*)tabBar didSelectButton:(NSInteger)index fromClick:(BOOL)fromClick{
    
    // if we are tapping the already selected index, fire delegate to collapse or expand
    if (fromClick && index == _selectedSideBarIndex) {
        if (self.isCollapsed || CGRectGetWidth(_contentView.bounds) < 20) {
            if ([self.delegate respondsToSelector:@selector(sidePanelViewControllerWantsToExpand:)]) {
                [self.delegate sidePanelViewControllerWantsToExpand:self];
            }
            return;
        }
        else if (!self.isCollapsed) {
            if ([self.delegate respondsToSelector:@selector(sidePanelViewControllerWantsToCollapse:)]) {
                [self.delegate sidePanelViewControllerWantsToCollapse:self];
            }
            return;
        }
    }
    else {
        if (self.isCollapsed) {
            if ([self.delegate respondsToSelector:@selector(sidePanelViewControllerWantsToExpand:)]) {
                [self.delegate sidePanelViewControllerWantsToExpand:self];
            }
        }
    }
    
    //
    // NOTE: We can't just remove the existing subviews and then
    //       re-add the current visible one -- something gets
    //       scewed up with autoresizing -- I think it has to
    //       do with the NSTableColumn resizing properties
    //
    for (NSView *v in _contentView.subviews){
        [v setHidden:YES];
    }
    
    [_measureVC deactivate];
    [_bookmarksVC deactivate];
    [_popupMgrVC deactivate];
    
    if (index == 0){
        if (!_tocContainerVC){
            _tocContainerVC = [[TocContainerViewController alloc]init];
            [_tocContainerVC eaf_addToContainerWithConstraints:_contentView];
        }
        [_tocContainerVC.view setHidden:NO];
    }
    else if (index == 1){
        //
        // NOTE: do not move this initialization code...basemaps view controller listens for webmap loading
        // so if we move this anywhere else, we risk having the basemapsvc try to do some logic when the main
        // webmap loads , as opposed to only when we change the basemap
        if (!_basemapsCVC) {
            _basemapsVC = [[EAFBasemapsViewController alloc]init];
            _basemapsCVC = [[EAFInsetRoundedContainerViewController alloc]initWithChildViewController:_basemapsVC];
            [_basemapsCVC eaf_addToContainerWithConstraints:_contentView];
        }
        [_basemapsCVC.view setHidden:NO];
    }
    else if (index == 2){
        [_bookmarksCVC.view setHidden:NO];
        [_bookmarksVC activate];
    }
    else if (index == 3){
        [_measureCVC.view setHidden:NO];
        [_measureVC activate];
    }
    else if (index == 4){
        [_resultsCVC.view setHidden:NO];
    }
    else if (index == 5){
        if (!_popupMgrVC){
            _popupMgrVC = [[EAFPopupManagerViewController alloc]init];
        }
        if (!_popupMgrVC.view.superview){
            [_popupMgrVC eaf_addToContainerWithConstraints:_contentView];
        }
        [_popupMgrVC.view setHidden:NO];
        [_popupMgrVC activate];
    }
    _selectedSideBarIndex = index;
}

-(void)activateTocVC{
    [self.sidebar selectButtonAtRow:0];
}

-(void)activateBasemapsVC{
    [self.sidebar selectButtonAtRow:1];
}

-(void)activateBookmarksVC{
    [self.sidebar selectButtonAtRow:2];
}

-(void)activateMeasureVC{
    [self.sidebar selectButtonAtRow:3];
}

-(void)activateResultsVC{
    [self.sidebar selectButtonAtRow:4];
}

-(void)foundPlaces:(NSNotification*)note{
    _resultsVC.results = [note.userInfo valueForKey:@"results"];
    [self.sidebar selectButtonAtRow:4];
}

-(void)findPlacesSearchCleared:(NSNotification*)note{
    _resultsVC.results = nil;
    [self.sidebar selectButtonAtRow:4];
}

-(void)fetchPopupsForPoint:(AGSPoint *)point{
    
    if (![[EAFAppContext sharedAppContext].webMap hasPopupsDefined]){
        return;
    }
    
    if (!_popupMgrVC){
        _popupMgrVC = [[EAFPopupManagerViewController alloc]init];
    }
    BOOL fetching = [_popupMgrVC fetchPopupsForPoint:point];
    if (fetching){
        [self.sidebar selectButtonAtRow:5];
    }
}

@end










