//
//  WebMailTitleView.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/08.
//
//

#import <UIKit/UIKit.h>
#import "WebMail.h"

@protocol WebMailTitleViewDelegate<NSObject>
- (void)touchTitleView:(UIView *)titleView;
@end
@interface WebMailTitleView : UIView{
    WebMail *mail;
    UILabel *nameLabel;
    UILabel *checkLabel;
    UILabel *unreadLabel;
    UIView  *contentView;
    UILabel *dateLabel;
    UILabel *weekLabel;
    UILabel *timeLabel;
    UILabel *titleLabel;
    BOOL isTouch;
}
@property (nonatomic,assign) id<WebMailTitleViewDelegate>delegate;
- (id)initWithMail:(WebMail *)_mail;
- (void)setSelected:(BOOL)isSelected;
- (BOOL)fromUser;

+ (UIColor *)userColor;
+ (UIColor *)accountColor;

- (BOOL) isEqualWebMail:(WebMail*)_mail;
@end
