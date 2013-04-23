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

#import "EAFWebMapLayerCredentialsViewController.h"
#import "EAFDefines.h"

@interface EAFWebMapLayerCredentialsViewController () <NSTextFieldDelegate>

@end

@implementation EAFWebMapLayerCredentialsViewController

-(id)init{
    return [self initWithNibName:@"EAFWebMapLayerCredentialsViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)awakeFromNib{
    self.messageLabel.stringValue = _message;
    self.okButton.enabled = _userNameTextField.stringValue.length > 0;
}

-(void)setMessage:(NSString *)message{
    _message = [message copy];
    self.messageLabel.stringValue = _message;
}

- (IBAction)okAction:(id)sender {
    self.credential = [[AGSCredential alloc]initWithUser:self.userNameTextField.stringValue password:self.passwordTextField.stringValue];
    EAFSuppressClangPerformSelectorLeakWarning([self.target performSelector:self.action withObject:self]);
}

- (IBAction)skipAction:(id)sender {
    self.credential = nil;
    EAFSuppressClangPerformSelectorLeakWarning([self.target performSelector:self.action withObject:self]);
}

-(void)controlTextDidChange:(NSNotification *)obj{
    if (obj.object == _userNameTextField) {
        self.okButton.enabled = _userNameTextField.stringValue.length > 0;
    }
}

@end
