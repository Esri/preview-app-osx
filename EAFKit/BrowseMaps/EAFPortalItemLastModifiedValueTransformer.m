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

#import "EAFPortalItemLastModifiedValueTransformer.h"

@interface EAFPortalItemLastModifiedValueTransformer ()
@property (nonatomic, strong) NSDateFormatter *modifiedDateFormatter;
@end

@implementation EAFPortalItemLastModifiedValueTransformer

- (id)transformedValue:(id)value {
    if (![value isKindOfClass:[NSDate class]]) {
        return @"";
    }
    NSString *dateString = [self.dateFormatter stringFromDate:value];
    return [NSString stringWithFormat:@"Modified on %@", dateString];
}

- (NSDateFormatter*)dateFormatter {
    if (!_modifiedDateFormatter) {
        _modifiedDateFormatter = [[NSDateFormatter alloc] init];
        [_modifiedDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [_modifiedDateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return _modifiedDateFormatter;
}
@end
