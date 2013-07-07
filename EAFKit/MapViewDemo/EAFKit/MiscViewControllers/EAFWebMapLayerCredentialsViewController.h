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

@interface EAFWebMapLayerCredentialsViewController : NSViewController

@property (nonatomic, strong) AGSCredential *credential;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;

#pragma mark actions / outlets
@property (strong) IBOutlet NSTextField *messageLabel;
@property (strong) IBOutlet NSTextField *userNameTextField;
@property (strong) IBOutlet NSTextField *passwordTextField;
- (IBAction)okAction:(id)sender;
- (IBAction)skipAction:(id)sender;
@property (strong) IBOutlet NSButton *okButton;

@end
