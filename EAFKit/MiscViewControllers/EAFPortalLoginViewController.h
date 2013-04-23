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
@class EAFHyperlinkButton;

@interface EAFPortalLoginViewController : NSViewController

@property (nonatomic, assign) BOOL allowCancel;

@property (weak) IBOutlet NSTextField *urlTextField;
@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSProgressIndicator *activityIndicator;
@property (weak) IBOutlet NSTextField *statusTextField;
@property (weak) IBOutlet NSButton *saveCredentialBtn;
@property (strong) IBOutlet EAFHyperlinkButton *tryNowButton;
@property (strong) IBOutlet EAFHyperlinkButton *helpButton;
@property (strong) IBOutlet EAFHyperlinkButton *portalDetailsButton;
@property (strong) IBOutlet NSButton *okButton;
@property (strong) IBOutlet NSButton *cancelButton;
@property (strong) IBOutlet NSImageView *signInImageView;

-(IBAction)okPressed:(id)sender;
-(IBAction)cancelPressed:(id)sender;


@property (strong) AGSPortal *portal;
@property (weak) id target;
@property (assign) SEL action;

+(NSString*)defaultUser;

@end
