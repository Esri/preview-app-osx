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

#import "EAFMeasureViewController.h"
#import "EAFMeasureCellView.h"
#import "EAFAppContext.h"
#import "AGSGeometryEngine+EAFAdditions.h"
#import "EAFLineSegment.h"
#import "EAFGradientView.h"
#import "NSColor+EAFAdditions.h"
#import "NSGradient+EAFAdditions.h"
#import "EAFTableView.h"

NSString *const EAFMeasureInImperialUserDefaultsKey = @"measureInImperial";
NSString *const EAFMeasureLayerName = @"Measure Layer";

@interface EAFMeasureViewController () <AGSMapViewTouchDelegate>{
    AGSMapView *_mv;
    AGSMutablePolyline *_poly;
    __weak id<AGSMapViewTouchDelegate> _formerTouchDelegate;
    BOOL _formerTrackMouseMovement;
    NSArray *_segments;
    BOOL _imperial;
    BOOL _activated;
    AGSSketchGraphicsLayer *_sgl;
}
@end

@implementation EAFMeasureViewController

-(void)createSgl{
    
    // this function is really only meant to be called once.
    
    if (_sgl){
        [[EAFAppContext sharedAppContext].mapView removeMapLayer:_sgl];
        [[NSNotificationCenter defaultCenter]removeObserver:self name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:_sgl];
        _sgl = nil;
    }
    
    if (!_sgl) {
        _sgl = [[AGSSketchGraphicsLayer alloc]initWithFullEnvelope:nil renderingMode:AGSGraphicsLayerRenderingModeDynamic];
        _sgl.name = EAFMeasureLayerName;
        _sgl.showNumbersForVertices = YES;
        _sgl.geometry = _poly;
        _sgl.visible = NO;
        NSColor *green = [NSColor colorWithDeviceRed:0.1176 green:0.7529 blue:0.1333 alpha:1.0000];
        NSColor *gray = [NSColor colorWithDeviceRed:0.2784 green:0.2784 blue:0.2824 alpha:.25];
        
        AGSSimpleMarkerSymbol *sqSms = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:
                                        [NSColor whiteColor]];
        AGSSimpleLineSymbol *sqOutline = [AGSSimpleLineSymbol simpleLineSymbolWithColor:[NSColor blackColor] width:1.0f];
        sqOutline.width = .5;
        sqSms.outline = sqOutline;
        sqSms.size = CGSizeMake(9, 9);
        sqSms.style = AGSSimpleMarkerSymbolStyleSquare;
        _sgl.midVertexSymbol = sqSms;
        
        AGSSimpleMarkerSymbol *svs = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:green];
        svs.style = AGSSimpleMarkerSymbolStyleCircle;
        svs.size = CGSizeMake(17, 17);
        _sgl.selectedVertexSymbol = svs;
        
        AGSSimpleMarkerSymbol *circSym = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[NSColor whiteColor]];
        AGSSimpleLineSymbol *circOutline = [AGSSimpleLineSymbol simpleLineSymbolWithColor:[NSColor blackColor] width:.5f];
        circSym.outline = circOutline;
        circSym.style = AGSSimpleMarkerSymbolStyleCircle;
        circSym.size = CGSizeMake(17, 17);
        _sgl.vertexSymbol = circSym;
        
        AGSCompositeSymbol *mainSym = [AGSCompositeSymbol compositeSymbol];
        AGSSimpleLineSymbol *msOutline1 = [AGSSimpleLineSymbol simpleLineSymbolWithColor:[NSColor whiteColor] width:4.0f];
        AGSSimpleFillSymbol *msFill = [AGSSimpleFillSymbol simpleFillSymbolWithColor:gray outlineColor:green];
        msFill.outline.width = 2;
        msFill.outline.style = AGSSimpleLineSymbolStyleSolid;
        [mainSym addSymbol:msOutline1];
        [mainSym addSymbol:msFill];
        _sgl.mainSymbol = mainSym;
        
        _sgl.selectedVertexSymbol = nil;
        _sgl.selectionColor = green;
        _sgl.drawLineAsPolygon = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sketchChanged:) name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:_sgl];

        [_mv addMapLayer:_sgl withName:EAFMeasureLayerName];
    }
}

