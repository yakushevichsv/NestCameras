/**
 *  Copyright 2017 Nest Labs Inc. All Rights Reserved.
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

#import <Foundation/Foundation.h>
#import "NestAuthManager.h"
#import "RESTManager.h"
#import "NestConfiguration.h"
#import "AccessToken.h"

@interface RESTManager ()

@property (nonatomic, strong) NSMutableData *responseData;
@end

@implementation RESTManager

/**
 * Creates or retrieves the shared REST manager.
 * @return The singleton shared REST manager
 */
+ (RESTManager *)sharedManager {
    static dispatch_once_t once;
    static RESTManager *instance;
    
    dispatch_once(&once, ^{
        instance = [[RESTManager alloc] initWithConfiguration: [NestConfiguration new]];
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

#pragma mark REST methods

/**
 * Create an HTTP request.
 * @param type The type of request, only GET and PUT is supported.
 * @param endpoint The Nest API endpoint to call.
 * @param data The key-value pairs to write to the Nest API for PUT calls, nil if a GET call
 */
- (NSMutableURLRequest *)createRequest:(NSString *)type
                           forEndpoint:(NSString *)endpoint
                              withData:(NSData *)data
{

    NSString *authBearer = [NSString stringWithFormat:@"Bearer %@",
                            [[NestAuthManager sharedManager] accessToken]];
    
    // Use this print out the token if you need it
    //NSLog(@"Token: %@", authBearer);
    
    NSMutableURLRequest *request = [NSMutableURLRequest new];
    
    [request setHTTPMethod:type];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:authBearer forHTTPHeaderField:@"Authorization"];
    [request setURL:[NSURL URLWithString:endpoint]];
    
    if (data)
        [request setHTTPBody:data];
    
    return request;
}

/**
 * Perform a GET (read) request.
 * @param endpoint The Nest API endpoint to call.
 * @param success Block to call after a successful response.
 * @param failure Block to call after a failure response.
 */
- (NSUInteger)configureData:(NSString *)endpoint
           withValues:(NSData *)putData
              success:(void (^)(BOOL redirect, NSDictionary *response))success
              failure:(void (^)(NSError* error))failure {
    
    __weak typeof(self) wSelf = self;
    NSData *values = putData;
    return [self configureDataInner:endpoint withValues: values success:success redirect:^(NSHTTPURLResponse *responseURL) {
        [wSelf configureDataInner:responseURL.URL.absoluteString withValues:values success:success redirect:nil failure:failure];
    } failure:failure];
    
}

/**
 * Perform a GET (read) request.
 * @param endpoint The Nest API endpoint to call.
 * @param success Block to call after a successful response.
 * @param redirect Block to call after a redirect response.
 * @param failure Block to call after a failure response.
 */
- (NSUInteger)configureDataInner:(NSString *)endpoint
                withValues:(NSData *)values
                   success:(void (^)(BOOL afterRedirect, NSDictionary *response))success
                  redirect:(void (^)(NSHTTPURLResponse *responseURL))redirect
                   failure:(void (^)(NSError* error))failure {
    
    BOOL isRedirect = redirect == nil;
    BOOL isSet = values != nil ;
    // Build the HTTP request
    NSString *targetURL = isRedirect ? endpoint : [self.configuration.apiEndPointURL URLByAppendingPathComponent: endpoint].absoluteString;
    
    NSMutableURLRequest *request = [self createRequest:isSet ? @"PUT" : @"GET"
                                           forEndpoint:targetURL
                                              withData:values];
    
   NSURLSessionDataTask *task =  [self.session dataTaskWithRequest:request completionHandler:
      ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
          
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
          NSLog(@"RESTManager Response Status Code: %ld", (long)[httpResponse statusCode]);
          
          if (!isRedirect  && ((long)[httpResponse statusCode] == 401 || (long)[httpResponse statusCode] == 307)) {
              
              // Check if a returned 401 is a true 401, sometimes it's a redirect.
              //   See https://developers.nest.com/documentation/cloud/how-to-handle-redirects
              //   for more information.
              NSDictionary *responseHeaders = [httpResponse allHeaderFields];
              if ([[responseHeaders objectForKey:@"Content-Length"] isEqual: @"0"]) {
                  // This is a true 401
                  failure(error);
              }
              else {
                  // It's actually a redirect, so redirect!
                  redirect(httpResponse);
              }
          }
          else if (error)
              failure(error);
          else {
              NSDictionary *requestJSON = [NSJSONSerialization JSONObjectWithData:data
                                                                          options:kNilOptions
                                                                            error:nil];
              
              if (requestJSON) {
                  success(isRedirect, requestJSON);
              }
              else {
                  if (httpResponse.statusCode != 200 || httpResponse.statusCode != 201) {
                      failure([NSError errorWithDomain:@"Custom" code:httpResponse.statusCode userInfo:nil]);
                      return;
                  }
              }
          }
          
      }];
    
    [task resume];
    return [task taskIdentifier];
}


/**
 * Perform a GET (read) request.
 * @param endpoint The Nest API endpoint to call.
 * @param success Block to call after a successful response.
 * @param failure Block to call after a failure response.
 */
- (NSUInteger)getData:(NSString *)endpoint
        success:(void (^)(BOOL redirect, NSDictionary *response))success
        failure:(void (^)(NSError* error))failure {
    
    return [self configureData:endpoint
             withValues:nil
                success:success
                failure:failure];
}

- (NSUInteger)getRawData: (NSURL *)url
                 success:(void (^)(BOOL redirect, NSDictionary *response))success
                 failure:(void (^)(NSError* error))failure {
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.queryItems = @[ [[NSURLQueryItem alloc] initWithName:@"auth" value:self.configuration.token.token]];
    //NSURL *fURL = [url URLByAppendingPathComponent:@" "]
    
    return [self configureDataInner:components.URL.absoluteString withValues:nil success:success redirect:nil failure:failure];
}


/**
 * Perform a PUT (write) request.
 * @param endpoint The Nest API endpoint to write to.
 * @param putData The key-value pairs to update the endpoint with.
 * @param success Block to call after a successful response.
 * @param failure Block to call after a failure response.
 */
- (NSUInteger)setData:(NSString *)endpoint
     withValues:(NSData *)putData
        success:(void (^)(BOOL redirect, NSDictionary *response))success
        failure:(void (^)(NSError* error))failure {
    
    return [self configureData:endpoint
             withValues:putData
                success:success
                failure:failure];
    
}

@end
