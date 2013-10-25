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

#import "EAFPortalLoginViewController.h"
#import "EAFDefines.h"
#import "EAFCGUtils.h"
#import "EAFKeychainHelper.h"
#import "EAFKeychainHelper+EAFAdditions.h"
#import "EAFHyperlinkButton.h"
#import "EAFAppContext.h"
#import "NSColor+EAFAdditions.h"

#warning SET YOUR DEFAULT CREDENTIALS HERE
NSString *const EAFPortalLoginViewControllerDefaultUser = @"";
NSString *const EAFPortalLoginViewControllerDefaultPassword = @"";

@interface EAFPortalLoginViewController () <AGSPortalDelegate, NSTextFieldDelegate>{
    BOOL _tryingNow;
    NSColor *_origStatusColor;
    id _eventMonitor;
}
@property (nonatomic, assign) BOOL allowAnonymousAccess;
@property (nonatomic, assign) BOOL allowNonOrgLogins;
@end

@implementation EAFPortalLoginViewController
@synthesize urlTextField = _urlTextField;
@synthesize usernameTextField = _usernameTextField;
@synthesize passwordTextField = _passwordTextField;
@synthesize activityIndicator = _activityIndicator;
@synthesize statusTextField = _statusTextField;

@synthesize portal = _portal;
@synthesize target = _target;
@synthesize action = _action;

+(NSString *)defaultUser{
    return EAFPortalLoginViewControllerDefaultUser;
}

-(id)init{
    return [self initWithNibName:@"EAFPortalLoginViewController" bundle:nil];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _allowCancel = YES;
        //
        // These flags can be different, but in the case where
        // allowNonOrgLogins is NO, allowAnonymousAccess will not work
        // (no matter if it's value is YES)
        _allowAnonymousAccess = NO;
        _allowNonOrgLogins = YES;
    }
    return self;
}

- (void)setAllowAnonymousAccess:(BOOL)allowAnonymousAccess {
    _allowAnonymousAccess = allowAnonymousAccess;
    //
    // this will set the ok button status based on
    // username length and the allow flags
    [self controlTextDidChange:nil];
}

-(void)setAllowNonOrgLogins:(BOOL)allowNonOrgLogins{
    _allowNonOrgLogins = allowNonOrgLogins;
    // this will set the ok button status based on
    // username length and the allow flags flag
    [self controlTextDidChange:nil];
}

- (void)dealloc {
    if (_eventMonitor) {
        [NSEvent removeMonitor:_eventMonitor];
        _eventMonitor = nil;
    }
}

-(void)enableButtons:(BOOL)enabled{
    [self.tryNowButton setEnabled:enabled];
    [self.okButton setEnabled:enabled];
}


-(void)awakeFromNib{
    
#ifdef DEBUG
    //
    // The following code to have a keystroke for toggling allowAnonymousAccess and allowNonOrgLogins
    // This should be DEBUG only
    EAFPortalLoginViewController *weakSelf = self;
    _eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^NSEvent *(NSEvent *incomingEvent) {
        NSEvent *result = incomingEvent;
        if ([incomingEvent type] == NSKeyDown) {
            NSString *characters = [incomingEvent characters];
            
            // if the user presses SHIFT + CMD + A
            if ([characters isEqualToString:@"a"] &&
                ([incomingEvent modifierFlags] & NSShiftKeyMask && [incomingEvent modifierFlags] & NSCommandKeyMask)) {
                weakSelf.allowAnonymousAccess = !weakSelf.allowAnonymousAccess;
                weakSelf.allowNonOrgLogins = !weakSelf.allowNonOrgLogins;
            }
        }
        return result;
    }];    
