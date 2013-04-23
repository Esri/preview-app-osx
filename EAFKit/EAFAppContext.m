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

#import "EAFAppContext.h"
#import "EAFStack.h"
#import "EAFKeychainHelper.h"
#import "EAFKeychainHelper+EAFAdditions.h"

@interface EAFAppContext (){
    NSMutableArray *_undoManagerStack;
}

@end

@implementation EAFAppContext

NSString *const EAFAppContextDidChangeWebMap = @"EAFAppContextDidChangeWebMap";
NSString *const EAFAppContextDidChangePortal = @"EAFAppContextDidChangePortal";
NSString *const EAFAppContextDidChangeMapView = @"EAFAppContextDidChangeMapView";
NSString *const EAFAppContextDidChangeRecentMaps = @"EAFAppContextDidChangeRecentMaps";

NSString *const EAFUserDefaultsRecentMapsKey = @"recentMaps";
NSString *const EAFUserDefaultsUserBookmarksKey = @"userBookmarks";


+ (EAFAppContext *)sharedAppContext {
    static dispatch_once_t _onceToken;
    static EAFAppContext *_sharedAppContext = nil;
    dispatch_once(&_onceToken, ^{
        _sharedAppContext = [[EAFAppContext alloc]init];
    });
    return _sharedAppContext;
}

-(id)init{
    self = [super init];
    if (self){
        NSDictionary *json = [[NSUserDefaults standardUserDefaults]dictionaryForKey:EAFUserDefaultsUserBookmarksKey];
        _userBookmarks = [AGSJSONUtility decodeFromDictionary:json withKey:@"value" fromClass:[AGSWebMapBookmark class]];
    }
    return self;
}

-(void)setUserBookmarks:(NSArray *)userBookmarks{
    _userBookmarks = userBookmarks;
    NSMutableDictionary *bookmarksJson = [NSMutableDictionary dictionary];
    [AGSJSONUtility encodeToDictionary:bookmarksJson withKey:@"value" AGSCodingArray:_userBookmarks];
    [[NSUserDefaults standardUserDefaults]setValue:bookmarksJson forKey:EAFUserDefaultsUserBookmarksKey];
}

-(void)setWebMap:(AGSWebMap *)webMap{
    _webMap = webMap;
    [[NSNotificationCenter defaultCenter]postNotificationName:EAFAppContextDidChangeWebMap object:self];
    
    //
    // make sure we have an itemId and title 
    if (webMap.portalItem.itemId && webMap.portalItem.title) {
        
        NSDictionary *itemInfo = @{ @"itemid" : webMap.portalItem.itemId, @"title" : webMap.portalItem.title};
        [[[EAFAppContext sharedAppContext] recentMaps] removeObject:itemInfo];
        //
        // add our recently opened map to recentMaps stack
        [[EAFAppContext sharedAppContext].recentMaps push:itemInfo];
        //
        // every time we push a recent map we should notify
        [[NSNotificationCenter defaultCenter] postNotificationName:EAFAppContextDidChangeRecentMaps object:self];
    }
}

-(void)setPortal:(AGSPortal *)portal{
    // when the portal is being changed...save recent maps
    [self saveRecentMaps];
    
    //
    // clear out recent maps and post notification
    [self.recentMaps removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:EAFAppContextDidChangeRecentMaps object:self];
    
    
    _portal = portal;
    [[NSNotificationCenter defaultCenter]postNotificationName:EAFAppContextDidChangePortal object:self];    
}

-(void)setMapView:(AGSMapView *)mapView{
    _mapView = mapView;
    [[NSNotificationCenter defaultCenter]postNotificationName:EAFAppContextDidChangeMapView object:self];
}

-(void)setRecentMaps:(EAFStack *)recentMaps {
    _recentMaps = recentMaps;
    [[NSNotificationCenter defaultCenter] postNotificationName:EAFAppContextDidChangeRecentMaps object:self];
}

-(NSInteger)lastWebMapLayerIndex{
    
    NSInteger index = [_mapView.mapLayers count] - 1;
    for (AGSLayer *lyr in [_mapView.mapLayers reverseObjectEnumerator]){
        AGSWebMapSubLayerInfo *sli = nil;
        AGSWebMapLayerInfo *mli = [_webMap webMapLayerInfoForLayer:lyr subLayerInfo:&sli];
        if (mli){
            return index;
        }
        index--;
    }
    // if here return the last layer
    return [_mapView.mapLayers count] - 1;
}

