//
//  BroadcastMailUserListViewController.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/02/26.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>
#import "SendMailHistoryPopup.h"
#import "userInfo.h"
#import "userInfoListManager.h"
#import "BroadcastMailUserInfo.h"
#import "TemplateInfoListManager.h"
#import "TemplateManagerViewController.h"
#import "BroadcastMail.h"
#import "GetWebMailUserStatuses.h"
#import "BroadcastMailSendPopup.h"
#import "SearchResultTableViewCell.h"
#import "BroadcastMailUserInfoPopupController.h"

/*
 ** CLASS
 */

/*
 ** INTERFACE
 */
@interface BroadcastMailUserListViewController : UIViewController
<
	UIScrollViewDelegate,
	UIAlertViewDelegate,
	UITableViewDataSource,
	UITableViewDelegate,
	SendMailHistoryPopupDelegate,
	TemplateManagerViewDelegate,
	BroadcastMailDelegate,
	GetWebMailUserStatusesDelegate,
	BroadcastMailSendPopupDelegate,
    SearchResultTableViewDelegate,
    BroadcastMailUserInfoPopupDelegate
>
{
	/*
	 UIパーツ
	 */
    IBOutlet UILabel* lblSelectedCategoryName;  //  選択されているカテゴリ名
    IBOutlet UILabel* lblSelectedCategoryNum;   //  選択されているカテゴリのテンプレート数
    IBOutlet UILabel* lblTemplateAllNum;        //  テンプレート全件数
    IBOutlet UILabel* lblAttachmentImgNum;      //  添付画像数
	IBOutlet UIButton* btnBroadcastMail;		//  一斉送信ボタン
	IBOutlet UIButton* btnTemplateManager;		//  テンプレート管理ボタン
	IBOutlet UIButton* btnMailHistory;			//  送信履歴ボタン
	IBOutlet UIButton* btnSelectedAll;			//  送信ユーザーの全選択
    IBOutlet UIButton* btnBlockMailUser;        //  受信拒否者表示
    IBOutlet UIButton* btnTemplateSelect;       //  テンプレート再選択
	IBOutlet UIButton* btnTemplateCategory;		//  カテゴリーボタン
	IBOutlet UIButton* btnTemplateEdit;         //  テンプレート編集ボタン
	IBOutlet UITableView* userTableView;		//  ユーザーテーブル
	IBOutlet UITableView* templateTableView;	//  テーブル
    IBOutlet UIView* userList;                  //  宛先のユーザーリスト
    IBOutlet UIView* templateList;              //  メールテンプレートリスト
    IBOutlet UIView* viewCreateAndCategory;     //  テンプレートの新規作成とカテゴリボタンのサブビューを持ったView
    IBOutlet UIView* viewEditAndSelect;         //  テンプレートの編集と再選択ボタンのサブビューを持ったView
    IBOutlet UIScrollView* templateAndPreview;  //  テンプレートリストとプレビューを持ったView
    IBOutlet UIScrollView* preview;             //  プレビュー
    IBOutlet UILabel* previewSubject;           //  プレビューを表示する際のメールの題目
    IBOutlet UITextView* previewMailBody;       //  プレビューを表示する際のメールの本文
    IBOutlet UIScrollView* previewPictures;     //  プレビューを表示する際の添付画像
    

	/*
	 設定データ
	 */
	NSString* _strSearchResult;					//  検索結果の文字列
	IPAD_CAMERA_WINDOW_VIEW _windowView;		//  遷移する画面
	userInfoListManager* _userInfoList;			//  ユーザー情報管理
    TemplateInfoListManager* _templInfoList;	//  テンプレート情報管理
	UIPopoverController* popOverCtrlMailHist;	//  送信履歴表示用
	UIPopoverController* _popOverCtrlCategory;	//  カテゴリー検索表示用
	NSMutableArray* _arrayBroadcastMailUser;	//  送信ユーザー情報
	NSMutableArray* _arrayCategoryStrings;		//  カテゴリー名
	NSMutableDictionary* _arrayRemoveUserList;	//  削除ユーザー情報
	NSMutableDictionary* _headPictureList;		//  代表写真リストのキャッシュ
    NSDictionary* _userMailStatusList;			//  ユーザの未読情報などを保持
	BOOL _selectedAll;							//  全選択ボタンの状態
    BOOL _showBlockMailUser;                    //  受信拒否者ボタンの状態
	GetWebMailUserStatuses* mailStatuses;		//  メールステータス
    NSString* _strSelectCategory;				//  選択されたカテゴリー名
    NSMutableArray* _previewPicturesList;       //  プレビューで表示するピクチャーリスト
	NSIndexPath* _oldIndexPath;                 //  テンプレートカテゴリ選択ボタン機能で使用
    NSMutableArray *sectionTitles;              //  セクションテーブル名のリスト
    NSMutableArray *activeSections;             //  有効なセクションを表す(送信すべきユーザが存在するか)

    UIView* dummyView;
}

/*
 ** PROPERTY
 */
@property(nonatomic, assign) NSString* strSearchResult;
@property(nonatomic, retain) userInfoListManager* userInfoList;
@property(nonatomic, copy)   NSDictionary* userMailStatusList;

/*
 ** METHOD
 */

/**
 代表画像リストの設定
 @param dic 代表画像リスト
 return なし
 */
- (void) setHeadPictureList:(NSDictionary*) dic;

/**
 画面外のタッチを受け取り、何の処理もしないダミーのViewを作成する
 viewの初期状態はHiddenに設定されたviewを返す。
 */
-(UIView*)createDummyView;

/*
 ** HANDLER METHOD
 */

/**
 OnReturnUserInfoList
 ユーザー情報画面に戻る
 */
- (IBAction) OnReturnUserInfoList;

/**
 OnBroadcastMail
 メールを一斉送信する
 @param sender id
 */
- (IBAction) OnBroadcastMail:(id)sender;

/**
 OnTemplateManager
 テンプレート管理画面を呼び出す
 @param sender id
 */
- (IBAction) OnTemplateManager:(id)sender;

/**
 OnMailHistory
 送信履歴
 @param sender id
 */
- (IBAction) OnMailHistory:(id)sender;

/**
 OnSelectedAll
 送信ユーザーの全選択
 */
- (IBAction) OnSelectedAll:(id)sender;

/**
 受信拒否者表示ボタン
 */
-(IBAction) OnBlockMailUser:(id)sender;

/**
 テンプレート再選択ボタン
 */
-(IBAction) OnTemplateSelect:(id)sender;

/**
 カテゴリ選択ボタンアクション
 */
- (IBAction) OnTemplateCategory:(id)sender;

/**
 新規作成ボタンアクション
 */
- (IBAction) OnTemplateCreator:(id)sender;

/**
 テンプレート編集ボタンアクション
 */
- (IBAction) OnTemplateEditor:(id)sender;

@end