#endif

    _origStatusColor = self.statusTextField.textColor;
    
    self.tryNowButton = [[EAFHyperlinkButton alloc]initWithFrame:CGRectZero];
    self.tryNowButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tryNowButton];
    
    [self.view setWantsLayer:YES];
    self.view.layer.backgroundColor = [NSColor whiteColor].CGColor;
    
    NSColor *textColor = [NSColor colorWithCalibratedRed:0.0431 green:0.2980 blue:0.5137 alpha:1.0000];
    NSColor *textHoverColor = textColor;
    
    [self.tryNowButton setTitle:@"Try It Now"];
    self.tryNowButton.alignment = NSCenterTextAlignment;
    self.tryNowButton.font = [NSFont systemFontOfSize:12];
    [self.tryNowButton setTextColor:textColor];
    [self.tryNowButton setTextHoverColor:textHoverColor];
    [self.tryNowButton setTarget:self];
    [self.tryNowButton setAction:@selector(tryNowButtonAction:)];
    
    self.helpButton = [[EAFHyperlinkButton alloc]initWithFrame:CGRectZero];
    self.helpButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.helpButton];
    
    [self.helpButton setTitle:@"Learn More"];
    self.helpButton.alignment = NSCenterTextAlignment;
    self.helpButton.font = [NSFont systemFontOfSize:12];
    [self.helpButton setTextColor:textColor];
    [self.helpButton setTextHoverColor:textHoverColor];
    [self.helpButton setTarget:self];
    [self.helpButton setAction:@selector(helpButtonAction:)];
    [self.helpButton sizeToFit];
    [self.helpButton setAlignment:NSRightTextAlignment];
    
    self.portalDetailsButton = [[EAFHyperlinkButton alloc]initWithFrame:CGRectZero];
    self.portalDetailsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.portalDetailsButton];
    
    [self.portalDetailsButton setTitle:@"Portal Details"];
    self.portalDetailsButton.alignment = NSCenterTextAlignment;
    self.portalDetailsButton.font = [NSFont systemFontOfSize:12];
    [self.portalDetailsButton setTextColor:textColor];
    [self.portalDetailsButton setTextHoverColor:textHoverColor];
    [self.portalDetailsButton setTarget:self];
    [self.portalDetailsButton setAction:@selector(portalDetailsButtonAction:)];
    [self.portalDetailsButton sizeToFit];
    [self.portalDetailsButton setAlignment:NSLeftTextAlignment];
    
    
//    [self.tryNowButton removeConstraints:self.tryNowButton.constraints];
//    [self.helpButton removeConstraints:self.helpButton.constraints];
//    [self.portalDetailsButton removeConstraints:self.portalDetailsButton.constraints];
    
    NSView *lineView1 = [[NSView alloc]initWithFrame:CGRectZero];
    [lineView1 setWantsLayer:YES];
    lineView1.layer.backgroundColor = [NSColor eaf_darkGrayBlueColor].CGColor;
    [self.view addSubview:lineView1];
    lineView1.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSView *lineView2 = [[NSView alloc]initWithFrame:CGRectZero];
    [lineView2 setWantsLayer:YES];
    lineView2.layer.backgroundColor = [NSColor eaf_darkGrayBlueColor].CGColor;
    [self.view addSubview:lineView2];
    lineView2.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSView *btn1 = self.portalDetailsButton;
    NSView *btn2 = self.tryNowButton;
    NSView *btn3 = self.helpButton;
    
    [btn2.superview addConstraint:[NSLayoutConstraint constraintWithItem:btn2
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:btn2.superview
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1
                                                                constant:0]];
    
    [btn1.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[btn1]-[lineView1(==1)]-[btn2]-[lineView2(==1)]-[btn3]"
                                                                             options:0
                                                                             metrics:nil
                                                                                views:NSDictionaryOfVariableBindings(btn1, btn2, btn3, lineView1, lineView2)]];
    [btn1.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[btn1]-|"
                                                                              options:0
                                                                              metrics:nil
                                                                                views:NSDictionaryOfVariableBindings(btn1)]];
    
    [btn2.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[btn2]-|"
                                                                                        options:0
                                                                                        metrics:nil
                                                                                          views:NSDictionaryOfVariableBindings(btn2)]];
    
    [btn3.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[btn3]-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:NSDictionaryOfVariableBindings(btn3)]];
    
    [lineView1.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[lineView1]-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:NSDictionaryOfVariableBindings(lineView1)]];
    
    [lineView1.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineView1
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:btn1
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:1
                                                                     constant:0]];
    
    [lineView2.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[lineView2]-|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(lineView2)]];
    
    [lineView2.superview addConstraint:[NSLayoutConstraint constraintWithItem:lineView2
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:btn1
                                                                    attribute:NSLayoutAttributeHeight
                                                                   multiplier:1
                                                                     constant:0]];
    
    [self.urlTextField setHidden:YES];
    [self.statusTextField setStringValue:@""];
    
    self.usernameTextField.delegate = self;
    
    [self.okButton setEnabled:self.allowAnonymousAccess && self.allowNonOrgLogins];
    
    if (_allowCancel){
        self.cancelButton.title = @"Cancel";
    }
    else{
        self.cancelButton.title = @"Quit";
    }
    
    self.signInImageView.image = [NSImage imageNamed:@"sign-in450x222"];
    
    [self.usernameTextField becomeFirstResponder];
}

-(void)setAllowCancel:(BOOL)allowCancel{
    _allowCancel = allowCancel;
    
    if (_allowCancel){
        self.cancelButton.title = @"Cancel";
    }
    else{
        self.cancelButton.title = @"Quit";
    }
    
}

