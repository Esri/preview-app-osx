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

#define EAFDebugStrokeBorder(view, width, color) \
do { \
[view setWantsLayer:YES]; \
view.layer.borderWidth = width; \
view.layer.borderColor = [color CGColor]; \
} while (0)

#define EAFDebugLogFunction() NSLog(@"%s", __PRETTY_FUNCTION__)