//
//  EditorPopup.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/02/28.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>
#import "TemplateCategoryViewCell.h"
#import "CommonPopupInfoManager.h"

/*
 ** ENUM
 */
enum EditorEvent
{
	CLICKED_CLOSE     = 0,	// 閉じる
	CLICKED_CLEAR_ALL = 1,	// 全てクリア
	CLICKED_MODE_CHG  = 2,	// モード変更
	CLICKED_INSERT    = 3,	// 挿入
	CLICKED_DELETE    = 4,	// 削除
	CLICKED_UPDATE    = 5,	// 更新
	CLICKED_EDIT      = 6,	// 項目編集
	CLICKED_CANCEL    = 7,	// 取消
	CLICKED_SELECT    = 8,	// 選択
};

NS_ENUM(NSInteger, PopupMode)
{
	POPUP_MODE_CATEGORY = 0,	// カテゴリーモード
	POPUP_MODE_GENERAL1 = 1,	// 汎用1モード
	POPUP_MODE_GENERAL2 = 2,	// 汎用2モード
	POPUP_MODE_GENERAL3 = 3,	// 汎用3モード
};

enum PopupEditMode
{
	POPUP_EDIT_UNSELECT = 0,	// セルが非選択状態
	POPUP_EDIT_SELECT   = 1,	// セルが選択状態
};

/*
 ** DECLARE
 */
@protocol EditorPopupDelegate;

/*
 ** INTERFACE
 */
@interface EditorPopup : UIViewController
<
	UITableViewDataSource,
	UITableViewDelegate
>
{
	/*
	 UIパーツ
	 */
	IBOutlet UINavigationBar* navibarTitle;
	IBOutlet UITableView *viewCategory;
	IBOutlet UIButton* btnClosePopup;
	IBOutlet UIButton* btnClearAll;
	IBOutlet UIButton* btnModeChange;
	IBOutlet UIButton* btnInsertList;
	IBOutlet UIButton* btnDeleteList;
	IBOutlet UIButton* btnUpdateList;
	IBOutlet UIButton* btnEditList;
	IBOutlet UIButton* btnCancelEdit;
	IBOutlet UITapGestureRecognizer* doubleTapGesture;
	
	/*
	 設定データ
	 */
	NSMutableArray* _arrayCellNames;
	NSInteger _popupMode;
	NSString* _strPopupTitle;
	NSString* _strKindName;
	id<EditorPopupDelegate> _delegate;
	UIPopoverController* _popOverController;
	CommonPopupInfoManager* _commonInfoManager;
	BOOL _defMode;
	BOOL _deleting;
	NSInteger _editMode;
}

/*
 ** PROPERTY
 */
@property(nonatomic, assign) NSInteger popupMode;
@property(nonatomic, assign) NSString* strPopupTitle;
@property(nonatomic, assign) NSString* strKindName;
@property(nonatomic, assign) id <EditorPopupDelegate> delegate;
@property(nonatomic, retain) UIPopoverController* popOverController;


/**
 initWithCategory
 カテゴリー編集ポップアップを初期化する
 @param category カテゴリー
 @param delegate デリゲート
 @param popOver ポップオーバーコントローラー
 */
- (id) initWithCategory:(id) category
				  title:(NSString*) title
		   selectString:(NSString*) selectString
			   delegate:(id) callback
				popOver:(UIPopoverController*) popOver;


/**
 initWithCategory
 汎用編集ポップアップを初期化する
 @param category カテゴリー
 @param delegate デリゲート
 @param popOver ポップオーバーコントローラー
 */
- (id) initWithGeneral:(id) general
				 title:(NSString*) title
		  selectString:(NSString*) selectString
			  delegate:(id) callback
			   popOver:(UIPopoverController*) popOver
				 GenNo:(NSInteger) genNo;

/**
 getCellNameFromIndex
 セル名を取得する
 @param index セル名へのインデックス
 @return セル名
 */
- (NSString*) getCellNameFromIndex:(NSInteger) index;

/**
 IDを取得する
 @param index 取得する　IDのインデックス
 
 */
- (NSString*) getCellCommonIDFromIndex:(NSInteger)index;

/**
 全て消去ボタンと編集モード切り替えボタンの有効・無効を切り替える
 @param enabled 有効・無効
 */
- (void) enabledEditBtn:(BOOL) enabled;

/**
 OnAddCategory
 閉じるボタンが押された
 */
- (IBAction) OnClosePopup:(id) sender;

/**
 OnAddCategory
 全てクリアボタンが押された
 */
- (IBAction) OnClearAll:(id) sender;

/**
 OnDelCategory
 モード変更ボタンが押された
 */
- (IBAction) OnModeChange:(id) sender;

/**
 OnEditCategory
 挿入ボタンが押された
 */
- (IBAction) OnInsertList:(id) sender;

/**
 OnCancelCategory
 削除ボタンが押された
 */
- (IBAction) OnDeleteList:(id) sender;

/**
 OnCancelCategory
 更新ボタンが押された
 */
- (IBAction) OnUpdateList:(id) sender;

/**
 OnCancelCategory
 編集ボタンが押された
 */
- (IBAction) OnEditList:(id) sender;

/**
 OnCancelEdit
 */
- (IBAction) OnCancelEdit:(id) sender;

/**
 OnDoubleTapGesture
 テーブルビュー内でダブルタップされた
 */
- (IBAction) OnDoubleTapGestureInTableView:(id)sender;

@end

/*
 ** PROTOCOL
 */
@protocol EditorPopupDelegate <NSObject>

/**
 OnClickedCategoryEditor
 カテゴリーエディターのボタンがクリックされた
 @param sender delegate
 @param event ボタンイベントの種類
 @param cellIndex 選択されたcellのインデックス
 */
- (void) OnClickedItemEditor:(id) sender Event:(NSInteger) event Index:(NSInteger) cellIndex Mode:(NSInteger) mode;
@end