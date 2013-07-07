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


#import <Cocoa/Cocoa.h>

@class EAFGradientView;
@class EAFTitledView;
@class AGSPortal;
@class AGSPortalItem;


typedef enum {
    EAFPortalContentTypeMyMaps,
    EAFPortalContentTypeFeaturedContent,
    EAFPortalContentTypeMostViewed,
    EAFPortalContentTypeHighestRated,
    EAFPortalContentTypeItems,
    EAFPortalContentTypeRecentMaps,
    EAFPortalContentTypeGroups,
    EAFPortalContentTypeFolders,
    EAFPortalContentTypeGeneric,
} EAFPortalContentType;


@interface EAFPortalContentViewController : NSViewController

@property (nonatomic, assign) NSUInteger maxVisibleItems;
@property (nonatomic, assign) EAFPortalContentType contentType;
@property (nonatomic, strong) IBOutlet EAFTitledView *titledView;
@property (nonatomic, copy) NSString *title;
//
// array of objects that are currently visible in the paged view
@property (nonatomic, strong, readonly) NSArray *visibleItems;
@property (nonatomic, strong, readonly) NSArray *portalContent;

- (void)addPortalContent:(NSArray*)portalContent;
- (void)removeAllPortalContent;

//
// initial query params to be used for the content of this view controller
// must call kickoffQuery method to execute
@property (nonatomic, strong) AGSPortalQueryParams *queryParams;
@property (nonatomic, strong) AGSPortalQueryParams *nextQueryParams;

- (id)initWithTitle:(NSString*)title contentType:(EAFPortalContentType)contentType portal:(AGSPortal*)portal queryParams:(AGSPortalQueryParams*)queryParams;

- (void)showLoadingView;
- (void)hideLoadingView;
- (void)updateVisibleItems;


//
// should be overridden by subclasses to reload the associated view
// that will display the items -- collectionview or tableview most likely
// this method will be called when the visible items for the view
// have been updated.
- (void)reloadData;

//
// subclasses should implement this method based on whether they are querying for groups/items/folders etc
//
// callers do not need to do anything after this point, this view controller will handle everything
// once the portal loads, if it hasn't yet
- (NSOperation*)loadPortalContentWithQueryParams:(AGSPortalQueryParams*)queryParams;

@end

