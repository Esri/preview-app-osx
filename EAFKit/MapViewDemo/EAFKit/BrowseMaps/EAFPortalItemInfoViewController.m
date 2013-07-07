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

#import "EAFPortalItemInfoViewController.h"
#import "NSAttributedString+EAFAdditions.h"
#import "EDStarRating.h"
#import "EAFFlippedView.h"
#import "EAFCGUtils.h"
#import "EAFPortalItemCommentViewController.h"
#import "NSString+EAFAdditions.h"

@interface EAFPortalItemInfoViewController ()<NSTableViewDataSource, NSTableViewDelegate, EDStarRatingProtocol> {
    BOOL _loadedOnce;
}
@property (nonatomic, strong) IBOutlet EDStarRating *starRating;
@property (nonatomic, strong) IBOutlet EDStarRating *userStarRating;
@property (nonatomic, strong) IBOutlet NSTableView *commentsTableView;
@property (nonatomic, strong) IBOutlet NSTextField *rateMapText;
@property (nonatomic, strong) NSOperation *addRatingOp;
@property (nonatomic, strong) NSOperation *fetchUserRatingOp;

@property (nonatomic, strong) IBOutlet NSScrollView *scrollView;
@property (nonatomic, strong) IBOutlet EAFFlippedView *scrollDocumentView;
@property (nonatomic, strong) WebView *webView;

@end

@implementation EAFPortalItemInfoViewController

- (void)dealloc {
    [self.webView setFrameLoadDelegate:nil];
    [self.webView setPolicyDelegate:nil];
    [self.fetchUserRatingOp cancel];
    [self.addRatingOp cancel];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithPortalItem:(AGSPortalItem*)portalItem {
    self = [super initWithNibName:@"EAFPortalItemInfoViewController" bundle:nil];
    if (self) {
        self.portalItem = portalItem;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratingSuccessful:) name:AGSPortalItemDidAddRatingNotification object:self.portalItem];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratingFailed:) name:AGSPortalItemDidFailToAddRatingNotification object:self.portalItem];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userRatingFetched:) name:AGSPortalItemDidFetchUserRatingNotification object:self.portalItem];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userRatingNotFetched:) name:AGSPortalItemDidFailToFetchUserRatingNotification object:self.portalItem];
        
        //
        // if we have a current logged in user, fetch their rating
        if (self.portalItem.portal.user.username) {
           self.fetchUserRatingOp = [self.portalItem fetchUserRating];
        }
        
        if (!self.portalItem.comments) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentsFetched:) name:AGSPortalItemDidFetchCommentsNotification object:self.portalItem];
            [self.portalItem fetchComments];
        }
    }
    return self;
}

- (void)awakeFromNib {
    //
    // the view-based table view cells being loaded from the NIB will case awakeFromNib to be called multiple times
    // we only want to do this stuff here once
    if (!_loadedOnce) {
        
        //
        // create our document view for the scroll view
        self.scrollDocumentView = [[EAFFlippedView alloc] initWithFrame:self.scrollView.bounds];
        self.scrollView.documentView = self.scrollDocumentView;
        
        //
        // initially create our web view the size of our document view
        self.webView = [[WebView alloc] initWithFrame:self.scrollDocumentView.bounds];
//        EAFDebugStrokeBorder(self.webView, 1.0, [NSColor redColor]);
        [self.scrollDocumentView addSubview:self.webView];
        
        [[self.webView mainFrame] loadHTMLString:self.portalItem.itemDescription baseURL:nil];
        self.webView.policyDelegate = self;
        self.webView.drawsBackground = NO;
        [self.webView setFrameLoadDelegate:self];
        [[self.webView preferences] setStandardFontFamily:@"Lucida Grande"];
        [[self.webView preferences] setDefaultFontSize:12];
        
        //
        // web maps ratings
        [self.starRating setBackgroundColor:[NSColor clearColor]];
        [self.starRating setWantsLayer:YES];
        self.starRating.starImage = [NSImage imageNamed:@"star-gray12x12"];
        self.starRating.starHighlightedImage = [NSImage imageNamed:@"star-orange12x12"];
        self.starRating.editable = NO;
        self.starRating.horizontalMargin = 0;
        self.starRating.displayMode = EDStarRatingDisplayAccurate;
        [self.starRating setMaxRating:5];
        //
        // we want to update the starRating's rating property with the avgRating of the portal item -- and
        // keep it updated in case it changes
        [self.starRating bind:@"rating" toObject:self.portalItem withKeyPath:@"avgRating" options:nil];
        
        //
        // user web map rating
        if (!self.portalItem.portal.user.username || [self.portalItem.owner isEqualToString:self.portalItem.portal.user.username]) {
            // if we are NOT logged in || if this map is OURS... hide userRating
            [self.userStarRating setHidden:YES];
            [self.rateMapText setHidden:YES];
        }
        [self.userStarRating setBackgroundColor:[NSColor clearColor]];
        [self.userStarRating setWantsLayer:YES];
        self.userStarRating.starImage = [NSImage imageNamed:@"star-gray12x12"];
        self.userStarRating.starHighlightedImage = [NSImage imageNamed:@"star-blue12x12"];
        self.userStarRating.editable = YES;
        self.userStarRating.horizontalMargin = 0;
        self.userStarRating.displayMode = EDStarRatingDisplayFull;
        [self.userStarRating setMaxRating:5];
        self.userStarRating.delegate = self;
        
        //
        // bind our user's starRating to the userRating property of the portal item
        [self.userStarRating bind:@"rating" toObject:self.portalItem withKeyPath:@"userRating" options:nil];
        
        _loadedOnce = YES;
    }
}

- (void)commentsFetched:(NSNotification*)note {
    if (self.portalItem.comments.count) {
        [self layoutScrollingContentView];
    }
}

