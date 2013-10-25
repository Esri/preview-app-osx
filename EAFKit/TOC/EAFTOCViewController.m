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
#import "EAFTOCViewController.h"
#import "EAFCheckTextTableCellView.h"

@interface EAFTOCViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, getter = isAwakeAlready) BOOL awakeAlready;

@end

@implementation EAFTOCViewController

-(id)init{
    AGSMapContentsTree *mct = [[AGSMapContentsTree alloc]initWithWebMap:[EAFAppContext sharedAppContext].webMap mapView:[EAFAppContext sharedAppContext].mapView];
    self = [self initWithContentsTree:mct];
    if (self){
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didOpenWebMap:) name:AGSWebMapDidOpenIntoMapViewNotification object:nil];
    }
    return self;
}

- (id)initWithContentsTree:(AGSMapContentsTree *)contentTree
{
    self = [super initWithNibName:@"EAFTOCViewController" bundle:nil];
    if (self) {
        self.tree = contentTree;
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
    if (!self.isAwakeAlready) {
        [_tocView setDataSource:self];
        [_tocView setDelegate:self];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(rowSelectionChanged:) name:NSOutlineViewSelectionDidChangeNotification object:_tocView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapZoomed:) name:AGSMapViewDidEndZoomingNotification object:self.tree.mapView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(viewDidExpand:)
                                                     name:@"NSOutlineViewItemDidExpandNotification"
                                                   object:self.tocView];
        
        //The next 2 lines adjust the indent spacing to be accomodate the cells with check boxes
        CGFloat indent = self.tocView.indentationPerLevel;
        self.tocView.indentationPerLevel = indent + 10;

        self.awakeAlready = YES;
    }
}

-(void)didOpenWebMap:(NSNotification*)note{
    if (note.object == [EAFAppContext sharedAppContext].webMap){
        AGSMapContentsTree *mct = [[AGSMapContentsTree alloc]initWithWebMap:[EAFAppContext sharedAppContext].webMap mapView:[EAFAppContext sharedAppContext].mapView];
        self.tree = mct;
    }
}

#pragma mark custom setters

-(void)setTree:(AGSMapContentsTree *)tree
{
    if (_tree){
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AGSMapContentsDidChangeNotification
                                                      object:_tree];
    }
    
    _tree = tree;
    [self.tocView reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mapContentsTreeDidChange:)
                                                 name:AGSMapContentsDidChangeNotification
                                               object:_tree];
}

#pragma mark OutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil){
        return self.tree.root.subLayers.count;
    }
    else {
        if ([item isKindOfClass:[AGSMapContentsLayerInfo class]]) {
            if ([(AGSMapContentsLayerInfo *)item showLegend] == NO) {
                return 0;
            }
            else {
                return [[(AGSMapContentsLayerInfo *)item subLayers] count] > 0 ?
                [[(AGSMapContentsLayerInfo *)item subLayers] count] :
                [[(AGSMapContentsLayerInfo *)item legendItems] count];
            }
        }
    }
    return 0;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (item == nil){
        return self.tree.root.subLayers.count > 0;
    }
    else {
        if ([item isKindOfClass:[AGSMapContentsLayerInfo class]]) {
            if ([(AGSMapContentsLayerInfo *)item showLegend] == NO) {
                return NO;
            }
            else {
            return [[(AGSMapContentsLayerInfo *)item subLayers] count] > 0 ?
                   [[(AGSMapContentsLayerInfo *)item subLayers] count] > 0 :
                   [[(AGSMapContentsLayerInfo *)item legendItems] count] > 0;
            }
        }
    }
    return NO;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    
    if (item == nil){
        if (index >= self.tree.root.subLayers.count){
            return nil;
        }
        
        return [self.tree.root.subLayers objectAtIndex:index];
    }
    else {
        if ([item isKindOfClass:[AGSMapContentsLayerInfo class]]) {
            return [[(AGSMapContentsLayerInfo *)item subLayers] count] > 0 ?
                   [[(AGSMapContentsLayerInfo *)item subLayers] objectAtIndex:index] :
                   [[(AGSMapContentsLayerInfo *)item legendItems] objectAtIndex:index];
        }
    }
    return nil;
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return (item == nil) ? @"" : [item title];
}

