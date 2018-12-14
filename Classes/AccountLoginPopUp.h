//
//  AccountLoginPopUp.h
//  iPadCamera
//
//  Created by MacBook on 11/09/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Common.h"

#import "PopUpViewContollerBase.h"
#ifdef EASY_LOGIN
#import <ZXingObjC.h>
#endif

@protocol AccountLoginPopUpDelegate;

///
/// アカウントログインポップアップViewControllerクラス
///
@interface AccountLoginPopUp : PopUpViewContollerBase
<
UIPopoverControllerDelegate
#ifdef EASY_LOGIN
,ZXCaptureDelegate
,NSXMLParserDelegate
#endif
>
{

	IBOutlet UILabel			*QRlblTitle;			// QRTitleラベル
    IBOutlet UILabel			*IDlblTitle;			// IDTitleラベル
    IBOutlet UILabel *lblTitle;
	
	IBOutlet UITextField		*txtAccountID;		// アカウントIDTextField
	IBOutlet UITextField		*txtPassword;		// パスワードTextField
    IBOutlet UITextField		*txtShopID;         // 店舗IDTextField
    IBOutlet UILabel            *lblShopID;         // 店舗IDラベル
	IBOutlet UITextField		*txtShopPassword;	// 店舗パスワードTextField
    IBOutlet UILabel            *lblShopPWD;        // 店舗パスワードラベル
    // 2016/4/22 TMS QRログイン対応
	IBOutlet UIButton			*btnOK;				// ID・パスワード入力OKボタン
    IBOutlet UIButton			*btnOK2;				// QROKボタン
    IBOutlet UIButton           *btnCancel;
    IBOutlet UIButton           *btnOption;         // 店舗オプション設定ボタン
    IBOutlet UILabel            *lblDocument;       // 店舗階層
#ifdef EASY_LOGIN
    IBOutlet UIView             *cameraRectView;    // カメラ枠
    IBOutlet UIView             *scanRectView;      // QRスキャンウィンドウ
    IBOutlet UILabel            *decodedLabel;
    IBOutlet UIButton           *btnQRstart;        // かんたん登録開始ボタン
    IBOutlet UIButton           *btnLoginStyle;     // ログインスタイル変更ボタン

    
    NSInteger                   PreCheckResult;     // ログイン前チェック結果
    NSString                    *accTYPE;           // アカウントタイプ
    NSString                    *accID;             // アカウントID
    NSString                    *accPWD;            // アカウントパスワード
    NSString                    *shopID;            // ショップID
    NSString                    *shopPWD;           // ショップパスワード
    NSString                    *accountName;       // アカウント名
    NSString                    *shopName;          // ショップ名
    NSString                    *errMsg0;
    NSString                    *errMsg1;
    BOOL                        isQRanalysis;
#endif
    
    BOOL                        isEasyLogin;        // かんたん登録か否か
    BOOL                        isQRLogin;          // QRコード使用のログインか？
    BOOL                        _isShopSupport;     // 店舗対応であるか？
	
}
@property (nonatomic, assign) id<AccountLoginPopUpDelegate> myDelegate;

#ifdef EASY_LOGIN
@property (nonatomic, strong) ZXCapture *capture;   // QRコードスキャン用
#endif

// 初期化 : superにて定義
/* - (id) initWithPopUpViewContoller:(NSUInteger)popUpID
 popOverController:(UIPopoverController*)controller 
 callBack:(id)callBackDelegate;*/

// 文字列変更 
- (IBAction) onChangeText:(id)sender;

// 編集終了
- (IBAction) onTextDidEnd:(id)sender;

// リターンキー
- (IBAction) onTextDidEndOnExit:(id)sender;

// 店舗オプションボタン
- (IBAction)onOption:(id)sender;

#ifdef EASY_LOGIN
// 簡単登録開始ボタン
- (IBAction)onQrReadStart:(id)sender;
// 登録スタイル変更ボタン
- (IBAction)onChageLoginStyle:(id)sender;
#endif
@end

@protocol AccountLoginPopUpDelegate <NSObject>

- (void)closeAccountLoginPopUp;     // ポップアップクローズ処理を行う

@end

