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

#import "EAFKit.h"
#import "TocContainerViewController.h"

@interface TocContainerViewController () <EAFTOCViewControllerDelegate>{
    EAFTOCViewController *_tocVC;
    EAFGradientView *_gradView;
}

@end

@implementation TocContainerViewController

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(id)init{
    _tocVC = [[EAFTOCViewController alloc]init];
    self = [super initWithChildViewController:_tocVC];
    if (self){
//        _gradView = [[EAFGradientView alloc]initWithStartGradient:[NSGradient eaf_sourceListGradient]];
//        _gradView.angle = 90;
//        _gradView.frame = self.view.bounds;
//        _gradView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
//        EAFInsetRoundedContainerView *rv = (EAFInsetRoundedContainerView*)self.view;
//        [rv.containerView addSubview:_gradView positioned:NSWindowBelow relativeTo:nil];
    }
    return self;
}

-(void)zoomToSelectedLayer{
    if (!_tocVC.selectedLayer){
        return;
    }
    AGSMapView *mapView = [EAFAppContext sharedAppContext].mapView;
    if ([_tocVC.selectedLayer isKindOfClass:[AGSFeatureLayer class]]){
        AGSFeatureLayer *fl = (AGSFeatureLayer*)_tocVC.selectedLayer;
        [mapView zoomToEnvelope:fl.serviceFullEnvelope animated:YES];
    }
    else{
        [mapView zoomToEnvelope:_tocVC.selectedLayer.fullEnvelope animated:YES];
    }
}

-(void)tocViewController:(EAFTOCViewController *)tocVC didSelectLayer:(AGSLayer *)layer{
}


@end
