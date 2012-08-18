//
//  SHKBlogger.m
//  ShareKit
//
//  Created by Shirmung Bielefeld on 6/29/12.
//  Copyright (c) 2012. All rights reserved.
//

#import "SHKBlogger.h"
#import "OAuthConsumer.h"
#include <sys/types.h>
#import "JSONKit.h"
#import "SHKBloggerAuthorizationViewController.h"

@interface SHKBlogger ()

@end

@implementation SHKBlogger

@synthesize authorizationToken, accessToken;

// TDL: add URLs
// TDL: move to SHKConfig so the user can modify them
#define CLIENT_ID @""
#define CLIENT_SECRET @""
#define REDIRECT_URI @"urn:ietf:wg:oauth:2.0:oob"
#define GRANT_TYPE @"authorization_code"

- (id)init
{
	if (self = [super init]) {		

	}
	
	return self;
}

#pragma mark - Configuration : Service Definition

+ (NSString *)sharerTitle
{
	return @"Blogger";
}

+ (BOOL)canShareText
{
	return YES;
}

#pragma mark - Configuration : Dynamic Enable

+ (BOOL)canShare
{
	return YES;
}

#pragma mark - Authentication

- (BOOL)isAuthorized
{	  
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    authorizationToken = [standardUserDefaults objectForKey:@"SHKBloggerAuthorizationToken"];
	
	return (authorizationToken != nil);
}

- (void)promptAuthorization
{	
	SHKBloggerAuthorizationViewController *sHKBloggerAuthorizationViewController = [[SHKBloggerAuthorizationViewController alloc] init];
	sHKBloggerAuthorizationViewController.delegate = self;
	
	[sHKBloggerAuthorizationViewController view];
		
	[self pushViewController:sHKBloggerAuthorizationViewController animated:YES];

	[[SHK currentHelper] showViewController:self];
}

- (void)authorizationComplete:(NSString *)anAuthorizationToken
{
	if (self.item) {
        NSURL *url = [NSURL URLWithString:@"https://accounts.google.com/o/oauth2/token"];
        
        OAMutableURLRequest *accessTokenRequest = [[OAMutableURLRequest alloc] initWithURL:url 
                                                                                  consumer:nil
                                                                                     token:nil   
                                                                                     realm:nil 
                                                                         signatureProvider:nil]; 
        accessTokenRequest.HTTPMethod = @"POST";

        OARequestParameter *code = [[OARequestParameter alloc] initWithName:@"code" value:anAuthorizationToken];
        OARequestParameter *clientID = [[OARequestParameter alloc] initWithName:@"client_id" value:CLIENT_ID];
        OARequestParameter *clientSecret = [[OARequestParameter alloc] initWithName:@"client_secret" value:CLIENT_SECRET];
        OARequestParameter *redirectURI = [[OARequestParameter alloc] initWithName:@"redirect_uri" value:REDIRECT_URI];
        OARequestParameter *grantType = [[OARequestParameter alloc] initWithName:@"grant_type" value:GRANT_TYPE];
        
        accessTokenRequest.parameters = [NSArray arrayWithObjects: code, clientID, clientSecret, redirectURI, grantType, nil];
        
        OADataFetcher *fetcher = [[OADataFetcher alloc] init];
        
        [fetcher fetchDataWithRequest:accessTokenRequest
                             delegate:self
                    didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
                      didFailSelector:@selector(accessTokenTicket:didFailWithError:)];
    }
}

- (void)accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{	
    if (ticket.didSucceed) {
        NSDictionary *responseDictionary = [[JSONDecoder decoder] parseJSONData:data];
        accessToken = [[NSString alloc] initWithString:[responseDictionary valueForKey:@"access_token"]];
        
        if (accessToken) {
            [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:@"SHKBloggerAccessToken"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self share];
        }
    } else {
		// TDL: handle the error
		
		// If the error was the result of the user no longer being authenticated, you can reprompt
		// for the login information with:
		// [self sendDidFailShouldRelogin];
		
		// Otherwise, all other errors should end with:
		//[self sendDidFailWithError:[SHK error:@"Why it failed"] shouldRelogin:NO];
    }
}

- (void)accessTokenTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	[self sendDidFailWithError:error shouldRelogin:NO];
}

// TDL: flushing and saving that one other token
+ (void)logout
{
    //[self flushAccessToken];
}

// TDL: share form
#pragma mark - Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
	if (type == SHKShareTypeText) {
        return [NSArray arrayWithObjects:[SHKFormFieldSettings label:@"Title" key:@"title" type:SHKFormFieldTypeText start:item.title], nil];
	}
	
	return nil;
}

+ (BOOL)canAutoShare
{
	return NO;
}

// Validate the user input on the share form
- (void)shareFormValidate:(SHKFormController *)form
{	
	/*
	 
	 Services should subclass this if they need to validate any data before sending.
	 You can get a dictionary of the field values from [form formValues]
	 
	 --
	 
	 You should perform one of the following actions:
	 
	 1.	Save the form - If everything is correct call [form saveForm]
	 
	 2.	Display an error - If the user input was incorrect, display an error to the user and tell them what to do to fix it
	 
	 
	 */	
	
	// default does no checking and proceeds to share
	[form saveForm];
}

#pragma mark - Implementation

// When an attempt is made to share the item, verify that it has everything it needs, otherwise display the share form
/*
- (BOOL)validateItem
{ 
	// The super class will verify that:
	// -if sharing a url	: item.url != nil
	// -if sharing an image : item.image != nil
	// -if sharing text		: item.text != nil
	// -if sharing a file	: item.data != nil
 
	return [super validateItem];
}
*/

- (BOOL)send
{	
	if (![self validateItem]) {
		return NO;
    }
    
    // TDL: DO WE REALLY NEED ALL THESE PREPARES
    if (item.shareType == SHKShareTypeText) {
        NSDictionary *outerDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:item.title, @"title", item.text, @"content", nil];
        NSData *data = [outerDictionary JSONData];
        
        // TDL: need option to choose which blog
        NSURL *url = [NSURL URLWithString:@"https://www.googleapis.com/blogger/v3/blogs/2760139947141883284/posts/"];
        
        OAMutableURLRequest *postRequest = [[OAMutableURLRequest alloc] initWithURL:url 
                                                                           consumer:nil
                                                                              token:nil   
                                                                              realm:nil 
                                                                  signatureProvider:nil]; 
        [postRequest prepare];
        
        [postRequest setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
        [postRequest prepare];

        [postRequest setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
        [postRequest prepare];
        
        postRequest.HTTPMethod = @"POST";
        [postRequest prepare];
        
        postRequest.HTTPBody = data;
        [postRequest prepare];
     
        OADataFetcher *fetcher = [[OADataFetcher alloc] init];
        
        [fetcher fetchDataWithRequest:postRequest
                             delegate:self
                    didFinishSelector:@selector(postTicket:didFinishWithData:)
                      didFailSelector:@selector(postTicket:didFailWithError:)];

        return YES;
	}	
    
    return NO;
}

- (void)postTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{	
    if (ticket.didSucceed) {
        [self sendDidFinish];
    } else {
		// TDL: handle the error
		
		// If the error was the result of the user no longer being authenticated, you can reprompt
		// for the login information with:
		// [self sendDidFailShouldRelogin];
		
		// Otherwise, all other errors should end with:
		//[self sendDidFailWithError:[SHK error:@"Why it failed"] shouldRelogin:NO];
    }
}

- (void)postTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	[self sendDidFailWithError:error shouldRelogin:NO];
}

@end