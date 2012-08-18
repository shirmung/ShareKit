//
//  SHKBloggerAuthorizationViewController.h
//  ShareKit
//
//  Created by Shirmung Bielefeld on 7/7/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol Authorization <NSObject>
@required
- (void)authorizationComplete:(NSString *)anAuthorizationToken;
@end

@interface SHKBloggerAuthorizationViewController : UIViewController <UIWebViewDelegate>
{
    UIWebView *bloggerWebView;
    id <Authorization> delegate;
}

@property (nonatomic, retain) UIWebView *bloggerWebView;
@property (nonatomic, retain) id delegate;

@end
