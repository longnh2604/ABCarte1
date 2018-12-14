//
//  WebMailListViewController.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/08.
//
//

#import <UIKit/UIKit.h>
#import "WebMail.h"
#import "WebMailTitleView.h"
#import "WebMailSender.h"
#import "SelectWebMails.h"
#import "UIPlaceHolderTextView.h"
#import "TouchScrollView.h"
#import "PullScrollView.h"
#import "GetWebMailUserStatus.h"
#import "ReadWebMail.h"
#import "CheckWebMail.h"
#import "DeleteWebMail.h"
#import "def64bit_common.h"

@protocol WebMailListViewControllerDelegate;

@interface WebMailListViewController : UIViewController<
	WebMailTitleViewDelegate,
	WebMailSenderDelegate,
	SelectWebMailsDelegate,
	GetWebMailUserStatusDelegate,
	ReadWebMailDelegate,
	CheckWebMailDelegate,
	PullScrollViewDelegate,
	UITextFieldDelegate,
	UITextViewDelegate,
	UIAlertViewDelegate,
	DeleteWebMailDelegate>
{
    
    IBOutlet UIView             *toolBack;
    IBOutlet UIToolbar          *toolbar;
    IBOutlet UIBarButtonItem    *userStatusLabel;
    IBOutlet UIBarButtonItem    *catalogButton;
    IBOutlet UIBarButtonItem    *upButton;
    PullScrollView              *mailsView;
    IBOutlet TouchScrollView    *contentView;
    UIPopoverController         *popover;
    UILabel                     *dateLabel;
    UILabel                     *titleLabel;
    UILabel                     *timeLabel;
    UIView                      *mailView;
    UITextView                  *mailContentLabel;
	IBOutlet UIBarButtonItem    *btnMailDelete;
    
    UIButton *nextButton;
    UIButton *checkButton;
    
    IBOutlet UIView             *replyView;
    IBOutlet UITextField        *replyTitleView;
    IBOutlet UIPlaceHolderTextView *replyTextView;

    IBOutlet UIButton *submitButton;
    
    USERID_INT          userId;
    NSMutableArray      *titleViews;
    WebMailTitleView    *activeTitleView;
    NSString            *nextUrl;
    // data
    NSMutableArray  *mails;
    NSInteger       mailIndex;   //メールの配列上での位置
    NSInteger       mailId;      //メールのid
    NSInteger       since;
    BOOL            mailsViewHidden; //縦画面時の一覧の表示／非表示を保存
    BOOL            gettingFirstMails;
    id<WebMailListViewControllerDelegate> delegate;
	UIAlertView     *alertMailDelete;	// ユーザ情報削除Alertダイアログ
	DeleteWebMail   *delMail;   // メール削除
	NSInteger       delProtect;	// メール削除時の連打防止策
    
    BOOL isSending;
}
@property(nonatomic, assign) USERID_INT userId;
@property(nonatomic, copy) NSString *nextUrl;
@property (nonatomic,assign) id<WebMailListViewControllerDelegate>delegate;
- (IBAction)catalog:(id)sender;
- (IBAction)up:(id)sender;
- (IBAction)down:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)submit:(id)sender;
- (IBAction)trushbox:(id)sender;
- (void)refreshWithUserId:(USERID_INT)_userId;
// webMail画面の表示・非表示通知
-(void) notifyViewShowWithFlag:(BOOL)isShow;
@end
@protocol WebMailListViewControllerDelegate <NSObject>
@optional
- (void)setStatusText:(NSString *)string;
@end
