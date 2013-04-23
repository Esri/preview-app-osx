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
#import "EAFPortalContentViewController+Internal.h"
#import "EAFPortalCollectionViewController.h"
#import "EAFRoundedView.h"
#import "EAFTitledView.h"
#import "EAFCollectionView.h"
#import "EAFCollectionViewItem.h"
#import "EAFCGUtils.h"
#import "AGSPortalQueryParams+EAFAdditions.h"

@interface EAFPortalCollectionViewController ()<EAFCollectionViewPortalItemDelegate>
@property (nonatomic, strong) EAFCollectionView *collectionView;
@end

@implementation EAFPortalCollectionViewController

- (id)initWithTitle:(NSString*)title contentType:(EAFPortalContentType)contentType portal:(AGSPortal*)portal queryParams:(AGSPortalQueryParams*)queryParams {
    self = [super initWithTitle:title contentType:contentType portal:portal queryParams:queryParams];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foundGroups:) name:AGSPortalDidFindGroupsNotification object:self.portal];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedToFindGroups:) name:AGSPortalDidFailToFindGroupsNotification object:self.portal];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // setup our view...add collection view
    self.collectionView = [[EAFCollectionView alloc] initWithFrame:self.titledView.contentView.bounds];
    self.collectionView.portalItemDelegate = self;
    [self.collectionView setMaxNumberOfColumns:3];
    [self.collectionView setMaxItemSize:NSMakeSize(275, 100)];
    [self.collectionView setMinItemSize:NSMakeSize(275, 100)];
    [self.collectionView setAutoresizingMask:(NSViewMinXMargin
                                              | NSViewWidthSizable
                                              | NSViewMaxXMargin
                                              | NSViewMinYMargin
                                              | NSViewHeightSizable
                                              | NSViewMaxYMargin)];

    [self.titledView.contentView addSubview:self.collectionView];

}

- (void)reloadData {
    if (!self.visibleItems.count) {
        [self.collectionView setHidden:YES];
    }
    else {
        [self.collectionView setHidden:NO];
        [self.collectionView setContent:self.visibleItems];
    }

    if (self.shouldAutoresizeToFitContent) {
        //
        // if there are no visible maps -- set the height to a nice default value
        if (!self.visibleItems.count) {
            self.view.frame = EAFCGRectSetHeight(self.view.frame, 400);
            return;
        }
        
        //
        // we need to calculate how many rows of content we actually have
        NSInteger fullRows = self.visibleItems.count / self.collectionView.maxNumberOfColumns;
        NSInteger partialRows = self.visibleItems.count % self.collectionView.maxNumberOfColumns == 0 ? 0 : 1;
        NSInteger totalRows = fullRows + partialRows;
        
        //
        // calculate the new height of the content, we have a fixed height so we can do this
        CGFloat contentViewNewHeight = totalRows * self.collectionView.minItemSize.height;
        //
        // figure out what the old height of the content was
        CGFloat contentViewOldHeight = CGRectGetHeight(self.collectionView.bounds);
        
        //
        // if we don't have the max visible items we may need to adjust the view's height
        // so we inset the maxY value by the difference between the old height and new height
        self.view.frame = EAFCGRectInsetMaxY(self.view.frame, contentViewOldHeight - contentViewNewHeight);
    }
}

- (void)eaf_kickoffQuery {
    switch (self.contentType) {
        case EAFPortalContentTypeFeaturedContent:
            [self loadFeaturedContent];
            break;
        case EAFPortalContentTypeHighestRated:
            [self loadHighestRated];
            break;
        case EAFPortalContentTypeMostViewed:
            [self loadMostViewed];
            break;
        case EAFPortalContentTypeMyMaps:
            [self loadMyMaps];
            break;
        default:
            return;
            break;
    }
    [self showLoadingView];
}

- (void)foundGroups:(NSNotification*)note {
    NSDictionary *userInfo = [note userInfo];
    NSOperation *op = [userInfo objectForKey:@"operation"];
    if (self.queryOp == op) {
        AGSPortalQueryResultSet *resultSet = [userInfo objectForKey:@"resultSet"];
        if (!resultSet.results.count) {
            [self hideLoadingView];
            return;
        }
        
        AGSPortalGroup *group = [resultSet.results objectAtIndex:0];
        AGSPortalQueryParams *qp = [AGSPortalQueryParams queryParamsForItemsOfType:AGSPortalItemTypeWebMap inGroup:group.groupId];
        qp.limit = self.maxVisibleItems;
        [qp eaf_constrainQueryExcludeBasemapsForPortal:self.portal];
        self.queryOp = [self.portal findItemsWithQueryParams:qp];
    }
}

