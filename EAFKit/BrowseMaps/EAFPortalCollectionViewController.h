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

@class EAFPortalContentViewController;
@protocol EAFPortalCollectionViewControllerDelegate;

@interface EAFPortalCollectionViewController : EAFPortalContentViewController
@property (nonatomic, weak) id<EAFPortalCollectionViewControllerDelegate> itemDelegate;
//
// this property tells the collection view controller to adjust it's height if there is
// not enough content to fill the view
@property (nonatomic, assign) BOOL shouldAutoresizeToFitContent;
@end

@protocol EAFPortalCollectionViewControllerDelegate <NSObject>

- (void)pcvc:(EAFPortalCollectionViewController*)pcvc wantsToOpenPortalItem:(AGSPortalItem*)portalItem;
- (void)pcvc:(EAFPortalCollectionViewController*)pcvc wantsToShowInfoForPortalItem:(AGSPortalItem*)portalItem;

@end