//
//  OKDThumbnailItemViewForWebMail.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/11/06.
//
//

#import "OKDThumbnailItemViewForWebMail.h"

@implementation OKDThumbnailItemViewForWebMail

- (void)setUser:(BOOL)_isUser{
    isUser = _isUser;
    if (isUser) {
        [btnSelected setBackgroundImage: [UIImage imageNamed:@"frame_user.png"] forState:UIControlStateNormal];
        lblTitle.backgroundColor = [UIColor colorWithRed:0.745f green:0.808f blue:0.859f alpha:1.0f];
    } else {
        [btnSelected setBackgroundImage: [UIImage imageNamed:@"frame_no_select.png"] forState:UIControlStateNormal];
    }
}
- (void) setButtonState
{
    [super setButtonState];
    if (!self.IsSelected && isUser) {
        [btnSelected setBackgroundImage: [UIImage imageNamed:@"frame_user.png"] forState:UIControlStateNormal];
    }
}

@end
