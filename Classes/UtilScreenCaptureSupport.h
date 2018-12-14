//
//  UtilScreenCaptureSupport.h
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import <Foundation/Foundation.h>


// ダイアログ表示のイベントハンドラ定義
typedef void (^UScrCaptureDone)(UIImage *img);

///
/// 画面のスクリーンキャプチャをサポートするユーティリティークラス
///
@interface UtilScreenCaptureSupport : NSObject

// 画面キャプチャの開始
+ (UIImage*) startCaptureWithFlashContiner:(UIViewController*)viewCtrl
                           completeHandler:(UScrCaptureDone) hdr;
+ (UIImage*) getScreenCaptureWithDevState:(BOOL)isPortrate;
@end
