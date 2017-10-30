//
//  NestConfiguration.m
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/25/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

#import "NestConfiguration.h"
#import "AccessToken.h"

static NSString *kClientId = @"nest.clientId";
static NSString *kHost = @"nest.Host";
static NSString *kSecret = @"nest.Secret";
static NSString *kAuthCode = @"nest.authCode";
static NSString *kAuthToken = @"nest.Token";
static NSString *kAPIEndPoint = @"nest.APIEndPoint";

@interface NestConfiguration()
@property (nonatomic, weak) NSUserDefaults *defaults;
@end

@implementation NestConfiguration

+ (instancetype)sharedConfiguration {
    
    static dispatch_once_t once;
    static NestConfiguration *instance;
    
    dispatch_once(&once, ^{
        instance = [NestConfiguration new];
    });
    
    return instance;
}

+ (void)initialize
{
    if (self == [NestConfiguration class]) {
        NSDictionary *defParams = @{kClientId : @"f158b3f7-4b18-4f9f-8e5c-046f269a207a",
                                    kHost : @"home.nest.com",
                                    kSecret: @"GmUepAb1xulKzYCoFGN5mAD3p",
                                    kAPIEndPoint: @"https://developer-api.nest.com"
                                    };
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:defParams];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.defaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}


- (NSString *)clientId {
    return [self.defaults stringForKey:kClientId];
}

- (NSString *)host {
    return [self.defaults stringForKey:kHost];
}

- (NSString *)clientSecret {
    return [self.defaults stringForKey:kSecret];
}

- (NSURL *)apiEndPointURL {
    NSString *str = [self.defaults stringForKey:kAPIEndPoint];
    return [NSURL URLWithString:str];
}

- (void)setAuthCode:(NSString *)authCode {
    if (!authCode.length) {
        [self.defaults removeObjectForKey:kAuthCode];
    }
    else
        [self.defaults setObject:authCode forKey:kAuthCode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)authCode {
    return [self.defaults stringForKey:kAuthCode];
}

- (AccessToken *)token {
    NSData *objc = [self.defaults objectForKey:kAuthToken];
    if ([objc isKindOfClass:[NSData class]])
        return [NSKeyedUnarchiver unarchiveObjectWithData:objc];
    else
        return nil;
}

- (void)setToken:(AccessToken *)token {
    if (!token) {
        [self.defaults removeObjectForKey:kAuthToken];
    }
    else {
        NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:token];
        [self.defaults setObject:encodedObject forKey:kAuthToken];
    }
    [self.defaults synchronize];
}

@end
