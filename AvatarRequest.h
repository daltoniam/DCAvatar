////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  AvatarRequest.h
//
//  Created by Dalton Cherry on 11/6/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

@interface AvatarRequest : NSOperation

typedef void (^DCAvatarRequestSuccess)(AvatarRequest *request);
typedef void (^DCAvatarRequestFailure)(AvatarRequest *request,NSError* error);
typedef void (^DCAvatarRequestProgress)(AvatarRequest *request,float progress);


/**
 Returns the url for the request.
 */
@property(nonatomic,strong,readonly)NSString *url;

/**
 Returns the response data for the request.
 */
@property(nonatomic,strong,readonly)NSData *responseData;

/**
 Returns the content length of the request.
 This is only greater than 0 when doing a head request.
 */
@property(nonatomic,assign,readonly)long long responseLength;

/**
 set if the request is a head request.
 This is used for image progress.
 */
@property(nonatomic)BOOL isHead;
/**
 Initializes and returns a new AvatarRequest object.
 @param url is the url you want to fetch the avatar from.
 @return A new AvatarRequest Object.
 */
-(instancetype)initWithURL:(NSString*)url;

/**
 A block that is run once a request has finished successfully.
 @param success is the success block to use if the request has finished successfully.
 */
-(void)setSuccessBlock:(DCAvatarRequestSuccess)success;

/**
 A block that is run once a request did not finished successfully.
 @param failure is the failure block to use if the request did not finish successfully.
 */
-(void)setFailureBlock:(DCAvatarRequestFailure)failure;

/**
 A block that is run as progress is made.
 @param progress is the progress block to use to notify the progress of the request.
 @param length is the expected length of the request.
 */
-(void)setProgressBlock:(DCAvatarRequestProgress)progress expectedLength:(long long)length;

/**
 Factory method that initializes and returns a new AvatarRequest object.
 @param url is the url you want to fetch the avatar from.
 @param success is the success block to use if the request has finished successfully.
 @param failure is the failure block to use if the request did not finish successfully.
 @return A new AvatarRequest Object.
 */
+(AvatarRequest*)requestWithURL:(NSString*)url success:(DCAvatarRequestSuccess)success failure:(DCAvatarRequestFailure)failure;


@end
