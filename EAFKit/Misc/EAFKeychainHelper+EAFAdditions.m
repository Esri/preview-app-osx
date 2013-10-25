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

#import "EAFKeychainHelper+EAFAdditions.h"

static EAFKeychainHelper *kEAFArcGISPreviewHelper;

@implementation EAFKeychainHelper (EAFAdditions)

+(id)eaf_sharedHelperForArcGISPreview {
    if (!kEAFArcGISPreviewHelper) {
        kEAFArcGISPreviewHelper = [[EAFKeychainHelper alloc] initWithServiceName:@"ArcGIS-Preview"];
    }
    return kEAFArcGISPreviewHelper;
}

- (AGSCredential*)eaf_credentialForUser:(NSString*)user {
    NSString *pw = [self passwordForUser:user];
    if (user && pw) {
        return [[AGSCredential alloc] initWithUser:user password:pw];
    }
    return nil;
}

- (OSStatus)eaf_storeCredential:(AGSCredential*)credential {
    return [self storePassword:credential.password forUser:credential.username];
}

- (OSStatus)eaf_removeCredential:(AGSCredential*)credential {
    return [self removePasswordForUser:credential.username];
}

@end
