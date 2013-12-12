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

/**
 This is provided so your subclass can be notified of progress.
 Default is NO. Set it to YES in your subclass if you want to show a progress view.
 */
@property(nonatomic,assign)BOOL showProgress;

/**
 This method does nothing by default. It is provided so your subclass can use it.
 @param progress is the progress of the image. It will be between 0.0 and 1.0.
 */
-(void)setProgress:(float)progress;

@end
