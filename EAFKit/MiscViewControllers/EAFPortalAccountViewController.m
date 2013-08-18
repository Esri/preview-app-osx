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

#import "EAFPortalAccountViewController.h"
#import "EAFHyperlinkButton.h"
#import "EAFDefines.h"
#import <WebKit/WebKit.h>

@interface EAFPortalAccountViewController ()

@end

@implementation EAFPortalAccountViewController

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(id)init{
    return [self initWithNibName:@"EAFPortalAccountViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(portalInfoFetchedThumbnail:) name:AGSPortalInfoDidFetchOrganizationThumbnail object:nil];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(portalInfoFetchedThumbnail:) name:AGSPortalInfoDidFetchPortalThumbnail object:nil];
    }
    
    return self;
}

-(void)awakeFromNib{
    [self.signOutBtn setTarget:self];
    [self.signOutBtn setAction:@selector(linkButtonAction:)];
//    [self.signOutBtn setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    
    self.webView.drawsBackground = NO;
    [self.webView setFrameLoadDelegate:self];
    [[self.webView preferences] setStandardFontFamily:@"Lucida Grande"];
    [[self.webView preferences] setDefaultFontSize:10];
    
    [self.imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self setupUI];
}

-(void)linkButtonAction:(id)sender{
    EAFSuppressClangPerformSelectorLeakWarning([self.target performSelector:self.action withObject:self]);
}

-(void)setupUI{
    if (!_portal){
        return;
    }
    
    [self.signOutBtn setTitle:@"Sign Out"];

    self.userTextField.stringValue = _portal.credential.username ? _portal.credential.username : @"Anonymous";
    NSString *portalName = (_portal.portalInfo.organizationName.length > 0) ? _portal.portalInfo.organizationName : _portal.portalInfo.portalName;
    self.portalNameTextField.stringValue = portalName;

    
//    NSString *title = [NSString stringWithFormat:@"Sign Out - %@", _portal.credential.username];
//    [self.signOutBtn setTitle:title];
//    NSString *portalName = (_portal.portalInfo.organizationName.length > 0) ? _portal.portalInfo.organizationName : _portal.portalInfo.portalName;
//    self.portalNameTextField.stringValue = portalName;
    
//    NSString *title = @"Sign Out";
//    [self.linkButton setTitle:title];
//    NSString *portalName = (_portal.portalInfo.organizationName.length > 0) ? _portal.portalInfo.organizationName : _portal.portalInfo.portalName;
//    self.portalNameTextField.stringValue = [NSString stringWithFormat:@"%@ - %@", portalName, _portal.credential.username];
    
    self.imageView.image = _portal.portalInfo.portalThumbnail ? _portal.portalInfo.portalThumbnail : _portal.portalInfo.organizationThumbnail;
    if (_portal.portalInfo.organizationDescription.length > 0){
        self.webView.frameLoadDelegate = self;
        [[self.webView mainFrame] loadHTMLString:_portal.portalInfo.organizationDescription baseURL:nil];
    }
    else{
        [self.webView removeFromSuperview];
        [self.view setFrameSize:[self.view fittingSize]];
    }
    
    if (!self.imageView.image){
        if (_portal.portalInfo.organizationThumbnailFileName.length){
            [_portal.portalInfo fetchOrganizationThumbnail];
        }
        else if (_portal.portalInfo.portalThumbnailFileName.length){
            [_portal.portalInfo fetchPortalThumbnail];
        }
        else{
            // no images, so let's get ride of the image view...
            [self.imageView removeFromSuperview];
            [self.view setFrameSize:[self.view fittingSize]];
        }
    }

}

-(void)setPortal:(AGSPortal *)portal{
    _portal = portal;
    [self setupUI];
}

-(void)portalInfoFetchedThumbnail:(NSNotification*)note{
    if (note.object == _portal.portalInfo){
        self.imageView.image = _portal.portalInfo.portalThumbnail ? _portal.portalInfo.portalThumbnail : _portal.portalInfo.organizationThumbnail;
    }
}


//called when the frame finishes loading
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)webFrame
{
    if([webFrame isEqual:[self.webView mainFrame]])
    {
        //get the rect for the rendered frame
//        NSRect webFrameRect = [[[webFrame frameView] documentView] frame];
//        [self.webView setFrameSize:CGSizeMake(self.webView.frame.size.width, webFrameRect.size.height)];
//        
//        [self.view setFrameSize:[self.view fittingSize]];
        
//        self.webView.frame = EAFCGRectSetHeight(self.webView.frame, webFrameRect.size.height);
//        [self layoutScrollingContentView];
    }
}

@end




