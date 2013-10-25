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

#import "EAFStatusViewController.h"
#import "EAFRoundedView.h"
#import "NSColor+EAFAdditions.h"

@interface EAFStatusViewController ()

@end

@implementation EAFStatusViewController

-(id)init{
    return [self initWithNibName:@"EAFStatusViewController" bundle:nil];
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
    self.roundedView.backgroundColor = [NSColor eaf_grayBlueColor];
    self.roundedView.cornerRadius = 5.0;
    self.roundedView.cornerFlags = NSBezierPathRoundedCornerBottomLeft | NSBezierPathRoundedCornerBottomRight | NSBezierPathRoundedCornerTopLeft | NSBezierPathRoundedCornerTopRight;
}

@end