- (id)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    NSTableCellView *result;
    if ([item isKindOfClass:[AGSMapContentsLegendElement class]]) {
        result = [outlineView makeViewWithIdentifier:@"ImageTextCell" owner:self];
        result.textField.stringValue = [item title];
        result.imageView.image = [(AGSMapContentsLegendElement*)item swatch];
        result.imageView.imageFrameStyle = NSImageFrameNone;
        [result.imageView.image setBackgroundColor:[NSColor colorWithSRGBRed:0 green:255 blue:0 alpha:1.0]];
        [result setToolTip:[item title]];
    }
    else {
        if ([(AGSMapContentsLayerInfo *)item canChangeVisibility]) {
            result = [outlineView makeViewWithIdentifier:@"CheckTextCell" owner:self];
            NSInteger checkBoxState = [(AGSMapContentsLayerInfo*)item visible] ? NSOnState : NSOffState;
            [[(EAFCheckTextTableCellView*)result checkBox] setState:checkBoxState];
            [[(EAFCheckTextTableCellView*)result checkBox] setTitle:[item title]];
            [(EAFCheckTextTableCellView*)result setLayerInfo:item];
            //set scale visibility
            [[(EAFCheckTextTableCellView*)result checkBox] setEnabled:[(AGSMapContentsLayerInfo *)item visibleAtMapScale:self.tree.mapView.mapScale]];
        }
        else {
            result = [outlineView makeViewWithIdentifier:@"TextCell" owner:self];
            //adding a space before the string value to improve the intent spacing in the outline
            result.textField.stringValue = [NSString stringWithFormat:@" %@", [item title]];
            //set scale visibility
            if (![(AGSMapContentsLayerInfo *)item visibleAtMapScale:self.tree.mapView.mapScale]) {
                [result.textField setTextColor:[NSColor disabledControlTextColor]];
            }
            else {
                [result.textField setTextColor:[NSColor controlTextColor]];
            }
        
        }
        [result setToolTip:[item layerName]];
    }
    return result;
}

#pragma mark delegate methods

- (void)mapContentsTreeDidChange:(NSNotificationCenter *)notif
{
    [self.tocView reloadData];
}

#pragma mark OutlineViewDelegate

-(void)rowSelectionChanged:(NSNotification*)note{    
    id item = [self.tocView itemAtRow:[self.tocView selectedRow]];
    if (![item isKindOfClass:[AGSMapContentsLayerInfo class]]){
        self.selectedLayer = nil;
        return;
    }
    AGSMapContentsLayerInfo *selectedItem = (AGSMapContentsLayerInfo *)item;
    if (selectedItem.layer){
        self.selectedLayer = selectedItem.layer;
        if ([self.delegate respondsToSelector:@selector(tocViewController:didSelectLayer:)]){
            [self.delegate tocViewController:self didSelectLayer:selectedItem.layer];
        }
    }
}

-(void)viewDidExpand:(NSNotification*)notif
{
    AGSMapContentsLayerInfo *item = [notif.userInfo objectForKey:@"NSObject"];
    NSInteger level = [self.tocView levelForItem:item];
    if ((level > -1) && (level < 1)) {
        for (AGSMapContentsLayerInfo *mcli in [(AGSMapContentsLayerInfo*)item subLayers]) {
        [self.tocView expandItem:mcli expandChildren:NO];
        }
    }
}

#pragma mark AGSMapViewDidEndZoomingNotification selector

-(void)mapZoomed:(NSNotification*)notif
{
    if ([self.tree.mapView loaded]) {
        if (![NSThread isMainThread]){
            [(NSObject*)self.tocView performSelectorOnMainThread:@selector(reloadData) withObject:self waitUntilDone:NO];
        }
        else {
            [self.tocView reloadData];
        }
    }
}

@end
