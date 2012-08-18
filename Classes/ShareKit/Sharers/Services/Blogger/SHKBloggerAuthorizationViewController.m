//
//  SHKBloggerAuthorizationViewController.m
//  ShareKit
//
//  Created by Shirmung Bielefeld on 7/7/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "SHKBloggerAuthorizationViewController.h"
#import "SHKBlogger.h"

@interface SHKBloggerAuthorizationViewController ()

@end

@implementation SHKBloggerAuthorizationViewController

@synthesize bloggerWebView, delegate;

// TDL: move to SHKConfig so the user can modify them
#define RESPONSE_TYPE @"code"
#define CLIENT_ID @""
#define REDIRECT_URI @"urn:ietf:wg:oauth:2.0:oob"
#define SCOPE @"https://www.googleapis.com/auth/blogger"

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        // Custom initialization
    }

    return self;
}

- (void)dealloc
{
    bloggerWebView.delegate = nil;
    [bloggerWebView release];

    [delegate release];

    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                   target:self
                                                                                   action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = barButtonItem;

    [barButtonItem release];

    if (!bloggerWebView) {
        bloggerWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        bloggerWebView.delegate = self;
        bloggerWebView.scalesPageToFit = YES;

        [self.view addSubview:bloggerWebView];
    }

    if (RESPONSE_TYPE && CLIENT_ID && REDIRECT_URI && SCOPE) {
        NSString *urlString = [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/auth?response_type=%@&client_id=%@&redirect_uri=%@&scope=%@", RESPONSE_TYPE, CLIENT_ID, REDIRECT_URI, SCOPE];
        [bloggerWebView loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]]];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];

	[bloggerWebView stopLoading];
	bloggerWebView.delegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - IBAction

- (IBAction)cancel:(UIBarButtonItem *)barButtonItem
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Web View Delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];

    // TDL: regex
    if ([[title substringWithRange:NSMakeRange(0, 7)] isEqualToString:@"Success"]) {
        NSString *authorizationToken = [title substringFromIndex:13];

        if (authorizationToken) {
            [[NSUserDefaults standardUserDefaults] setObject:authorizationToken forKey:@"SHKBloggerAuthorizationToken"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            [delegate authorizationComplete:authorizationToken];
        }

        [self dismissModalViewControllerAnimated:YES];
    } else if ([[title substringWithRange:NSMakeRange(0, 6)] isEqualToString:@"Denied"]) {
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[self dismissModalViewControllerAnimated:YES];
}

@end