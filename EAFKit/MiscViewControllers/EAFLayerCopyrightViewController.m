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

#import "EAFLayerCopyrightViewController.h"

@interface EAFLayerCopyrightViewController ()

@end

@implementation EAFLayerCopyrightViewController

-(id)init{
    return [self initWithNibName:@"EAFLayerCopyrightViewController" bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)setMapServiceInfo:(AGSMapServiceInfo *)mapServiceInfo{
    _mapServiceInfo = mapServiceInfo;
    [self setupUI];
}

-(void)setupUI{
    if (_mapServiceInfo.documentInfo.title.length){
        self.layerNameTextField.stringValue = _mapServiceInfo.documentInfo.title;
    }
    else{
        self.layerNameTextField.stringValue = @"";
    }
    if (_mapServiceInfo.copyright.length){
        self.copyrightTextField.stringValue = _mapServiceInfo.copyright;
    }
    else{
        self.copyrightTextField.stringValue = @"";
    }
}

-(void)awakeFromNib{
    [self setupUI];
}

@end
