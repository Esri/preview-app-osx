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

#import "EAFWebMapGalleryViewController.h"
#import "EAFFindWebMapsViewController.h"
#import "EAFPortalContentViewController.h"
#import "EAFPortalContentViewController+Internal.h"
#import "EAFPortalItemInfoViewController.h"
#import "EAFPortalCollectionViewController.h"
#import "EAFPortalContentTableViewController.h"
#import "EAFRecentMapsTableViewController.h"
#import "EAFPortalFolderTableViewController.h"
#import "EAFPortalGroupTableViewController.h"
#import "EAFAppContext.h"
#import "EAFFlippedView.h"
#import "EAFHyperlinkButton.h"
#import "NSAttributedString+EAFAdditions.h"
#import "EAFCGUtils.h"
#import "NSViewController+EAFAdditions.h"
#import "NSView+EAFAdditions.h"
#import "EAFStack.h"
#import "NSColor+EAFAdditions.h"
#import "EAFRoundedView.h"

//#define USE_TEXTURED_BACKGROUND
#define PCVC_HEIGHT 431

typedef enum {
    EAFWebMapGalleryModeSinglePane,
    EAFWebMapGalleryModeMultiPane,
} EAFWebMapGalleryMode;

@interface EAFWebMapGalleryViewController ()<AGSPortalDelegate, AGSPortalItemDelegate, EAFPortalCollectionViewControllerDelegate, EAFFindWebMapsDelegate, EAFPortalGroupTableViewDelegate, EAFPortalFolderTableViewDelegate, EAFRecentMapsTableViewDelegate, NSWindowDelegate>

@property (nonatomic, strong) IBOutlet NSScrollView *contentScrollView;

@property (nonatomic, weak) AGSPortal *portal;
@property (nonatomic, strong) NSCollectionView *collectionView;

@property (nonatomic, copy, readwrite) NSString *subGalleryDisplayText;

@property (nonatomic, strong) EAFPortalCollectionViewController *myMapsVC;
@property (nonatomic, strong) EAFPortalCollectionViewController *featuredContentVC;
@property (nonatomic, strong) EAFPortalCollectionViewController *highestRatedVC;
@property (nonatomic, strong) EAFPortalCollectionViewController *mostViewedVC;
@property (nonatomic, strong) EAFPortalCollectionViewController *subGalleryVC;
@property (nonatomic, strong) EAFPortalGroupTableViewController *groupListVC;
@property (nonatomic, strong) EAFRecentMapsTableViewController *recentMapsVC;
@property (nonatomic, strong) EAFPortalFolderTableViewController *folderListVC;

@property (nonatomic, strong) NSWindow *infoWindow;
@property (nonatomic, strong) NSWindowController *windowController;

@property (nonatomic, strong, readwrite) EAFFindWebMapsViewController *fwmvc;

@property (nonatomic, assign) EAFWebMapGalleryMode mode;

@property (nonatomic, strong) EAFFlippedView *singleGalleryDocumentView;
@property (nonatomic, strong) EAFFlippedView *multiGalleryDocumentView;

@property (nonatomic, strong) EAFFlippedView *singleGalleryContainerView;
@property (nonatomic, strong) EAFFlippedView *multiGalleryContainerView;

@property (nonatomic, strong) EAFRoundedView *bannerView;
@property (nonatomic, strong) NSImageView *bannerImageView;
@property (nonatomic, strong) NSOperation *bannerOp;

//
// constraints
@property (nonatomic, strong) NSArray *singleGalleryGroupListConstraints;
@property (nonatomic, strong) NSArray *multiGalleryGroupListConstraints;

@property (nonatomic, strong) NSArray *singleGalleryRecentMapsConstraints;
@property (nonatomic, strong) NSArray *multiGalleryRecentMapsConstraints;

@property (nonatomic, strong) NSArray *singleGalleryFolderListConstraints;
@property (nonatomic, strong) NSArray *multiGalleryFolderListConstraints;

- (BOOL)shouldShowMyMaps;
@end

@implementation EAFWebMapGalleryViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //
    // if we are still querying the banner op, let's cancel it
    [self.bannerOp cancel];
}

-(id)init{
    return [self initWithNibName:@"EAFWebMapGalleryViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.portal = [[EAFAppContext sharedAppContext] portal];
        _mode = EAFWebMapGalleryModeMultiPane;
    }
    return self;
}

- (void)activate {
    [_fwmvc.view setHidden:NO];
    
    //
    // use ivar in set hidden call so we don't invoke lazy load if this hasn't been created yet
    if (self.mode == EAFWebMapGalleryModeSinglePane) {
        [_singleGalleryDocumentView setHidden:NO];
//        [[_singleGalleryDocumentView animator] setAlphaValue:1.0];
    }
    else {
        [_multiGalleryDocumentView setHidden:NO];
//        [[_multiGalleryDocumentView animator] setAlphaValue:1.0];
    }
}

