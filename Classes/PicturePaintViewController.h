//
//  PicturePaintViewController.h
//  iPadCamera
//
//  Created by MacBook on 11/03/03.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIFlickerButton.h"
#import "MailSendPopUp.h"
#import "SetUpSmtpPopUp.h"
#import "def64bit_common.h"

@class PicturePaintManagerView;
@class PicturePaintPalletView;

@interface PicturePaintViewController : UIViewController
<
UIFlickerButtonDelegate,
PopUpViewContollerBaseDelegate,UIPopoverPresentationControllerDelegate
>
{
	// タイトル関連
	IBOutlet UILabel		  *lblUserName;				// ユーザ名
	IBOutlet UILabel		  *lblWorkDate;				// 施術日
	IBOutlet UILabel		  *lblWorkDateTitle;	    // 施術日タイトル
	IBOutlet UIView			  *viewUserNameBack;		// ユーザ名背景
	IBOutlet UIView			  *viewWorkDateBack;		// 施術日背景
	
	IBOutlet UIButton		  *btnLockMode;				// ロックモード切り替えボタン
	IBOutlet UIButton		  *btnHardCopyPrint;			// ハードコピーボタン
	
	// 以下はスクロールするView群となる：この順が構成順序となる
	IBOutlet UIScrollView	  *myScrollView;				// スクロールビュー
	IBOutlet UIView			  *vwScrollConteiner;			// スクロールのコンテナView
	// IBOutlet UIView			*vwPictureConteiner;		// 写真のコンテナView
	IBOutlet PicturePaintManagerView *vwPaintManager;	// 写真描画の管理View	:lockモードのみ有効
	IBOutlet UIFlickerButton  *btnFlick;				// フリックボタン		:unlockモードのみ有効
	IBOutlet UIView			  *vwSaparete;				// 区分線				:lockモードのみ表示
	IBOutlet UIView			  *vwGrayOut1;				// グレイアウトView-1	:lockモードのみ表示
	IBOutlet UIView			  *vwGrayOut2;				// グレイアウトView-2	:lockモードのみ表示
	IBOutlet UIImageView	  *imgvwPicture;			// 写真ImageView		:常に表示
	IBOutlet UIButton		  *btnSave;					// 保存ボタン
    IBOutlet UIButton		  *btnMail;					// メールボタン
    IBOutlet UIView           *vwStampE;
	IBOutlet UIImageView      *imgvwStamp;
    
	// パレット
	PicturePaintPalletView	*vwPaintPallet;				// パレット:InterfaceBuilderを使用しない
	
	BOOL	_isModeLock;								// ロックモード：YES
	BOOL	_isRotated;									// 回転されたか
	BOOL	_isSaved;									// 合成画像が保存されたか
	
	USERID_INT		_userID;							// ユーザID
	HISTID_INT		_histID;                            // 履歴ID（画像合成ビューで必要）
	UIImage	*_pictImageMixed;							// 合成済み画像
	UIAlertView *modifyCheckAlert;						// 修正確認Alertダイアログ
	NSUInteger	_modifyCheckAlertWait;					// 修正確認Alertダイアログ終了待機
	
	UIView					*flashView;					// 画像保存時のflashView
	
	UInt32					_shutterSoundID;			// シャッター音のID
    
    UIPopoverController		*popoverCntlMailSend;		// Mail送信用ポップアップコントローラ
    MailSendPopUp           *vcMailSend;                // Mail送信ポップアップ
    
    NSMutableString         *lastSavedFilename;         // 最後に保存したファイル名
    
    BOOL                    memWarning;                 // メモリワーニング
    UInt32                  angle;                      // 画像の角度
    float                   width;                      // 画像の横
    float                   height;                     // 画像の縦
}

@property		BOOL	IsNavigationCall;				// 本画面がnavigationControllerよりコールされたか
@property		BOOL	IsCompViewSkipped;				// 画像合成画面がスキップされたか
@property		BOOL	IsCompViewDirty;				// 合成画像が編集（ズームまたはスクロール）を行ったフラグ
@property		BOOL	IsUpdown;                       // 上下比較かどうか

// ロックモード切り替えボタン
- (IBAction) OnBtnLockMode:(id)sender;
// ハードコピー
- (IBAction)OnHardCopyPrint;
// 画像保存ボタン
- (IBAction)OnSaveImage:(id)sender;
//メール送信ボタンイベント
- (IBAction)OnImageMail:(id)sender;
// 初期化
//	picture:写真Image  userName:対象ユーザ名  nameColor:ユーザ名の色 workDate:施術日（nil可：その場合は表示されない）
- (void)initWithPicture:(UIImage*)picture userName:(NSString*)name nameColor:(UIColor*)color workDate:(NSString*)date;

// ユーザー情報の設定
- (void)setUser:(USERID_INT)userID;
- (void)setWorkItemInfo:(USERID_INT)userID workItemHistID:(HISTID_INT)histID;

// mail機能の有効
- (void) setMailEnableIsFlag:(BOOL)isEnable;

//スタンプを真ん中に配置 //DELC SASAGE
- (void) setStampFromImage:(UIImage *)image;
//スタンプ選択画面のスタンプを全て、未選択状態に //DELC SASAGE
- (void) setStampsUnselected;
// アプリがスリープされた時に、一旦メモりワーニングフラグをクリアする
- (void)willResignActive;
// 縦横の切り替え
- (void) changeToPortrait:(BOOL)isPortrait;
// 画像の回転
- (void)rotateImage;

@end
