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

#import "EAFFindWebMapsViewController.h"
#import "EAFAppContext.h"
#import "AGSPortalQueryParams+EAFAdditions.h"

@interface EAFFindWebMapsViewController () <NSMenuDelegate>
@end

@implementation EAFFindWebMapsViewController

-(id)init{
    return [self initWithNibName:@"EAFFindWebMapsViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

-(void)awakeFromNib{
    // default to search all web maps
    self.searchField.tag = 500;
    
    AGSPortal *portal = [EAFAppContext sharedAppContext].portal;
    
    //
    // if we are not "trying it now" and we have an org id show that
    if (portal.portalInfo.organizationId && ![EAFAppContext sharedAppContext].tryingItNow) {
        //
        [[self.searchField cell] setPlaceholderString:[NSString stringWithFormat:@"Search %@", portal.portalInfo.organizationName]];
    }
    else {
        [[self.searchField cell] setPlaceholderString:@"Search Maps"];
    }
}

#pragma mark XIB Action, etc

- (IBAction)startSearch:(id)sender {
    
    NSSearchField *sf = (NSSearchField*)sender;
    //NSLog(@"searching for : %@", sf.stringValue);
    
    if (sf.stringValue.length == 0){
        return;
    }
    
    //
    // add to recent searches
    NSMutableArray * arr = [NSMutableArray arrayWithArray:self.searchField.recentSearches];
    if ([arr containsObject:sf.stringValue]){
        [arr removeObject:sf.stringValue];
    }
    [arr insertObject:sf.stringValue atIndex:0];
    [self.searchField setRecentSearches:arr];
    
    NSString *queryString = sf.stringValue;
    
    AGSPortalQueryParams *queryParams = [AGSPortalQueryParams queryParamsForItemsOfType:AGSPortalItemTypeWebMap withSearchString:queryString];
    //
    // we only want to show maps from within the org if the current portal is an org
    [queryParams eaf_constrainQueryForPortal:[EAFAppContext sharedAppContext].portal];
    
    if ([self.delegate respondsToSelector:@selector(fwmvc:wantsToSearchForMapsWithQueryParams:)]) {
        [self.delegate fwmvc:self wantsToSearchForMapsWithQueryParams:queryParams];
    }
}

-(IBAction)chooseSearchOption:(id)sender{
    NSMenuItem *mi = (NSMenuItem*)sender;
    NSMenuItem *m500 = [mi.menu itemWithTag:500];
    NSMenuItem *m501 = [mi.menu itemWithTag:501];
    
    m500.state = (sender == m500);
    m501.state = !m500.state;
    
    self.searchField.tag = m500.state == 1 ? 500 : 501;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
    if (menuItem.tag != 500 &&
        menuItem.tag != 501){
        return YES;
    }
    
    // this function works in conjunction with
    // chooseSearchOption to show the correct checkmark
    // this is because the menu gets recreated when the recent items are changed
    menuItem.state = self.searchField.tag == menuItem.tag;
    return YES;
}

@end