- (void)deactivate {
    [_fwmvc.view setHidden:YES];
    //
    // use ivar so we don't invoke lazy load if this hasn't been created yet
    [_singleGalleryDocumentView setHidden:YES];
    [_multiGalleryDocumentView setHidden:YES];
//    [_singleGalleryDocumentView setAlphaValue:0.0];
//    [_multiGalleryDocumentView setAlphaValue:0.0];
}

- (void)showSubGallery {
    self.mode = EAFWebMapGalleryModeSinglePane;
    [self activate];
}

- (void)showMainGallery {
    self.mode = EAFWebMapGalleryModeMultiPane;
    [self activate];
}

-(void)setSearchContainerView:(NSView *)searchContainerView{
    _searchContainerView = searchContainerView;
    [_fwmvc.view removeFromSuperview];
    [_fwmvc eaf_addToAndCenterInContainer:_searchContainerView];
}

- (CGFloat)heightForContent {
    // this is for search results, group, folder contents
    if (self.mode == EAFWebMapGalleryModeSinglePane) {
        return 1581;
    }
    //
    // This is the multi-pane mode and logged in and NOT "tryingitnow"
    else if ([self shouldShowMyMaps]) {
        // 300 + 25 + 431 + 25 + 431 + 25 + 431 + 25 + 431 + 25
        return PCVC_HEIGHT*4 + 25*5 + 300;
        
    }
    //
    // multi-pane mode anonymous or try it now
    else {
        // 300 + 25 + 431 + 25+ 431 + 25 + 431 + 25
        return PCVC_HEIGHT*3 + 25*4 + 300;
    }
}


- (void)setMode:(EAFWebMapGalleryMode)mode {
    if (_mode == mode) {
        return;
    }
    _mode = mode;
    
    // swizzle our views for different modes
    switch (_mode) {
        case EAFWebMapGalleryModeMultiPane:
            self.subGalleryDisplayText = nil;
            
            self.contentScrollView.documentView = self.multiGalleryDocumentView;
            
            [self.singleGalleryContainerView removeConstraints:self.singleGalleryRecentMapsConstraints];
            [self.recentMapsVC.view removeFromSuperview];
            [self.multiGalleryContainerView addSubview:self.recentMapsVC.view];
            [self.multiGalleryContainerView addConstraints:self.multiGalleryRecentMapsConstraints];
            
            if (self.portal.user.username) {
                [self.singleGalleryContainerView removeConstraints:self.singleGalleryFolderListConstraints];
                [self.folderListVC.view removeFromSuperview];
                [self.singleGalleryContainerView removeConstraints:self.singleGalleryGroupListConstraints];
                [self.groupListVC.view removeFromSuperview];
                
                [self.multiGalleryContainerView addSubview:self.groupListVC.view];
                [self.multiGalleryContainerView addConstraints:self.multiGalleryGroupListConstraints];
                
                [self.multiGalleryContainerView addSubview:self.folderListVC.view];
                [self.multiGalleryContainerView addConstraints:self.multiGalleryFolderListConstraints];
            }
            break;
        case EAFWebMapGalleryModeSinglePane:
            self.contentScrollView.documentView = self.singleGalleryDocumentView;
            
            [self.multiGalleryContainerView removeConstraints:self.multiGalleryRecentMapsConstraints];
            [self.recentMapsVC.view removeFromSuperview];
            [self.singleGalleryContainerView addSubview:self.recentMapsVC.view];
            [self.singleGalleryContainerView addConstraints:self.singleGalleryRecentMapsConstraints];
            
            if (self.portal.user.username) {
                [self.multiGalleryContainerView removeConstraints:self.multiGalleryFolderListConstraints];
                [self.folderListVC.view removeFromSuperview];
                [self.multiGalleryContainerView removeConstraints:self.multiGalleryGroupListConstraints];
                [self.groupListVC.view removeFromSuperview];

                [self.singleGalleryContainerView addSubview:self.groupListVC.view];
                [self.singleGalleryContainerView addConstraints:self.singleGalleryGroupListConstraints];
                [self.singleGalleryContainerView addSubview:self.folderListVC.view];
                [self.singleGalleryContainerView addConstraints:self.singleGalleryFolderListConstraints];
            }
            break;
    }
    
    //
    // since our gallery swaps out two different views depending on the
    // current mode, we want to make sure the widths of our documentViews
    // are always inline with the width of the scrollView that they get
    // assigned to
    CGFloat scrollViewWidth = CGRectGetWidth(self.contentScrollView.bounds);
    self.singleGalleryDocumentView.frame = EAFCGRectSetWidth(self.singleGalleryDocumentView.frame, scrollViewWidth);
    self.multiGalleryDocumentView.frame = EAFCGRectSetWidth(self.multiGalleryDocumentView.frame, scrollViewWidth);
}

