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

@interface AGSPortalQueryParams (EAFAdditions)

//
// this method will modify the existing query such that it will
// only produce maps from the org and not public maps.
- (void)eaf_constrainQueryForPortal:(AGSPortal*)portal;

//
// this attempts to construct the query such that basemaps are not
// in the results.
-(void)eaf_constrainQueryExcludeBasemapsForPortal:(AGSPortal *)portal;
@end
