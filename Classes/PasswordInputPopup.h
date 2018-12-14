//
//  PasswordInputPopup.h
//  iPadCamera
//
//  Created by MacBook on 11/07/14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Common.h"

#import "PopUpViewContollerBase.h"

///
/// パスワード入力ポップアップViewControllerクラス
///
@interface PasswordInputPopup : PopUpViewContollerBase {

	IBOutlet UILabel			*lblTitle;			// Titleラベル
	
	IBOutlet UITextField		*txtPassword;		// パスワードTextField
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

// パスワードの変更ボタン
- (IBAction) onPasswordChanged:(id)sender;

@end
