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

#import "EAFLineSegment.h"

double const kEAFMeasurementSegmentLengthThreshold = 1000000; // 1000 km

@interface EAFLineSegment ()

@property (nonatomic, assign, readwrite) double length;
@property (nonatomic, assign, readwrite) BOOL lengthIsShapePreserving;
@property (nonatomic, strong, readwrite) AGSPolyline *linearLine;
@property (nonatomic, strong, readwrite) AGSPoint *linearStart;
@property (nonatomic, strong, readwrite) AGSPoint *linearEnd;
//@property (nonatomic, strong, readwrite) AGSPoint *angularStart;
//@property (nonatomic, strong, readwrite) AGSPoint *angularEnd;
@property (nonatomic, copy, readwrite) NSString *dmsStart;
@property (nonatomic, copy, readwrite) NSString *dmsEnd;

@end

@implementation EAFLineSegment

-(id)initWithLinearStart:(AGSPoint*)linearStart
               linearEnd:(AGSPoint*)linearEnd{
    self = [super init];
    
    if (self){
        _linearStart = linearStart;
        _linearEnd = linearEnd;
//        _angularStart = angularStart;
//        _angularEnd = angularEnd;
        
        AGSMutablePolyline *ll = [[AGSMutablePolyline alloc]initWithSpatialReference:_linearStart.spatialReference];
        [ll addPathToPolyline];
        [ll addPointToPath:linearStart];
        [ll addPointToPath:linearEnd];
        
        double len = [[AGSGeometryEngine defaultGeometryEngine] lengthOfGeometry:ll];
        
        // make sure it is in meters
        if (ll.spatialReference.unit != AGSSRUnitMeter){
            len = [ll.spatialReference convertValue:len toUnit:AGSSRUnitMeter];
        }
        
        // get true shape if less than threshold
        if (len > 0 && len < kEAFMeasurementSegmentLengthThreshold){
            len = [[AGSGeometryEngine defaultGeometryEngine] shapePreservingLengthOfGeometry:ll inUnit:AGSSRUnitMeter];
            _lengthIsShapePreserving = YES;
        }
        
        _length = len;
        
        _dmsStart = [[AGSGeometryEngine defaultGeometryEngine]degreesMinutesSecondsForPoint:_linearStart numDigits:2];
        _dmsEnd = [[AGSGeometryEngine defaultGeometryEngine]degreesMinutesSecondsForPoint:_linearEnd numDigits:2];
    }
    return self;
}

-(NSString*)description{
    return [NSString stringWithFormat:@"%@ - %.2f", _dmsStart, _length];
}

@end
