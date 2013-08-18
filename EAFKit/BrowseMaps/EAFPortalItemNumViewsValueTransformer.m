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

#import "EAFPortalItemNumViewsValueTransformer.h"

@interface EAFPortalItemNumViewsValueTransformer ()
@property (nonatomic, strong) NSNumberFormatter *numViewFormatter;
@end

@implementation EAFPortalItemNumViewsValueTransformer

- (id)transformedValue:(id)value {
    //
    // this is meant to be used with the number of views for a portal item
    // so if the value is not an NSNumber return blank
    if (![value isKindOfClass:[NSNumber class]]) {
        return @"";
    }
    return [self.numViewFormatter stringFromNumber:value];
}

- (NSNumberFormatter*)numViewFormatter {
    if (!_numViewFormatter) {
        _numViewFormatter = [[NSNumberFormatter alloc] init];
        [_numViewFormatter setFormat:@"#,### views"];
        [_numViewFormatter setHasThousandSeparators:YES];
    }
    return _numViewFormatter;
}

@end
