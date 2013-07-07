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
@class EAFGradientView;
@class EAFTableView;

@interface EAFMeasureViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

-(void)activate;
-(void)deactivate;

@property (retain) IBOutlet EAFTableView *tableView;
@property (retain) IBOutlet NSTextField *totalLengthTextField;
@property (retain) IBOutlet NSTextField *areaTextField;
@property (retain) IBOutlet NSTextField *perimeterTextField;
@property (retain) IBOutlet NSTextField *currentMousePointTextField;
@property (weak) IBOutlet EAFGradientView *gradientTitleView;
@property (weak) IBOutlet NSView *statusView;

@property (weak) IBOutlet NSPopUpButton *unitsPopupButton;
@property (weak) IBOutlet NSMenu *unitsMenu;
@property (weak) IBOutlet NSMenuItem *metricMenuItem;
@property (weak) IBOutlet NSMenuItem *imperialMenuItem;

- (IBAction)imperialSelected:(id)sender;
- (IBAction)metricSelected:(id)sender;

- (IBAction)resetSGL:(id)sender;

@end
