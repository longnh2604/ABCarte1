//
//  OverlayViewSettingPopup.h
//  iPadCamera
//
//  Created by MacBook on 11/07/13.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectPopUp.h"

@protocol OverlayViewSettingPopupDelegate;

#ifdef VER150_LATER
#define		GUIDE_LINE_NUMS_MAX			10				// ガイド線の最大本数（１から10まで連続）
#else
#define		GUIDE_LINE_NUMS_MAX			13				// ガイド線の最大本数（１から13まで連続）
#endif

///
/// 重ね合わせ画像設定ポップアップViewController
///
@interface OverlayViewSettingPopup : UIViewController  
<
//UIPickerViewDelegate, UIPickerViewDataSource,
SelectPopUpDelegate
>
{
    IBOutlet UILabel                *lblTimeValue;      // 自動停止時間
    IBOutlet UISlider               *sliderTime;        // 自動停止時間設定スライダー
    IBOutlet UILabel                *lblTimeTitle;      // 自動停止時間タイトル
    IBOutlet UILabel                *lblMaxTimeValue;   // 最大録画時間
    IBOutlet UISlider               *sliderMaxTime;     // 最大録画時間設定スライダー
    IBOutlet UILabel                *lblMaxTimeTitle;   // 最大録画時間タイトル
    IBOutlet UILabel                *lblCapacityValue;  // ローカル保存容量
    IBOutlet UISlider               *sliderCapacity;    // ローカル保存容量設定スライダー
    IBOutlet UILabel                *lblCapacityTitle;  // ローカル保存容量タイトル
	IBOutlet UILabel				*lblTitle;			// ポップアップのタイトル
	IBOutlet UISlider				*sliderAlpha;		// 透過率のスライダー
	IBOutlet UILabel				*lblAlphaValue;		// 透過率の表示:[%]
    IBOutlet UILabel                *lblAhphaTitle;     // 透過率のタイトル
//	IBOutlet UIPickerView			*pkvwGuideLineNums;	// ガイド線本数にPickerView
    IBOutlet UIButton               *btnGuideLineNums;  // ガイド線本数設定ボタン
    IBOutlet UILabel                *lblGuideLineNums;
	IBOutlet UISwitch				*swWithOverlaySave;	// 重ね合わせ画像も一緒に保存するか？スイッチ
    IBOutlet UILabel                *lblOverlaySave;    // 重ね合わせ画像のラベル
	IBOutlet UISwitch				*swWithGuideSave;	// ガイド線も一緒に保存するか？スイッチ
    IBOutlet UILabel                *lblGuideSave;      // ガイド線も保存のラベル
    IBOutlet UISegmentedControl     *segPicResolution;  // 写真解像度
    IBOutlet UILabel                *lblPicResolution;  // 写真解像度
    IBOutlet UILabel                *lblPicResDocument; // 写真解像度についての説明
    IBOutlet UILabel                *lblGuideLine;
    IBOutlet UILabel                *lblGuideLineValue;
    IBOutlet UISlider               *sliderGuideLine;
    
    UILabel                         *lblCamRotate;      // カメラ画像回転角
    UIButton                        *btnCamRotate;
    UILabel                         *lblCamResolution;  // カメラ画像解像度
    UIButton                        *btnCamResolution;
    UISegmentedControl              *segCamResolution;

	CGFloat                         _maxRecTime;        // 最大録画時間
    CGFloat                         _maxDuration;       // 規定時間
    CGFloat                         _localCapacity;     // ローカル保存容量
    NSInteger                       _webCamRotate;
    NSInteger                       _webCamResolution;
    
    // 初期化時に設定される変数
	CGFloat							_viewAlpha;			// 透過率:0.0から1.0
	NSInteger						_guideLineNums;		// ガイド線本数
	BOOL							_isWithOverlaySave;	// 重ね合わせ画像も一緒に保存するか？
	BOOL							_isWithGuideSave;	// ガイド線も一緒に保存するか？
    
    NSString                        *_lblText;
    NSInteger                       _mode;
	
	UIPopoverController             *popoverController;
    
    NSArray                         *rotateArray;
    NSArray                         *resolutionArray;
    
    BOOL                            isiPad2;            // iPad2か？
}

@property(nonatomic)	CGFloat	maxRecTime;
@property(nonatomic)	CGFloat	maxDuration;
@property(nonatomic)	CGFloat	localCapacity;
@property(nonatomic)	CGFloat	viewAlpha;
@property(nonatomic)	NSInteger guideLineNums;
@property(nonatomic, readonly)	BOOL isWithOverlaySave;
@property(nonatomic, readonly)	BOOL isWithGuideSave;
@property(nonatomic)    NSInteger camResolution;        // iPadカメラ写真解像度(H/M/L)
@property(nonatomic)    NSInteger webCamRotate;         // Sonyカメラ画像回転角
@property(nonatomic)    NSInteger webCamResolution;     // Sonyカメラ写真解像度

@property(nonatomic, retain)		UIPopoverController* popoverController;
@property(nonatomic, assign)    id <OverlayViewSettingPopupDelegate> delegate;

// 初期化
- (id) initWithSetParams:(CGFloat)alpha guideLineNums:(NSInteger)nums
	   isWithOverlaySave:(BOOL)isWith
		 isWithGuideSave:(BOOL)isWithGuide
           camResolution:(NSInteger)resolution
                 lblText:(NSString *)lblText
                    mode:(NSInteger)mode
	   popOverController:(UIPopoverController*)controller
		callBackDelegate:(id)callBack;
- (IBAction)OnSliderMaxTimeValueChange:(id)sender;
- (IBAction)OnSliderTimeValueChange;
- (IBAction)OnSliderLocalCapacityValueChange;
// 透過率スライダーの値変更イベント
- (IBAction) OnSliderAlphaValueChange:(UISlider*)sender;
- (IBAction) OnSliderGuideLineValueChange:(UISlider*)sender;

// 重ね合わせ画像も一緒に保存する変更イベント
- (IBAction) OnWithOverlaySaveValueChange:(UISwitch*)sender;
// ガイド線も一緒に保存する変更イベント
- (IBAction) OnWithGuideSaveValueChange:(UISwitch*)sender;

- (IBAction)OnGuideLineNum:(id)sender;

@end


// 重ね合わせ画像設定ポップアップViewControllerのイベント
@protocol OverlayViewSettingPopupDelegate<NSObject>
@optional
// 透過率の設定
- (void)OverlayView:(OverlayViewSettingPopup*)sender OnAlphaChange:(CGFloat)alpha;
// ガイド線本数の設定
- (void)OverlayView:(OverlayViewSettingPopup*)sender OnGuideLineNumsChange:(NSInteger)nums;
// 本Popupを閉じる時
- (void)OverlayViewOnClose:(OverlayViewSettingPopup*)sender;

- (void)OverlayView:(OverlayViewSettingPopup*)sender OnGuideLineAlphaChange:(CGFloat)alpha;

@end
