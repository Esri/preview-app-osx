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

#import "EAFInsetRoundedContainerViewController.h"
#import "EAFInsetRoundedContainerView.h"
#import "EAFRoundedView.h"
#import "NSViewController+EAFAdditions.h"

@interface EAFInsetRoundedContainerViewController (){
    NSViewController *_childVC;
}

@end

@implementation EAFInsetRoundedContainerViewController

-(id)initWithChildViewController:(NSViewController*)childVC{
    self = [super initWithNibName:nil bundle:nil];
    if (self){
        _childVC = childVC;
    }
    return self;
}

-(void)loadView{
    EAFInsetRoundedContainerView *rv = [[EAFInsetRoundedContainerView alloc]initWithFrame:CGRectMake(0, 0, 30, 30)/*CGRectMake(0, 0, 300, 500)*/];

    
    [_childVC eaf_addToContainerWithConstraints:rv.containerView];
//    [_childVC addToContainer:rv.containerView];
    self.view = rv;
}

@end
