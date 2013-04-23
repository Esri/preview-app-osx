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

#import "EAFCGUtils.h"


CGRect EAFCGRectInsetMinX(CGRect rect, CGFloat dx) {
    return CGRectMake(rect.origin.x + dx, rect.origin.y, CGRectGetWidth(rect) - dx, CGRectGetHeight(rect));
};

CGRect EAFCGRectInsetMaxX(CGRect rect, CGFloat dx) {
    return CGRectMake(rect.origin.x, rect.origin.y, CGRectGetWidth(rect) - dx, CGRectGetHeight(rect));
};

CGRect EAFCGRectInsetMinY(CGRect rect, CGFloat dy) {
    return CGRectMake(rect.origin.x, rect.origin.y + dy, CGRectGetWidth(rect), CGRectGetHeight(rect) - dy);
};

CGRect EAFCGRectInsetMaxY(CGRect rect, CGFloat dy) {
    return CGRectMake(rect.origin.x, rect.origin.y, CGRectGetWidth(rect), CGRectGetHeight(rect) - dy);
};

CGRect EAFCGRectInsetEdges(CGRect rect, CGFloat minX, CGFloat minY, CGFloat maxX, CGFloat maxY) {
    return CGRectMake(rect.origin.x + minX, rect.origin.y + minY, CGRectGetWidth(rect) - minX - maxX, CGRectGetHeight(rect) - minY - maxY);
};

CGRect EAFCGRectSetWidth(CGRect rect, CGFloat width) {
    return CGRectMake(rect.origin.x, rect.origin.y, width, rect.size.height);
};

CGRect EAFCGRectSetHeight(CGRect rect, CGFloat height) {
    return CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height);
};

CGRect EAFCGRectSetOrigin(CGRect rect, CGFloat x, CGFloat y) {
    return CGRectMake(x, y, CGRectGetWidth(rect), CGRectGetHeight(rect));
}