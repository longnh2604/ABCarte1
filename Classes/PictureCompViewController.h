//
//  PictureCompViewController.h
//  iPadCamera
//
//  Created by 管理者 on 11/06/17.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "MainViewController.h"
#import "GrayOutImageView.h"
#import "def64bit_common.h"
#import "OKDClickImageView.h"
#import "UIFlickerButton.h"

// 2012 6/26 伊藤 余白サイズの拡大
#define INIT_IMAGE_SCALE       1.0f				// 画像初期倍率(背景の黒色が余白となる)
// サムネイルitemの幅
#define ITEM_WITH_COMP	54.0f
// サムネイルitemの高さ
#define ITEM_HEIGHT_COMP	45.0f
#define IPAD2_MAX_SIZE      1280

// 制御パレットボタンのコマンド（ボタン種別）
//typedef enum
//{
//	PALLET_SEPARATE_ON	= 0,		// 区分線あり
//	PALLET_SEPARATE_OFF,			// 区分線なし
//	PALLET_LEFT_TURN	= 0x101,	// 左側画像反転
//	PALLET_RIGHT_TURN,				// 右側画像反転
//	PALLET_SAVE			= 0x201,	// 保存
//} PALLET_CTRL_BUTTON;

@class PicturePaintPalletView;

@interface PictureCompViewController : UIViewController 
	<OKDClickImageViewDelegate,MainViewControllerDelegate,UIFlickerButtonDelegate>
{

	// タイトル関連
	IBOutlet UILabel		*lblUserName;				// ユーザ名
	IBOutlet UILabel		*lblWorkDate;				// 施術日
	IBOutlet UILabel		*lblWorkDateTitle;			// 施術日タイトル
	IBOutlet UIView			*viewUserNameBack;			// ユーザ名背景
	IBOutlet UIView			*viewWorkDateBack;			// 施術日背景
	
	// ボタン
	IBOutlet UIButton		*btnLockMode;				// ロックモード切り替えボタン
	IBOutlet UIButton		*btnToolBarShow;			// コンテナView表示カスタムボタン

	// 以下はスクロールするView群となる：この順が構成順序となる
    IBOutlet UIImageView    *backGroundView;            // 透過合成時の黒背景
	IBOutlet UIScrollView	*myScrollView1;				// スクロールビュー1
	IBOutlet UIScrollView	*myScrollView2;				// スクロールビュー2
	IBOutlet UIView			*vwSaparete;				// 区分線				:lockモードのみ表示
	GrayOutImageView		*imgvwPicture1;				// 写真ImageView1		:常に表示
	GrayOutImageView		*imgvwPicture2;				// 写真ImageView2		:常に表示
	
	// 制御パレット
	IBOutlet UIView			*vwCtrlPallet;				// 制御パレットビュー
	IBOutlet UIButton		*btnSeparateOn;				// 区分線ありボタン
	IBOutlet UIButton		*btnSeparateOff;			// 区分線なしボタン
	IBOutlet UIButton		*btnLeftTurn;				// 左側画像反転ボタン
	IBOutlet UIButton		*btnRightTurn;				// 右側画像反転ボタン
    IBOutlet UIButton		*btnLeftTurn2;				// 左側画像反転ボタン : 透過画像用
	IBOutlet UIButton		*btnRightTurn2;				// 右側画像反転ボタン : 透過画像用

    // 2012 7/12 透過レイヤーコントローラー
	IBOutlet UIView			*vwSynthesisCtrlPallet;		// 制御パレットビュー
	IBOutlet UIButton		*btnBackOn;                 // 背後ビュー操作
	IBOutlet UIButton		*btnFrontOn;                // 全面ビュー操作
	IBOutlet UISlider		*sldRatio;                  // 透過度スライダー

	//UIImage	*_pictImage1;								// 画像1
	//UIImage	*_pictImage2;								// 画像2
	//UIImage	*_pictImageMixed;							// 合成済み画像
	
	BOOL	_isModeLock;								// ロックモード：YES
	BOOL	_isPicturePaintDisplaied;					// 写真描画に遷移したか
	BOOL	_isToolBar;									// 制御パレットビューとお客様情報を表示中か
	BOOL	_isSkipThisView;							// 本ViewControllerをスキップするか

	USERID_INT		_userID;							// ユーザID
	HISTID_INT		_histID;							// 履歴ID
	IBOutlet UIImageView	*imgvwTest;					// TEST
	UIView	*skippedBackgroundView;						// 背景View(画面スキップ時に表示される)
	
	UIInterfaceOrientation	_toInterfaceOrientation;	// 回転する予定のデバイスの向き
	
	BOOL	_isDirty;									// 編集（ズームまたはスクロール）を行ったフラグ
    BOOL    LastRotated;                                // 前回の回転
    
    CGSize  picOrgSize1;
    CGSize  picOrgSize2;
    
    BOOL    memWarning;                                 // メモリワーニングが出ているか
    BOOL    sel1st_2nd;                                 // 透過合成時に選択されているView
    
    NSMutableArray *pictImageItems;						// 画像Imageのリスト：UIImage*のリスト
    NSMutableArray *errorTags;                          // 読み込みエラーの起きた画像のtagID
    NSMutableArray* imagePointList;                     // モーフィング用画像イメージ座標リスト
    NSMutableArray* imageScaleList;                     // モーフィング用画像イメージ倍率リスト
    NSMutableArray *realImageList;// モーフィング用画像イメージリスト
    
    BOOL                    isiPad2;                    // iPad2か？
    NSInteger               selectedImageID;			// モーフィングモードにて選択中の画像
    NSUInteger              selectedImageIndex;            // モーフィング選択モードにて選択中の画像
    float                   beforeValue;                // 全開のスライダー位置
    NSInteger               activeImgView;              // 前面に出てるイメージビュー
    
    UIAlertView *modifyCheckAlert;                        // 修正確認Alertダイアログ
    NSUInteger    _modifyCheckAlertWait;                    // 修正確認Alertダイアログ終了待機
    BOOL                    isModify;                   //編集モードに切り替えたか
}