- (void)controlTextDidChange:(NSNotification *)obj{
    BOOL enabled = (_usernameTextField.stringValue.length > 0) || (self.allowAnonymousAccess && self.allowNonOrgLogins);
    [self.okButton setEnabled:enabled];
}

-(void)tryNowButtonAction:(EAFHyperlinkButton*)button{
    
    [EAFAppContext sharedAppContext].tryingItNow = YES;
    
    AGSCredential *cred = nil;
    cred = [[AGSCredential alloc]initWithUser:EAFPortalLoginViewControllerDefaultUser password:EAFPortalLoginViewControllerDefaultPassword];
    self.portal = [[AGSPortal alloc]initWithURL:[NSURL URLWithString:@"https://www.arcgis.com"] credential:cred];
    self.portal.delegate = self;
    
    self.statusTextField.textColor = _origStatusColor;
    self.statusTextField.stringValue = @"Connecting to portal...";
    [self.activityIndicator startAnimation:nil];
    
    [self enableButtons:NO];
}

- (void)helpButtonAction:(EAFHyperlinkButton*)button {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://developers.arcgis.com/en/os-x/"]];
}

- (void)portalDetailsButtonAction:(EAFHyperlinkButton*)button {
    // toggle portal url text field
    [self.urlTextField setHidden:!self.urlTextField.isHidden];
}

-(IBAction)okPressed:(id)sender{

    [EAFAppContext sharedAppContext].tryingItNow = NO;
    
    AGSCredential *cred = nil;    
    if (self.usernameTextField.stringValue.length){
        cred = [[AGSCredential alloc]initWithUser:self.usernameTextField.stringValue password:self.passwordTextField.stringValue];
    }
    NSString *urlString = self.urlTextField.stringValue;
    if (!urlString.length){
        urlString = @"https://www.arcgis.com";
    }
    self.portal = [[AGSPortal alloc]initWithURL:[NSURL URLWithString:urlString] credential:cred];
    self.portal.delegate = self;
    
    self.statusTextField.textColor = _origStatusColor;
    self.statusTextField.stringValue = @"Connecting to portal...";
    [self.activityIndicator startAnimation:nil];
    
    [self enableButtons:NO];
}

-(IBAction)cancelPressed:(id)sender{
    [self.activityIndicator stopAnimation:nil];
    self.portal = nil;
    if ([_target respondsToSelector:_action]){
        EAFSuppressClangPerformSelectorLeakWarning([_target performSelector:_action withObject:self]);
    }
}


#pragma portal delegate

-(void)portalDidLoad:(AGSPortal *)portal{
    //
    // we want to limit this app to organizations only...unless non-org access is enabled
    if (!portal.portalInfo.organizationId && !self.allowNonOrgLogins) {
        // if not an org, fail with Invalid Credentials
        [self displayLoginFailureWithString:@"Invalid account. Account must be part of an organization."];
        [self enableButtons:YES];
        return;
    }
    
    if ([_target respondsToSelector:_action]){
        EAFSuppressClangPerformSelectorLeakWarning([_target performSelector:_action withObject:self]);
    }
    self.statusTextField.textColor = _origStatusColor;
    self.statusTextField.stringValue = @"Successfully connected to portal.";
    [self.activityIndicator stopAnimation:nil];
    
    //
    // since a new portal has loaded, remove any user/password/portal url we currently have stored
    [[EAFAppContext sharedAppContext] clearLastUserAndPortal];
    
    //
    // if the user checked the box to save the credentials
    if (![EAFAppContext sharedAppContext].tryingItNow && self.saveCredentialBtn.state == 1) {
        //
        // if they are NOT "tryingitnow" then we save the credentials/portal url
        [[EAFAppContext sharedAppContext] saveCredentialAndPortal:_portal];
    }
    
    [self enableButtons:YES];
}

-(void)portal:(AGSPortal *)portal didFailToLoadWithError:(NSError *)error{
    [self displayLoginFailureWithString:[error localizedDescription]];
    [self enableButtons:YES];
}

- (void)displayLoginFailureWithString:(NSString*)loginFailureString {
    [self.activityIndicator stopAnimation:nil];
    self.statusTextField.textColor = [NSColor colorWithCalibratedRed:0.8000 green:0.0784 blue:0.1412 alpha:1.0000];
    self.statusTextField.stringValue = loginFailureString;
    
    CGRect f = self.statusTextField.frame;
    f = EAFCGRectSetHeight(f, 48);
    f = EAFCGRectInsetMaxY(f, 24);
    [self.statusTextField setFrame:f];
    
    //    [self.statusTextField setFrameSize:CGSizeMake(self.statusTextField.frame.size.width, self.statusTextField.frame.size.height*2)];
    
    [self.view layoutSubtreeIfNeeded];
    
}

@end
