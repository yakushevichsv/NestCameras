//
//  NetworkBaseManager.h
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/29/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NestConfiguration;

@interface NetworkBaseManager : NSObject

- (instancetype)initWithConfiguration:(NestConfiguration *)configuration;

@property (nonatomic, readonly) NSURLSession *session;
@property (nonatomic, readonly) NestConfiguration *configuration;

- (void)cancelTask:(NSUInteger)taskIdentifier;

@end
