//
//  SHKBlogger.h
//  ShareKit
//
//  Created by Shirmung Bielefeld on 6/29/12.
//  Copyright (c) 2012. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHKSharer.h"
#import "SHKBloggerAuthorizationViewController.h"

@interface SHKBlogger : SHKSharer <Authorization>
{

}

@property (nonatomic, retain) NSString *authorizationToken;
@property (nonatomic, retain) NSString *accessToken;

@end
