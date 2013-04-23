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

#import "NSGradient+EAFAdditions.h"
#import "NSColor+EAFAdditions.h"

static NSGradient *kEAFAppStoreTitleBarTopGradient = nil;
static NSGradient *kEAFAppStoreTitleBarBottomGradient = nil;
static NSGradient *kEAFAppStoreTitleBarGradient = nil;
static NSGradient *kEAFBreadCrumbGradient = nil;
static NSGradient *kEAFBreadCrumbSelectedGradient = nil;
static NSGradient *kEAFSourceListGradient = nil;

@implementation NSGradient (EAFAdditions)

+(NSGradient*)eaf_appStoreTitleBarTopGradient {
    if (!kEAFAppStoreTitleBarTopGradient) {
        kEAFAppStoreTitleBarTopGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:243.0/255 green:243.0/255 blue:243.0/255 alpha:1.0]
                                                                        endingColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
    }
    return kEAFAppStoreTitleBarTopGradient;
}

+(NSGradient*)eaf_appStoreTitleBarBottomGradient {
    if (!kEAFAppStoreTitleBarBottomGradient) {
        kEAFAppStoreTitleBarBottomGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:229.0/255 green:229.0/255 blue:229.0/255 alpha:1.0]
                                                                           endingColor:[NSColor colorWithDeviceRed:237.0/255 green:237.0/255 blue:237.0/255 alpha:1.0]];
    }
    return kEAFAppStoreTitleBarBottomGradient;
}

+(NSGradient*)eaf_appStoreTitleBarGradient {
    if (!kEAFAppStoreTitleBarGradient) {
        kEAFAppStoreTitleBarGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:229.0/255 green:229.0/255 blue:229.0/255 alpha:1.0]
                                                                     endingColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0]];
    }
    return kEAFAppStoreTitleBarGradient;
}

+(NSGradient*)eaf_breadCrumbGradient {
    if (!kEAFBreadCrumbGradient) {
        kEAFBreadCrumbGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:219.0/255.0 green:219.0/255.0 blue:219.0/255.0 alpha:1.0]
                                                            endingColor:[NSColor colorWithDeviceRed:254.0/255.0 green:254.0/255.0 blue:254.0/255.0 alpha:1.0]];
    }
    return kEAFBreadCrumbGradient;
}

+(NSGradient*)eaf_breadCrumbSelectedGradient {
    if (!kEAFBreadCrumbSelectedGradient) {
        kEAFBreadCrumbSelectedGradient = [[NSGradient alloc] initWithStartingColor:[NSColor eaf_darkGrayBlueColor]
                                                            endingColor:[NSColor eaf_grayBlueColor]];
    }
    return kEAFBreadCrumbSelectedGradient;
}

+(NSGradient*)eaf_sourceListGradient {
    if (!kEAFSourceListGradient) {
        kEAFSourceListGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:0.8235 green:0.8510 blue:0.8784 alpha:1.0000]
                                                                    endingColor:[NSColor colorWithCalibratedRed:0.9098 green:0.9255 blue:0.9451 alpha:1.0000]];
    }
    return kEAFSourceListGradient;
}

@end