- (EAFFlippedView*)singleGalleryContainerView {
    if (!_singleGalleryContainerView) {
        _singleGalleryContainerView = [[EAFFlippedView alloc] initWithFrame:NSMakeRect(0, 0, /*875*/1050, [self heightForContent])];
        [_singleGalleryContainerView setWantsLayer:YES];
        //EAFDebugStrokeBorder(_singleGalleryContainerView, 2.0, [NSColor blueColor]);
        _singleGalleryContainerView.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin;
        _singleGalleryContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *singleGalleryWidthConstraint = [NSLayoutConstraint constraintWithItem:_singleGalleryContainerView
                                                                                        attribute:NSLayoutAttributeWidth
                                                                                        relatedBy:NSLayoutRelationEqual
                                                                                           toItem:nil
                                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                                       multiplier:1.0
                                                                                         constant:1050];
        [_singleGalleryContainerView addConstraint:singleGalleryWidthConstraint];
        
        NSLayoutConstraint *singleGalleryHeightConstraint = [NSLayoutConstraint constraintWithItem:_singleGalleryContainerView
                                                                                         attribute:NSLayoutAttributeHeight
                                                                                         relatedBy:NSLayoutRelationEqual
                                                                                            toItem:nil
                                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                                        multiplier:1.0
                                                                                          constant:[self heightForContent]];
        [_singleGalleryContainerView addConstraint:singleGalleryHeightConstraint];

    }
    return _singleGalleryContainerView;
}

- (EAFFlippedView*)singleGalleryDocumentView {
    if (!_singleGalleryDocumentView) {
        self.singleGalleryDocumentView = [[EAFFlippedView alloc] initWithFrame:NSMakeRect(0, 0, CGRectGetWidth(self.contentScrollView.bounds), [self heightForContent])];
        _singleGalleryDocumentView.autoresizingMask = NSViewWidthSizable;
        //EAFDebugStrokeBorder(_singleGalleryDocumentView, 1.0, [NSColor redColor]);
        [_singleGalleryDocumentView addSubview:self.singleGalleryContainerView];
        
        NSLayoutConstraint *singleGalleryCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.singleGalleryContainerView
                                                                                          attribute:NSLayoutAttributeCenterX
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:_singleGalleryDocumentView
                                                                                          attribute:NSLayoutAttributeCenterX
                                                                                         multiplier:1.0
                                                                                           constant:0.0];
        [_singleGalleryDocumentView addConstraint:singleGalleryCenterXConstraint];
        
        NSLayoutConstraint *singleGalleryCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.singleGalleryContainerView
                                                                                          attribute:NSLayoutAttributeCenterY
                                                                                          relatedBy:NSLayoutRelationEqual
                                                                                             toItem:_singleGalleryDocumentView
                                                                                          attribute:NSLayoutAttributeCenterY
                                                                                         multiplier:1.0
                                                                                           constant:0.0];
        [_singleGalleryDocumentView addConstraint:singleGalleryCenterYConstraint];
        
        NSLayoutConstraint *scrollDocumentWidthConstraint = [NSLayoutConstraint constraintWithItem:_singleGalleryDocumentView
                                                                                         attribute:NSLayoutAttributeWidth
                                                                                         relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                                            toItem:nil
                                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                                        multiplier:1.0
                                                                                          constant:1100.0];
        [_singleGalleryDocumentView addConstraint:scrollDocumentWidthConstraint];
    }
    return _singleGalleryDocumentView;
}

- (EAFFlippedView*)multiGalleryContainerView {
    if (!_multiGalleryContainerView) {
        _multiGalleryContainerView = [[EAFFlippedView alloc] initWithFrame:NSMakeRect(0, 0, /*875*/1050, [self heightForContent])];
        [_multiGalleryContainerView setWantsLayer:YES];
        //EAFDebugStrokeBorder(_multiGalleryContainerView, 2.0, [NSColor blueColor]);
        _multiGalleryContainerView.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin;
        _multiGalleryContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *multiGalleryWidthConstraint = [NSLayoutConstraint constraintWithItem:_multiGalleryContainerView
                                                                                       attribute:NSLayoutAttributeWidth
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:nil
                                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                                      multiplier:1.0
                                                                                        constant:1050];
        [_multiGalleryContainerView addConstraint:multiGalleryWidthConstraint];
        
        NSLayoutConstraint *multiGalleryHeightConstraint = [NSLayoutConstraint constraintWithItem:_multiGalleryContainerView
                                                                                        attribute:NSLayoutAttributeHeight
                                                                                        relatedBy:NSLayoutRelationEqual
                                                                                           toItem:nil
                                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                                       multiplier:1.0
                                                                                         constant:[self heightForContent]];
        [_multiGalleryContainerView addConstraint:multiGalleryHeightConstraint];
        
    }
    return _multiGalleryContainerView;
}

