//
//  itemEditerPopup.h
//  iPadCamera
//
//  Created by MacBook on 11/06/26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "defines.h"
#import "DateAddDaysPopup.h"
#import "def64bit_common.h"

@protocol itemEditerPopupDelegate;

@class itemTableManager;

// モードの定義
typedef enum
{
	ITEM_EDITER_SELECT		= 0x0001,		// 選択モード
	ITEM_EDITER_EDIT		= 0x0010,		// 編集モード
	ITEM_EDITER_NAUTRAL		= 0xffff,		// モード初期状態
} ITEM_EDITER_MODE;

#define	EDIT_SELECTED_INDEX_INVALID		NSIntegerMin		// 編集用選択の無効値

///
/// 項目編集ポップアップViewControllerクラス
///
@interface itemEditerPopup : UIViewController
<
    UIAlertViewDelegate,
    DataAddDaysPopupDelegate
>
{
	IBOutlet UILabel			*lblTitle;			// Titleラベル
	
	IBOutlet UIScrollView		*scrollView;		// スクロールView
	IBOutlet UIView				*conteinerView;		// 選択ボタンのコンテナView
	
	/* 選択モードのボタン定義 */
	IBOutlet UIButton			*btnClose;			// 閉じるボタン
	IBOutlet UIButton			*btnAllReset;		// 全てを解除
	
	/* 編集モードのボタン定義 */
	IBOutlet UIButton			*btnUpdateData;		// 更新ボタン
	IBOutlet UIButton			*btnChancel;		// 取消ボタン
	IBOutlet UIButton			*btnInsert;			// 追加ボタン
	IBOutlet UIButton			*btnDelete;			// 削除ボタン
	IBOutlet UIButton			*btnItemEdit;		// 項目編集ボタン
	
	/* モード切り替えのボタン定義 */
	IBOutlet UIButton			*btnModeChange;		// モード切り替えボタン
	
	UITextField					*_dummyTextField;	// 編集・追加用ダミーテキストFiled
	UIPopoverController			*popoverController;
	id <itemEditerPopupDelegate> delegate;			// 項目編集ポップアップのイベント
	
	ITEM_EDITER_MODE			_nowMode;			// 現在モード
	
	ITEM_EDIT_KIND				_itemEditKind;		// 項目編集種別
	
	itemTableManager			*_itemTableManager;	// 項目テーブル管理クラス
	
	NSInteger					_editSelectedIndex;	// 編集用選択のindex
    
    UIPopoverController			*_popCtlDatePicker;	// ポップアップコントローラ
}

@property(nonatomic, assign)	UILabel					*lblTitle;
@property(nonatomic, retain)	UIPopoverController		*popoverController;
@property(nonatomic, assign)    id <itemEditerPopupDelegate> delegate;

// 初期化
- (id) initWithHistID:(HISTID_INT)histID
		 itemEditKind:(ITEM_EDIT_KIND)editKind
		itemListString:(NSString*)strings
	popOverController:(UIPopoverController*)controller 
			 callBack:(id)callBackDelegate;

// ポップアップタイトルの設定
-(void) setPopupTitleWithUserName:(NSString*)userName memoTitle:(NSString*)memoTitle;
-(void) setPopupTitle:(NSString*)title;

/* 選択モードのボタン */
// 閉じるボタン
-(IBAction) onClose:(id)sender;
// 全てを解除
-(IBAction) onAllReset:(id)sender;

/* 編集モードのボタン */
// 更新ボタン
-(IBAction) onUpdateData:(id)sender;
// 取消ボタン
-(IBAction) onChancel:(id)sender;

// 追加ボタン
-(IBAction) onInsert:(id)sender;
// 削除ボタン
-(IBAction) onDelete:(id)sender;
// 項目編集
-(IBAction) onItemEdit:(id)sender;

/* モード切り替えのボタン */
// モード切り替え
-(IBAction) onModeChange:(id)sender;

@end

// 項目編集ポップアップのイベント
@protocol itemEditerPopupDelegate<NSObject>
@optional
// 項目をクリックした時のイベント
- (void)OnItemSetWithSelecteds:(NSArray*)selecteds itemEditKind:(ITEM_EDIT_KIND)editKind;
// 全ての項目の選択解除
- (void)OnAllItemReset:(ITEM_EDIT_KIND)editKind;
// ポップアップのクローズ処理
- (void)afterPopupClose;
@end
