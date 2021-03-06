////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  DCImageView.m
//
//  Created by Dalton Cherry on 11/8/13.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#import "DCImageView.h"
#import "AvatarManager.h"

@implementation DCImageView

////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)setAvatarValue:(NSString *)value
{
    AvatarManager *manager = [AvatarManager manager];
    if(_avatarValue)
        [manager cancelAvatar:_avatarValue];
    if(value)
    {
        if(self.showProgress)
        {
            [manager avatarForValue:value success:^(DCImage *image){
                self.image = image;
            }progress:^(float progress){
                [self setProgress:progress];
            }failure:NULL];
        }
        else
        {
            [manager avatarForValue:value success:^(DCImage *image){
                self.image = image;
            } failure:NULL];
        }
    }
    _avatarValue = value;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)cancelAvatar
{
    self.avatarValue = nil;
}
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)setProgress:(float)progress
{
    //default implementation does nothing.
}
////////////////////////////////////////////////////////////////////////////////////////////////////

@end
