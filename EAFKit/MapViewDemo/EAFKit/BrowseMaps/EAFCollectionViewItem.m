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

#import "EAFCollectionViewItem.h"
#import "EAFCollectionView.h"
#import "EAFRoundedImageView.h"
#import "EDStarRating.h"
#import "EAFHyperlinkButton.h"
#import "NSColor+EAFAdditions.h"

@interface EAFCollectionViewItem ()<AGSPortalItemDelegate>
@property (nonatomic, strong) IBOutlet EAFRoundedImageView *thumbnail;
@property (nonatomic, strong) IBOutlet EDStarRating *starRating;
@property (nonatomic, strong) IBOutlet NSTextField *numRatingsLabel;
@property (nonatomic, strong) IBOutlet NSTextField *noRatingsLabel;
@property (nonatomic, strong) IBOutlet EAFHyperlinkButton *titleButton;
@property (nonatomic, strong) IBOutlet NSTextField *ownerLabel;
@property (nonatomic, strong) IBOutlet NSButton *openButton;
@property (nonatomic, strong) IBOutlet NSButton *infoButton;
@property (nonatomic, strong) NSOperation *thumbnailOp;
- (IBAction)openButtonClicked:(id)sender;
- (IBAction)infoButtonClicked:(id)sender;
@end

@implementation EAFCollectionViewItem

- (id)initWithPortalItem:(AGSPortalItem*)portalItem {
    self = [super initWithNibName:@"EAFCollectionViewItem" bundle:nil];
    if (self) {
        self.portalItem = portalItem;
        self.portalItem.delegate = self;
        if (!self.portalItem.thumbnail) {
            self.thumbnailOp = [self.portalItem fetchThumbnail];
        }        
    }
    return self;
}

- (void)mapTitleBtnClicked {
    [self.titleButton mouseExited:nil];
    [self openButtonClicked:nil];
}

- (IBAction)openButtonClicked:(id)sender {
    
    EAFCollectionView *cv = (EAFCollectionView*)self.collectionView;
    if ([cv.portalItemDelegate respondsToSelector:@selector(collectionView:wantsToOpenPortalItem:)]) {
        [cv.portalItemDelegate collectionView:cv wantsToOpenPortalItem:self.portalItem];
    }
}

- (IBAction)infoButtonClicked:(id)sender {
    EAFCollectionView *cv = (EAFCollectionView*)self.collectionView;
    if ([cv.portalItemDelegate respondsToSelector:@selector(collectionView:wantsToShowInfoForPortalItem:)]) {
        [cv.portalItemDelegate collectionView:cv wantsToShowInfoForPortalItem:self.portalItem];
    }
}

- (void)awakeFromNib {
    [self.view setWantsLayer:YES];

    NSView *thinWhiteLineView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1, CGRectGetHeight(self.view.bounds))];
    [thinWhiteLineView setWantsLayer:YES];
    thinWhiteLineView.layer.backgroundColor = [[NSColor whiteColor] CGColor];
    [self.view addSubview:thinWhiteLineView];
    
    NSColor *lineGrayColor = [NSColor colorWithDeviceRed:217.0/255 green:217.0/255 blue:217.0/255 alpha:1.0];
    
    NSView *thinGrayHorizontalView = [[NSView alloc] initWithFrame:NSMakeRect(1, 0, CGRectGetWidth(self.view.bounds)-1, 1)];
    [thinGrayHorizontalView setWantsLayer:YES];
    thinGrayHorizontalView.layer.backgroundColor = [lineGrayColor CGColor];
    [self.view addSubview:thinGrayHorizontalView];
    
    
    NSView *thinGrayVerticalView = [[NSView alloc] initWithFrame:NSMakeRect(CGRectGetWidth(self.view.bounds)-1, 0, 1, CGRectGetHeight(self.view.bounds))];
    [thinGrayVerticalView setWantsLayer:YES];
    thinGrayVerticalView.layer.backgroundColor = [lineGrayColor CGColor];
    [self.view addSubview:thinGrayVerticalView];
    
    self.thumbnail.xRadius = 4.0f;
    self.thumbnail.yRadius = 4.0f;
    
    [self.thumbnail setWantsLayer:YES];
    self.thumbnail.layer.cornerRadius = 4.0f;
    self.thumbnail.layer.borderColor = [[NSColor lightGrayColor] CGColor];
    self.thumbnail.layer.borderWidth = 1.0f;
    self.thumbnail.layer.masksToBounds = YES;
    [self.thumbnail setImageScaling:NSImageScaleProportionallyUpOrDown];
    
    [self.starRating setBackgroundColor:[NSColor clearColor]];
    [self.starRating setWantsLayer:YES];
    self.starRating.starImage = [NSImage imageNamed:@"star-gray12x12"];
    self.starRating.starHighlightedImage = [NSImage imageNamed:@"star-orange12x12"];
    self.starRating.editable = NO;
    self.starRating.horizontalMargin = 0;
    self.starRating.displayMode = EDStarRatingDisplayAccurate;
    [self.starRating setMaxRating:5];
    
    //
    // bind our starRating's rating property to the avgRating of the portalItem
    [self.starRating bind:@"rating" toObject:self.portalItem withKeyPath:@"avgRating" options:nil];
    
    // NumRatings label
    [self.numRatingsLabel setEditable:NO];
    [self.numRatingsLabel setBordered:NO];
    [self.numRatingsLabel setDrawsBackground:NO];
    [self.numRatingsLabel setTextColor:[NSColor eaf_appStoreLightGrayTextColor]];
    
    // NoRatings Label
    [self.noRatingsLabel setTextColor:[NSColor eaf_appStoreLightGrayTextColor]];
    
    //
    // clickable map title button
    [self.titleButton setFont:[NSFont boldSystemFontOfSize:12]];
    [self.titleButton setTarget:self];
    [self.titleButton setLineBreakMode:NSLineBreakByTruncatingTail];
    [self.titleButton setAction:@selector(mapTitleBtnClicked)];
    [self.titleButton bind:@"title" toObject:self.portalItem withKeyPath:@"title" options:nil];    

    //
    // owner label
    [self.ownerLabel setTextColor:[NSColor eaf_appStoreLightGrayTextColor]];
    [self.ownerLabel setEditable:NO];
    [self.ownerLabel setBordered:NO];
    [self.ownerLabel setDrawsBackground:NO];
    
    //
    // if we don't have a thumbnail and are not actively fetching it -- set the default
    if (!self.thumbnail.image && !self.thumbnailOp) {
        self.thumbnail.image = [NSImage imageNamed:@"map200x133"];
    }
}

#pragma mark -
#pragma mark AGSPortalItemDelegate

- (void)portalItem:(AGSPortalItem *)portalItem operation:(NSOperation *)op didFailToFetchThumbnailWithError:(NSError *)error {
    self.thumbnailOp = nil;
    self.thumbnail.image = [NSImage imageNamed:@"map200x133"];
}

- (void)portalItem:(AGSPortalItem *)portalItem operation:(NSOperation *)op didFetchThumbnail:(NSImage *)thumbnail {
    self.thumbnailOp = nil;
}

@end
