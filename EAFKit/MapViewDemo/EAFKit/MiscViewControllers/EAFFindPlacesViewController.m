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

#import "EAFFindPlacesViewController.h"
#import "EAFAppContext.h"

NSString *const EAFFindPlacesViewControllerDidFindPlacesNotification = @"EAFFindPlacesViewControllerDidFindPlacesNotification";
NSString *const EAFFindPlacesViewControllerDidClearSearchNotification = @"";
NSString *const EAFFindPlacesSearchOptionDefaultsKey = @"limitSearchResultsToCurrentExtent";

@interface EAFFindPlacesViewController () <AGSLocatorDelegate, NSMenuDelegate>{
    AGSLocator *_locator;
    NSOperation *_findPlaceOp;
    BOOL _limitResultsToCurrentExtent;
}

@end

@implementation EAFFindPlacesViewController

-(id)init{
    return [self initWithNibName:@"EAFFindPlacesViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

-(void)awakeFromNib{
    // default to search full extent
    self.searchField.tag = 501;
    [[self.searchField cell] setPlaceholderString:@"Search"];
}

-(void)clearSearch{
    self.searchField.stringValue = @"";
}

#pragma mark XIB Action, etc

- (IBAction)startSearch:(id)sender {
    
    // cancel anything going
    [_findPlaceOp cancel];
    
    NSSearchField *sf = (NSSearchField*)sender;
    //NSLog(@"searching for : %@", sf.stringValue);
    
    //
    // Cleared search
    if (sf.stringValue.length == 0){
        NSNotification *note = [NSNotification notificationWithName:EAFFindPlacesViewControllerDidClearSearchNotification object:self userInfo:nil];
        [[NSNotificationCenter defaultCenter]postNotification:note];
        return;
    }
    
    if (!_locator){
        _locator = [AGSLocator locator];
        _locator.delegate = self;
    }
    
    AGSMapView *mapView = EAFAppContext.sharedAppContext.mapView;
    
    //
    // set up the search parameters
    AGSLocatorFindParameters *lfp = [[AGSLocatorFindParameters alloc]init];
    lfp.text = sf.stringValue;
    
    if (_limitResultsToCurrentExtent){
        lfp.searchExtent = mapView.visibleAreaEnvelope;
    }
    else if (mapView.mapScale < 5000000){
        lfp.location = mapView.visibleAreaEnvelope.center;
        lfp.distance = 48280.3; // 30 miles
        //lfp.distance = 24140.2; // 15 miles
        //lfp.distance = 500;
    }
    
    
    lfp.outSpatialReference = mapView.spatialReference;
    _findPlaceOp = [_locator findWithParameters:lfp];
    
    //
    // add to recent searches
    NSMutableArray * arr = [NSMutableArray arrayWithArray:self.searchField.recentSearches];
    if ([arr containsObject:sf.stringValue]){
        [arr removeObject:sf.stringValue];
    }
    [arr insertObject:sf.stringValue atIndex:0];
    [self.searchField setRecentSearches:arr];
}

-(IBAction)chooseSearchOption:(id)sender{
    NSMenuItem *mi = (NSMenuItem*)sender;

    _limitResultsToCurrentExtent = !_limitResultsToCurrentExtent;
    mi.state = _limitResultsToCurrentExtent;
    
    [[NSUserDefaults standardUserDefaults] setValue:@(_limitResultsToCurrentExtent) forKey:EAFFindPlacesSearchOptionDefaultsKey];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
    if (menuItem.tag != 500){
        return YES;
    }
    
    // this function works in conjunction with
    // chooseSearchOption to show the correct checkmark
    // this is because the menu gets recreated when the recent items are changed
    _limitResultsToCurrentExtent = [[[NSUserDefaults standardUserDefaults]valueForKey:EAFFindPlacesSearchOptionDefaultsKey]boolValue];
    menuItem.state = _limitResultsToCurrentExtent;
    return YES;
}

#pragma mark AGSLocatorDelegate

-(void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFind:(NSArray *)results{
    self.results = results;
    
    if (results.count == 0){
        NSAlert *alert = [NSAlert alertWithMessageText:@"No locations found" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"No locations found"];
        [alert runModal];
    }
    
    //
    // post notification
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    [info setValue:results forKey:@"results"];
    NSNotification *note = [NSNotification notificationWithName:EAFFindPlacesViewControllerDidFindPlacesNotification object:self userInfo:info];
    [[NSNotificationCenter defaultCenter]postNotification:note];
}

-(void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFailToFindWithError:(NSError *)error{
    //NSLog(@"Error finding places: %@", error);
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
}

@end
