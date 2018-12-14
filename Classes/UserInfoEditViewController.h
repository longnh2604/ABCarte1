//
//  UserInfoEditViewController.h
//  iPadCamera
//
//  Created by MacBook on 10/10/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PopUpViewContollerBase.h"
#import "SelectMailAddress.h"
#import "BlockMailStatus.h"
#import "BloodGroupPopUp.h"
#import "PrefecturePopUp.h"

#import "MainViewController.h"
#import "iPadCameraAppDelegate.h"
#import "OKDImageFileManager.h"
#import "ThumbnailViewController.h"

#define	EMPTY_TEXT				@""			// UITextFieldのTextフィールドの初期値（空文字）

#ifdef CLOUD_SYNC
// popupViewのID定義
typedef enum
{
    USER_EDIT_POPUP_SELECT_SHOP       = 0x0800,       // 店舗の選択
} USER_EDIT_POPUP_VIEW_ID;
#endif
#define USER_SET_BIRTHDAY_POPUP     0x1000
#define USER_SET_BLOODTYPE_POPUP    0x1100
#define USER_SET_PREFECTURE_POPUP   0x1200

@class mstUser;
@class UIKanaSupportTextField;

// ユーザ情報編集ViewControllerクラス
@interface UserInfoEditViewController: PopUpViewContollerBase
<
	UITextFieldDelegate,
	UIPickerViewDelegate,
	UIPickerViewDataSource,
	SelectMailAddressDelegate,
	BlockMailStatusDelegate,
    BloodGroupPopUpDelegate,
    PrefecturePopUpDelegate
>
{
#ifdef CLOUD_SYNC
    UIPopoverController		*popoverCntlSelectShop;  // 店舗選択用ポップアップコントローラ
#endif
	IBOutlet UITextField		*txtFirstNameCana;		// 姓：かな
	IBOutlet UITextField		*txtSecondNameCana;		// 名：かな
    IBOutlet UILabel            *lblName;               // 名前ラベル
    IBOutlet UILabel            *lblKana;               // かなラベル
    IBOutlet UILabel            *lblNameSuffix;         // 様
	IBOutlet UIKanaSupportTextField		*txtFirstName;			// 姓 
	IBOutlet UIKanaSupportTextField		*txtSecondName;			// 名
    IBOutlet UITextField        *txtMidName;            // ミドルネーム
	IBOutlet UITextField		*txtUserRegistNumber;	// お客様番号
    IBOutlet UILabel            *lblUserRegistNumber;   // お客様番号ラベル
    IBOutlet UIView             *vwRequired;            // 必須項目囲み線用
    IBOutlet UITextField *txtShopName;
    
    IBOutlet UIButton *btnChangeAvatar;
    IBOutlet UISegmentedControl	*segSex;				// 性別
    IBOutlet UILabel            *lblSex;                // 性別ラベル
	
    IBOutlet UIButton           *btnBirthday;           // 生年月日設定ボタン
	UIPopoverController			*popCtlDatePicker;		// 生年月日ポップアップコントローラ
    NSDate                      *birthDay;              // 生年月日
    IBOutlet UILabel            *lblBirthday;           // 生年月日ラベル
	
    IBOutlet UIImageView *imvCustomer;
    IBOutlet UIButton           *btnBloodType;          // 血液型設定ポップアップ呼び出し
    IBOutlet UILabel            *lblBloodType;          // 血液型ラベル
	IBOutlet UILabel			*lblBloadTypeMessage;	// 血液型が設定されていませんLabel
	IBOutlet UITextField		*txtSyumi;				// 趣味
    IBOutlet UILabel            *lblSyumi;              // 趣味ラベル
    IBOutlet UITextField		*emailText1;            // Email1
    IBOutlet UITextField		*emailText2;            // Email2
    IBOutlet UILabel            *lblEmailNotice;        // Emailに関する注意点表示ラベル
    IBOutlet UILabel            *lblMailReject;         // メール受信拒否ラベル
    IBOutlet UISwitch           *swMailBlock;           // メールの受信設定
	IBOutlet UITextView			*txtViewMemo;			// メモ（修正可能）
    IBOutlet UILabel            *lblMemo;               // メモラベル
	IBOutlet UIButton			*btnRegist;				// 登録ボタン
    IBOutlet UIButton           *btnCancel;             // 取り消しボタン
    IBOutlet UILabel            *lblAddress;            // 住所ラベル
    IBOutlet UITextField        *postal;                // 郵便番号
    IBOutlet UIButton           *btnPrefecture;         // 都道府県選択ボタン
    IBOutlet UITextField        *txtPrefecture;         // 都道府県
    IBOutlet UITextField        *adr2;                  // 住所（郡/市区町村）
    IBOutlet UITextField        *adr3;                  // 住所（以降の住所）
    IBOutlet UITextField        *adr4;                  // 住所（以降の住所２）
    IBOutlet UIButton           *btnConvPostal;         // 郵便番号->住所変換
    IBOutlet UITextField        *telephone;             // 電話番号
    IBOutlet UILabel            *lblTelephone;          // 電話番号ラベル
    IBOutlet UILabel            *lblMobile;
    IBOutlet UITextField        *txtMobile;
    IBOutlet UILabel *lblEmail;
    
	IBOutlet UILabel			*lblDialogTitle;		// ダイアログのタイトル
    
    IBOutlet UIScrollView       *scrContents;           // スクロールView(for iPhone)
    IBOutlet UIView             *viewContents;          // コンテントView(for iPhone)
    IBOutlet UIButton           *btnMemoKeybordHide;    // メモのキーボードを閉じる(for iPhone)
    
    IBOutlet UIButton           *btnShopSelectShow;     // 店舗選択Picker表示ボタン
    IBOutlet UILabel            *lblShopName;           // 選択中の店舗名
    IBOutlet UISegmentedControl *segCountry;            // 国設定
	
	mstUser						*editUser;				// 編集するユーザ
	BOOL						isEditableUserName;		// ユーザ名（かな含む）の編集可フラグ
#ifdef CLOUD_SYNC
    NSMutableArray              *_shopItemList;          // 店舗Itemの一覧
    SHOPID_INT                   selectShopID;           //選択中のショップID
#endif
    UITextField*                *_editingTextBox;       //編集中のテキストボックス
    
    BOOL                        isJapanese;             // 設定言語が日本語か？
    NSString                    *txtDialogTitle;
    NSString                    *txtBtnTitle;
    // 2016/7/17 TMS 参照モード追加対応
    int                         viewMode;               //画面モード
    // 2016/8/12 TMS 顧客情報に担当者を追加
    IBOutlet UITextField		*txtResponsible;		// 担当者
    IBOutlet UILabel            *lblResponsible;        // 担当者ラベル
    
    BOOL                        _isModeLock;                                // ロックモード：YES
}

