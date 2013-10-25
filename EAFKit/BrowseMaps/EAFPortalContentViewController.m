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
#import "EAFRoundedView.h"
#import "EAFGradientView.h"
#import "NSGradient+EAFAdditions.h"
#import "EAFTitledView.h"
#import "EAFAppContext.h"
#import "EAFHyperlinkButton.h"

//#define USE_APP_STORE_TITLE_VIEW_GRADIENT

@interface EAFPortalContentViewController ()

@property (nonatomic, strong) IBOutlet NSTextField *infoTextField;

@property (nonatomic, copy) NSString *contentTitle;

@property (nonatomic, strong) NSProgressIndicator *progressIndicator;


@property (nonatomic, assign) NSInteger totalResults;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) NSInteger totalPages;

@property (nonatomic, weak) AGSPortal *portal;

@property (nonatomic, strong) NSOperation *queryOp;

@property (nonatomic, strong) NSMutableArray *visibleItems;
@property (nonatomic, strong) NSMutableArray *portalContent;

@end

@implementation EAFPortalContentViewController

- (void)dealloc {
    [self.queryOp cancel];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithTitle:(NSString*)title contentType:(EAFPortalContentType)contentType portal:(AGSPortal*)portal queryParams:(AGSPortalQueryParams*)queryParams{
    if (self = [super initWithNibName:@"EAFPortalContentViewController" bundle:nil]) {

        self.contentType = contentType;
        self.contentTitle = title;
        self.portal = portal;
        self.currentPage = 1;
        self.portalContent = @[];
        //self.nextQueryParams = queryParams;
        self.maxVisibleItems = 12;

        
        if (self.portal.loaded) {
            // kick off queries...
            //
            // give dev a chance to set properties before kicking off...
            [self performSelector:@selector(portalLoaded:) withObject:nil afterDelay:0.0];
        }
        else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portalLoaded:) name:AGSPortalDidLoadNotification object:self.portal];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foundItems:) name:AGSPortalDidFindItemsNotification object:self.portal];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedToFindItems:) name:AGSPortalDidFailToFindItemsNotification object:self.portal];
    }
    return self;
}

- (NSString*)title {
    return self.titledView.title;
}

- (void)setTitle:(NSString *)title {
    self.titledView.title = title;
}

- (void)setCurrentPage:(NSInteger)currentPage {
    self.titledView.currentPage = currentPage;
}

- (NSInteger)currentPage {
    //
    // we default to 1, because in some cases we may be accessing current
    // page before the titldView has been created, in which case our
    // current page should be 1
    return self.titledView.currentPage ? self.titledView.currentPage : 1;
}

- (void)setTotalPages:(NSInteger)totalPages {
    self.titledView.totalPages = totalPages;
}

-(NSInteger)totalPages {
    return self.titledView.totalPages;
}

- (void)setTotalResults:(NSInteger)totalResults {
    _totalResults = totalResults;
    NSInteger fullPages = _totalResults / self.maxVisibleItems;
    NSInteger partialPages = (_totalResults % self.maxVisibleItems) > 0 ? 1 : 0;
    self.totalPages = fullPages + partialPages;
}

- (void)queryGeneric {
    if (self.nextQueryParams) {
        self.nextQueryParams.limit = self.maxVisibleItems;
        self.queryOp = [self.portal findItemsWithQueryParams:self.nextQueryParams];        
    }
}

- (NSOperation*)loadPortalContentWithQueryParams:(AGSPortalQueryParams*)queryParams {
    switch (self.contentType) {
        case EAFPortalContentTypeFeaturedContent:
        case EAFPortalContentTypeHighestRated:
        case EAFPortalContentTypeMostViewed:
        case EAFPortalContentTypeMyMaps:
        case EAFPortalContentTypeFolders:
        case EAFPortalContentTypeItems:
            self.queryOp = [self.portal findItemsWithQueryParams:queryParams];
            break;
        case EAFPortalContentTypeGroups:
            self.queryOp = [self.portal findGroupsWithQueryParams:queryParams];
            break;            
        default:
            return nil;
    }
    [self showLoadingView];
    return self.queryOp;
}

- (void)eaf_kickoffQuery {
//    [self doesNotRecognizeSelector:_cmd];
}

- (void)portalLoaded:(NSNotification*)note {
    [self eaf_kickoffQuery];
}

- (void)foundItems:(NSNotification*)note {
    NSDictionary *userInfo = [note userInfo];
    NSOperation *op = [userInfo objectForKey:@"operation"];
    if (self.queryOp == op) {
        AGSPortalQueryResultSet *resultSet = [userInfo objectForKey:@"resultSet"];
        self.nextQueryParams = resultSet.nextQueryParams;
        
        //
        // our query result tells us the number of total results
        // so we set that here
        self.totalResults = resultSet.totalResults;
        
        [self addPortalContent:resultSet.results];
        [self updateVisibleItems];
        [self hideLoadingView];
        self.queryOp = nil;
    }
}

- (void)failedToFindItems:(NSNotification*)note {
    NSDictionary *userInfo = [note userInfo];
    NSOperation *op = [userInfo objectForKey:@"operation"];
    if (self.queryOp == op) {
        [self hideLoadingView];
        self.queryOp = nil;
    }
}