- (EAFFlippedView*)multiGalleryDocumentView {
    if (!_multiGalleryDocumentView) {
        self.multiGalleryDocumentView = [[EAFFlippedView alloc] initWithFrame:NSMakeRect(0, 0, CGRectGetWidth(self.contentScrollView.bounds), [self heightForContent])];
        _multiGalleryDocumentView.autoresizingMask = NSViewWidthSizable;
        //EAFDebugStrokeBorder(_multiGalleryDocumentView, 1.0, [NSColor redColor]);
        [_multiGalleryDocumentView addSubview:self.multiGalleryContainerView];
        
        NSLayoutConstraint *multiGalleryCenterXConstraint = [NSLayoutConstraint constraintWithItem:self.multiGalleryContainerView
                                                                                         attribute:NSLayoutAttributeCenterX
                                                                                         relatedBy:NSLayoutRelationEqual
                                                                                            toItem:_multiGalleryDocumentView
                                                                                         attribute:NSLayoutAttributeCenterX
                                                                                        multiplier:1.0
                                                                                          constant:0.0];
        [_multiGalleryDocumentView addConstraint:multiGalleryCenterXConstraint];
        
        NSLayoutConstraint *multiGalleryCenterYConstraint = [NSLayoutConstraint constraintWithItem:self.multiGalleryContainerView
                                                                                         attribute:NSLayoutAttributeCenterY
                                                                                         relatedBy:NSLayoutRelationEqual
                                                                                            toItem:_multiGalleryDocumentView
                                                                                         attribute:NSLayoutAttributeCenterY
                                                                                        multiplier:1.0
                                                                                          constant:0.0];
        [_multiGalleryDocumentView addConstraint:multiGalleryCenterYConstraint];
        
        NSLayoutConstraint *scrollDocumentWidthConstraint = [NSLayoutConstraint constraintWithItem:_multiGalleryDocumentView
                                                                                         attribute:NSLayoutAttributeWidth
                                                                                         relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                                            toItem:nil
                                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                                        multiplier:1.0
                                                                                          constant:1100.0];
        [_multiGalleryDocumentView addConstraint:scrollDocumentWidthConstraint];
    }
    return _multiGalleryDocumentView;
}

- (void)awakeFromNib {
#ifdef USE_TEXTURED_BACKGROUND
    self.contentScrollView.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"LightGrayTexture100x100"]];
#else
    self.contentScrollView.backgroundColor = [NSColor eaf_lighterGrayColor];
