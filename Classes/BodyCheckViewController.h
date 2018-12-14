//
//  BodyCheckViewController.h
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/CALayer.h>
#import "RadarChartView.h"
#import "sizeInfo.h"
#import "GoodsItem.h"
#import "MainViewController.h"
#import "iPadCameraAppDelegate.h"
#import "def64bit_common.h"
#import "userDbManager.h"
#import "OKDImageFileManager.h"
#import "ThumbnailViewController.h"
#import "HistListViewController.h"
#import "HistDetailViewController.h"
#import "grantFmdbManager.h"
#import "productM.h"
#import "brandM.h"

#import "courseItemBaseViewController.h"

typedef enum
{
    POPUP_NUMBER_INPUT          = 0x1000 ,      // 番号入力
    POPUP_GOODS_SELECT          = 0x2000 ,      // 商品選択
    POPUP_INTEGER_INPUT         = 0x3000 ,      // 整数入力
    POPUP_SIZE_SELECT           = 0x4000 ,      // 整数入力
}BODYCHECK_POPUP_ID;

typedef enum
{
    NOWSIZE_BUTTON       = 1,       // 現在サイズ
    IDEALSIZE_BUTTON     = 2,       // 理想サイズ
    SETSIZE_BUTTON       = 3        // 着衣サイズ
}BODYCHECK_TITLEBUTTON_TAG;

#define INTRODUSE_NAME_INVALID      @"（なし）"     // 紹介者の無効設定
#define PRDCT_VIEW_POS_X 20         //商品表示位置
#define PRDCT_VIEW_POS_Y 10
#define PRDCT_VIEW_POS_ADDX 175
#define PRDCT_VIEW_POS_ADDY 190
#define PRDCT_VIEW_SIZE_W 160       //商品表示ベースサイズ
#define PRDCT_VIEW_SIZE_H 180
#define PRDCT_IMG_SIZE_W 100        //商品画像サイズ
#define PRDCT_IMG_SIZE_H 100
#define PRDCT_TITLE_SIZE_W 150      //商品タイトルサイズ
#define PRDCT_TITLE_SIZE_H 20
#define PRDCT_SIZE_SIZE_W 60        //サイズのサイズ
#define PRDCT_SIZE_SIZE_H 20
#define PRDCT_NUM_SIZE_W 100        //個数のサイズ
#define PRDCT_NUM_SIZE_H 30
#define PRDCT_PRICE_SIZE_W 60       //価格のサイズ
#define PRDCT_PRICE_SIZE_H 20
#define SYOKEI_VIEW_POS_X 200       //小計の位置
#define SYOKEI_VIEW_POS_Y 388
#define SYOKEI_VIEW_SIZE_W 50       //小計のサイズ
#define SYOKEI_VIEW_SIZE_H 30
#define SYOKEI_VIEW_POS_X_ADD -20
#define ZEI_VIEW_POS_X 370          //消費税の位置
#define ZEI_VIEW_SIZE_W 50          //消費税のサイズ
#define ZEI_VIEW_SIZE_H 30
#define GOKEI_VIEW_POS_X 550        //合計の位置
#define GOKEI_VIEW_SIZE_W 50        //合計のサイズ
#define GOKEI_VIEW_SIZE_H 30
#define SYOKEI_VIEW_VALUE_SIZE_W 140
#define ITEMSEL_VIEW_POS_X 450      //選択中アイテムの位置
#define ITEMSEL_VIEW_POS_Y 5
#define ITEMSEL_VIEW_SIZE_W 250     //選択中アイテムのサイズ
#define ITEMSEL_VIEW_SIZE_H 30
#define FRAME_VIEW_SIZE_W 300       //ドラムのベースのサイズ
#define FRAME_VIEW_SIZE_H 400
#define PICKER_VIEW_SIZE_W 250      //ドラムのサイズ
#define PICKER_VIEW_SIZE_H 300
#define SETTEIBTN_POS_X 75          //ドラムの設定ボタンの位置
#define SETTEIBTN_POS_Y 350
#define SETTEIBTN_SIZE_W 65         //ドラムの設定ボタンのサイズ
#define SETTEIBTN_SIZE_H 30
#define CANCELBTN_POS_X 160         //ドラムの取消ボタンの位置
#define CANCELBTN_POS_Y 350

// @protocol courseItemDelegate;