- (void)addPortalContent:(NSArray*)portalContent {
    NSMutableArray *content = [NSMutableArray arrayWithArray:self.portalContent];
    [content addObjectsFromArray:portalContent];
    self.portalContent = content;
}

- (void)removeAllPortalContent{
    self.portalContent = @[];
    self.totalPages = 1;
    self.currentPage = 1;
    self.totalResults = 0;
    self.titledView.showPageInfo = NO;
}

- (void)awakeFromNib {
    [self.view setWantsLayer:YES];
    self.view.layer.backgroundColor = [[NSColor lightGrayColor] CGColor];
    self.view.layer.borderWidth = 1.0f;
    self.view.layer.borderColor = [[NSColor lightGrayColor] CGColor];
    self.view.layer.cornerRadius = 5.0f;
    
    self.title = self.contentTitle;
    
#ifdef USE_APP_STORE_TITLE_VIEW_GRADIENT
    EAFGradientView *gradientView = [[EAFGradientView alloc] initWithStartGradient:[NSGradient eaf_appStoreTitleBarBottomGradient]
                                                                       endGradient:[NSGradient eaf_appStoreTitleBarTopGradient]];
#else
    EAFGradientView *gradientView = [[EAFGradientView alloc] initWithStartGradient:[NSGradient eaf_breadCrumbGradient]];
#endif
    gradientView.frame = self.titledView.titleBarView.bounds;
    gradientView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    gradientView.angle = 90.0f;
    [self.titledView.titleBarView addSubview:gradientView];
    
    //
    // add target/action to our titledView's buttons
    [self.titledView.nextButton setTarget:self];
    [self.titledView.nextButton setAction:@selector(nextItemBtnClicked)];
    
    [self.titledView.prevButton setTarget:self];
    [self.titledView.prevButton setAction:@selector(prevItemBtnClicked)];

    //
    // add our progress indicator to show while querying portal items
    NSRect piFrame = NSMakeRect(CGRectGetMidX(self.titledView.contentView.bounds) - 50, CGRectGetMidY(self.titledView.contentView.bounds) - 50, 100, 100);
    self.progressIndicator = [[NSProgressIndicator alloc] initWithFrame:piFrame];
    [self.progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
    [self.progressIndicator setHidden:YES];
    self.progressIndicator.autoresizingMask = NSViewMinYMargin | NSViewMaxYMargin;
    [self.view addSubview:self.progressIndicator];
}

- (void)prevItemBtnClicked {
    //
    // if the user clicks back while we are querying the next set of items,
    // cancel the query and hide the loading view.
    [self.queryOp cancel];
    [self hideLoadingView];
    
    self.currentPage--;
    [self updateVisibleItems];
}

- (void)nextItemBtnClicked {
    self.currentPage++;
    [self updateVisibleItems];
    if (!self.visibleItems.count) {
        // if we don't currently have any items, we need to query
        // so disable the next button until this query comes back
        [self.titledView.nextButton setEnabled:NO];
        self.queryOp = [self loadPortalContentWithQueryParams:self.nextQueryParams];
//        self.queryOp = [self.portal findItemsWithQueryParams:self.nextQueryParams];
//        [self showLoadingView];
    }

}


//
// subclasses need to implement this!
- (void)reloadData {
    [self doesNotRecognizeSelector:_cmd];
}


- (void)updateVisibleItems {
    self.visibleItems = nil;
    
    //
    // if we are currently querying, don't show "no maps" display text
    if (!self.portalContent.count && !self.queryOp.isExecuting) {
        [self.infoTextField setHidden:NO];
        [self reloadData];
        return;
    }
    
    NSUInteger startLoc = (self.currentPage - 1) * self.maxVisibleItems;
    if (startLoc == self.portalContent.count) {
//        [self.infoTextField setHidden:NO];
//        [self reloadData];
        // we need to get more items...
        return;
    }
    
    [self.infoTextField setHidden:YES];

    NSUInteger range = 0;
    
    //
    // get the range of visible items in the portalContent array
    range = (self.portalContent.count - startLoc) / self.maxVisibleItems >= 1 ? self.maxVisibleItems : self.portalContent.count % self.maxVisibleItems;

    self.visibleItems = [self.portalContent subarrayWithRange:NSMakeRange(startLoc, range)];

    //
    // if our content view controller is updated with 0 items, show info display
    if (self.visibleItems.count) {
        [self.infoTextField setHidden:YES];
        [self.titledView.prevButton setEnabled:(self.currentPage - 1) > 0 ? YES : NO];
        [self.titledView.nextButton setEnabled:YES];
    }
    else {
        [self.infoTextField setHidden:NO];
        [self.titledView.prevButton setEnabled:NO];
        [self.titledView.nextButton setEnabled:NO];
    }
    
    if (!self.nextQueryParams && (self.currentPage*self.maxVisibleItems/* + self.maxVisibleItems*/) >= /*self.portalContent.count*/self.totalResults) {
        [self.titledView.nextButton setEnabled:NO];
    }
    
    [self reloadData];
}

- (void)showLoadingView {
    [self.progressIndicator startAnimation:nil];
    [self.progressIndicator setHidden:NO];
}

- (void)hideLoadingView {
    [self.progressIndicator stopAnimation:nil];
    [self.progressIndicator setHidden:YES];
}
@end
