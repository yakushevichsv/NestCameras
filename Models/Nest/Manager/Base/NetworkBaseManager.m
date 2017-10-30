//
//  NetworkBaseManager.m
//  NestCameras
//
//  Created by Siarhei Yakushevich on 10/29/17.
//  Copyright © 2017 Siarhei Yakushevich. All rights reserved.
//

#import "NetworkBaseManager.h"
#import "NestConfiguration.h"

@interface NetworkBaseManager ()

@property (nonatomic, strong) NestConfiguration *configuration;
@property (nonatomic, readonly) NSString *host;
@property (nonatomic) NSOperationQueue *processingQueue;
@property (nonatomic) NSURLSession *session;

@end

@implementation NetworkBaseManager

//[SY]
/* Constructor
 @param configuration Nest host domain
 */
- (instancetype)initWithConfiguration:(NestConfiguration *)configuration {
    if (self = [super init]) {
        NSParameterAssert(configuration != nil);
        self.configuration = configuration;
        self.processingQueue = [NSOperationQueue new];
        self.processingQueue.maxConcurrentOperationCount = 10; // async..
        
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                     delegate:nil
                                                delegateQueue:self.processingQueue];
    }
    return self;
}

- (instancetype)init
{
    //TODO: provide warning ....
    NSParameterAssert(false);
    return nil;
}

- (void)cancelTask:(NSUInteger)taskIdentifier {
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
       
        NSMutableArray<NSURLSessionTask *> *tasks = [NSMutableArray array];
        
        [tasks addObjectsFromArray:dataTasks];
        [tasks addObjectsFromArray:uploadTasks];
        [tasks addObjectsFromArray:downloadTasks];
        
       NSInteger fIndex =  [tasks indexOfObjectPassingTest:^BOOL(NSURLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if (obj.taskIdentifier == taskIdentifier) {
               *stop = YES;
               return YES;
           }
           return NO;
        }];
        
        if (fIndex != NSNotFound) {
            NSURLSessionTask *fTask = tasks[fIndex];
            [fTask cancel];
        }
        
    }];
}

@end