-(id)init{
    return [self initWithNibName:@"EAFMeasureViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        BOOL defined = ([[NSUserDefaults standardUserDefaults]valueForKey:EAFMeasureInImperialUserDefaultsKey] != nil);
        if (!defined){
            _imperial = ![[[NSLocale currentLocale]objectForKey:NSLocaleUsesMetricSystem] boolValue];
        }
        else{
            _imperial = [[NSUserDefaults standardUserDefaults]boolForKey:EAFMeasureInImperialUserDefaultsKey];
        }
        
        _mv = [EAFAppContext sharedAppContext].mapView;
        _activated = NO;
        
//        NSMutableSet *exclude = [NSMutableSet setWithSet:[EAFAppContext sharedAppContext].mapContentsTree.excludeList];
//        [exclude addObject	:EAFMeasureLayerName];
//        [EAFAppContext sharedAppContext].mapContentsTree.excludeList = exclude;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)awakeFromNib{
    self.gradientTitleView.startGradient = [NSGradient eaf_breadCrumbGradient];
    self.gradientTitleView.angle = 90;
//    self.gradientTitleView.endGradient = [NSGradient eaf_appStoreTitleBarTopGradient];
    
    [self.statusView setWantsLayer:YES];
    self.statusView.layer.backgroundColor = [NSColor whiteColor].CGColor;
    self.statusView.layer.borderColor = [NSColor eaf_grayBlueColor].CGColor;
    self.statusView.layer.borderWidth = 1.0f;
    
    
    self.tableView.colorEvenRows = NO;
    
    [self handleUnitsChange];
}

-(void)handleUnitsChange{
    [[NSUserDefaults standardUserDefaults]setBool:_imperial forKey:EAFMeasureInImperialUserDefaultsKey];
    self.metricMenuItem.state = !_imperial;
    self.imperialMenuItem.state = _imperial;
    [self.unitsPopupButton selectItemAtIndex:_imperial ? 1 : 0];
    [self sketchChanged:nil];
}

- (IBAction)imperialSelected:(id)sender {
    _imperial = YES;
    [self handleUnitsChange];
}

- (IBAction)metricSelected:(id)sender {
    _imperial = NO;
    [self handleUnitsChange];
}

-(void)activate{
    
    if (!_poly){
        _poly = [[AGSMutablePolyline alloc]initWithSpatialReference:_mv.spatialReference];
    }
    if (!_sgl){
        [self createSgl];
    }
    
    if (_activated){
        return;
    }
    _activated = YES;
    
    _formerTrackMouseMovement = _mv.trackMouseMovement;
    _mv.trackMouseMovement = YES;
    _formerTouchDelegate = _mv.touchDelegate;
    _mv.touchDelegate = self;
    _sgl.visible = YES;
    _mv.showMagnifierOnTapAndHold = YES;
    
    [[EAFAppContext sharedAppContext] pushUndoManager:_sgl.undoManager];
}

-(void)deactivate{
    
    if (!_activated){
        return;
    }
    
    _activated = NO;
    
    _mv.trackMouseMovement = _formerTrackMouseMovement;
    _mv.touchDelegate = _formerTouchDelegate;
    _sgl.visible = NO;
    
    [[EAFAppContext sharedAppContext] popupUndoManager];
}

-(void)sketchChanged:(id)sender{
    
    double len = 0;
    double area = 0;
    double perim = 0;
    
    _segments = [AGSGeometryEngine eaf_measurementsAndSegmentsForPolygon:_sgl.drawnPolygon length:&len area:&area perimeter:&perim];
    AGSUnits lenUnits;
    AGSAreaUnits areaUnits;
    AGSUnits perimUnits;
    [AGSGeometryEngine eaf_imperial:_imperial displayUnits:&lenUnits displayLength:&len forLengthInMeters:len];
    [AGSGeometryEngine eaf_imperial:_imperial displayUnits:&perimUnits displayLength:&perim forLengthInMeters:perim];
    [AGSGeometryEngine eaf_imperial:_imperial displayUnits:&areaUnits displayArea:&area forAreaInSquareMeters:area];
    
    NSString *lenString = [AGSGeometryEngine eaf_displayStringForLength:len inUnits:lenUnits];
    NSString *perimString = [AGSGeometryEngine eaf_displayStringForLength:perim inUnits:perimUnits];
    NSString *areaString = [AGSGeometryEngine eaf_displayStringForArea:area inAreaUnits:areaUnits];
    
    self.totalLengthTextField.stringValue = [NSString stringWithFormat:@"%@", lenString];
    self.perimeterTextField.stringValue = [NSString stringWithFormat:@"%@", perimString];
    self.areaTextField.stringValue = [NSString stringWithFormat:@"%@", areaString];
    
    [_tableView reloadData];
}


#pragma  mark tableview

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    if ([_poly numPoints] == 0){
        return 0;
    }
    else if ([_poly numPoints] == 1){
        return 1;
    }
    else{
        return _segments.count;
    }
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{

    if ([tableColumn.identifier isEqualToString:@"1"]){
        return [NSString stringWithFormat:@"%lu.", row+1];
    }
    else if ([tableColumn.identifier isEqualToString:@"2"]){
        
        if (row == 0){
            AGSPoint *p = [_poly pointOnPath:0 atIndex:0];
            return [[AGSGeometryEngine defaultGeometryEngine] degreesMinutesSecondsForPoint:p numDigits:2];
        }
        else{
            EAFLineSegment *seg = [_segments objectAtIndex:row-1];
            return seg.dmsEnd;
        }
    }
    else{
        if (row == 0){
            return nil;
        }
        else{
            EAFLineSegment *seg = [_segments objectAtIndex:row-1];
            double len = seg.length;
            AGSUnits lenUnits;
            [AGSGeometryEngine eaf_imperial:_imperial displayUnits:&lenUnits displayLength:&len forLengthInMeters:len];
            return [AGSGeometryEngine eaf_displayStringForLength:len inUnits:lenUnits];
        }
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row{
    // turns off selection that comes with "source list" highlight
    return NO;
}

-(void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    // doesn't allow the aattributed text that comes with "source list" highlight
    [cell setStringValue:[cell stringValue]];
}

- (IBAction)resetSGL:(id)sender {
    [_sgl clear];
}

#pragma mark AGSMapViewTouchDelegate

-(void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics{
    [_sgl mapView:mapView didClickAtPoint:screen mapPoint:mappoint graphics:graphics];
}

-(void)mapView:(AGSMapView *)mapView didMoveMouseToPoint:(CGPoint)screen mapPoint:(AGSPoint*)mappoint{
//    NSLog(@"mouse moved: %@", mappoint);
    self.currentMousePointTextField.stringValue = [[AGSGeometryEngine defaultGeometryEngine]degreesMinutesSecondsForPoint:mappoint numDigits:2];
}

-(void)mapView:(AGSMapView *)mapView didTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics{
    [_sgl mapView:mapView didTapAndHoldAtPoint:screen mapPoint:mappoint graphics:graphics];
}

-(void)mapView:(AGSMapView *)mapView didEndTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics{
    [_sgl mapView:mapView didEndTapAndHoldAtPoint:screen mapPoint:mappoint graphics:graphics];
}

-(BOOL)mapView:(AGSMapView *)mapView didMouseDownAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics{
    return [_sgl mapView:mapView didMouseDownAtPoint:screen mapPoint:mappoint graphics:graphics];
}

-(void)mapView:(AGSMapView *)mapView didMouseDragToPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint{
    self.currentMousePointTextField.stringValue = [[AGSGeometryEngine defaultGeometryEngine]degreesMinutesSecondsForPoint:mappoint numDigits:2];
    [_sgl mapView:mapView didMouseDragToPoint:screen mapPoint:mappoint];
}

-(void)mapView:(AGSMapView *)mapView didMouseUpAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint{
    [_sgl mapView:mapView didMouseUpAtPoint:screen mapPoint:mappoint];
}

-(void)mapView:(AGSMapView *)mapView didKeyDown:(NSEvent *)event{
    if (event.keyCode == 51){
        [_sgl removeSelectedVertex];
    }
}

@end
