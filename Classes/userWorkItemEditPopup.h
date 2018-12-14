//
//  userWorkItemEditPopup.h
//  iPadCamera
//
//  Created by MacBook on 11/05/09.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PopUpViewContollerBase.h"

///
/// 施術内容のマスタ編集ポップアップViewControllerクラス
///
@interface userWorkItemEditPopup : PopUpViewContollerBase 
{
	IBOutlet UILabel			*lblTitle;			// Titleラベル
	
	IBOutlet UIScrollView		*scrollView;		// スクロールView
	IBOutlet UIView				*conteinerView;		// 選択ボタンのコンテナView
	
	IBOutlet UIButton			*btnUpdate;			// 更新ボタン
	
	NSMutableDictionary			*masterTable;		// 施術マスタテーブル(本クラスでは編集しない)
	NSMutableDictionary			*_editMasterTable;	// 編集用施術マスタテーブル
}

@property(nonatomic, assign)	NSMutableDictionary		*masterTable;
@property(nonatomic, assign)	UILabel					*lblTitle;

// 初期化
- (id) initWithWorkItemMaster:(NSUInteger)popUpID 
			popOverController:(UIPopoverController*)controller 
					 callBack:(id)callBackDelegate
		  workItemMasterTable:(NSMutableDictionary*)mstTable;



@end
