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

@class AGSPortal;
@class AGSPortalItem;
@class EAFFindWebMapsViewController;
@protocol EAFWebMapGalleryDelegate;

@interface EAFWebMapGalleryViewController : NSViewController

@property (nonatomic, weak) id<EAFWebMapGalleryDelegate> delegate;

@property (nonatomic, strong, readonly) EAFFindWebMapsViewController *fwmvc;

@property (nonatomic, strong) NSView *searchContainerView;

@property (nonatomic, copy, readonly) NSString *subGalleryDisplayText;

//
// by default will use a placeholder image
// set this to your custom image
@property (nonatomic, strong) NSImage *bannerImage;

//
// must call activate after init'ing
-(void)activate;
-(void)deactivate;

- (void)showSubGallery;
- (void)showMainGallery;

@end

@protocol EAFWebMapGalleryDelegate <NSObject>
@optional
-(void)webMapGallery:(EAFWebMapGalleryViewController*)wmgvc wantsToOpenPortalItem:(AGSPortalItem*)portalItem;
-(void)webMapGallery:(EAFWebMapGalleryViewController*)wmgvc didSwitchToSubGallery:(NSString*)subGalleryDisplayText;
@end