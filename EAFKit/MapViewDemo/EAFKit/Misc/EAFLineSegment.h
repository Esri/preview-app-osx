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

@interface EAFLineSegment : NSObject

// in meters
@property (nonatomic, assign, readonly) double length;
@property (nonatomic, assign, readonly) BOOL lengthIsShapePreserving;

@property (nonatomic, strong, readonly) AGSPolyline *linearLine;

@property (nonatomic, strong, readonly) AGSPoint *linearStart;
@property (nonatomic, strong, readonly) AGSPoint *linearEnd;
//@property (nonatomic, strong, readonly) AGSPoint *angularStart;
//@property (nonatomic, strong, readonly) AGSPoint *angularEnd;

@property (nonatomic, copy, readonly) NSString *dmsStart;
@property (nonatomic, copy, readonly) NSString *dmsEnd;


-(id)initWithLinearStart:(AGSPoint*)linearStart
               linearEnd:(AGSPoint*)linearEnd;

//-(id)initWithLinearStart:(AGSPoint*)linearStart
//               linearEnd:(AGSPoint*)linearEnd
//            angularStart:(AGSPoint*)angularStart
//              angularEnd:(AGSPoint*)angularEnd;

@end
