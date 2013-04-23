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

#import "EAFCollectionView.h"
#import "EAFCollectionViewItem.h"

@implementation EAFCollectionView

//
// we override this method so we can send our custom view to the collection view instead
// of using an item prototype
- (NSCollectionViewItem*)newItemForRepresentedObject:(id)object {
    // To pad the last row -- check if object isKindOfClass (whatever rep object should be)
    // if not, create the blank one and color accordingly
    // if it is  -- create the standard collectionviewitem with portal item
    //
    
    AGSPortalItem *pi = (AGSPortalItem*)object;
    EAFCollectionViewItem *cvi = [[EAFCollectionViewItem alloc] initWithPortalItem:pi];
    
    //
    // we want to use alternating row colors similar to the app store
    if (([self.content indexOfObject:pi] / self.maxNumberOfColumns) % 2 == 0) {
        cvi.view.layer.backgroundColor = [[NSColor colorWithDeviceRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:1.0] CGColor];
    }
    else {
        cvi.view.layer.backgroundColor = [[NSColor windowBackgroundColor] CGColor];
    }
    
    return cvi;
}

@end
