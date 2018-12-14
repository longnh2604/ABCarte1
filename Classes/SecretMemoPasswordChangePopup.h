//
//  SecretMemoPasswordChangePopup.h
//  iPadCamera
//
//  Created by MacBook on 16/06/24.
//  Copyright 2016 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PopUpViewContollerBase.h"

///
/// シークレットメモパスワード入力ポップアップViewControllerクラス
///
@interface SecretMemoPasswordChangePopup : PopUpViewContollerBase
{
	IBOutlet UILabel			*lblTitle;			// Titleラベル
	
	IBOutlet UITextField		*txtOldPassword;	// 旧パスワードTextField
	IBOutlet UITextField		*txtNewPassword1;	// 新パスワードTextField
	IBOutlet UITextField		*txtNewPassword2;	// 新パスワードTextField（確認用）

    IBOutlet UIButton			*btnReset;		    // リセットボタン
	IBOutlet UIButton			*btnOK;				// OKボタン
    IBOutlet UIButton           *btnCancel;         // Cancelボタン
}

// 初期化 : superにて定義
/* - (id) initWithPopUpViewContoller:(NSUInteger)popUpID 
 popOverController:(UIPopoverController*)controller 
 callBack:(id)callBackDelegate;*/

// 編集開始
// - (IBOutlet) onTextEditBegin:(id)sender;

// 文字列変更 
- (IBAction) onChangeText:(id)sender;

// 編集終了
- (IBAction) onTextDidEnd:(id)sender;

// リターンキー
- (IBAction) onTextDidEndOnExit:(id)sender;

// OKボタン
- (IBAction) onOkButton:(id)sender;
// リセットボタン
- (IBAction) onResetButton:(id)sender;

@end
