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

#import "AppDelegate.h"
#import "EAFKit.h"


@interface AppDelegate ()
@property (nonatomic, strong) IBOutlet NSWindow *aboutWindow;
@property (nonatomic, copy) NSString *copyright;
@property (nonatomic, copy) NSAttributedString *credits;
@property (nonatomic, copy) NSString *applicationName;
@property (nonatomic, copy) NSString *version;
@end

@implementation AppDelegate

- (IBAction)showAboutPanel:(id)sender
{
    if ( !self.aboutWindow )
        [NSBundle loadNibNamed:@"AboutPanel" owner:self];
    
    [self.aboutWindow makeKeyAndOrderFront:self.aboutWindow];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    //
    // set our window's delegate so we know when it is closed.
    [self.window setDelegate:self];
    
    //
    // we only want to set the minimum size if the user has not already launched
    // the app and subsequently closed it
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"AppLaunchedOnce"]) {
        CGSize mainScreenSize = [AGSScreen mainScreenSize];
        if (mainScreenSize.height < 900) {
            [self.window setContentSize:NSMakeSize(1100, 730)];
        }
        else {
            [self.window setContentSize:NSMakeSize(1200, 900)];
        }
    }
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    self.copyright = [info valueForKey:@"NSHumanReadableCopyright"];
    NSString *version = [info valueForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [info valueForKey:@"CFBundleVersion"];
    self.version = [NSString stringWithFormat:@"Version %@ (%@)", version, buildNumber];
    self.applicationName = [info valueForKey:@"CFBundleExecutable"];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Credits"  ofType:@"rtf"];
    self.credits = [[NSAttributedString alloc] initWithPath:path documentAttributes:NULL];
    
    //
    // set the additional user agent info for this application based on app name and version number
#warning ADD YOUR USER AGENT HERE
//    [AGSRequest setAdditionalUserAgentInfo:<add your user agent here>];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    //
    // set a flag so we know that the app has been launched before
    [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:@"AppLaunchedOnce"];
    
    //
    // save our recent maps
    [[EAFAppContext sharedAppContext] saveRecentMaps];
    
    //
    // when the application ends, let's make sure we have written out our
    // settings to userDefaults
    if (![[NSUserDefaults standardUserDefaults] synchronize]) {
        //NSLog(@"FAILED -- writing to user defaults");
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

#pragma mark -
#pragma mark NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    //
    // if our main window closes -- we want to terminate, even if other windows are open
    if ([[notification object] isEqualTo:self.window]) {
        [self.window setDelegate:nil];
        [[NSApplication sharedApplication] terminate:nil];
    }
}
@end
