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

@class AGSGeometryEngine;

@interface AGSGeometryEngine (EAFAdditions)

/**
 Always returns in meters for length and meters squared for area.
 If measurements are going to be under a certainn threshold,
 they will be true shape or geodetic for accuracy.
 */
+(NSArray*)eaf_measurementsAndSegmentsForPolygon:(AGSPolygon*)poly length:(double*)lengthToCalc area:(double*)areaToCalc perimeter:(double*)perimToCalc;

/**
 Figures out the best units to use based on the length passed in.
 You choose imperial or metric output. You must pass in length in meters.
 */
+(void)eaf_imperial:(BOOL)imperial displayUnits:(AGSUnits*)units displayLength:(double*)len forLengthInMeters:(double)meters;

/**
 Figures out the best area units to use based on the area passed in.
 You choose imperial or metric output. You must pass in area in sq meters.
 */
+(void)eaf_imperial:(BOOL)imperial displayUnits:(AGSAreaUnits*)units displayArea:(double*)area forAreaInSquareMeters:(double)sqMeters;

/** String to display for length in units.
 */
+(NSString*)eaf_displayStringForLength:(double)len inUnits:(AGSUnits)units;

/** String to display for area in units.
 */
+(NSString*)eaf_displayStringForArea:(double)area inAreaUnits:(AGSAreaUnits)units;

/** Returns the DMS string for a point, normalizing the point if necessary
 before performing the calculation.
 */
+(NSString*)eaf_DMSForPoint:(AGSPoint*)point;
@end
