////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  AvatarManager.m
//
//  Created by Dalton Cherry on 11/4/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "AvatarManager.h"
#import "AvatarRequest.h"
#import <CommonCrypto/CommonHMAC.h>

static NSString * const kDCAvatarLockName = @"com.basementkrew.networking.operation.lock";

typedef void (^DCAvatarSuccess)(DCImage *image);

typedef void (^DCAvatarFailure)(NSError *error);

@interface AvatarManager ()

//this stores images in memory to make image responses fast, like any cache would.
@property(nonatomic,strong)NSCache *cachedImages;

//stores the last time we check on the disk cache to clear it if needed.
@property(nonatomic,strong)NSDate *lastDiskCheck;

//preforms all the I/O operations.
@property(nonatomic,strong)NSOperationQueue *optQueue;

//lock for processing I/O returns.
@property(readwrite, nonatomic, strong)NSRecursiveLock *lock;

//block mappings on success
@property(nonatomic,strong)NSMutableDictionary *successBlocks;

//block mappings on failure
@property(nonatomic,strong)NSMutableDictionary *failureBlocks;


@end

@implementation AvatarManager

////////////////////////////////////////////////////////////////////////////////////////////////////
+(AvatarManager*)manager
{
    static AvatarManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[[self class] alloc] init];
    });
    return manager;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(id)init
{
    if(self = [super init])
    {
        self.optQueue = [[NSOperationQueue alloc] init];
        self.optQueue.maxConcurrentOperationCount = 6;
        self.lock = [[NSRecursiveLock alloc] init];
        self.lock.name = kDCAvatarLockName;
        self.successBlocks = [NSMutableDictionary new];
        self.failureBlocks = [NSMutableDictionary new];
#if TARGET_OS_IPHONE
        // Subscribe to memory warning, so we can clear the image cache on iOS
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemCache)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
#endif
    }
    return self;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)avatarForValue:(NSString*)value success:(DCAvatarSuccess)success failure:(DCAvatarFailure)failure
{
    NSString *hash = [self hashValue:value];
    DCImage *image = [self.cachedImages objectForKey:hash];
    if(image)
    {
        success(image);
        return;
    }
    [self addReturnBlock:success failure:failure forHash:hash];
    //check if same request is already running...
    
    //do disk cache check
    
    //do http request
    NSString *url = value;
    if(isEmail(value))
        url = [self gravatarString:value];
    
    AvatarRequest *request = [AvatarRequest requestWithURL:url success:^(AvatarRequest *request){
        [self processImageData:request.responseData hash:hash];
    }failure:^(AvatarRequest *request,NSError *error){
        [self processFailure:error hash:hash];
    }];
    [self.optQueue addOperation:request];
    
    //do disk cleaning
    if(self.optQueue.operations.count == 0)
    {
        if(!self.lastDiskCheck || [self.lastDiskCheck timeIntervalSinceNow] > 5*60)
            [self cleanDisk];
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)processImageData:(NSData*)data hash:(NSString*)hash
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if(str && str.length > 0 && [str rangeOfString:@"<"].location != NSNotFound)
    {
        NSRange find = [str rangeOfString:@"og:image"];
        if(find.location != NSNotFound)
        {
            NSRange start = [str rangeOfString:@"<meta" options:NSBackwardsSearch range:NSMakeRange(0, find.location)];
            if(start.location != NSNotFound)
            {
                NSRange end = [str rangeOfString:@">" options:0 range:NSMakeRange(find.location, str.length-find.location)];
                NSString *element = [str substringWithRange:NSMakeRange(start.location, (end.location-start.location)+1)];
                NSRange clean = [element rangeOfString:@"content="];
                if(clean.location != NSNotFound)
                {
                    NSInteger begin = clean.location + clean.length;
                    NSInteger end = element.length-1;
                    if([element hasSuffix:@"/>"])
                        end -= 1;
                    clean = [element rangeOfString:@" " options:0 range:NSMakeRange(begin, end-begin)];
                    if(clean.location != NSNotFound)
                        end = clean.location;
                    NSString *url = [element substringWithRange:NSMakeRange(begin, end-begin)];
                    url = [url stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    url = [url stringByReplacingOccurrencesOfString:@"'" withString:@""];
                    if([url hasPrefix:@"//"])
                        url = [NSString stringWithFormat:@"http:%@",url];
                    AvatarRequest *request = [AvatarRequest requestWithURL:url success:^(AvatarRequest *request){
                        [self processImageData:request.responseData hash:hash];
                    }failure:^(AvatarRequest *request,NSError *error){
                        [self processFailure:error hash:hash];
                    }];
                    [self.optQueue addOperation:request];
                }
                
                return;
            }
        }
        NSError *error = [self errorWithDetail:NSLocalizedString(@"No avatar was found in the domain's meta data.", Nil) code:DCAvatarErrorCodeNoMeta];
        [self processFailure:error hash:hash];
    }
    else
    {
        DCImage *image = [[DCImage alloc] initWithData:data];
        NSArray *successArray = [self successBlocksForHash:hash];
        for(DCAvatarSuccess success in successArray)
            success(image);
        [self.cachedImages setObject:image forKey:hash];
        [self removeBlocksForHash:hash];
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)processFailure:(NSError*)error hash:(NSString*)hash
{
    NSArray *failureArray = [self failureBlocksForHash:hash];
    for(DCAvatarFailure failure in failureArray)
        failure(error);
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)addReturnBlock:(DCAvatarSuccess)success failure:(DCAvatarFailure)failure forHash:(NSString*)hash
{
    [self.lock lock];
    NSMutableArray *successArray = self.successBlocks[hash];
    NSMutableArray *failureArray = self.failureBlocks[hash];
    if(!successArray)
    {
        successArray = [NSMutableArray new];
        self.successBlocks[hash] = successArray;
        failureArray = [NSMutableArray new];
        self.failureBlocks[hash] = failureArray;
    }
    [successArray addObject:success];
    [failureArray addObject:failure];
    [self.lock unlock];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSArray*)successBlocksForHash:(NSString*)hash
{
    return [self blocksForHash:hash dict:self.successBlocks];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSArray*)failureBlocksForHash:(NSString*)hash
{
    return [self blocksForHash:hash dict:self.failureBlocks];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSArray*)blocksForHash:(NSString*)hash dict:(NSDictionary*)dict
{
    [self.lock lock];
    NSArray *array = dict[hash];
    [self.lock unlock];
    return array;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)removeBlocksForHash:(NSString*)hash
{
    [self.lock lock];
    [self.successBlocks removeObjectForKey:hash];
    [self.failureBlocks removeObjectForKey:hash];
    [self.lock unlock];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//cache methods
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)cleanDisk
{
    self.lastDiskCheck = [NSDate date];
    [self.optQueue addOperationWithBlock:^(void){
       //do the disk cleaning
    }];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)clearMemCache
{
    [self.cachedImages removeAllObjects];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
//email methods
////////////////////////////////////////////////////////////////////////////////////////////////////
BOOL isEmail(NSString *checkString)
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    //NSString *emailRegex = @".+@.+\.[A-Za-z]{2}[A-Za-z]*";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSString*)gravatarString:(NSString*)email
{
    NSString *hash = email;
    hash = [hash stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    hash = [[self hashValue:hash] lowercaseString];
    return [NSString stringWithFormat:@"http://www.gravatar.com/avatar/%@.png",hash];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSString*)hashValue:(NSString*)value
{
    // Strip trailing slashes
    if ([[value substringFromIndex:[value length]-1] isEqualToString:@"/"])
        value = [value substringToIndex:[value length]-1];
    
    // Borrowed from: http://stackoverflow.com/questions/652300/using-md5-hash-on-a-string-in-cocoa
    const char *cStr = [value UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],result[4], result[5], result[6], result[7],result[8],
            result[9], result[10], result[11],result[12], result[13], result[14], result[15]];
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(NSError*)errorWithDetail:(NSString*)detail code:(DCAvatarErrorCode)code
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:detail forKey:NSLocalizedDescriptionKey];
    return [[NSError alloc] initWithDomain:NSLocalizedString(@"DCAvatar", nil) code:code userInfo:details];
}
////////////////////////////////////////////////////////////////////////////////////////////////////

@end
