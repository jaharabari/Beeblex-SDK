//
//  NSURLConnection+SendAsync.m
//  Beeblex-SDK
//
//  Created by Stéphane Peter on 7/20/12.
//  Copyright (c) 2012 Blue Parabola, LLC. All rights reserved.
//

#import "NSURLConnection+SendAsync.h"
#import <objc/runtime.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_5_0

typedef void (^URLConnectionCompletionHandler)(NSURLResponse *response, NSData *data, NSError *error);

@interface URLConnectionDelegate : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, copy) URLConnectionCompletionHandler handler;

@end

@implementation URLConnectionDelegate

@synthesize response;
@synthesize data;
@synthesize queue;
@synthesize handler;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)theResponse {
    self.response = theResponse;
    [data setLength:0]; // reset data
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)theData {
    [data appendData:theData]; // append incoming data
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.data = nil;
    if (handler) { [queue addOperationWithBlock:^{ handler(response, nil, error); }]; }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // TODO: Are we passing the arguments to the block correctly? Should we copy them?
    if (handler) { [queue addOperationWithBlock:^{ handler(response, data, nil); }]; }
}

@end

static void sendAsynchronousRequest4(id self, SEL _cmd, NSURLRequest *request, NSOperationQueue *queue,
                                     URLConnectionCompletionHandler handler) {
    
    URLConnectionDelegate *connectionDelegate = [[URLConnectionDelegate alloc] init];
    connectionDelegate.data = [NSMutableData data];
    connectionDelegate.queue = queue;
    connectionDelegate.handler = handler;
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request
                                                                delegate:connectionDelegate];
    NSAssert(connection, nil);
}

@implementation NSURLConnection (SendAsync)

+ (void)load {
    SEL sendAsyncSelector = @selector(sendAsynchronousRequest:queue:completionHandler:);
    if (![NSURLConnection instancesRespondToSelector:sendAsyncSelector]) {
        class_addMethod(object_getClass([self class]),
                        sendAsyncSelector, (IMP)sendAsynchronousRequest4, "v@:@@@");
    }
}

@end

#endif