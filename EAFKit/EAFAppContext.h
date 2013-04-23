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

#import <Foundation/Foundation.h>

@class AGSMapView;
@class AGSWebMap;
@class AGSPortal;
@class EAFStack;

@interface EAFAppContext : NSObject

+(EAFAppContext*)sharedAppContext;

AGS_EXTERN NSString *const EAFAppContextDidChangeWebMap;
AGS_EXTERN NSString *const EAFAppContextDidChangePortal;
AGS_EXTERN NSString *const EAFAppContextDidChangeMapView;
AGS_EXTERN NSString *const EAFAppContextDidChangeRecentMaps;

AGS_EXTERN NSString *const EAFUserDefaultsRecentMapsKey;

//
// should only be set after this webmap has loaded
@property (nonatomic, strong) AGSWebMap *webMap;
//
// should only be set after this portal has loaded
@property (nonatomic, strong) AGSPortal *portal;

@property (nonatomic, strong) AGSMapView *mapView;
@property (nonatomic, strong, readonly) EAFStack *recentMaps;
@property (nonatomic, copy, readwrite) NSArray *userBookmarks;

@property (nonatomic, strong, readonly) NSUndoManager *currentUndoManager;

@property (nonatomic, assign, readwrite) BOOL tryingItNow;

-(void)pushUndoManager:(NSUndoManager*)undoManager;
-(void)popupUndoManager;

-(void)loadRecentMaps;
-(void)saveRecentMaps;

-(NSInteger)lastWebMapLayerIndex;

//
// removes the last saved user and portal url from NSUserDefaults
// and the saved password for that user from the keychain
- (void)clearLastUserAndPortal;

//
// saves the user, password and portal url from the current portal
- (void)saveCredentialAndPortal:(AGSPortal*)portal;

//
// creates and returns a portal from the saved user and portal url, if exists
// returns nil if there was not one saved
- (AGSPortal*)loadLastPortal;


@end