#pragma mark -
#pragma mark WebPolicyDecisionListener

//
// this prevents the links in the web view from causing the webview to navigate away
// we just blindly open up safari
- (void)webView:(WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id <WebPolicyDecisionListener>)listener
{
    NSDictionary *info = actionInformation;
    NSURL *url = [info objectForKey:WebActionOriginalURLKey];
    NSString *path = [url absoluteString];
    NSRange range;
    
    range = [path rangeOfString:@"file://"];
    
    if (range.location != 0) {
        // open in Safari ö
        [listener ignore];
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
    }
}

#pragma mark -
#pragma mark WebFrameDelegate

//called when the frame finishes loading
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)webFrame
{
    if([webFrame isEqual:[self.webView mainFrame]])
    {
        //get the rect for the rendered frame
        NSRect webFrameRect = [[[webFrame frameView] documentView] frame];
        self.webView.frame = EAFCGRectSetHeight(self.webView.frame, webFrameRect.size.height);
        [self layoutScrollingContentView];
    }
}

- (void)layoutScrollingContentView {
    NSRect current = self.webView.frame;

    if (self.portalItem.comments) {
        
        NSView *lastView = self.webView;
        NSSize commentsSize = [@"Comments" eaf_sizeForWidth:125 font:[NSFont boldSystemFontOfSize:18]];

        NSTextField *commentTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(5, CGRectGetHeight(current) + 10, 125, 35)];
        //commentTextField.translatesAutoresizingMaskIntoConstraints = NO;
        [commentTextField setTextColor:[NSColor darkGrayColor]];
        [commentTextField setFont:[NSFont boldSystemFontOfSize:18]];
        [commentTextField setStringValue:@"Comments"];
        [commentTextField setBezeled:NO];
        commentTextField.drawsBackground = NO;

        //
        // make the "Comments" section title 10 points from the bottom of the web view
        NSLayoutConstraint *commentsTextLC = [NSLayoutConstraint constraintWithItem:commentTextField
                                                                          attribute:NSLayoutAttributeTop
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:lastView
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1.0
                                                                           constant:10.0];
        
        [self.scrollDocumentView addSubview:commentTextField];
        [self.scrollDocumentView addConstraint:commentsTextLC];

        current = EAFCGRectSetHeight(current, CGRectGetHeight(current) + commentsSize.height + 10 + 10);
        
        lastView = commentTextField;

        //
        // if we have comments to add to our view -- we need to figure out the content size
        // keep a counter so we don't show thousands of comments..we will show the 25 (or less) most recent comments
        int numComments = 0;
        for (AGSPortalItemComment *pic in self.portalItem.comments) {
            numComments++;
            
            // create our comment view -- adjust it's content size -- then add it to our document view and adjust it's frame
            EAFPortalItemCommentViewController *picvc = [[EAFPortalItemCommentViewController alloc] initWithPortalItemComment:pic];
            picvc.view.translatesAutoresizingMaskIntoConstraints = NO;
            
            //
            // add constraint on this view to be 5 points below the previous view
            NSLayoutConstraint *lc = [NSLayoutConstraint constraintWithItem:picvc.view
                                                                  attribute:NSLayoutAttributeTop
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:lastView
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1.0
                                                                   constant:5.0];

            [self.scrollDocumentView addSubview:picvc.view];
            [self.scrollDocumentView addConstraint:lc];
            
            //
            // maintain pointer to the last added view so we can add the next one just below it
            lastView = picvc.view;
            
            //
            // we call this manually so our view's geometry is up to date
            [picvc.view layoutSubtreeIfNeeded];

            //
            // we need to maintain a rect that will be the frame of our scrollView's document view
            current = EAFCGRectSetHeight(current, CGRectGetHeight(current) + CGRectGetHeight(lastView.bounds) + 5);
            
            //
            // for our last comment, we don't want to see the separator view
            // our last comment is either: the 25th comment (because we don't want to show thousands)
            // or the last object in our comments array
            if (numComments == 25 || (pic == [self.portalItem.comments lastObject])) {
                [picvc.separatorView setHidden:YES];
            }
        }
    }
    
    //
    // update our scroll view's document 
    self.scrollDocumentView.frame = current;
}

#pragma mark -
#pragma mark EDStarRatingProtocol

- (void)starsSelectionChanged:(EDStarRating *)control rating:(float)rating {
    //
    // if we are currently rating...cancel
    if (self.addRatingOp) {
        [self.addRatingOp cancel];
    }
    self.addRatingOp = [self.portalItem addRating:rating];

}

#pragma mark -
#pragma mark AGSPortalItem Notifications

- (void)ratingSuccessful:(NSNotification*)note {
    NSDictionary *userInfo = [note userInfo];
    NSOperation *op = [userInfo valueForKey:@"operation"];
    if (self.addRatingOp == op) {
        self.addRatingOp = nil;
    }
}

- (void)ratingFailed:(NSNotification*)note {
    NSDictionary *userInfo = [note userInfo];
    NSOperation *op = [userInfo valueForKey:@"operation"];
    if (self.addRatingOp == op) {
        self.addRatingOp = nil;
    }
}

- (void)userRatingFetched:(NSNotification*)note {
    NSDictionary *userInfo = [note userInfo];
    NSOperation *op = [userInfo valueForKey:@"operation"];
    if (self.fetchUserRatingOp == op) {
        self.fetchUserRatingOp = nil;
    }
}

- (void)userRatingNotFetched:(NSNotification*)note {
    NSDictionary *userInfo = [note userInfo];
    NSOperation *op = [userInfo valueForKey:@"operation"];
    if (self.fetchUserRatingOp == op) {
        self.fetchUserRatingOp = nil;
    }
}

@end
