//
//  UserInfoDispViewSupport.h
//  iPadCamera
//
//  Created by MacBook on 10/12/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "def64bit_common.h"
// 2016/6/24 TMS シークレットメモ対応
#import "iPadCameraAppDelegate.h"

@protocol UserInfoDispViewSupportDelegate;

@class UIFlickerButton;
@class mstUser;

// ボタンクリックのハンドラ定義
typedef void (^onUserInfoButtonClick)(NSInteger buttonTag);

#define USER_INFO_DISP_BTN_EDIT         1   // ユーザ編集ボタンタグ
#define USER_INFO_DISP_BTN_THUMBNAIL    2   // サムネイル表示ボタンタグ
#define USER_INFO_DISP_BTN_CLOSE        99  // 閉じるボタンタグ
// 2016/6/24 TMS シークレットメモ対応
#define POPUP_SECRET_MEMO_PASSWORD             0x9000      // シークレットメモパスワード入力
#define POPUP_SECRET_MEMO_PASSWORD_CHANGE      0x9001      // シークレットメモパスワード変更
#define POPUP_PASSWORD_INPUT_VIEW_LOCK		   0x0010
#define SECRET_MEMO_PWD_KEY			@"secret_memo_pwd_key"		// シークレットメモパスワード
#define COLOR_SEX_FEMALE [UIColor colorWithRed:0.93 green:0.43 blue:0.60 alpha:1.0]
#define COLOR_SEX_MALE [UIColor colorWithRed:0.08 green:0.60 blue:0.87 alpha:1.0]

#define SECRET_MEMO__PWD_INIT_VALUE			@"0000"						// シークレットメモパスワード初期値

// ユーザ情報表示サポートクラス
@interface UserInfoDispViewSupport : UIViewController<UIActionSheetDelegate>
{
	IBOutlet UIImageView	*imgViewPicture;		// 写真
	IBOutlet UILabel		*lblName;				// 名前（姓＋名）
    IBOutlet UILabel        *userNameHonoTitle;     // 敬称
	IBOutlet UILabel		*userRegistNumberTitle;	// お客様番号タイトル
    IBOutlet UILabel        *userRegistNumber;		// お客様番号
	IBOutlet UILabel		*lblSex;				// 性別
	IBOutlet UILabel		*lblLastWorkDate;		// 最新施術日
	IBOutlet UILabel		*lblLastWorkTitle;		// 最新施術内容タイトル
	IBOutlet UILabel		*lblLastWorkContent;	// 最新施術内容
	IBOutlet UILabel		*lblBirthday;			// 生年月日
	IBOutlet UILabel		*lblBloadType;			// 血液型
    IBOutlet UILabel        *lblBloadTypeTitle;     // 血液型タイトル
	IBOutlet UILabel		*lblSyumi;				// 趣味
	IBOutlet UITextView		*txtViewMemo;			// メモ
	
//    IBOutlet UIFlickerButton    *btnUserInfo;        // ユーザ情報のフリッカボタン    :tag=256
	IBOutlet UIFlickerButton	*btnPictView;		// 写真一覧画面へ			:tag=257
    
    IBOutlet UILabel        *lblShopName;              // 店舗名
	
	NSDate					*_lastWorkDate;			// 最新施術日
    BOOL                    _isSexMen;              // 選択されているのは男性か？
    
    BOOL                    _isDialogDispUse;       // このVCがダイアログ表示で使用されるか？
    
    onUserInfoButtonClick   _buttonClickHandler;    // ボタンクリックのイベントハンドラ
    // 2016/6/24 TMS シークレットメモ対応
    UIPopoverController	*popoverCntlPwdInput;	    // パスワード入力ポップアップコントローラ
    UIPopoverController	*popoverCntlPwdChange;	    // パスワード変更ポップアップコントローラ
    NSString *_passwordSecretMemo;                  // シークレットメモパスワード
    USERID_INT				currentUserId;			// 現在選択中のユーザID
    float                   iOSVersion;             // iOSバージョン
}

@property(nonatomic,assign)    id <UserInfoDispViewSupportDelegate> delegate;
@property(nonatomic, retain) NSDate		*lastWorkDate;
@property(nonatomic, retain) UILabel	*lblLastWorkContent;
@property(nonatomic)         BOOL       isSexMen;       

// userIDによる初期化:通常表示（ダイアログ表示ではない）
- (id)initWithUserID:(USERID_INT)userID ownerView:(id)ownerView;

// userIDによる初期化:ダイアログ表示
- (id)initWithUserID4DialogDisp:(USERID_INT)userID hButtonClick:(onUserInfoButtonClick) hClick;

// ユーザ情報の設定
- (void) setUserInfo:(USERID_INT)userID Language:(BOOL)isJapanese;

// ユーザ情報の更新
- (void) updateSelectedUserByUserInfo:(mstUser*) userInfo;

// サムネイル一覧表示ボタンの表示
- (void)showThumbnailViewBtn;
// お客様情報の編集
- (IBAction) onUserInfo:(id)sender;
// お客様写真の一覧（サムネイル）の表示
- (IBAction) onThumbnailViewDisp:(id)sender;
// view(ダイアログ)を閉じる
- (IBAction) onViewClose:(id)sender;
// 2016/6/24 TMS シークレットメモ対応
// シークレットメモ画面の表示
- (IBAction)OnSecretManager:(id)sender;

- (IBAction)onCustomerPreview:(UIButton *)sender;

@end

@protocol UserInfoDispViewSupportDelegate<NSObject>

- (void)onPreviewCustomer:(id)sender;

// シングルタップイベント
- (void)OnSingleTap:(id)sender;

@end