#endif
    self.contentScrollView.documentView = self.multiGalleryDocumentView;
    [self.contentScrollView setHasHorizontalScroller:NO];
    [self.contentScrollView setHasVerticalScroller:YES];

    //
    // subviews of this may want to modify the layer properties..
    [self.contentScrollView setWantsLayer:YES];
    
    //
    // create our banner view
    self.bannerView = [[EAFRoundedView alloc] initWithFrame:NSMakeRect(0, 0, 1050, 300)];
    self.bannerView.backgroundColor = [NSColor clearColor];
    self.bannerView.cornerRadius = 5.0f;
    self.bannerView.cornerFlags = NSBezierPathRoundedCornerBottomLeft | NSBezierPathRoundedCornerBottomRight;
    self.bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    //
    // if the user logs into an org, we will fetch the image from the portal so
    // we will need a handle to this image view
    self.bannerImageView = [[NSImageView alloc] initWithFrame:self.bannerView.bounds];
    self.bannerImage = [NSImage imageNamed:@"default-banner1050x300"];
    [self.bannerImageView setImage:self.bannerImage];
    //
    // if we have an org -- fetch the banner image, else use the default
    if (self.portal.portalInfo.organizationName) {
        self.bannerOp = [self.portal.portalInfo fetchOrganizationBanner];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchedBanner:) name:AGSPortalInfoDidFetchOrganizationBanner object:self.portal.portalInfo];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchBannerFailed:) name:AGSPortalInfoDidFailToFetchOrganizationBanner object:self.portal.portalInfo];
        //
        // we hide the image until the fetch operation returns
        // and then set the new image (if exists) and unhide it
        [self.bannerImageView setHidden:YES];
    }
    self.bannerImageView.imageScaling = NSImageScaleProportionallyUpOrDown;

    //
    // add subview using constraints
    [self.bannerView eaf_addSubview:self.bannerImageView inset:CGSizeZero];
    NSView *bannerIV = self.bannerImageView;
    //
    // this ensures that our banner container view will always be the size of the banner image
    NSArray *bannerImageHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[bannerIV]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(bannerIV)];
    bannerIV.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bannerView addConstraints:bannerImageHConstraints];
    
    
    [self.multiGalleryContainerView addSubview:self.bannerView];
    
    NSView *bannerView = self.bannerView;
    NSArray *bannerVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[bannerView(<=300)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(bannerView)];
    NSArray *bannerHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[bannerView(<=1050)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(bannerView)];
    [self.multiGalleryContainerView addConstraints:bannerVConstraints];
    [self.multiGalleryContainerView addConstraints:bannerHConstraints];
    
    //
    // create the constraints for our banner view
    NSLayoutConstraint *alignX = [NSLayoutConstraint constraintWithItem:self.bannerView
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.multiGalleryContainerView
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1.0
                                                               constant:0.0];
    [self.multiGalleryContainerView addConstraint:alignX];
    
    NSLayoutConstraint *topY = [NSLayoutConstraint constraintWithItem:self.bannerView
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.multiGalleryContainerView
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1.0
                                                             constant:0.0];
    [self.multiGalleryContainerView addConstraint:topY];

    //
    // we want to know the last view so we can set the constraints on the next view
    NSView *prevView = self.bannerView;
    
    if ([self shouldShowMyMaps]) {
        //
        // this is my maps
        self.myMapsVC = [[EAFPortalCollectionViewController alloc] initWithTitle:@"My Maps" contentType:EAFPortalContentTypeMyMaps portal:self.portal queryParams:nil];
        self.myMapsVC.itemDelegate = self;

        [self.multiGalleryContainerView addSubview:self.myMapsVC.view];
        
        //
        // we want myMaps to be just below the banner view
        NSView *myMapsView = self.myMapsVC.view;
        myMapsView.translatesAutoresizingMaskIntoConstraints = NO;
        NSArray *myMapsVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[prevView]-25-[myMapsView(==431)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(prevView, myMapsView)];
        NSArray *myMapsHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[myMapsView(==825)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(myMapsView)];
        [self.multiGalleryContainerView addConstraints:myMapsVConstraints];
        [self.multiGalleryContainerView addConstraints:myMapsHConstraints];
        prevView = myMapsView;
    }
    
    self.featuredContentVC = [[EAFPortalCollectionViewController alloc] initWithTitle:@"Featured Content" contentType:EAFPortalContentTypeFeaturedContent portal:self.portal queryParams:nil];
    self.featuredContentVC.itemDelegate = self;
    [self.featuredContentVC.view setWantsLayer:YES];
    [self.multiGalleryContainerView addSubview:self.featuredContentVC.view];
    //
    // we want featuredContent to be just below the previous content view
    NSView *fcView = self.featuredContentVC.view;
    fcView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *fcVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[prevView]-25-[fcView(==431)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(prevView, fcView)];
    NSArray *fcHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[fcView(==825)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(fcView)];
    [self.multiGalleryContainerView addConstraints:fcVConstraints];
    [self.multiGalleryContainerView addConstraints:fcHConstraints];
    prevView = fcView;
    
    self.mostViewedVC = [[EAFPortalCollectionViewController alloc] initWithTitle:@"Most Viewed" contentType:EAFPortalContentTypeMostViewed portal:self.portal queryParams:nil];
    self.mostViewedVC.itemDelegate = self;
    [self.multiGalleryContainerView addSubview:self.mostViewedVC.view];
    //
    // we want mostViewed to be just below the previous content view
    NSView *mvView = self.mostViewedVC.view;
    mvView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *mvVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[prevView]-25-[mvView(==431)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(prevView, mvView)];
    NSArray *mvHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[mvView(==825)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(mvView)];
    [self.multiGalleryContainerView addConstraints:mvVConstraints];
    [self.multiGalleryContainerView addConstraints:mvHConstraints];
    prevView = mvView;
    
    //
    // highest rated
    self.highestRatedVC = [[EAFPortalCollectionViewController alloc] initWithTitle:@"Highest Rated" contentType:EAFPortalContentTypeHighestRated portal:self.portal queryParams:nil];
    self.highestRatedVC.itemDelegate = self;
    [self.multiGalleryContainerView addSubview:self.highestRatedVC.view];
    //
    // we want highestRated to be just below the previous content view
    NSView *hrView = self.highestRatedVC.view;
    hrView.translatesAutoresizingMaskIntoConstraints = NO;
    NSArray *hrVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[prevView]-25-[hrView(==431)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(prevView, hrView)];
    NSArray *hrHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[hrView(==825)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(hrView)];
    [self.multiGalleryContainerView addConstraints:hrVConstraints];
    [self.multiGalleryContainerView addConstraints:hrHConstraints];
    prevView = hrView;
    
    
    //self.mode = EAFWebMapGalleryModeMultiPane;
    
    //
    // since we know we are starting off in our "multi-pane" mode, let's add groups/recent maps
    
    [self.multiGalleryContainerView addSubview:self.recentMapsVC.view];

    [self.multiGalleryContainerView addConstraints:self.multiGalleryRecentMapsConstraints];
    
    //
    // if we are logged in, let's show this user's groups
    if (self.portal.user.username) {
        [self.multiGalleryContainerView addSubview:self.groupListVC.view];
        [self.multiGalleryContainerView addConstraints:self.multiGalleryGroupListConstraints];
        
        [self.multiGalleryContainerView addSubview:self.folderListVC.view];
        [self.multiGalleryContainerView addConstraints:self.multiGalleryFolderListConstraints];
    }
    
    self.fwmvc = [[EAFFindWebMapsViewController alloc] initWithNibName:@"EAFFindWebMapsViewController" bundle:nil];
    self.fwmvc.delegate = self;
}

