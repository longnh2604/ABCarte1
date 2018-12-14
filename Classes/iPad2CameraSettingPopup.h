//
//  iPad2CameraSettingPopup.h
//  iPadCamera
//
//  Created by MacBook on 11/05/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PopUpViewContollerBase.h"

// キャプチャ速度の定数値
typedef enum
{
	IPAD2_CAM_CAPTURE_LOW		= 8,
	IPAD2_CAM_CAPTURE_MIDDLE	= 20,
    //2015/11/2 TMS キャプチャ速度が異常値であったため、修正
	IPAD2_CAM_CAPTURE_HIGH		= 30,
} IPAD2_CAM_SET_CAPTURE_SPEED;

///
/// iPad内蔵カメラの設定用popupコントローラ
///
@interface iPad2CameraSettingPopup : PopUpViewContollerBase 
{
	IBOutlet UILabel				*lblTitle;			// ポップアップのタイトル
	IBOutlet UISwitch				*swIsHandVib;		// 手ぶれ補正の有効／無効
	IBOutlet UITextField			*txtDelayTime;		// 手ぶれ補正速度[秒]
	IBOutlet UISegmentedControl		*segCapSpeed;		// キャプチャ速度
    IBOutlet UIButton               *btnOk;             // 登録ボタン
    IBOutlet UIButton               *btnCancel;         // 取消ボタン

	BOOL							isHandVib;			// 手ぶれ補正の有効／無効
	NSInteger						delayTime;			// 手ぶれ補正速度[秒]
	IPAD2_CAM_SET_CAPTURE_SPEED		captureSpeed;		// キャプチャ速度
}

@property(nonatomic) BOOL	isHandVib;
@property(nonatomic) NSInteger	delayTime;
@property(nonatomic) IPAD2_CAM_SET_CAPTURE_SPEED captureSpeed;

// 手ぶれ補正の有効／無効
- (IBAction)onIshancVid:(id)sender;

// 手ぶれ補正速度TextFieldのEnterキーイベント
- (IBAction)onTextDidEnd:(id)sender;

// 初期化
- (id) initWithSetParams:(NSUInteger)popUpID 
	   popOverController:(UIPopoverController*)controller 
				callBack:(id)callBackDelegate
			   isHandVid:(BOOL)isHandVid 
			   delayTime:(NSInteger)time 
			captureSpeed:(IPAD2_CAM_SET_CAPTURE_SPEED)speed;

@end
