/**
 *  Copyright 2014 Nest Labs Inc. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#import "NestConnectViewController.h"
#import "NestAuthManager.h"
#import "NestWebViewAuthController.h"

static NSString *buttonDefTitle = @"Connect with your Nest account!";

@interface NestConnectViewController () <NestWebViewAuthControllerDelegate>

@property (nonatomic, weak) UIButton *nestConnectButton;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) NestWebViewAuthController *nestWebViewAuthController;

@property (nonatomic, weak) NestAuthManager *manager;

@end

@implementation NestConnectViewController

#pragma mark View Setup Methods

/**
 * Setup the view.
 */
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.manager = [NestAuthManager sharedManager];
    }
    return self;
}

- (void)loadView
{
    // Setup the view itself
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // Add a scrollview just to feel a little nicer
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [scrollView setFrame:self.view.bounds];
    scrollView.translatesAutoresizingMaskIntoConstraints = YES;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [scrollView setBounces:YES];
    [scrollView setAlwaysBounceVertical:YES];
    scrollView.autoresizesSubviews = YES;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    // Add the button the scrollview
    UIButton *connectButton = [self createNestConnectButton];
    connectButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:connectButton];
    
    self.nestConnectButton = connectButton;
    
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:self.nestConnectButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.nestConnectButton.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    
    
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:self.nestConnectButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.nestConnectButton.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    
    NSLayoutConstraint *widthProp = [NSLayoutConstraint constraintWithItem:self.nestConnectButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.nestConnectButton.superview attribute:NSLayoutAttributeWidth multiplier:0.8 constant:0];
    
    [self.nestConnectButton.titleLabel sizeToFit];
    
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.nestConnectButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:self.nestConnectButton.bounds.size.height];
    
    [self.nestConnectButton setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    
    [NSLayoutConstraint activateConstraints:@[centerX, centerY, widthProp, height]];
}

/**
 * Create the nest connect button.
 * @return The new nest connect button.
 */
- (UIButton *)createNestConnectButton
{
    UIButton *nestConnectButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 250, 130)];
    [nestConnectButton setTitleColor:[[UIColor blueColor] colorWithAlphaComponent:0.5] forState:UIControlStateNormal];
    [nestConnectButton setTitleColor:[[UIColor blueColor] colorWithAlphaComponent:0.8] forState:UIControlStateHighlighted];
    
    [nestConnectButton setTitle:buttonDefTitle forState:UIControlStateNormal];
    
    [nestConnectButton.titleLabel setNumberOfLines:0];
    [nestConnectButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    nestConnectButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [nestConnectButton setTitleEdgeInsets:UIEdgeInsetsMake(10, 0, 10, 00.0)];
    
    [nestConnectButton.layer setBorderColor:[UIColor blueColor].CGColor];
    [nestConnectButton.layer setCornerRadius:8.f];
    [nestConnectButton.layer setBorderWidth:3.f];
    [nestConnectButton.layer setMasksToBounds:NO];
    
    [nestConnectButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:33]];
    [nestConnectButton addTarget:self action:@selector(nestConnectButtonHit:) forControlEvents:UIControlEventTouchUpInside];
    return nestConnectButton;
}

/**
 * Called when the nest connect button is hit.
 * Presents the web auth URL.
 * @param sender The button that sent the message.
 */
- (void)nestConnectButtonHit:(UIButton *)sender
{
    // First we need to create the authorization_code URL
    NSString *authorizationCodeURL = [self.manager authorizationURL];
    [self presentWebViewWithURL:authorizationCodeURL];
}


/**
 * Present the web view with the given url.
 * @param url The url you wish to have the web view load.
 */
- (void)presentWebViewWithURL:(NSString *)url
{
    // Present modally the web view controller
    self.nestWebViewAuthController = [[NestWebViewAuthController alloc] initWithURL:url delegate:self];
    [self presentViewController:self.nestWebViewAuthController animated:YES completion:^{}];
}

#pragma mark ViewController Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the nav bar title
    self.title = @"Welcome";
    
    [self.nestConnectButton setEnabled:YES];
}

#pragma mark NestWebViewControllerDelegate Methods

/**
 * Called from the NestWebViewControllerDelegate
 * if the user successfully finds the authorization code.
 * @param authorizationCode The authorization code NestAuthManager found.
 */
- (void)foundAuthorizationCode:(NSString *)authorizationCode
{
    [self.nestWebViewAuthController dismissViewControllerAnimated:YES completion:^{}];
    
    // Save the authorization code
    [self.manager setAuthorizationCode:authorizationCode];
    __weak typeof(self) wSelf = self;
    [self.manager receiveToken:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error != nil) {
                [wSelf.nestConnectButton setEnabled:YES];
                [wSelf.nestConnectButton setTitle:buttonDefTitle forState:UIControlStateNormal];
            }
        });
    }];
    // Check for the access token every second and once we have it leave this page
    
    // Set the button to disabled
    [self.nestConnectButton setEnabled:NO];
    [self.nestConnectButton setTitle:@"Loading..." forState:UIControlStateNormal];
}

/**
 * Called from the NestWebViewControllerDelegate if the user hits cancel
 * @param sender The button that sent the message.
 */
- (void)cancelButtonHit:(UIButton *)sender
{
    [self.nestWebViewAuthController dismissViewControllerAnimated:YES completion:^{}];
}

@end
