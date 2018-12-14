//
//  MailAddressSetPopup.h
//  iPadCamera
//
//  Created by MacBook on 11/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Common.h"

#import "PopUpViewContollerBase.h"

///
/// メールアドレス設定PopupViewControllerクラス
///
@interface MailAddressSetPopup : PopUpViewContollerBase {
	IBOutlet UILabel			*lblTitle;			// Titleラベル
	
	IBOutlet UITextField		*txtMailAddress;	// メールアドレス
	IBOutlet UIButton			*btnOK;				// OKボタン
	
	NSString					*_mailAddress;
}

// 初期化 :
- (id) initPopUpViewWithPopupID:(NSUInteger)popUpID
					mailAddress:(NSString*)address
			  popOverController:(UIPopoverController*)controller 
					   callBack:(id)callBackDelegate;

// 編集開始
// - (IBOutlet) onTextEditBegin:(id)sender;

// 文字列変更 
- (IBAction) onChangeText:(id)sender;

// 編集終了
- (IBAction) onTextDidEnd:(id)sender;

// リターンキー
- (IBAction) onTextDidEndOnExit:(id)sender;

@end
