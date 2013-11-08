////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCImageView.h
//
//  Created by Dalton Cherry on 11/8/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#if TARGET_OS_IPHONE
@interface DCImageView : UIImageView
#else
@interface DCImageView : NSImageView
#endif

/**
 avatarValue is the domain, url, or email value of the avatar to fetch.
 Once this value is set, the value will be fetched.
 */
@property(nonatomic,copy)NSString *avatarValue;

/**
 Cancel the avatar request.
 */
-(void)cancelAvatar;

@end
