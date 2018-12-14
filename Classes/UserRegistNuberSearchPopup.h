//
//  UserRegistNuberSearchPopup.h
//  iPadCamera
//
//  Created by MacBook on 11/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PopUpViewContollerBase.h"

///
/// お客様番号による検索用ポップアップ
///
@interface UserRegistNuberSearchPopup : PopUpViewContollerBase<UITextFieldDelegate> 
{
	IBOutlet UILabel			*lblDialogTitle;		// ダイアログのタイトル
	IBOutlet UITextField		*txtUserRegistNumber;	// お客様番号
	IBOutlet UIButton			*btnSet;				// 設定ボタン
    IBOutlet UIButton           *btnCancel;             // 取消ボタン
	
	NSInteger					_lastRegistNumber;		// 前回検索で使用した番号：REGIST_NUMBER_INVALIDで無効
}

// お客様番号による検索用PopUpの作成
//		LastRegistNumber:前回検索で使用した番号（REGIST_NUMBER_INVALIDで無効）
- (id) initWithLastRegNumPopUpViewContoller:(NSUInteger)popUpID 
						popOverController:(UIPopoverController*)controller callBack:(id)callBackDelegate
						   LastRegistNumber:(NSInteger)lastNum;

// TextFieldのText変更ベント
- (IBAction)onTextChanged:(id)sender;
// TextFieldのEnterキーイベント
- (IBAction)onTextDidEnd:(id)sender;

@end