// パス情報なども含めた画像リストの設定
- (void)setPictImageItems:(NSMutableArray*)images;

// サムネイルの位置調整
- (void)setCoordinateThumbnailList;
// ロックモード切り替えボタン
- (IBAction) OnBtnLockMode:(id)sender;

// picture1:写真Image1  pictureImage2:写真Image2  userName:対象ユーザ名  nameColor:ユーザ名の色 workDate:施術日（nil可：その場合は表示されない）
- (void)initWithPicture:(UIImage*)picture1 pictureImage2:(UIImage*)picture2 userName:(NSString*)name nameColor:(UIColor*)color workDate:(NSString*)date;

// 施術情報の設定
- (void)setWorkItemInfo:(USERID_INT)userID workItemHistID:(HISTID_INT)histID;

// 制御パレットボタン
- (IBAction)OnBtnCtrlPallet:(id)sender;

// コンテナViewとユーザ名の表示ボタン（横表示のみ）
- (IBAction)onShowToolBar;

// レイアウトを設定する
//- (void)setLayout;

// スキップ設定
- (void)setSkip:(BOOL)skip;

// 画像描画画面からの戻りを通知
- (void)backFromPicturePaintView;

// アプリがスリープされた時に、一旦メモりワーニングフラグをクリアする
- (void)willResignActive;

@property (nonatomic, retain) UIImage*	_pictImage1;		// 画像1
@property (nonatomic, retain) UIImage*	_pictImage2;		// 画像2

@property (nonatomic, retain) UIImage*	_pictImageMixed;	// 合成済み画像
@property		BOOL	IsSetLayout;						// レイアウト調整を行うか
@property		BOOL	IsNavigationCall;					// 本画面がnavigationControllerよりコールされたか
@property		BOOL	IsRotated;							// 回転されたかどうか

//
@property		BOOL	IsOverlap;							// 透過オーバーラップモードかどうか
@property		BOOL	IsUpdown;							// 上下比較かどうか
@property       BOOL    IsvwSaparate;                       // 突き合わせ時の分割線のON/OFF
@property		BOOL	IsMorphing;							// モーフィングモードかどうか

@end
