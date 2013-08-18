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

//
// assumes drawing from bottom to top

@interface NSGradient (EAFAdditions)
+(NSGradient*)eaf_appStoreTitleBarTopGradient;
+(NSGradient*)eaf_appStoreTitleBarBottomGradient;
+(NSGradient*)eaf_appStoreTitleBarGradient;

+(NSGradient*)eaf_breadCrumbGradient;
+(NSGradient*)eaf_breadCrumbSelectedGradient;
+(NSGradient*)eaf_sourceListGradient;
@end
