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

#import "EAFFindPlacesResultCellView.h"
#import "EAFFindPlacesResultsViewController.h"
#import "EAFAppContext.h"

@interface EAFFindPlacesResultCellView () {
    
}

@end

@implementation EAFFindPlacesResultCellView

-(void)setResult:(AGSLocatorFindResult *)result{
    _result = result;
    if (_result){
        self.imageView.image = [NSImage imageNamed:@"pin-green21x34"];
        self.textField.stringValue = [result.graphic attributeAsStringForKey:@"title"];
        self.detailTextField.stringValue = [result.graphic attributeAsStringForKey:@"detail"];
        
        [self.bookmarkBtn setEnabled:YES];
        for (AGSWebMapBookmark *bkmk in [EAFAppContext sharedAppContext].userBookmarks){
            if ([bkmk.extent isEqualToEnvelope:result.extent] && [bkmk.name isEqualToString:result.name]){
                [self.bookmarkBtn setEnabled:NO];
                break;
            }
        }
    }
}

-(void)bookmarkResult:(id)sender{
    NSMutableArray *bkmks = [NSMutableArray arrayWithArray:[EAFAppContext sharedAppContext].userBookmarks];
    AGSWebMapBookmark *bkmk = [[AGSWebMapBookmark alloc]init];
    bkmk.name = self.result.name;
    bkmk.extent = self.result.extent;
    [bkmks addObject:bkmk];
    [EAFAppContext sharedAppContext].userBookmarks = bkmks;
    [self.bookmarkBtn setEnabled:NO];
    
    NSView *sView = _parentVC.bookmarkAnimationContainerView;
    CGRect initialFrame = [self.imageView convertRect:self.imageView.bounds toView:sView];
    NSImageView *animationImageView = [[NSImageView alloc]initWithFrame:initialFrame];
    [animationImageView setWantsLayer:YES];
    animationImageView.image = [NSImage imageNamed:@"pin-bookmark21x34"];
    [sView addSubview:animationImageView positioned:NSWindowAbove relativeTo:nil];
    
    [self performSelector:@selector(doAnimationForView:) withObject:animationImageView afterDelay:.25];
}

-(void)doAnimationForView:(NSImageView *)animationImageView{
    
    CGPoint to = [_parentVC.bookmarkAnimationView convertPoint:_parentVC.bookmarksAnimationLocation toView:_parentVC.bookmarkAnimationContainerView];
    CGSize toSize = CGSizeMake(3, 3);
    //CGSize toSize = animationImageView.frame.size;
//    CGSize toSize = CGSizeMake(animationImageView.frame.size.width * .25,
//                               animationImageView.frame.size.height * .25);
    CGFloat offsetX = toSize.width * .5;
    CGFloat offsetY = toSize.height * .5;
    CGFloat duration = .5;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        NSMutableDictionary *animDict = [NSMutableDictionary dictionaryWithCapacity:3];
        [animDict setObject:animationImageView forKey:NSViewAnimationTargetKey];
        NSRect toFrame = CGRectMake(to.x - offsetX, to.y - offsetY, toSize.width, toSize.height);
        [animDict setObject:[NSValue valueWithRect:toFrame] forKey:NSViewAnimationEndFrameKey];
        //[animDict setValue:NSViewAnimationEffectKey forKey:NSViewAnimationFadeOutEffect];
        NSViewAnimation *anim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animDict, nil]];
        [anim setDuration:duration];
        [anim startAnimation];
        [anim setAnimationCurve:NSAnimationEaseIn];
    } completionHandler:^{
        [animationImageView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:duration];
    }];

}

@end