@property(nonatomic, retain) mstUser	*editUser;
@property(nonatomic) BOOL isEditableUserName;
@property(nonatomic) int viewMode;

// 生年月日pickerのイベント
- (IBAction)onBirthday:(id)sender;

// 各TextFieldのEnterキーイベント
- (IBAction)onTextDidEnd:(id)sender;

// 血液型の設定変更
- (IBAction)onBloodTypeChange:(id)sender;

// メモのキーボードを閉じるボタンのClickイベント(for iPhone)
- (IBAction)onMemoKeybordHide:(id)sender;

// 店舗名リストの表示jボタン
- (IBAction)onBtnShopSelectShow:(id)sender;

// 郵便番号から住所への変換
- (IBAction)onBtnConvertPostal:(id)sender;

// 住所（都道府県選択）
- (IBAction)onPrefectureSelect:(id)sender;

// 言語設定の変更
- (IBAction)onCountrySelect:(id)sender;

// 性別変更
- (IBAction)onGenerChange:(id)sender;

// ユーザ情報編集PopUpの作成
- (id) initWithUserEditPopUpViewContoller:(NSUInteger)popUpID 
						popOverController:(UIPopoverController*)controller callBack:(id)callBackDelegate
								user4Edit:(mstUser*)user;

// 新規ユーザ情報PopUpの作成
- (id) initWithNewUserPopUpViewContoller:(NSUInteger)popUpID
				popOverController:(UIPopoverController*)controller callBack:(id)callBackDelegate;

// 生年月日の和暦表示
- (void) dispLabelBirthday:(NSDate*)date;

// メール受信設定を取得する
- (NSInteger) getMailRecieveSetting;

// e-mailが存在する
- (BOOL) isEmailExist;

@end
