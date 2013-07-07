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

//
// Provides ability to maintain a stack, and if desired, limited to
// a specific number of items. It the limit is 10 and an item is pushed onto
// the stack, the oldest item in the stack is removed.

@interface EAFStack : NSObject


@property (nonatomic, assign, readonly) NSUInteger limit;


- (id)initWithArray:(NSArray*)items;
- (id)initWithLimit:(NSUInteger)limit;

// designated initializer
- (id)initWithArray:(NSArray*)items limit:(NSUInteger)limit;


// actions
- (void)push:(id)obj;
- (id)pop;

- (NSArray*)allObjects;
- (BOOL)containsObject:(id)obj;
- (void)removeObject:(id)obj;
- (void)removeAllObjects;
@end
