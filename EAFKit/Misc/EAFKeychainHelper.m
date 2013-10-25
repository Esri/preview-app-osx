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

#import "EAFKeychainHelper.h"

#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>

@interface EAFKeychainHelper ()
@property (nonatomic, copy, readwrite) NSString *serviceName;
@end

@implementation EAFKeychainHelper

- (id)initWithServiceName:(NSString*)serviceName {
    self = [super init];
    if (self) {
        self.serviceName = serviceName;
    }
    return self;
}


- (NSString*)passwordForUser:(NSString*)user {
    OSStatus status;
    if (!user || !self.serviceName) {
        return nil;
    }
    
    UInt32 userLength = (UInt32)[user length];
    UInt32 serviceLength = (UInt32)[self.serviceName length];
    
    UInt32 passwordLength;
    
    void *passwordData = nil;
    status = SecKeychainFindGenericPassword (
                                             NULL,                      // default keychain
                                             serviceLength,             // length of service name
                                             [self.serviceName UTF8String],  // service name
                                             userLength,                // length of account name
                                             [user UTF8String],         // account name
                                             &passwordLength,            // length of password
                                             &passwordData,              // pointer to password data
                                             NULL                    // the item reference
                                             );
    
    NSString *pw = nil;
    if (status == noErr)       //If call was successful, authenticate user and continue.
    {
        if (passwordData) {
            pw = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
        }

        //Free the data allocated by SecKeychainFindGenericPassword:
        status = SecKeychainItemFreeContent ( NULL,           //No attribute data to release
                                             passwordData    //Release data buffer allocated by SecKeychainFindGenericPassword
                                             );
        
    }
    return pw;
}

- (OSStatus)storePassword:(NSString*)password forUser:(NSString*)user {
    OSStatus status;
    if (!password || !user || !self.serviceName) {
        return -50; // paramErr
    }
    
    UInt32 pwLength = (UInt32)[password length];
    UInt32 userLength = (UInt32)[user length];
    UInt32 serviceLength = (UInt32)[self.serviceName length];
    
    const void *pwData = [[password dataUsingEncoding:NSUTF8StringEncoding] bytes];
    
    status = SecKeychainAddGenericPassword(NULL,                        // default keychain
                                           serviceLength,               // length of service name
                                           [self.serviceName UTF8String],    // service name
                                           userLength,                  // length of username
                                           [user UTF8String],           // username
                                           pwLength,                    // length of password
                                           pwData,                      // data representing password
                                           NULL                         // item to reference
                                           );
    return status;
}

- (OSStatus)removePasswordForUser:(NSString*)user {
    OSStatus status;
    if (!user || !self.serviceName) {
        return -50; // paramErr
    }
    
    UInt32 userLength = (UInt32)[user length];
    UInt32 serviceLength = (UInt32)[self.serviceName length];
    
    SecKeychainItemRef itemRef = nil;
    status = SecKeychainFindGenericPassword (
                                             NULL,                      // default keychain
                                             serviceLength,             // length of service name
                                             [self.serviceName UTF8String],  // service name
                                             userLength,                // length of account name
                                             [user UTF8String],         // account name
                                             NULL,            // length of password
                                             NULL,              // pointer to password data
                                             &itemRef                    // the item reference
                                             );
    
    if (status == noErr)       //If call was successful, authenticate user and continue.
    {
        if (itemRef) {
            //pw = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
            status = SecKeychainItemDelete(itemRef);
            CFRelease(itemRef);
            //NSLog(@"Deleted and released item: %d", status);
        }
        
    }
    return status;

}
@end
