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

#import "EAFMapCopyrightViewController.h"
#import "EAFLayerCopyrightViewController.h"
#import "NSView+EAFAdditions.h"
#import "EAFCGUtils.h"
#import "NSColor+EAFAdditions.h"
#import "EAFAppContext.h"

@interface EAFMapCopyrightViewController (){
    NSMutableArray *_layerVCs;
}

@end

@implementation EAFMapCopyrightViewController

-(id)init{
    return [self initWithNibName:@"EAFMapCopyrightViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}


-(void)awakeFromNib{
    
    self.scrollView.backgroundColor = [NSColor whiteColor];
    
    NSView *prev = nil;
    _layerVCs = [NSMutableArray array];
    
    NSView *myDocView = [[NSView alloc]initWithFrame:CGRectZero];
    myDocView.translatesAutoresizingMaskIntoConstraints = NO;
    //[myDocView setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
    
    self.scrollView.documentView = myDocView;
    NSView *docSuper = myDocView.superview;
    [myDocView.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[myDocView]-0-|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(myDocView)]];
    [myDocView.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[myDocView(>=docSuper)]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(myDocView, docSuper)]];
    
    NSTextField *textField = [[NSTextField alloc] initWithFrame:CGRectZero];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [textField setStringValue:@"Copyright Infomation"];
    [textField setFont:[NSFont systemFontOfSize:14]];
    [textField setTextColor:[NSColor lightGrayColor]];
    [textField setBezeled:NO];
    [textField setDrawsBackground:NO];
    [textField setEditable:NO];
    [textField setSelectable:NO];
    [myDocView addSubview:textField];
    [myDocView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[textField]-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(textField)]];
    [myDocView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[textField]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(textField)]];
    prev = textField;
    
    for (AGSLayer *lyr in [EAFAppContext sharedAppContext].mapView.mapLayers){
        AGSMapServiceInfo *msi = nil;
        if ([lyr isKindOfClass:[AGSTiledMapServiceLayer class]]){
            AGSTiledMapServiceLayer *tmsl = (AGSTiledMapServiceLayer*)lyr;
            msi = tmsl.mapServiceInfo;
        }
        else if ([lyr isKindOfClass:[AGSDynamicMapServiceLayer class]]){
            AGSDynamicMapServiceLayer *dmsl = (AGSDynamicMapServiceLayer*)lyr;
            msi = dmsl.mapServiceInfo;
        }
        
        if (msi.copyright.length){
            EAFLayerCopyrightViewController *layerVC = [[EAFLayerCopyrightViewController alloc]init];
            [_layerVCs addObject:layerVC];
            [layerVC setMapServiceInfo:msi];
            
            NSView *curr = layerVC.view;
            curr.translatesAutoresizingMaskIntoConstraints = NO;
            
            //            EAFDebugStrokeBorder(curr, 1, [NSColor greenColor]);
            //            EAFDebugStrokeBorder(self.scrollView, 1, [NSColor greenColor]);
            
//            EAFDebugStrokeBorder(myDocView, 1, [NSColor redColor]);
//            EAFDebugStrokeBorder(myDocView.superview, 1, [NSColor yellowColor]);
            
            [myDocView addSubview:curr];
            
            NSArray *hcs = [NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[curr]-0-|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:NSDictionaryOfVariableBindings(curr)];
            [myDocView addConstraints:hcs];

            if (prev){
                NSArray *vcs = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[prev]-0-[curr]"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:NSDictionaryOfVariableBindings(curr, prev)];
                [myDocView addConstraints:vcs];
            }
            else{
                NSArray *vcs = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[curr]"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:NSDictionaryOfVariableBindings(curr)];
                [myDocView addConstraints:vcs];
            }
            prev = layerVC.view;
        }
    }
    
    // !!!
    // for last one set vertical constraint
    // this one is really important so that the layout knows the height of the
    // document view
    if (prev){
        [myDocView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[prev]|"
                                                                         options:0
                                                                         metrics:nil
                                                                            views:NSDictionaryOfVariableBindings(prev)]];
    }
    
}
                                          
                                          

@end
