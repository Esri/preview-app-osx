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

CGRect EAFCGRectInsetMinX(CGRect rect, CGFloat dx);
CGRect EAFCGRectInsetMaxX(CGRect rect, CGFloat dx);
CGRect EAFCGRectInsetMinY(CGRect rect, CGFloat dy);
CGRect EAFCGRectInsetMaxY(CGRect rect, CGFloat dy);
CGRect EAFCGRectInsetEdges(CGRect rect, CGFloat minX, CGFloat minY, CGFloat maxX, CGFloat maxY);

// returns a rect with the same origin, height and the
// specified width
CGRect EAFCGRectSetWidth(CGRect rect, CGFloat width);

// returns a rect with the same origin, width and the
// specified height
CGRect EAFCGRectSetHeight(CGRect rect, CGFloat height);

//
// returns a rect of the same size with a new origin
CGRect EAFCGRectSetOrigin(CGRect rect, CGFloat x, CGFloat y);