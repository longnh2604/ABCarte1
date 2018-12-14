//
//  QRCodeViewController.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/04/18.
//
//

/*
 IMPORT
 */
#import <UIKit/UIKit.h>
#import "ZXingObjC.h"

/*
 ENUM
 */
enum QRCodeCarrier
{
	QR_CARRIER_DEFAULT,		// デフォルト設定
	QR_CARRIER_SMARTPHONE,	// スマホとか
	QR_CARRIER_DOCOMO,		// docomo携帯向け
	QR_CARRIER_AU,			// au携帯向け
	QR_CARRIER_SOFTBANK,	// softbank携帯向け
};

/*
 DEFINE
 */
#define MAIL_ADDRESS @"qrmail@abcarte.net"


/*
 INTERFACE
 */
@interface QRCodeViewController : UIViewController

/**
 初期化する
 @param userId ユーザーID
 @param delegate デリゲート
 @return 自身のポインタ
 */
- (id) initWithUserId:(NSInteger)userId Delegate:(id) delegate;

/**
 QRコード作成
 @param userId ユーザーID
 @param delegate デリゲート
 @return YES:成功 NO:失敗
 */
- (BOOL) createQRCodeWithUserId:(NSInteger)userId Delegate:(id)delegate;

@end


/*
 PROTOCOL
 */
@protocol QRCodeViewControllerDelegate <NSObject>

/**
 QRコードが表示された際に呼び出される
 @param sender 送信元
 @param userId ユーザーID
 */
- (void) OnQRCodeFinished:(id)sender UserId:(NSInteger)userId;

@end