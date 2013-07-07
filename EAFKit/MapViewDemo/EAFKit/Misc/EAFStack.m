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

#import "EAFStack.h"

@interface EAFStack ()
@property (nonatomic, strong) NSMutableArray *objects;
@property (nonatomic, assign, readwrite) NSUInteger limit;
@end

@implementation EAFStack

- (id)init {
    return [self initWithArray:nil limit:10];
}

- (id)initWithLimit:(NSUInteger)limit {
    return [self initWithArray:nil limit:limit];
}

- (id)initWithArray:(NSArray *)items {
    return [self initWithArray:items limit:items.count];
}

- (id)initWithArray:(NSArray *)items limit:(NSUInteger)limit {
    self = [super init];
    if (self) {
        self.objects = [NSMutableArray array];
        [self.objects addObjectsFromArray:items];
        self.limit = limit;
    }
    return self;
}

- (void)push:(id)obj {
    [self.objects insertObject:obj atIndex:0];
    if (self.objects.count > self.limit) {
        [self.objects removeLastObject];
    }
}

- (id)pop {
    id obj = [self.objects lastObject];
    [self.objects removeLastObject];
    return obj;
}

- (NSArray*)allObjects {
    return [NSArray arrayWithArray:self.objects];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"(%@)", [self.objects componentsJoinedByString:@"),("]];
}

- (BOOL)containsObject:(id)obj {
    return [self.objects containsObject:obj];
}

- (void)removeObject:(id)obj {
    [self.objects removeObject:obj];
}

- (void)removeAllObjects {
    [self.objects removeAllObjects];
}
@end