- (BOOL)shouldShowMyMaps {
    return ![EAFAppContext sharedAppContext].tryingItNow && self.portal.user.username;
}

#pragma mark -
#pragma mark Setters

//
// when we are given a new banner image, we need to set it on the bannerImageView
- (void)setBannerImage:(NSImage *)bannerImage {
    _bannerImage = bannerImage;
    [self.bannerImageView setImage:_bannerImage];
}

#pragma mark -
#pragma mark EAFPortalCollectionViewControllerDelegate

- (void)pcvc:(EAFPortalCollectionViewController*)pcvc wantsToOpenPortalItem:(AGSPortalItem *)portalItem {
    if ([self.delegate respondsToSelector:@selector(webMapGallery:wantsToOpenPortalItem:)]) {
        [self.delegate webMapGallery:self wantsToOpenPortalItem:portalItem];
    }
}

- (void)pcvc:(EAFPortalCollectionViewController*)pcvc wantsToShowInfoForPortalItem:(AGSPortalItem *)portalItem {
    EAFPortalItemInfoViewController *piivc = [[EAFPortalItemInfoViewController alloc] initWithPortalItem:portalItem];
    
    NSRect current = NSMakeRect(pcvc.view.bounds.origin.x, pcvc.view.bounds.origin.y, 800, 600);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:current/*pcvc.view.bounds*/ styleMask:NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
    [window setContentView:piivc.view];
    window.delegate = self;
    [window setReleasedWhenClosed:NO];
    
    //
    // this next bit of code allows default run loop to continue to process events while
    // we are showing this window
    NSModalSession modalSession = [NSApp beginModalSessionForWindow:window];
    NSInteger result = NSRunContinuesResponse;

    while (result == NSRunContinuesResponse)
    {
        //run the modal session
        //once the modal window finishes, it will return a different result and break out of the loop
        result = [NSApp runModalSession:modalSession];
        
        //this gives the main run loop some time so your other code processes
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        
        //do some other non-intensive task if necessary
    }

    [NSApp endModalSession:modalSession];
}

- (void)windowWillClose:(NSNotification *)notification {
    [NSApp stopModal];
}


#pragma mark -
#pragma mark EAFFindWebMapsDelegate

- (EAFRecentMapsTableViewController*)recentMapsVC {
    if (!_recentMapsVC) {
        _recentMapsVC = [[EAFRecentMapsTableViewController alloc] initWithTitle:@"Recent Maps" portal:self.portal];
        NSArray *recentMaps = [[[EAFAppContext sharedAppContext] recentMaps] allObjects];
        [_recentMapsVC addPortalContent:recentMaps];
        _recentMapsVC.maxVisibleItems = 10;
        _recentMapsVC.delegate = self;

        _recentMapsVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _recentMapsVC;
}

- (NSArray*)singleGalleryRecentMapsConstraints {
    if (!_singleGalleryRecentMapsConstraints) {
        NSView *recentMapsView = _recentMapsVC.view;
        NSArray *mgrmVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-25-[recentMapsView(==231)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(recentMapsView)];
        NSArray *mgrmHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[recentMapsView(==200)]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(recentMapsView)];
        NSMutableArray *constraints = [NSMutableArray arrayWithArray:mgrmVConstraints];
        [constraints addObjectsFromArray:mgrmHConstraints];
        _singleGalleryRecentMapsConstraints = [NSArray arrayWithArray:constraints];
    }
    return _singleGalleryRecentMapsConstraints;
}

- (NSArray*)multiGalleryRecentMapsConstraints {
    if (!_multiGalleryRecentMapsConstraints) {
        NSView *recentMapsView = _recentMapsVC.view;
        NSView *bannerView = self.bannerView;
        NSArray *mgrmVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[bannerView]-25-[recentMapsView(==231)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(recentMapsView, bannerView)];
        NSArray *mgrmHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[recentMapsView(==200)]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(recentMapsView)];
        NSMutableArray *constraints = [NSMutableArray arrayWithArray:mgrmVConstraints];
        [constraints addObjectsFromArray:mgrmHConstraints];
        _multiGalleryRecentMapsConstraints = [NSArray arrayWithArray:constraints];

    }
    return _multiGalleryRecentMapsConstraints;
}

