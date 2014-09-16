////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  AvatarRequest.m
//
//  Created by Dalton Cherry on 11/6/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "AvatarRequest.h"

typedef NS_ENUM(NSInteger, AvatarOperationState) {
    AvatarOperationPausedState      = -1,
    AvatarOperationReadyState       = 1,
    AvatarOperationExecutingState   = 2,
    AvatarOperationFinishedState    = 3,
};

@interface AvatarRequest ()

@property (readwrite, nonatomic, assign, getter = isCancelled) BOOL cancelled;
@property(nonatomic,strong)NSString *saveURL;
@property(nonatomic,strong)NSMutableData *receivedData;
@property(nonatomic,strong)NSURLConnection *urlConnection;
@property(nonatomic,assign)AvatarOperationState state;

@property(nonatomic,assign)long long contentLength;
@property(nonatomic,strong)DCAvatarRequestSuccess success;
@property(nonatomic,strong)DCAvatarRequestFailure failure;

@property(nonatomic)long long expectedLength;
@property(nonatomic,strong)DCAvatarRequestProgress progress;

@end

@implementation AvatarRequest

@synthesize cancelled = _cancelled;
////////////////////////////////////////////////////////////////////////////////////////////////////
-(instancetype)initWithURL:(NSString*)url
{
    if(self = [super init])
    {
        self.receivedData = [[NSMutableData alloc] init];
        self.saveURL = url;
    }
    return self;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)setSuccessBlock:(DCAvatarRequestSuccess)success
{
    self.success = success;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)setFailureBlock:(DCAvatarRequestFailure)failure
{
    self.failure = failure;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)setProgressBlock:(DCAvatarRequestProgress)progress expectedLength:(long long)length
{
    self.progress = progress;
    self.expectedLength = length;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSData*)responseData
{
    return self.receivedData;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSString*)url
{
    return self.saveURL;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(long long)responseLength
{
    return self.contentLength;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedData appendData:data];
    if(self.progress && self.expectedLength > 0)
    {
        float increment = 100.0f/self.expectedLength;
        float current = (increment*self.receivedData.length);
        current = current*0.01f;
        if(current > 1)
            current = 1;
        self.progress(self,current);
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connectionDidFinishLoading:(NSURLConnection *)currentConnection
{
    if(self.success)
        self.success(self);
    [self finish];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connection:(NSURLConnection *)currentConnection didFailWithError:(NSError *)error
{
    if(self.failure)
        self.failure(self,error);
    [self finish];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.receivedData setLength:0];
    if ([response isKindOfClass:[NSHTTPURLResponse self]])
    {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        NSDictionary *headers = [httpResponse allHeaderFields];
        self.contentLength = [[headers objectForKey:@"Content-Length"] longLongValue];
    }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)start
{
    if(![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    [self willChangeValueForKey:@"isExecuting"];
    self.state = AvatarOperationExecutingState;
    [self didChangeValueForKey:@"isExecuting"];
    
    NSURL* url = [[NSURL alloc] initWithString:self.saveURL];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    if(self.isHead)
        [request setHTTPMethod:@"HEAD"];
    self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)finish
{
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.state = AvatarOperationFinishedState;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)cancel
{
    [self.urlConnection cancel];
    [self willChangeValueForKey:@"isCancelled"];
    _cancelled = YES;
    [self willChangeValueForKey:@"isCancelled"];
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isConcurrent
{
    return YES;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isFinished
{
    return self.state == AvatarOperationFinishedState;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)isExecuting
{
    return self.state == AvatarOperationExecutingState;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//factory method
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
+(AvatarRequest*)requestWithURL:(NSString*)url success:(DCAvatarRequestSuccess)success failure:(DCAvatarRequestFailure)failure
{
    AvatarRequest *request = [[AvatarRequest alloc] initWithURL:url];
    [request setSuccess:success];
    [request setFailure:failure];
    return request;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
@end
