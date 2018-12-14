//
//  MailSendPopUp.h
//  iPadCamera
//
//  Created by MacBook on 13/05/24.
//
//

#import "PopUpViewContollerBase.h"
#import "TextLogTableViewController.h"
#import "userDbManager.h"
#import "userFmdbManager.h"
#import "mstUser.h"
#import "WebMail.h"
#import "WebMailSender.h"
#import "def64bit_common.h"

#define MAILSEND_POPUP_ID   100

@interface MailSendPopUp : PopUpViewContollerBase <UITextFieldDelegate, UIAlertViewDelegate,WebMailSenderDelegate>{
    USERID_INT   selectUserID;
    HISTID_INT   selectHistID;
    
    NSArray     *addrArray;             //ドメイン配列
    UITextField *ccTextField;           //CC入力フィールド
    NSString    *ccText;                //CCテキスト
    NSMutableArray *selectImageArray;   //添付画像配列
    BOOL        sendCCFlag;             //CCフラグ
    BOOL        addrInsertFlag;         //メールアドレス登録フラグ
    
    UIPopoverController *popover;       //ログ表示ポップアップ
    NSError *mailError;                 //メール送信エラー
//    NSException *mailError;
    UIAlertView *indicatorAlert;        //送信中アラート
    BOOL        aliveThreadFlag;        //メール送信処理中のフラグ
    UIAlertView *ccAlert;               //あて先(CC)入力アラート
    BOOL        dissmissPopupFlag;      //メール送信中に画面の向きを変えたらたてるフラグ
    //
    WebMail *mail;
    BOOL isSending;
    
    IBOutlet UILabel        *lblTitle;      // タイトルラベル
    IBOutlet UIButton       *btnCancel;     // 取り消しボタン
    IBOutlet UILabel        *lblEmailNotice;    // Emailに関する注意点表示ラベル
    
    NSInteger               selectShopID;
    NSString                *shopName;
}
@property(nonatomic)        USERID_INT selectUserID;
@property(nonatomic)        HISTID_INT selectHistID;

- (IBAction)doMailsend:(UIButton *)sender;
- (IBAction)addMailCC:(UIButton *)sender;
//- (IBAction)OnCancelBtn:(id)sender;

//@property (retain, nonatomic) IBOutlet UIButton *MailCancel;
@property (retain, nonatomic) IBOutlet UIButton *MailSend;
@property (retain, nonatomic) IBOutlet UIScrollView *myScrollView;
@property (retain, nonatomic) IBOutlet UITextField *emailField1;
@property (retain, nonatomic) IBOutlet UITextField *emailField2;
@property (retain, nonatomic) IBOutlet UITextField *emailTitle;
@property (retain, nonatomic) IBOutlet UITextView *emailText;
@property (retain, nonatomic) IBOutlet UILabel  *imageLabel1;
@property (retain, nonatomic) IBOutlet UILabel  *imageLabel2;

- (id) initWithMailSetting:(NSMutableArray *)pictImageItems
              selectUserID:(USERID_INT)userID
              selectHistID:(HISTID_INT)histID
                 pictIndex:(NSInteger)indexID
                   popUpID:(NSUInteger)popUpID
                  callBack:(id)callBack;
- (UIImage*)resizedImage:(UIImage*)img size:(CGSize)size;

- (BOOL) onceSaveMailData;
- (NSString *) base64EncodeString: (NSString *) strData;
@end