@interface BodyCheckViewController: UIViewController <courseItemDelegate, UITextFieldDelegate,UIPickerViewDelegate,UIPickerViewDataSource>{
    IBOutlet    UIScrollView        *baseView;
    
    IBOutlet    RadarChartView      *radarChartView;
    IBOutlet    UIView      *propetyView;
    IBOutlet    UIView      *vwTitle;
    
    IBOutlet    UIView      *vwNameContiner;
    
    IBOutlet    UIView      *vwCourseItemContiner;
    
    //現在値変更
    IBOutlet    UIButton    *btnHeight;
    IBOutlet    UIButton    *btnWeight;
    IBOutlet    UIButton    *btnTopBreast;
    IBOutlet    UIButton    *btnUnderBreast;
    IBOutlet    UIButton    *btnWaist;
    IBOutlet    UIButton    *btnHip;
    IBOutlet    UIButton    *btnThigh;
    IBOutlet    UIButton    *btnHipHeight;
    IBOutlet    UIButton    *btnWaistHeight;
    IBOutlet    UIButton    *btnTopBreastHeight;
    
    //理想値表示
    IBOutlet    UILabel     *lblIdealHeight;
    IBOutlet    UILabel     *lblIdealWeight;
    IBOutlet    UILabel     *lblIdealTopBreast;
    IBOutlet    UILabel     *lblIdealUnderBreast;
    IBOutlet    UILabel     *lblIdealWaist;
    IBOutlet    UILabel     *lblIdealHip;
    IBOutlet    UILabel     *lblIdealThigh;
    IBOutlet    UILabel     *lblIdealHipHeight;
    IBOutlet    UILabel     *lblIdealWaistHeight;
    IBOutlet    UILabel     *lblIdealTopBreastHeight;

    //着用値
    IBOutlet    UIButton    *btnSetHeight;
    IBOutlet    UIButton    *btnSetWeight;
    IBOutlet    UIButton    *btnSetTopBreast;
    IBOutlet    UIButton    *btnSetUnderBreast;
    IBOutlet    UIButton    *btnSetWaist;
    IBOutlet    UIButton    *btnSetHip;
    IBOutlet    UIButton    *btnSetThigh;
    IBOutlet    UIButton    *btnSetHipHeight;
    IBOutlet    UIButton    *btnSetWaistHeight;
    IBOutlet    UIButton    *btnSetTopBreastHeight;
    
    
    IBOutlet    UIButton    *nowSizeShow;
    IBOutlet    UIButton    *setSizeShow;
    IBOutlet    UIButton    *idealSizeShow;

    IBOutlet    UIView      *goodsListBaseView;
    IBOutlet    UIView      *goodsListHiddenTagetView;
    IBOutlet    UIScrollView *goodsList;

    sizeInfo    *nowSize;
    sizeInfo    *setSize;
    sizeInfo    *idealSize;
    UIPopoverController		*numberInput;  // 数値入力ポップアップ
    
    //デモ用
    GoodsItem   *NipperBisuchie;
    IBOutlet    UILabel *nipperBisuchieName;
    IBOutlet    UILabel *nipperBisuchieColor;
    IBOutlet    UIButton *nipperBisuchieButton;
    IBOutlet    UIImageView *nipperBisuchieImage;
    IBOutlet    UILabel * nipperBisuchieSize;
    IBOutlet    UIButton *nipperBisuchieNumButton;
    IBOutlet    UILabel *NipperBisuchiePrice;
    IBOutlet    UIButton    *NipperBisuchieSizeBtn;