- (void)failedToFindGroups:(NSNotification*)note {
    [self hideLoadingView];
}


#pragma mark -
#pragma mark querying maps

- (void)loadFeaturedContent {
    AGSPortalQueryParams *queryParams;
    if (self.portal.portalInfo.featuredItemsGroupQuery.length > 0){
        queryParams = [AGSPortalQueryParams queryParamsWithQuery:self.portal.portalInfo.featuredItemsGroupQuery];
        queryParams.limit = self.maxVisibleItems;
        self.queryOp = [self.portal findGroupsWithQueryParams:queryParams];
    }
    else {
        queryParams = [AGSPortalQueryParams queryParamsForItemsOfType:AGSPortalItemTypeWebMap withSearchString:[NSString stringWithFormat:@"(orgid:%@)", self.portal.portalInfo.organizationId]];
        queryParams.limit = self.maxVisibleItems;
        [queryParams eaf_constrainQueryExcludeBasemapsForPortal:self.portal];
        self.queryOp = [self.portal findItemsWithQueryParams:queryParams];
    }
}

- (void)loadHighestRated {
    AGSPortalQueryParams *queryParams;
    queryParams = [AGSPortalQueryParams queryParamsForItemsOfType:AGSPortalItemTypeWebMap withSearchString:nil];
    queryParams.sortField = @"avgRating";
    queryParams.sortOrder = AGSPortalQuerySortOrderDescending;
    queryParams.limit = self.maxVisibleItems;
    //
    // we only want to show maps from within the org if the current portal is an org
    [queryParams eaf_constrainQueryForPortal:self.portal];
    [queryParams eaf_constrainQueryExcludeBasemapsForPortal:self.portal];
    self.queryOp = [self.portal findItemsWithQueryParams:queryParams];
}

- (void)loadMostViewed {
    AGSPortalQueryParams *queryParams;
    queryParams = [AGSPortalQueryParams queryParamsForItemsOfType:AGSPortalItemTypeWebMap withSearchString:nil];
    queryParams.limit = self.maxVisibleItems;
    queryParams.sortField = @"numViews";
    queryParams.sortOrder = AGSPortalQuerySortOrderDescending;
    //
    // we only want to show maps from within the org if the current portal is an org
    [queryParams eaf_constrainQueryForPortal:self.portal];
    [queryParams eaf_constrainQueryExcludeBasemapsForPortal:self.portal];
    self.queryOp = [self.portal findItemsWithQueryParams:queryParams];
}

- (void)loadMyMaps {
    if (self.portal.user.username) {
        AGSPortalQueryParams *queryParams;
        // logged in, so get my maps
        NSString *queryString = [NSString stringWithFormat:@"owner:%@", self.portal.user.username];
        queryParams = [AGSPortalQueryParams queryParamsForItemsOfType:AGSPortalItemTypeWebMap withSearchString:queryString];
        queryParams.limit = self.maxVisibleItems;
        self.queryOp = [self.portal findItemsWithQueryParams:queryParams];
    }
}

#pragma mark -
#pragma mark EAFCollectionViewDelegate

- (void)collectionView:(EAFCollectionView *)collectionView wantsToOpenPortalItem:(AGSPortalItem *)portalItem {
    if ([self.itemDelegate respondsToSelector:@selector(pcvc:wantsToOpenPortalItem:)]) {
        [self.itemDelegate pcvc:self wantsToOpenPortalItem:portalItem];
    }
}

- (void)collectionView:(EAFCollectionView *)collectionView wantsToShowInfoForPortalItem:(AGSPortalItem *)portalItem {
    if ([self.itemDelegate respondsToSelector:@selector(pcvc:wantsToShowInfoForPortalItem:)]) {
        [self.itemDelegate pcvc:self wantsToShowInfoForPortalItem:portalItem];
    }
}

@end
