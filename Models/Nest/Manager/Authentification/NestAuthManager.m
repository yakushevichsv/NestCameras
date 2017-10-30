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

#import "NestAuthManager.h"
#import "AccessToken.h"
#import "NestConfiguration.h"

NSString * const NestManagerDidDetectTokenNotification = @"NestManagerDidDetectTokenNotification";

@interface NestAuthManager ()

@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic) NSString *authState;
@end

@implementation NestAuthManager

/**
 * Get the shared manager singleton.
 * @return The singleton object
 */
+ (NestAuthManager *)sharedManager {
	static dispatch_once_t once;
	static NestAuthManager *instance;
    
	dispatch_once(&once, ^{
        instance = [[NestAuthManager alloc] initWithConfiguration: [NestConfiguration new]];
	});
    
	return instance;
}

//[SY]
/* Constructor
 @param configuration Nest host domain
 */
- (instancetype)initWithConfiguration:(NestConfiguration *)configuration {
    self = [super initWithConfiguration:configuration];
    return self;
}


/**
 * Checks whether or not the current session is authenticated by checking for the
 * authorization token and making sure it is not expired.
 * @return YES if valid session, NO if invalid session.
 */
- (BOOL)isValidSession
{
    return [self accessToken].length != 0;
}

/**
 * Get the URL to get the authorizationcode.
 * @return The URL to get the authorization code (the login with nest screen).
 */
- (NSString *)authorizationURL
{
    // First get the client id
    NSString *clientId = self.configuration.clientId;
    NSParameterAssert(clientId.length);
    
    
    if (!self.authState.length) {
        self.authState = [NSString stringWithFormat:@"%d.state",arc4random() % 1000];
    }
        
    return [NSString stringWithFormat:@"https://%@/login/oauth2?client_id=%@&state=%@", self.configuration.host, clientId, self.authState];
}

/**
 * Get the URL to deauthorize the connection.
 * @return The URL to deauthorize the connection.
 */
- (NSString *)deauthorizationURL
{
    // Get the access token
    NSString *authBearer = [NSString stringWithFormat:@"%@", self.configuration.token.token];
    
    return [NSString stringWithFormat:@"https://api.%@/oauth2/access_tokens/%@", self.configuration.host, authBearer];
}

/**
 * Get the URL for to get the access key.
 * @return The URL to get the access token from Nest.
 */
- (NSString *)accessURL
{
    NSString *clientId = self.configuration.clientId;
    NSString *clientSecret = self.configuration.clientSecret;
    NSString *authorizationCode = self.configuration.authCode;
    
    if (clientId && clientSecret && authorizationCode) {
        return [NSString stringWithFormat:@"https://api.%@/oauth2/access_token?code=%@&client_id=%@&client_secret=%@&grant_type=authorization_code", self.configuration.host, authorizationCode, clientId, clientSecret];
    } else {
        if (!clientSecret) {
            NSLog(@"Missing Client Secret");
        }
        if (!clientId) {
            NSLog(@"Missing Client ID");
        }
        if (!authorizationCode) {
            NSLog(@"Missing authorization code");
        }
        return nil;
    }
}

/**
 * Get the access token (if there is one).
 * @return The access token for this session. String is nil if no access token.
 */
- (NSString *)accessToken
{
    AccessToken *at = self.configuration.token;
    return [at isValid] ? at.token : nil;
}



/**
 * Set the authorization code.
 * @param authorizationCode The authorization code you wish to write to NSUserdefaults.
 */
- (void)setAuthorizationCode:(NSString *)authorizationCode
{
    self.configuration.authCode = authorizationCode;
}

/*
 "access_token": "c.DxuNBFKG5FvqC7pOQq1FLLKeOKbcbY4L3BB2hMQ0hVnPLTPH4pVhwJ8uSbBl3jNQte9IrudnILQp7WsRyKQiL8Ims4x4jdfo3IJb5iSIyfatuAHcGln27GJufbemu1LNCC6cjwI4Mo0HlNye",
 "expires_in": 315360000
 */

/**
 * Set the acccess token.
 * @param accessToken The access token you wish to set.
 * @param expiration The expiration of the token (long).
 */
- (void)setAccessToken:(NSString *)accessToken withExpiration:(long)expiration
{
    NSDate *cDate = [NSDate date];
    AccessToken *token = [AccessToken tokenWithToken:accessToken requestedOn:cDate expiresIn:expiration];
    self.configuration.token = token; //TODO create timer for detecting token expiration...
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:NestManagerDidDetectTokenNotification object:nil];
    });
}

/**
 * Remove the access token and authorization code from storage
 *    upon deauthorization.
 */
- (void)removeAuthorizationData
{
    self.configuration.token = nil;
    self.configuration.authCode = nil;
}

- (BOOL)receiveToken: (void (^)(BOOL success, NSError *error))completionBlock {
 
    if (self.configuration.authCode.length == 0) {
        return false;
    }
    
    self.responseData = [NSMutableData new];
    
    // Get the accessURL
    NSString *accessURL = [self accessURL];
    
    // For the POST request
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString:accessURL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"form-data" forHTTPHeaderField:@"Content-Type"];
    
    // Assign the session to the main queue so the call happens immediately
    NSURLSession *session = self.session;
    
    [[session dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
          
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSLog(@"AuthManager Token Response Status Code: %ld", (long)[httpResponse statusCode]);
          
          [self.responseData appendData:data];
          
          // The request is complete and data has been received
          // You can parse the stuff in your instance variable now
          NSDictionary* json = [NSJSONSerialization JSONObjectWithData:self.responseData
                                                               options:kNilOptions
                                                                 error:&error];
          
          
          // Store the access key
          long expiresIn = [[json objectForKey:@"expires_in"] longValue];
          NSString *accessToken = [json objectForKey:@"access_token"];
          BOOL failed = YES;
          if (accessToken.length && expiresIn > 0) {
              failed = NO;
              [self setAccessToken:accessToken withExpiration:expiresIn];
              completionBlock(!failed, error);
          }
      }] resume];
    
    return true;
}

#pragma mark - NestControlsViewControllerDelegate Methods

/**
 * Called from NestControlsViewControllerDelegate, lets
 * the AuthManager know to deauthorize the Works with Nest connection
 */
- (NSUInteger)deauthorizeConnection:(void (^)(BOOL, NSError *))completionBlock
{
    // Get the deauthorizationURL
    NSString *deauthURL = [self deauthorizationURL];
    
    // Create the DELETE request
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    [request setURL:[NSURL URLWithString:deauthURL]];
    [request setHTTPMethod:@"DELETE"];
    
    // Assign the session to the main queue so the call happens immediately
    NSURLSession *session = self.session;
    
    __weak typeof(self) wSelf = self;
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
          
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSLog(@"AuthManager Delete Response Status Code: %ld", (long)[httpResponse statusCode]);
          BOOL success = httpResponse.statusCode >=200 && httpResponse.statusCode < 300;
          
          if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
              return; //cancelled..
          }
          
          [wSelf removeAuthorizationData];
     
          completionBlock(success, error);
      }];
    
    [task resume];

    return task.taskIdentifier;
}

@end
