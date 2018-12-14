//
//  SecretManagerViewController.h
//  iPadCamera
//
//  Created by TMS on 2016/06/26.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>
#import "EditorPopup.h"
#import "TemplateInfoListManager.h"
#import "userInfo.h"
#import "userInfoListManager.h"

#define APP_STORE_SAMPLE_DEF_KEY    @"appstore_sample_download"
#define APP_STORE_SAMPLE_DB_DEF_KEY    @"appstore_sample_db_download"
#define SECRET_MEMO_PWD_KEY            @"secret_memo_pwd_key"        // シークレットメモパスワード
#define SECRET_MEMO__PWD_INIT_VALUE            @"0000"                        // シークレットメモパスワード初期値

#define ACCOUNT_ID_SAVE_KEY        @"accountIDSave"        // アカウントIDの保存用Key
#define ACCOUNT_PWD_SAVE_KEY    @"accountPwdSave"        // アカウントパスワードの保存用Key

@protocol SecretManagerViewDelegate;

/*
 ** INTERFACE
 */
@interface SecretManagerViewController : UIViewController
<
	UIScrollViewDelegate,
	UIAlertViewDelegate,
	UITableViewDataSource,
	UITableViewDelegate
	//TemplateCreatorViewControllerDelegate
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
	IBOutlet UIButton *btnSecretMemoDelete;		//  削除ボタン
	IBOutlet UIButton *btnTemplateEditor;		//  編集ボタン
    IBOutlet UIButton *btnSakuseibiOrderBy;		//  作成日昇順ボタン
    IBOutlet UIButton *btnSakuseibiOrderByDesc; //  作成日降順ボタン
    IBOutlet UIButton *btnMemoOrderBy;          //  メモ昇順ボタン
    IBOutlet UIButton *btnMemoOrderByDesc;		//  メモ降順ボタン
	IBOutlet UITableView *templateTableView;	//  テンプレートテーブル
	IBOutlet UIView *templateList;              //  テンプレートテーブル
    IBOutlet UIScrollView* preview;             //  プレビュー
    IBOutlet UIView* previewBody;               //  プレビュー本体
    IBOutlet UILabel* previewSubject;           //  プレビューを表示する際のメールの題目
    IBOutlet UITextView* previewMailBody;       //  プレビューを表示する際のメールの本文
	/*
	 設定データ
	 */
	IPAD_CAMERA_WINDOW_VIEW _windowView;		// 遷移する画面
	CommonPopupInfoManager* _commonInfoMng;		// カテゴリー用情報
	NSMutableArray* _arrayCategoryStrings;		// カテゴリー名
	NSString* _strSelectCategory;				// 選択されたカテゴリー名
	TemplateInfoListManager* _templInfoList;	// テンプレート情報管理
	id<SecretManagerViewDelegate> _delegate;	// デリゲート
	NSIndexPath* _oldIndexPath;
    int orderMode;                              // 並び順の種類
    int workMode;                               // 作業モード
    NSInteger selectedSecretMemoId;              // 選択中のシークレットメモID
    NSMutableArray *SecretMemoInfoList;         //シークレットメモリスト
    NSString *initStr;                          //編集是非の比較用
    NSDate *selectedSMDate;
    
    userInfoListManager        *userInfoList;
    USERID_INT                currentUserId;
    NSMutableArray        *userInfoListArray;        // ユーザ情報リスト
    SEARCH_KIND_TYPE    searchKind;                // 検索対象の定義(全検索など)
    NSString            *searchNameTitle;       // 名前検索時の検索文字列
    NSMutableArray        *colStatements_j;        // 各行のSQLステートメント(日本語環境)
    NSMutableArray        *colStatements_e;        // 各行のSQLステートメント(英語環境)
    UIActivityIndicatorView  *indicator;
    UIAlertController *pending;
}

/*
 ** PROPERTY
 */
@property(nonatomic,assign) USERID_INT userId;

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
 OnTemplateCreator
 テンプレート作成画面を表示する
 */
- (IBAction) OnTemplateCreator:(id)sender;

/**
 OnSecretMemoDelete
 シークレットメモを削除する
 */
- (IBAction) OnSecretMemoDelete:(id)sender;

/**
 OnTemplateEditor
 テンプレート作成画面を表示する
 */
- (IBAction) OnTemplateEditor:(id)sender;

/**
 作成日の昇順
 */
- (IBAction) OnOrderBySakuseibi:(id)sender;

/**
 作成日の降順
 */
- (IBAction) OnOrderBySakuseibiDesc:(id)sender;

/**
 本文の昇順
 */
- (IBAction) OnOrderByMemo:(id)sender;

/**
 本文の降順
 */
- (IBAction) OnOrderByMemoDesc:(id)sender;
@end

/*
 ** PROTOCOL
 */
@protocol TemplateManagerViewDelegate <NSObject>

@end
