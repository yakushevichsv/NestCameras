//
//  NestConfiguration.h
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/25/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AccessToken;

@interface NestConfiguration : NSObject

+ (instancetype)sharedConfiguration;

@property (nonatomic, readonly) NSString *clientId;
@property (nonatomic, readonly) NSString *clientSecret;
@property (nonatomic, readonly) NSString *host;
@property (nonatomic, readonly) NSURL *apiEndPointURL;

@property (nonatomic) NSString *authCode;
@property (nonatomic) AccessToken *token;

@end
