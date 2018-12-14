//
//  TemplateCreatorViewController.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/02/26.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>
#import "EditorPopup.h"
#import "TemplateInfoListManager.h"
#import "OKDThumbnailItemView.h"

/*
 ** ENUM
 */
enum TemplateEditMode
{
	TMPL_MODE_CREATE = 0,
	TMPL_MODE_EDIT   = 1,
};

/*
 ** CLASS
 */
@class fcUserWorkItem;
@class takePicture4PhotoLibrary;

/*
 ** PROTOCOL
 */
@protocol TemplateCreatorViewControllerDelegate;

/*
 ** INTERFACE
 */
@interface TemplateCreatorViewController : UIViewController
<
	UIScrollViewDelegate,
	UIAlertViewDelegate,
	UITextFieldDelegate,
    UITextViewDelegate,
	EditorPopupDelegate,
	OKDThumbnailItemViewDelegate,
	UINavigationControllerDelegate,
	UIImagePickerControllerDelegate,
	UIPopoverControllerDelegate
>
{
	IBOutlet UIView* viewPictureConteiner;			// 写真
    IBOutlet UIImageView* viewPictureAlbum;			// 写真アルバム取り込みのプレビュー
	IBOutlet UIScrollView* scviewPictContainer;		// 写真用ScrollView
    IBOutlet UIScrollView* scviewBasePanel;			// baseパネル用ScrollView
	IBOutlet UIView* viewBasePanel;					// baseパネル

	IBOutlet UIButton* btnCategoryEditor;			// カテゴリー編集
    IBOutlet UIButton* btnAddNameField;				// 名前フィールドボタン
    IBOutlet UIButton* btnAddDateField;				// 日付フィールドボタン
    IBOutlet UIButton* btnAddGeneral1Field;			// 汎用１フィールドボタン
    IBOutlet UIButton* btnAddGeneral2Field;			// 汎用２フィールドボタン
    IBOutlet UIButton* btnAddGeneral3Field;			// 汎用３フィールドボタン
	IBOutlet UIButton* btnDeletePicture;			// 画像削除
    IBOutlet UIButton* btnPictureAlbum;				// 写真アルバム取り込みボタン
	IBOutlet UIActivityIndicatorView* actIndView;	// 待機アイコン
	
	IBOutlet UITextField *textCategory;				// カテゴリー
	IBOutlet UITextView *textTitle;					// タイトル
	IBOutlet UITextView *textMailBody;				// メール本文
	IBOutlet UILongPressGestureRecognizer *longPressGesture1; // 長押し（汎用１）
	IBOutlet UILongPressGestureRecognizer *longPressGesture2; // 長押し（汎用２）
	IBOutlet UILongPressGestureRecognizer *longPressGesture3; // 長押し（汎用３）

	/*
	 設定データ
	 */
	UIAlertView* deleteNoAlert;						// 削除なしAlertダイアログ
	UIAlertView* deleteCheckAlert;					// 削除確認Alertダイアログ
	BOOL		_dirty;								// 編集フラグ
	BOOL		_isThumbnailRedraw;					// 再描画フラグ
	BOOL		_isTemplateSave;					// テンプレート保存フラグ
    BOOL		isCategoryClear;				    // カテゴリ削除フラグ
	NSInteger	_editMode;							// 編集モード
	NSMutableArray* _arrayThumbailItems;			// 写真アイテム
	NSMutableArray* _selectItemOrder;				// 選択サムネイルItemの順序Table
	UIPopoverController* popOverController;			// ポップオーバー表示用
	TemplateInfo* _templInfo;						// テンプレート情報
	NSMutableArray* _arrayCategoryStrings;			// カテゴリー名
	NSString* _strSelectCategory;					// 選択されたカテゴリー名
	NSMutableArray* _arrayGenFieldStrings;			// 汎用フィールド名
	NSMutableDictionary* _dicGeneralFields;			// 選択された汎用フィールド
	NSMutableDictionary* _dicOldGeneralFields;		// 選択された汎用フィールド
	UIPopoverController* _imagePopController;		// フォトライブラリ用ポップアップ
	NSMutableArray* _saveOldTextData;				// 編集モード時にテキストフィールドが編集されているかのチェック用
	NSString* _tmpTemplateId;						// 作成モード時の仮のテンプレートID
	NSMutableArray* _capturePictInfo;				// 取り込み画像用
	NSMutableArray* _oldArrayThumbailItems;			// 起動時に選択した画像一覧
	NSMutableArray* _oldSelectItemOrder;			// 選択サムネイルItemの順序Table
	NSMutableArray* _delPictureList;				// 削除する画像リスト
	id<TemplateCreatorViewControllerDelegate> _delegate;	// デリゲート
    
    float _btnDefaultPosY;                          // 画面が構成された際のボタンの位置（Y）を保存しておく
    float _textMailBodyMarginBottom;                // 画面が構成された際の本文フィールドからボタンまでのマージンを保存しておく
    //  名前フィールドボタンを基点とした距離を保存しておく
    float _pictLocalPosY;                         // 画面が構成された際のs写真用スクロールビューの位置（Y）を保存しておく
    float _btnPictureAlbumLocalPosY;              // 画面が構成された際のアルバム取り込みボタンの位置（Y）を保存しておく
    
    UIPopoverController	*_popoverCntlWorkItemSet;	// 施術内容の設定ポップアップコントローラ
}

/*
 ** PROPERTY
 */
@property BOOL dirty;
@property NSInteger editMode;

/*
 ** METHOD
 */

/**
 initWithTemplateInfo
 テンプレート情報で初期化する
 */
- (id) initWithTemplateInfo:(TemplateInfo*) templInfo Delegate:(id)delegate;

/**
 OnReturnTemplateManage
 テンプレート管理画面に戻る
 */
- (IBAction) OnReturnTemplateManage;

/**
 OnCategoryEditor
 カテゴリー編集
 */
- (IBAction) OnCategoryEditor:(id)sender;

/**
 OnAddNameField
 名前フィールドをメール本文に追加する
 */
- (IBAction) OnAddNameField:(id)sender;

/**
 OnAddDateField
 日付フィールドをメール本文に追加する
 */
- (IBAction) OnAddDateField:(id)sender;

/**
 OnAddGeneral1Field
 汎用１フィールドをメール本文に追加する
 */
- (IBAction) OnAddGeneral1Field:(id)sender;

/**
 OnAddGeneral2Field
 汎用２フィールドをメール本文に追加する
 */
- (IBAction) OnAddGeneral2Field:(id)sender;

/**
 OnAddGeneral3Field
 汎用３フィールドをメール本文に追加する
 */
- (IBAction) OnAddGeneral3Field:(id)sender;

/**
 画像を削除する
 */
- (IBAction) OnDeletePicture:(id)sender;

/**
 OnPhotoAlbum
 アルバムを開く
 */
- (IBAction) OnPhotoAlbum:(id)sender;

@end

/*
 UISpecialAlertView
 */
@interface UISpecialAlertView : UIAlertView
{
	void (^Callback)( NSInteger buttonIndex );
}

- (void) showWithCallback:(void(^)(NSInteger buttonIndex)) callback;

@end

/*
 ** PROTOCOL
 */
@protocol TemplateCreatorViewControllerDelegate<NSObject>

/**
 TemplateCategoryViewが終了する際に呼び出される
 @param categoryName カテゴリ名
 @param templateId テンプレートID
 @return なし
 */
- (void) finishedTemplateCreatorView:(NSString*)categoryName TemplateId:(NSString*)templateId;

/**
 テンプレートリストのリロード
 */
- (void)reloadTemplateList;

@end
