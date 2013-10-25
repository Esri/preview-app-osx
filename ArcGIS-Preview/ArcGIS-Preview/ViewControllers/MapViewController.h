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
@protocol MapViewControllerDelegate;
@class EAFHyperlinkButton;
@class EAFFindPlacesViewController;

@interface MapViewController : NSViewController

@property (nonatomic, strong) NSView *searchContainerView;
@property (nonatomic, strong) NSPopUpButton *collectFeatureButton;
@property (nonatomic, weak) id<MapViewControllerDelegate> delegate;
@property (nonatomic, strong) EAFFindPlacesViewController *findVC;

-(void)openWebMapPortalItem:(AGSPortalItem*)item;
-(void)activate;
-(void)deactivate;

#pragma mark outlets
@property (strong) IBOutlet AGSMapView *mapView;
@property (strong) IBOutlet NSView *leftContainer;
@property (weak) IBOutlet NSTextField *mapScaleLabel;
@property (weak) IBOutlet NSSplitView *splitView;
@property (strong) IBOutlet EAFHyperlinkButton *copyrightBtn;

@end


@protocol MapViewControllerDelegate <NSObject>
@optional
-(void)mapViewController:(MapViewController*)mapVC wantsToLoginAndReOpenWebMap:(AGSWebMap*)webmap;
@end