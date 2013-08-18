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

#import "NSColor+EAFAdditions.h"

@implementation NSColor (EAFAdditions)

+(NSColor*)eaf_appStoreLightGrayTextColor {
    return [NSColor colorWithCalibratedRed:105.0/255.0 green:105.0/255.0 blue:105.0/255.0 alpha:1.0];
}

+(NSColor*)eaf_lighterGrayColor{
    return [NSColor colorWithDeviceRed:0.9294 green:0.9294 blue:0.9294 alpha:1.0000];
}

+(NSColor *)eaf_grayBlueColor{
    return [NSColor colorWithDeviceRed:143.0/255.0 green:146.0/255.0 blue:152.0/255.0 alpha:1.0];
}

+(NSColor *)eaf_darkGrayBlueColor{
    return [NSColor colorWithDeviceRed:101.0/255.0 green:105.0/255.0 blue:113.0/255.0 alpha:1.0];
}

+(NSColor *)eaf_orangeColor{
    return [NSColor colorWithCalibratedRed:0.8471 green:0.2863 blue:0.0980 alpha:1.0000];
}

@end
