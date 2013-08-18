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

#import "EAFFindPlacesResultCellView.h"
#import "EAFFindPlacesViewController.h"
#import "EAFFindPlacesResultsViewController.h"
#import "EAFAppContext.h"
#import "EAFDefines.h"
#import "NSColor+EAFAdditions.h"
#import "EAFStatusViewController.h"
#import "EAFTableRowView.h"
#import "NSColor+EAFAdditions.h"
#import "NSViewController+EAFAdditions.h"

NSString *const EAFFindPlacesLayerName = @"Search Results";

@interface EAFFindPlacesResultsViewController ()<NSTableViewDelegate, NSTableViewDataSource, AGSWebMapDelegate, AGSInfoTemplateDelegate>{
    EAFStatusViewController *_statusVC;
    AGSPictureMarkerSymbol *_mainPMS;
    AGSSimpleMarkerSymbol *_circleSym;
}
@property (nonatomic, strong) AGSGraphicsLayer *placeResultsGraphicsLayer;
@end

@implementation EAFFindPlacesResultsViewController

-(void)dealloc{
}

-(id)init{
    return [self initWithNibName:@"EAFFindPlacesResultsViewController" bundle:nil];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        //
        // create our place results graphics layer now so we can add it to the map as soon as possible
        self.placeResultsGraphicsLayer = [AGSGraphicsLayer graphicsLayer];
        self.placeResultsGraphicsLayer.name = EAFFindPlacesLayerName;
        [[[EAFAppContext sharedAppContext] mapView] addMapLayer:self.placeResultsGraphicsLayer];
        
//        NSMutableSet *exclude = [NSMutableSet setWithSet:[EAFAppContext sharedAppContext].mapContentsTree.excludeList];
//        [exclude addObject:self.placeResultsGraphicsLayer.name];
//        [EAFAppContext sharedAppContext].mapContentsTree.excludeList = exclude;
    }
    
    return self;
}

-(void)awakeFromNib{
    [self setupUI];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return _results.count;
}

-(void)setupUI{
    
    // this is causing problems when you do a search and the side-panel slides
    // in (which is a bug), but changing the UI here causes a crash with that
    
    // no results show status vc
    if (!_results.count){
        [self showStatusVC];
        return;
    }

    // if results show table view
    [_statusVC.view setHidden:YES];
    [self.tableView setHidden:NO];
}

-(void)showStatusVC{
    if (!_statusVC){
        _statusVC = [[EAFStatusViewController alloc]init];
        [_statusVC view];
        [_statusVC eaf_addToAndCenterInContainer:self.view];
    }
    _statusVC.messageLabel.stringValue = @"Perform a search to show places";
    [_statusVC.view setHidden:NO];
    [self.tableView setHidden:YES];
}

-(void)setResults:(NSArray *)results{
    _results = results;
    
    //
    // remove any graphics we may already have on the map
    [self.placeResultsGraphicsLayer removeAllGraphics];
        
    [self setupUI];
    
    AGSMapView *mapView = EAFAppContext.sharedAppContext.mapView;
    AGSMutableEnvelope *me = [[AGSMutableEnvelope alloc]initWithXmin:NAN ymin:NAN xmax:NAN ymax:NAN spatialReference:mapView.spatialReference];

    NSInteger i = 1;
    for (AGSLocatorFindResult *result in _results){
        
        result.graphic.infoTemplateDelegate = self;
        
        NSString *addressType = [result.graphic attributeAsStringForKey:@"Addr_Type"];
        if ([addressType isEqualToString:@"POI"]){
            [result.graphic setValue:result.name forKey:@"title"];
            [result.graphic setValue:result.name forKey:@"detail"];
        }
        else if ([addressType isEqualToString:@"StreetName"]){
            NSArray *comps = [result.name componentsSeparatedByString:@","];
            if (comps.count){
                [result.graphic setValue:[comps objectAtIndex:0] forKey:@"title"];
            }
            else{
                [result.graphic setValue:result.name forKey:@"title"];
            }
            [result.graphic setValue:result.name forKey:@"detail"];
        }
        else{
            [result.graphic setValue:result.name forKey:@"title"];
            [result.graphic setValue:result.name forKey:@"detail"];
        }
        
        // add number...
        NSString *title = [NSString stringWithFormat:@"%lu. %@", i, [result.graphic attributeAsStringForKey:@"title"]];
        [result.graphic setValue:title forKey:@"title"];
        
        //
        // set our symbol
        result.graphic.symbol = [self symbolForGraphicAtIndex:i];
        
        //
        // update our envelope for the results
        [me unionWithEnvelope:result.graphic.geometry.envelope];
        
        //
        [self.placeResultsGraphicsLayer addGraphic:result.graphic];
        i++;
    }
    
    
    /// zoom to the envelope of the results
    if ([me isValid]){
        if ([me isEmpty]){
            if (mapView.spatialReference.unit == AGSSRUnitMeter){
                [mapView zoomToScale:3200 withCenterPoint:me.center animated:YES];
            }
        }
        else{
            [me expandByFactor:1.25];
            [mapView zoomToEnvelope:me animated:YES];
        }
    }
    
    [_tableView reloadData];
}

