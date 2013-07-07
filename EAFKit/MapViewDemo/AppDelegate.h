// Copyright 2013 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet AGSMapView *mapView;
@property (weak) IBOutlet NSBox *leftContainer;
- (IBAction)contentsAction:(id)sender;
- (IBAction)basemapsAction:(NSButton *)sender;
@property (weak) IBOutlet NSView *findContainer;
- (IBAction)measureAction:(id)sender;

@end
