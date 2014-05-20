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

#import "AGSGeometryEngine+EAFAdditions.h"
#import "EAFLineSegment.h"

@implementation AGSGeometryEngine (EAFAdditions)

double const kEAFMeasurementLengthThreshold = 1000000; // 1000 km
double const kEAFMeasurementAreaThreshold = 1000000000; // 1000 sq km

+(NSArray*)eaf_measurementsAndSegmentsForPolygon:(AGSPolygon*)poly length:(double*)lengthToCalc area:(double*)areaToCalc perimeter:(double*)perimToCalc{
    
    AGSPolygon *linearPoly = nil;
    
    // make sure we have a polygon in linear units
    if (![poly.spatialReference inLinearUnits]){
        linearPoly = (AGSPolygon*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:poly toSpatialReference:[AGSSpatialReference webMercatorSpatialReference]];
    }
    else{
        linearPoly = poly;
    }
    
    //
    // for testing, we can also test here by using a different sr
    //linearPoly = (AGSPolygon*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:poly toSpatialReference:[AGSSpatialReference spatialReferenceWithWKID:102747]];
    
    
    // create segments, get length
    double len = 0;
    double perim = 0;
    NSInteger numPoints = [poly numPoints];
    NSMutableArray *segments = nil;
    if (numPoints > 1){
        segments = [NSMutableArray arrayWithCapacity:[poly numPoints] - 1];
        for (NSInteger i = 0; i<[poly numRings]; i++){
            NSInteger numPointsInRing = [poly numPointsInRing:i];
            for (NSInteger j=0; j<numPointsInRing; j++){

                NSInteger nextCoord = j+1;
                BOOL lastSeg = NO;
                if (nextCoord == numPointsInRing){
                    nextCoord = 0;
                    lastSeg = YES;
                }
                EAFLineSegment *seg = [[EAFLineSegment alloc]initWithLinearStart:[linearPoly pointOnRing:i atIndex:j]
                                                                       linearEnd:[linearPoly pointOnRing:i atIndex:nextCoord]];
                [segments addObject:seg];
                perim += seg.length;
                
                if (!lastSeg){
                    len += seg.length;
                }
            }
        }
    }
    
    
    //
    // area
    double area = fabs([[AGSGeometryEngine defaultGeometryEngine] areaOfGeometry:linearPoly]);
    
    // make sure it is in square meters
    if (linearPoly.spatialReference.unit != AGSSRUnitMeter){
        double factor = [linearPoly.spatialReference convertValue:1.0 toUnit:AGSSRUnitMeter];
        area = area * factor * factor;
    }
    
    // shape preserving when under a threshold
    if (area > 0 && area < kEAFMeasurementAreaThreshold){
        //NSLog(@"going to shape preserving area....");
        area = [[AGSGeometryEngine defaultGeometryEngine] shapePreservingAreaOfGeometry:linearPoly inUnit:AGSAreaUnitsSquareMeters];
    }
    
    *lengthToCalc = len;
    *areaToCalc = area;
    *perimToCalc = perim;
//    NSLog(@"segments; %@", segments);
    
    return [segments copy];
}

+(void)eaf_imperial:(BOOL)imperial displayUnits:(AGSUnits*)units displayLength:(double*)len forLengthInMeters:(double)meters{
    
    // the logic for displaying a length and units in either imperial or metric
    if (!imperial){
        if (meters >= 500){
            *units = AGSUnitsKilometers;
            *len = AGSUnitsToUnits(meters, AGSUnitsMeters, AGSUnitsKilometers);
        }
        else if (meters < 1){
            *units = AGSUnitsCentimeters;
            *len = AGSUnitsToUnits(meters, AGSUnitsMeters, AGSUnitsCentimeters);
        }
        else{
            *units = AGSUnitsMeters;
            *len = meters;
        }
    }
    else{
        double feet = AGSUnitsToUnits(meters, AGSUnitsMeters, AGSUnitsFeet);
        if (feet >= 2640){
            *units = AGSUnitsMiles;
            *len = AGSUnitsToUnits(meters, AGSUnitsMeters, AGSUnitsMiles);
        }
        else if (feet >= 300){
            *units = AGSUnitsYards;
            *len = AGSUnitsToUnits(meters, AGSUnitsMeters, AGSUnitsYards);
        }
        else if (feet < 1){
            *units = AGSUnitsInches;
            *len = AGSUnitsToUnits(meters, AGSUnitsMeters, AGSUnitsInches);
        }
        else{
            *units = AGSUnitsFeet;
            *len = feet;
        }
    }
}

+(void)eaf_imperial:(BOOL)imperial displayUnits:(AGSAreaUnits*)units displayArea:(double*)area forAreaInSquareMeters:(double)sqMeters{
    
    // the logic for displaying a length and units in either imperial or metric
    if (!imperial){
        if (sqMeters >= 500000){
            *units = AGSAreaUnitsSquareKilometers;
            *area = AGSAreaUnitsToAreaUnits(sqMeters, AGSAreaUnitsSquareMeters, AGSAreaUnitsSquareKilometers);
        }
        else if (sqMeters < 1){
            *units = AGSAreaUnitsSquareCentimeters;
            *area = AGSAreaUnitsToAreaUnits(sqMeters, AGSAreaUnitsSquareMeters, AGSAreaUnitsSquareCentimeters);
        }
        else{
            *units = AGSAreaUnitsSquareMeters;
            *area = sqMeters;
        }
    }
    else{
        double acre = AGSAreaUnitsToAreaUnits(sqMeters, AGSAreaUnitsSquareMeters, AGSAreaUnitsAcres);
        if (acre >= 640){
            *units = AGSAreaUnitsSquareMiles;
            *area = AGSAreaUnitsToAreaUnits(sqMeters, AGSAreaUnitsSquareMeters, AGSAreaUnitsSquareMiles);
        }
        else if (acre < .1){
            *units = AGSAreaUnitsSquareFeet;
            *area = AGSAreaUnitsToAreaUnits(sqMeters, AGSAreaUnitsSquareMeters, AGSAreaUnitsSquareFeet);
        }
        else{
            *units = AGSAreaUnitsAcres;
            *area = acre;
        }
    }
}

+(NSString*)eaf_displayStringForLength:(double)len inUnits:(AGSUnits)units{
    if (isnan(len)){
        len = 0.0f;
    }
    return [NSString stringWithFormat:@"%.2f %@", len, AGSUnitsAbbreviatedString(units)];
}

+(NSString*)eaf_displayStringForArea:(double)area inAreaUnits:(AGSAreaUnits)units{
    if (isnan(area)){
        area = 0.0f;
    }
    return [NSString stringWithFormat:@"%.2f %@", area, AGSAreaUnitsAbbreviatedString(units)];
}

+(NSString*)eaf_DMSForPoint:(AGSPoint*)point {
    AGSMutablePoint *mp = [point mutableCopy];
    [mp normalize];
    return [mp degreesMinutesSecondsStringWithNumDigits:2];
}
@end
