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

#import <Foundation/Foundation.h>

//
// this object is used to transform the number of views for a portal
// item into the format "#,### view(s)" from "######"
//
// We could have just specified the views text in the bindings within the
// NIB but we would have lost the ability to have the number formatted
@interface EAFPortalItemNumViewsValueTransformer : NSValueTransformer

@end
