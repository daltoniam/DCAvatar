////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  AvatarManager.h
//
//  Created by Dalton Cherry on 11/4/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, DCAvatarErrorCode) {
    DCAvatarErrorCodeNoMeta      = 1 //there is no meta data on the domain
};

@interface AvatarManager : NSObject

#if TARGET_OS_IPHONE
typedef UIImage DCImage;
#else
typedef NSImage DCImage;
#endif

typedef void (^DCAvatarSuccess)(DCImage *image);

typedef void (^DCAvatarFailure)(NSError *error);

typedef void (^DCAvatarProgess)(float progress);

/**
 This is how long a cache image should exist on disk. Default is 24 hours.
 */
@property(nonatomic,assign)NSInteger maxCacheAge;

/**
 Returns the AvatarManger singleton.
 This is what you will use to interaction with avatarManager.
 @return AvatarManager singleton.
 */
+(AvatarManager*)manager;

/**
 Fetchs the avatar for the value. It is important that using this method will cause a HEAD request to be sent for every image url.
 This is not ideal for very small images and should only be used for large images that load slowly or images that need a progress view.
 @param value is the url, domain, or email(gravatar) to use to get the avatar for.
 @param size is the size of the image data so we have an idea on how long it will take to load.
 @param success block returns an the image on success
 @param progress block returns the progress of the request. This would be between 0.0 and 1.0.
 @param failure block returns an error on failure.
 */
-(void)avatarForValue:(NSString*)value size:(long long)size success:(DCAvatarSuccess)success progress:(DCAvatarProgess)progress failure:(DCAvatarFailure)failure;
/**
 Fetchs the avatar for the value. It is important that using this method will cause a HEAD request to be sent for every image url.
 This is not ideal for very small images and should only be used for large images that load slowly or images that need a progress view.
 @param value is the url, domain, or email(gravatar) to use to get the avatar for.
 @param success block returns an the image on success
 @param progress block returns the progress of the request. This would be between 0.0 and 1.0.
 @param failure block returns an error on failure.
 */
-(void)avatarForValue:(NSString*)value success:(DCAvatarSuccess)success progress:(DCAvatarProgess)progress failure:(DCAvatarFailure)failure;

/**
 Fetchs the avatar for the value.
 @param value is the url, domain, or email(gravatar) to use to get the avatar for.
 @param success block returns an the image on success
 @param failure block returns an error on failure.
 */
-(void)avatarForValue:(NSString*)value success:(DCAvatarSuccess)success failure:(DCAvatarFailure)failure;

/**
 Cancel a avatar request.
 @param value is the url, domain, email avatar request you want to cancel.
 */
-(void)cancelAvatar:(NSString*)value;

@end
