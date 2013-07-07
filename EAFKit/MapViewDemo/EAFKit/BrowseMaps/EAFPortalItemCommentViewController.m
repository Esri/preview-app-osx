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

#import "EAFPortalItemCommentViewController.h"
#import "EAFCGUtils.h"
#import "NSString+EAFAdditions.h"

@interface EAFPortalItemCommentViewController ()
@property (nonatomic, strong, readwrite) AGSPortalItemComment *portalItemComment;
//@property (nonatomic, copy) NSString *commenterDisplayString;

@property (nonatomic, strong) IBOutlet NSTextField *commenterTextField;
@property (nonatomic, strong) IBOutlet NSTextField *commentTextField;
@property (nonatomic, strong, readwrite) NSView *separatorView;
@end

@implementation EAFPortalItemCommentViewController

-(id)initWithPortalItemComment:(AGSPortalItemComment*)portalItemComment {
    self = [super initWithNibName:@"EAFPortalItemCommentViewController" bundle:nil];
    if (self) {
        self.portalItemComment = portalItemComment;
        
        //
        // set our date style and display string for the top of the view
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateStyle:NSDateFormatterLongStyle];
        self.commenterDisplayString = [NSString stringWithFormat:@"%@ on %@", self.portalItemComment.owner, [df stringFromDate:self.portalItemComment.created]];
    }
    return self;
}

- (void)awakeFromNib {
    //
    // we add our constraints here because interface builder doesn't like the constraints we
    // set there
    //EAFDebugStrokeBorder(self.commentTextField, 1.0, [NSColor blueColor]);

    self.commenterTextField.translatesAutoresizingMaskIntoConstraints = NO;
    //
    // leading
    NSLayoutConstraint *commenterLeadingLC = [NSLayoutConstraint constraintWithItem:self.commenterTextField
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0
                                                                           constant:10.0];
    [self.view addConstraint:commenterLeadingLC];
    
    //
    // trailing
    NSLayoutConstraint *commenterTrailingLC = [NSLayoutConstraint constraintWithItem:self.commenterTextField
                                                                          attribute:NSLayoutAttributeTrailing
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeTrailing
                                                                         multiplier:1.0
                                                                           constant:-10.0];
    [self.view addConstraint:commenterTrailingLC];
    
    //
    // top
    NSLayoutConstraint *commenterTopLC = [NSLayoutConstraint constraintWithItem:self.commenterTextField
                                                                      attribute:NSLayoutAttributeTop
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0
                                                                       constant:5.0];
    [self.view addConstraint:commenterTopLC];
    
    //
    // height
    NSLayoutConstraint *commenterHeightLC = [NSLayoutConstraint constraintWithItem:self.commenterTextField
                                                                      attribute:NSLayoutAttributeHeight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                                     multiplier:1.0
                                                                       constant:17.0];
    [self.view addConstraint:commenterHeightLC];
    
    
    self.commentTextField.translatesAutoresizingMaskIntoConstraints = NO;
    //
    // height
    NSLayoutConstraint *commentHeightLC = [NSLayoutConstraint constraintWithItem:self.commentTextField
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0
                                                                        constant:14.0];
    [self.commentTextField addConstraint:commentHeightLC];
    
    //
    // leading
    NSLayoutConstraint *commentLeadingLC = [NSLayoutConstraint constraintWithItem:self.commentTextField
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0
                                                                           constant:10.0];
    [self.view addConstraint:commentLeadingLC];
    
    //
    // trailing
    NSLayoutConstraint *commentTrailingLC = [NSLayoutConstraint constraintWithItem:self.commentTextField
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.view
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:-10.0];
    [self.view addConstraint:commentTrailingLC];
    
    //
    // top
    NSLayoutConstraint *commentTopLC = [NSLayoutConstraint constraintWithItem:self.commentTextField
                                                                    attribute:NSLayoutAttributeTop
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.commenterTextField
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:5.0];
    [self.view addConstraint:commentTopLC];
    
    //
    // bottom
    NSLayoutConstraint *commentBottomLC = [NSLayoutConstraint constraintWithItem:self.commentTextField
                                                                    attribute:NSLayoutAttributeBottom
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.view
                                                                    attribute:NSLayoutAttributeBottom
                                                                   multiplier:1.0
                                                                     constant:-10.0];
    [self.view addConstraint:commentBottomLC];


    // at this point we need to figure out the size of our comment
    NSSize size = [self.commentTextField.stringValue eaf_sizeForWidth:CGRectGetWidth(self.commentTextField.bounds) font:self.commentTextField.font];

    self.commentTextField.frame = EAFCGRectSetHeight(self.commentTextField.frame, size.height);
    
    self.separatorView = [[NSView alloc] initWithFrame:NSMakeRect(10, 0, CGRectGetWidth(self.commentTextField.bounds), 1.0)];
    [self.separatorView setWantsLayer:YES];
    self.separatorView.layer.backgroundColor = [[NSColor darkGrayColor] CGColor];
    [self.view addSubview:self.separatorView];
    
    [self.commentTextField setSelectable:YES];
}
@end