    GoodsItem   *HighWaistGirdle;
    IBOutlet    UILabel *HighWaistGirdleName;
    IBOutlet    UILabel *HighWaistGirdleColor;
    IBOutlet    UIButton *HighWaistGirdleButton;
    IBOutlet    UIImageView *HighWaistGirdleImage;
    IBOutlet    UILabel * HighWaistGirdlSize;
    IBOutlet    UIButton *HighWaistGirdleNumButton;
    IBOutlet    UILabel *HighWaistGirdlePrice;
    IBOutlet    UIButton    *HighWaistGirdleSizeBtn;

    
    GoodsItem   *TBackBodySuit;
    IBOutlet    UILabel *TBackBodySuitName;
    IBOutlet    UILabel *TBackBodySuitColor;
    IBOutlet    UIButton *TBackBodySuitButton;
    IBOutlet    UIImageView *TBackBodySuitImage;
    IBOutlet    UILabel * TBackBodySuitSize;
    IBOutlet    UIButton *TBackBodySuitNumButton;
    IBOutlet    UILabel *TBackBodySuitPrice;
    IBOutlet    UIButton    *TBackBodySuitSizeBtn;

    
    GoodsItem   *TBackShorts;
    IBOutlet    UILabel *TBackShortsName;
    IBOutlet    UILabel *TBackShortsColor;
    IBOutlet    UIButton *TBackShortsButton;
    IBOutlet    UIImageView *TBackShortsImage;
    IBOutlet    UILabel * TBackShortsSize;
    IBOutlet    UIButton *TBackShortsNumButton;
    IBOutlet    UILabel *TBackShortsPrice;
    IBOutlet    UIButton    *TBackShortsSizeBtn;


    GoodsItem   *CoolbizTrencker;
    IBOutlet    UILabel *CoolbizTrenckerName;
    IBOutlet    UILabel *CoolbizTrenckerColor;
    IBOutlet    UIButton *CoolbizTrenckerButton;
    IBOutlet    UIImageView *CoolbizTrenckerImage;
    IBOutlet    UILabel * CoolbizTrenckerSize;
    IBOutlet    UIButton *CoolbizTrenckerNumButton;
    IBOutlet    UILabel *CoolbizTrenckerPrice;
    IBOutlet    UIButton    *CoolbizTrenckerSizeBtn;


    IBOutlet    UILabel *sumPrice;

    UIPopoverController		*goodsSelector;  // 商品選択ポップアップ
    UIPopoverController     *sizeSelector;  //サイズ選択
    
    NSMutableArray          *goodsItems;
    
    IBOutlet    UITextField *txtCustomerName;   // お名前
    IBOutlet    UITextField *txtAdviser;        // アドバイザー
    IBOutlet    UITextField *txtIntroduces;     // 紹介者
    IBOutlet    UITextField *txtNowDate;        // 現在日付の表示
    
    IBOutlet    UIButton    *btnHardCopy;
    
    IBOutlet    UIButton    *btnBrand;
    IBOutlet    UIButton    *btnCourse2;
    IBOutlet    UIButton    *btnCourse3;
    IBOutlet    UIButton    *btnCourse4;
    IBOutlet    UIButton    *btnCourse5;
    
    IBOutlet    UIButton    *btnNormalSize;
    IBOutlet    UIButton    *btnLargeSize;
    IBOutlet    UIButton    *btnSpeceialSize;
    
    UIView					*flashView;					// 画像保存時のflashView
    USERID_INT              _userID;				    // ユーザID
    HISTID_INT              _histID;                    // 履歴ID
    NSString                *_selectedUserName;         // 選択されたユーザ名
    UIScrollView            *prdctScrollView;           // 商品表示
    UIView                  *overlayView;
    UIView                  *frameView;
    grantFmdbManager        *gfManager;
    NSMutableArray          *brandList;
    NSMutableArray          *prdctList;
    UIPickerView            *picker;
    NSInteger               selectedBrandIdx;           //選択中のブランド
    NSInteger               selectedPrdctIdx;           //選択中の商品
    UILabel                 *syokei;                    //小計
    UILabel                 *zei;                       //税額
    UILabel                 *gokei;                     //合計
    UILabel                 *itemSel;                   //選択状態
    NSInteger               grantPrdctVer;
    UIActivityIndicatorView *indicator;
    UIView *loadingViewGround;
    UIView *loadingView;
    UIActivityIndicatorView *_indicator;
    UILabel *msgLabel;
    BOOL inputFlag;
}
@property(nonatomic)			NSInteger	_selectedUserID;
//@property(nonatomic)			NSInteger	histID;
@property                       BOOL	    IsNavigationCall;				// 本画面がnavigationControllerよりコールされたか
@property(nonatomic, copy)			NSString	*selectedUserName;

- (void)setSelectedUser:(NSInteger)userID;

- (void)setButtonState:(UIButton *)selectButton;
- (void)setIdeal:(CGFloat)height;

- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object;

// ユーザー情報の設定
- (void)setUser:(USERID_INT)userID;
- (void)setUserName:(NSString*)userName;

// 現在日付の設定
-(void) setNowDate;

@end
