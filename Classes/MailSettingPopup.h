//
//  MailSettingPopup.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/11.
//
//

#import "PopUpViewContollerBase.h"
#import "AccountInfoForWebMail.h"

@interface MailSettingPopup : PopUpViewContollerBase<AccountInfoForWebMailDelegate, UIAlertViewDelegate>{
    
	IBOutlet UILabel			*lblTitle;			// Titleラベル
	
	IBOutlet UITextField		*txtMailAddress;	// メールアドレス
    IBOutlet UITextField        *txtSenderName;     // 送信者名
	IBOutlet UIButton			*btnOK;				// OKボタン
    IBOutlet UIButton           *btnReset;          // リセットボタン
    IBOutlet UIButton           *btnCancel;         // キャンセルボタン
	
	NSString					*_mailAddress;
    NSString                    *_senderName;
    BOOL                        addressOK;
    BOOL                        nameOK;
}
- (id) initPopUpViewWithPopupID:(NSUInteger)popUpID
			  popOverController:(UIPopoverController*)controller
					   callBack:(id)callBackDelegate;
@end
