//
//  TemplateManagerViewController.h
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
#import "TemplateCreatorViewController.h"
#import "userInfo.h"
#import "userInfoListManager.h"

@protocol TemplateManagerViewDelegate;

/*
 ** INTERFACE
 */
@interface TemplateManagerViewController : UIViewController
<
	UIScrollViewDelegate,
	UIAlertViewDelegate,
	UITableViewDataSource,
	UITableViewDelegate,
	EditorPopupDelegate,
	TemplateCreatorViewControllerDelegate
>
{
	/*
	 UIパーツ
	 */
    IBOutlet UILabel* lblSelectedCategoryName;  //  選択されているカテゴリ名
    IBOutlet UILabel* lblSelectedCategoryNum;   //  選択されているカテゴリのテンプレート数
    IBOutlet UILabel* lblTemplateAllNum;        //  テンプレート全件数
    IBOutlet UILabel* lblAttachmentImgNum;      //  添付画像数
	IBOutlet UIButton *btnTemplateCreator;		//  作成ボタン
	IBOutlet UIButton *btnTemplateDelete;		//  削除ボタン
	IBOutlet UIButton *btnTemplateEditor;		//  編集ボタン
	IBOutlet UIButton *btnTemplateCategory;		//  カテゴリーボタン
	IBOutlet UITableView *templateTableView;	//  テンプレートテーブル
	IBOutlet UIView *templateList;              //  テンプレートテーブル
    IBOutlet UIScrollView* preview;             //  プレビュー
    IBOutlet UIView* previewBody;               //  プレビュー本体
    IBOutlet UILabel* previewSubject;           //  プレビューを表示する際のメールの題目
    IBOutlet UITextView* previewMailBody;       //  プレビューを表示する際のメールの本文
    IBOutlet UIScrollView* previewPictures;     //  プレビューを表示する際の添付画像
	/*
	 設定データ
	 */
	IPAD_CAMERA_WINDOW_VIEW _windowView;		// 遷移する画面
	CommonPopupInfoManager* _commonInfoMng;		// カテゴリー用情報
	NSMutableArray* _arrayCategoryStrings;		// カテゴリー名
	NSString* _strSelectCategory;				// 選択されたカテゴリー名
	TemplateInfoListManager* _templInfoList;	// テンプレート情報管理
	UIPopoverController* popOverCtrlCategory;	// カテゴリー検索表示用
	id<TemplateManagerViewDelegate> _delegate;	// デリゲート
	NSIndexPath* _oldIndexPath;
    NSMutableArray* _previewPicturesList;       //  プレビューで表示するピクチャーリスト

}

/*
 ** PROPERTY
 */
@property(nonatomic,assign) NSInteger userId;

/*
 ** METHOD
 */

/**
 初期化
 */
- (id) initWithDelegate:(id) delegate;

/**
 OnReturnUserInfoList
 ユーザー情報画面に戻る
 */
- (IBAction) OnReturnUserInfoList;

/**
 OnGotoTemplateCreator
 テンプレート作成画面に進む
 */
- (IBAction) OnGotoTemplateCreator:(id)sender;

/**
 OnTemplateCreator
 テンプレート作成画面を表示する
 */
- (IBAction) OnTemplateCreator:(id)sender;

/**
 OnTemplateDelete
 テンプレートを削除する
 */
- (IBAction) OnTemplateDelete:(id)sender;

/**
 OnTemplateEditor
 テンプレート作成画面を表示する
 */
- (IBAction) OnTemplateEditor:(id)sender;

/**
 OnTemplateCategory
 テンプレートをカテゴリーで絞り込む
 */
- (IBAction) OnTemplateCategory:(id)sender;

/**
 テンプレートリストのリロード
 */
- (void)reloadTemplateList;

@end
/*
 ** PROTOCOL
 */
@protocol TemplateManagerViewDelegate <NSObject>

@end
