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
@class EDSideBar;
@protocol SidePanelViewControllerDelegate;

@interface SidePanelViewController : NSViewController
@property (weak) IBOutlet EDSideBar *sidebar;
@property (weak) IBOutlet NSView *contentView;
@property (nonatomic, assign, getter = isCollapsed) BOOL collapsed;
@property (nonatomic, weak) id<SidePanelViewControllerDelegate> delegate;

-(void)activateTocVC;
-(void)activateBasemapsVC;
-(void)activateBookmarksVC;
-(void)activateMeasureVC;
-(void)activateResultsVC;

-(void)fetchPopupsForPoint:(AGSPoint*)point;
@end

@protocol SidePanelViewControllerDelegate <NSObject>

- (void)sidePanelViewControllerWantsToSetWidth:(CGFloat)width;
- (void)sidePanelViewControllerWantsToCollapse:(SidePanelViewController*)sidePanelVC;
- (void)sidePanelViewControllerWantsToExpand:(SidePanelViewController*)sidePanelVC;

@end