-(NSString *)titleForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint{
    return [graphic attributeAsStringForKey:@"title"];
}

-(NSString *)detailForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)mapPoint{
    return [graphic attributeAsStringForKey:@"detail"];
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row >= _results.count){
        return nil;
    }
    if (_results.count == 0){
        return nil;
    }
    
    EAFFindPlacesResultCellView *result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
//    if (!result) {
//        result = [[ EAFFindPlacesResultCellView alloc] initWithFrame:NSMakeRect(0, 0, 100, 50)];
//        result.identifier = tableColumn.identifier;
//    }
    // have to set this here because i think these cell views get created in the xib
    result.parentVC = self;
    
    AGSLocatorFindResult *r = [_results objectAtIndex:row];
    result.result = r;
    return result;
}

- (NSTableRowView*)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    EAFTableRowView *trv = [[EAFTableRowView alloc] initWithFrame:NSZeroRect];
    trv.row = row;
    return trv;
}

// if we just want the title, uncomment this, and comment the above method
//-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
//    AGSWebMap *wm = [_basemaps objectAtIndex:row];
//    NSLog(@"%@", [wm valueForKey:@"title"]);
//    return [wm valueForKey:@"title"];
//}

-(IBAction)resultSelected:(id)sender{
    self.selectedResult = [_results objectAtIndex:_tableView.selectedRow];
    AGSGraphic *g = self.selectedResult.graphic;
    g.infoTemplateDelegate = self;
    
    [[EAFAppContext sharedAppContext].mapView.callout showCalloutAtPoint:g.geometry.envelope.center forGraphic:g animated:YES];
    [[EAFAppContext sharedAppContext].mapView centerAtPoint:g.geometry.envelope.center animated:YES];
    
    EAFSuppressClangPerformSelectorLeakWarning([_target performSelector:_action withObject:self]);
//    [_tableView deselectRow:_tableView.selectedRow];
}

#pragma mark Symbol code

-(AGSPictureMarkerSymbol*)mainPMS{
    if (!_mainPMS){
        _mainPMS = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"pin-green21x34"];
        _mainPMS.offset = CGPointMake(0, 15);
    }
    return _mainPMS;
}

-(AGSSimpleMarkerSymbol*)circleSym{
    if (!_circleSym){
        CGPoint offset = CGPointMake(-12, 28);
        _circleSym = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[NSColor whiteColor]];
        AGSSimpleLineSymbol *outline = [AGSSimpleLineSymbol simpleLineSymbolWithColor:[NSColor blackColor] width:.5f];
        _circleSym.outline = outline;
        _circleSym.style = AGSSimpleMarkerSymbolStyleCircle;
        _circleSym.size = CGSizeMake(17, 17);
        _circleSym.offset = offset;
    }
    return _circleSym;
}

-(AGSSymbol*)symbolForGraphicAtIndex:(NSInteger)index{
    AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
    [cs addSymbol:[self mainPMS]];
    [cs addSymbol:[self circleSym]];
    
    // Because of a core bug we have to create this after creating the circle sym
    // compose composite symbol for numbering results
    AGSTextSymbol *ts = [AGSTextSymbol textSymbolWithText:[@(index) stringValue] color:[NSColor blackColor]];
    ts.fontSize = 9;
    ts.offset = CGPointMake(-12, 28);
    
    [cs addSymbol:ts];
    return cs;
}


@end
