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

@property(nonatomic,strong)NSString *saveURL;
@property(nonatomic,strong)NSMutableData *receivedData;
@property(nonatomic,strong)NSURLConnection *urlConnection;
@property(nonatomic,assign)AvatarOperationState state;
@property(readwrite, nonatomic, assign, getter = isCancelled)BOOL cancelled;

@property(nonatomic,strong)DCAvatarRequestSuccess success;
@property(nonatomic,strong)DCAvatarRequestFailure failure;

@end

@implementation AvatarRequest

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
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedData appendData:data];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connectionDidFinishLoading:(NSURLConnection *)currentConnection
{
    if(self.success)
        self.success(self);
}
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connection:(NSURLConnection *)currentConnection didFailWithError:(NSError *)error
{
    if(self.failure)
        self.failure(self,error);
}
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.receivedData setLength:0];
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    self.state = AvatarOperationExecutingState;
    [self didChangeValueForKey:@"isExecuting"];
    
    NSURL* url = [[NSURL alloc] initWithString:self.saveURL];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    
    NSPort* port = [NSPort port];
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop]; // Get the main runloop
    [runLoop addPort:port forMode:NSDefaultRunLoopMode];
    [self.urlConnection scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
    [self.urlConnection start];
    [runLoop run];
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
