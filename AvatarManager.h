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

#ifdef TARGET_OS_IPHONE
typedef UIImage DCImage;
#else
typedef NSImage DCImage;
#endif

/**
 Returns the AvatarManger singleton.
 This is what you will use to interaction with avatarManager.
 @return AvatarManager singleton.
 */
+(AvatarManager*)manager;

/**
 Fetchs the avatar for the value.
 @param value is the url, domain, or email(gravatar) to use to get the avatar for.
 @param success block returns an the image on success
 @param failure block returns an error on failure.
 */
-(void)avatarForValue:(NSString*)value success:(void (^)(DCImage *image))success failure:(void (^)(NSError *error))failure;

/**
 Cancel a avatar request.
 @param value is the url, domain, email avatar request you want to cancel.
 */
-(void)cancelAvatar:(NSString*)value;

@end
