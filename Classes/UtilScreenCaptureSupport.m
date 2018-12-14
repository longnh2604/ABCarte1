//
//  UtilScreenCaptureSupport.m
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import "UtilScreenCaptureSupport.h"

#import "Common.h"

// renderInContextメソッドの警告防止のため
#import <quartzcore/quartzcore.h>

@implementation UtilScreenCaptureSupport

#pragma mark private_methods

// 画面キャプチャの取得
+ (UIImage*) getScreenCaptureWithDevState:(BOOL)isPortrate
{
	CGRect rect = [[UIScreen mainScreen] bounds];
    
	UIGraphicsBeginImageContext(rect.size); //コンテクスト開始
	UIApplication *app = [UIApplication sharedApplication];
	
	//#import <quartzcore/quartzcore.h>をしておかないとrenderInContextで警告が出る
	[app.keyWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
	// [app.keyWindow.layer drawInContext:UIGraphicsGetCurrentContext()];
	
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext(); //画像を取得してからコンテクスト終了
	
	// [img drawInRect:rect];
    
    NSLog(@"hard copy image size = %f X %f", img.size.width, img.size.height);
	
    if (isPortrate)
    {   return (img); }
    
    // Landscapeの場合、画像を回転させる
    
    CGSize cntxtSize	= CGSizeMake(rect.size.height, rect.size.width);
    CGPoint transPoint	= CGPointMake(rect.size.height, rect.size.width);
    CGFloat rtRadian	= M_PI_2;		// PI/2
    
    // グラフィックコンテキストを作成
	UIGraphicsBeginImageContext(cntxtSize);
	// contextを取得
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// 回転処理
	if (! CGPointEqualToPoint(transPoint, CGPointZero))
		CGContextTranslateCTM(context, transPoint.x, transPoint.y);
	CGContextScaleCTM(context, 1.0f, -1.0f);
	CGContextRotateCTM(context, rtRadian);
    
	// ImageRefの取得
	CGImageRef imgRef = img.CGImage;
	
	// CGContextへの描画
	CGContextDrawImage(context,
					   CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height),
					   imgRef);
	// 回転後のImageを取得
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
	
	return (image);
}

#pragma matk public_methods

// 画面キャプチャの開始
+ (UIImage*) startCaptureWithFlashContiner:(UIViewController*)viewCtrl
                           completeHandler:(UScrCaptureDone) hdr
{
    __block UIImage* image = nil;
    
    @try {
        
        // 一旦、確認用ダイアログから抜ける
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            
            // 画面キャプチャの取得
            image
                = [UtilScreenCaptureSupport getScreenCaptureWithDevState:viewCtrl.interfaceOrientation];
            
            // 画面をフラッシュする
            [Common flashViewWindowWithParentView:viewCtrl.view];
            
            // シャッター音を鳴らす
            [Common playSoundWithResouceName:@"shutterSound" ofType:@"mp3"];
            
            // 画像をカメラロールに保存する
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            
            if (hdr) {
                hdr(image);
            }
        });
    }
    @catch (NSException *exception) {
        NSLog(@"startCaptureWithFlashContiner: Caught %@: %@",
              [exception name], [exception reason]);
    }
        
    return (image);
}

@end