-(NSUndoManager *)currentUndoManager{
    return [_undoManagerStack lastObject];
}

-(void)pushUndoManager:(NSUndoManager*)undoManager{
    if (!_undoManagerStack){
        _undoManagerStack = [NSMutableArray array];
    }
    [_undoManagerStack addObject:undoManager];
}

-(void)popupUndoManager{
    [_undoManagerStack removeLastObject];
}

- (NSString*)portalKey {
    NSString *key = self.portal.portalInfo.portalName;
    if (!key) {
        key = self.portal.portalInfo.organizationName;
    }
    if (self.portal.user.username) {
        key = [NSString stringWithFormat:@"%@:%@", self.portal.user.username, key];
    }
    return key;
}

-(void)loadRecentMaps {
    NSDictionary *recentMapsDict = [[NSUserDefaults standardUserDefaults] valueForKey:EAFUserDefaultsRecentMapsKey];
    NSArray *recentMapsArray = [recentMapsDict valueForKey:[self portalKey]];
    _recentMaps = [[EAFStack alloc] initWithArray:recentMapsArray limit:10];
    [[NSNotificationCenter defaultCenter] postNotificationName:EAFAppContextDidChangeRecentMaps object:self];

}
-(void)saveRecentMaps {
    AGSPortal *currentPortal = [self portal];
    if (currentPortal) {
        NSDictionary *mapsDict = [[NSUserDefaults standardUserDefaults] objectForKey:EAFUserDefaultsRecentMapsKey];
        NSMutableDictionary *recentMapsDict = [NSMutableDictionary dictionaryWithDictionary:mapsDict];
        if (!recentMapsDict) {
            recentMapsDict = [NSMutableDictionary dictionary];
        }
        NSArray *maps = [self.recentMaps allObjects];
        NSString *portalKey = [self portalKey];
        [recentMapsDict setObject:maps forKey:portalKey];
        [[NSUserDefaults standardUserDefaults] setObject:recentMapsDict forKey:EAFUserDefaultsRecentMapsKey];
        if (![[NSUserDefaults standardUserDefaults] synchronize]) {
            //NSLog(@"FAILED -- writing recent maps to user defaults");
        }
    }

}

- (void)clearLastUserAndPortal {
    //
    // remove the LAST user we stored credentials for
    NSString *lastUser = [[NSUserDefaults standardUserDefaults] valueForKey:@"savedUser"];
    if (lastUser) {
        [[EAFKeychainHelper eaf_sharedHelperForArcGISPreview] removePasswordForUser:lastUser];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedUser"];
    }
    
    //
    // remove the LAST portal URL we stored
    NSString *lastPortalUrl = [[NSUserDefaults standardUserDefaults] valueForKey:@"savedPortalURL"];
    if (lastPortalUrl) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"savedPortalURL"];
    }

    //
    // make sure we write them out
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveCredentialAndPortal:(AGSPortal*)portal {
    //
    // add this user's credentials
    if (portal.credential.username) {
        [[NSUserDefaults standardUserDefaults] setValue:portal.credential.username forKey:@"savedUser"];
        [[EAFKeychainHelper eaf_sharedHelperForArcGISPreview] eaf_storeCredential:portal.credential];
    }
    
    //
    // save the portal url
    [[NSUserDefaults standardUserDefaults] setValue:[portal.URL absoluteString] forKey:@"savedPortalURL"];

    //
    // make sure we write them out
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (AGSPortal*)loadLastPortal {
    AGSCredential *savedCredential = nil;
    
    //
    // see if we have a user stored
    NSString *savedUser = [[NSUserDefaults standardUserDefaults] valueForKey:@"savedUser"];
    if (savedUser) {
        //
        // if we do, grab the AGSCredential for this user
        savedCredential = [[EAFKeychainHelper eaf_sharedHelperForArcGISPreview] eaf_credentialForUser:savedUser];
    }
    
    NSString *savedPortalURL = [[NSUserDefaults standardUserDefaults] valueForKey:@"savedPortalURL"];
    NSURL *lastPortalURL = [NSURL URLWithString:savedPortalURL];
    
    AGSPortal *portal = nil;
    if (savedCredential && savedPortalURL) {
        portal = [[AGSPortal alloc] initWithURL:lastPortalURL credential:savedCredential];
    }
    return portal;
}
@end
