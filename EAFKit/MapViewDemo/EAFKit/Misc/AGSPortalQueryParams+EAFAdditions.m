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

#import "AGSPortalQueryParams+EAFAdditions.h"

@implementation AGSPortalQueryParams (EAFAdditions)

// @todo remove this when/if they enforce this at the server
- (void)eaf_constrainQueryForPortal:(AGSPortal*)portal {
    
    NSString *orgId = portal.portalInfo.organizationId;
    //
    // we want to not search public maps if the org is setup that way
    // this is a hack for the fact that they don't enforce this at the server level.
    // @todo remove this when/if they enforce this at the server
    if (!portal.portalInfo.canSearchPublic && orgId.length){
        if (self.query.length){
            NSString *q = [NSString stringWithFormat:@"(%@) AND orgid:%@", self.query, orgId];
            self.query = q;
        }
        else{
            NSString *q = [NSString stringWithFormat:@"orgid:%@", orgId];
            self.query = q;
        }
    }
}

-(void)eaf_constrainQueryExcludeBasemapsForPortal:(AGSPortal *)portal{

    // this attempts to construct the query such that basemaps are not
    // in the results.
    // @"NOT group:e288dc13050b4cdd80c0600c2e37919b";
    if ([portal.portalInfo.basemapGalleryGroupQuery.lowercaseString hasPrefix:@"id:"] &&
        portal.portalInfo.basemapGalleryGroupQuery.length == 35){
        NSString *basemapFilter = [NSString stringWithFormat:@"NOT %@", [[portal.portalInfo.basemapGalleryGroupQuery lowercaseString] stringByReplacingOccurrencesOfString:@"id:" withString:@"group:"]];
        
        if (self.query.length){
            NSString *q = [NSString stringWithFormat:@"(%@) AND %@", self.query, basemapFilter];
            self.query = q;
        }
        else{
            self.query = basemapFilter;
        }
    }
}

@end