- (EAFPortalFolderTableViewController*)folderListVC {
    if (!_folderListVC) {
        _folderListVC = [[EAFPortalFolderTableViewController alloc] initWithTitle:@"Folders" portal:self.portal];
        _folderListVC.delegate = self;
        _folderListVC.maxVisibleItems = 10;
        [self.multiGalleryContainerView addSubview:_folderListVC.view];
        
        _folderListVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _folderListVC;
}

- (NSArray*)singleGalleryFolderListConstraints {
    if (!_singleGalleryFolderListConstraints) {        
        NSView *folderListView = _folderListVC.view;
        NSView *groupListView = self.groupListVC.view;
        NSArray *sgflVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[groupListView]-25-[folderListView(==231)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(folderListView, groupListView)];
        NSArray *sgflHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[folderListView(==200)]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(folderListView)];
        NSMutableArray *constraints = [NSMutableArray arrayWithArray:sgflVConstraints];
        [constraints addObjectsFromArray:sgflHConstraints];
        _singleGalleryFolderListConstraints = [NSArray arrayWithArray:constraints];
    }
    return _singleGalleryFolderListConstraints;
}

- (NSArray*)multiGalleryFolderListConstraints {
    if (!_multiGalleryFolderListConstraints) {
        NSView *folderListView = _folderListVC.view;
        NSView *groupListView = self.groupListVC.view;
        NSArray *mgflVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[groupListView]-25-[folderListView(==231)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(folderListView, groupListView)];
        NSArray *mgflHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[folderListView(==200)]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(folderListView)];
        NSMutableArray *constraints = [NSMutableArray arrayWithArray:mgflVConstraints];
        [constraints addObjectsFromArray:mgflHConstraints];
        _multiGalleryFolderListConstraints = [NSArray arrayWithArray:constraints];

    }
    return _multiGalleryFolderListConstraints;
}

- (EAFPortalGroupTableViewController*)groupListVC {
    if (!_groupListVC) {
        _groupListVC = [[EAFPortalGroupTableViewController alloc] initWithTitle:@"Groups" portal:self.portal];
        _groupListVC.delegate = self;
        _groupListVC.maxVisibleItems = 10;
        //[self.multiGalleryContainerView addSubview:_groupListVC.view];
        
        _groupListVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _groupListVC;
}

- (NSArray*)singleGalleryGroupListConstraints {
    if (!_singleGalleryGroupListConstraints) {        
        NSView *groupListView = _groupListVC.view;
        NSView *recentMapsView = self.recentMapsVC.view;
        NSArray *sgglVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[recentMapsView]-25-[groupListView(==231)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(groupListView, recentMapsView)];
        NSArray *sgglHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[groupListView(==200)]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(groupListView)];
        NSMutableArray *constraints = [NSMutableArray arrayWithArray:sgglVConstraints];
        [constraints addObjectsFromArray:sgglHConstraints];
        _singleGalleryGroupListConstraints = [NSArray arrayWithArray:constraints];
    }
    return _singleGalleryGroupListConstraints;
}

- (NSArray*)multiGalleryGroupListConstraints {
    if (!_multiGalleryGroupListConstraints) {
        NSView *groupListView = _groupListVC.view;
        NSView *recentMapsView = self.recentMapsVC.view;
        NSArray *mgglVConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[recentMapsView]-25-[groupListView(==231)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(groupListView, recentMapsView)];
        NSArray *mgglHConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[groupListView(==200)]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(groupListView)];
        NSMutableArray *constraints = [NSMutableArray arrayWithArray:mgglVConstraints];
        [constraints addObjectsFromArray:mgglHConstraints];
        _multiGalleryGroupListConstraints = [NSArray arrayWithArray:constraints];
    }
    return _multiGalleryGroupListConstraints;
}

- (EAFPortalCollectionViewController*)subGalleryVC {
    if (!_subGalleryVC) {
        self.subGalleryVC = [[EAFPortalCollectionViewController alloc] initWithTitle:@"Search" contentType:EAFPortalContentTypeItems portal:self.portal queryParams:nil];
        _subGalleryVC.maxVisibleItems = 45;
        _subGalleryVC.itemDelegate = self;
        _subGalleryVC.shouldAutoresizeToFitContent = YES;
        _subGalleryVC.view.frame = NSMakeRect(0, 25, 825, 1535);
        [_subGalleryVC.view setWantsLayer:YES];
        
        //
        // since the subgallery is shown secondary to the main gallery, we will add the subview
        // lazily
        [self.singleGalleryContainerView addSubview:_subGalleryVC.view];
        [self.singleGalleryDocumentView addSubview:self.singleGalleryContainerView];

    }
    return _subGalleryVC;
}


- (void)fwmvc:(EAFFindWebMapsViewController *)fmwvc wantsToSearchForMapsWithQueryParams:(AGSPortalQueryParams *)queryParams {
    [self showSubGallery];
    
    queryParams.limit = 45;
    self.subGalleryVC.queryParams = queryParams;
    [self.subGalleryVC removeAllPortalContent];
    [self.subGalleryVC loadPortalContentWithQueryParams:queryParams];
    NSString *subGalleryDisplayString = [NSString stringWithFormat:@"Search - '%@'", [fmwvc.searchField stringValue]];
    self.subGalleryVC.title = subGalleryDisplayString;
    self.subGalleryDisplayText = subGalleryDisplayString;
    if ([self.delegate respondsToSelector:@selector(webMapGallery:didSwitchToSubGallery:)]) {        
        [self.delegate webMapGallery:self didSwitchToSubGallery:subGalleryDisplayString];
    }
}

#pragma mark -
#pragma mark EAFPortalGroupTableViewDelegate

- (void)pgtvc:(EAFPortalGroupTableViewController *)pgtvc wantsToOpenPortalGroup:(AGSPortalGroup *)group {
    [self showSubGallery];
    
    AGSPortalQueryParams *queryparams = [AGSPortalQueryParams queryParamsForItemsOfType:AGSPortalItemTypeWebMap inGroup:group.groupId];
    queryparams.limit = 45;
    self.subGalleryVC.contentType = EAFPortalContentTypeItems;
    self.subGalleryVC.title = group.title;
    [self.subGalleryVC removeAllPortalContent];
    [self.subGalleryVC loadPortalContentWithQueryParams:queryparams];
    
    self.subGalleryDisplayText = group.title;
    

    //
    // notify delegate (app) that we are switching to a group w/ title
    if ([self.delegate respondsToSelector:@selector(webMapGallery:didSwitchToSubGallery:)]) {
        [self.delegate webMapGallery:self didSwitchToSubGallery:group.title];
    }
}

#pragma mark -
#pragma mark EAFPortalFolderTableViewDelegate

- (void)pftvc:(EAFPortalFolderTableViewController *)pftvc wantsToOpenPortalFolder:(AGSPortalFolder *)folder {
    [self showSubGallery];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchedUserFolderContent:) name:AGSPortalDidFetchPortalUserContentNotification object:self.portal.user];
    
    //
    // by setting the queryOp, this will tell the controller that we are waiting on items to come back
    // so don't display the "No Maps to Display" text
    self.subGalleryVC.queryOp = [self.portal.user fetchContentInFolder:folder.folderId];
    self.subGalleryVC.maxVisibleItems = 45;
    [self.subGalleryVC showLoadingView];
    [self.subGalleryVC removeAllPortalContent];
    [self.subGalleryVC updateVisibleItems];
    self.subGalleryVC.contentType = EAFPortalContentTypeItems;
    self.subGalleryVC.title = folder.title;
    self.subGalleryDisplayText = folder.folderId;

    //
    // notify delegate (app) that we are switching to a group w/ title
    if ([self.delegate respondsToSelector:@selector(webMapGallery:didSwitchToSubGallery:)]) {
        [self.delegate webMapGallery:self didSwitchToSubGallery:folder.title];
    }
}

- (void)fetchedUserFolderContent:(NSNotification*)note {
    self.subGalleryVC.queryOp = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AGSPortalDidFetchPortalUserContentNotification object:self.portal.user];
    
    [self.subGalleryVC hideLoadingView];
    NSDictionary *userInfo = [note userInfo];

    NSArray *items = [userInfo valueForKey:@"items"];
//    [self.subGalleryVC removeAllPortalContent];
    [self.subGalleryVC addPortalContent:items];
    //
    // in this case the user content query fetches ALL items in the folder
    // so we need to set the totalResults to our item count
    self.subGalleryVC.totalResults = items.count;
    [self.subGalleryVC updateVisibleItems];
}


#pragma mark -
#pragma mark EAFRecentMapsTableViewDelegate

- (void)rmtvc:(EAFRecentMapsTableViewController *)rmtvc wantsToOpenPortalItem:(AGSPortalItem *)item {
    if ([self.delegate respondsToSelector:@selector(webMapGallery:wantsToOpenPortalItem:)]) {
        [self.delegate webMapGallery:self wantsToOpenPortalItem:item];
    }
}

#pragma mark -
#pragma mark Banner Fetching Notifications

- (void)fetchedBanner:(NSNotification*)note {
    self.bannerOp = nil;
    NSImage *img = [[note userInfo] ags_safeObjectForKey:@"banner"];
    if (img) {
        [self.bannerImageView setImage:img];
    }
    [self.bannerImageView setHidden:NO];
}

- (void)fetchBannerFailed:(NSNotification*)note {
    self.bannerOp = nil;
    [self.bannerImageView setHidden:NO];
}
@end
