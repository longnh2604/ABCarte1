//
//  UtilHardCopySupport.m
//  iPadCamera
//
//  Created by MacBook on 11/05/12.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "UtilHardCopySupport.h"
#import "PrintPhotoPageRenderer.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "Common.h"

#import "MainViewController.h"

@implementation UtilHardCopySupport

#pragma mark local_methods

// 現在のデバイスの向きを取得
+ (UIInterfaceOrientation) getNowDeviceOrientation
{
	UIInterfaceOrientation orient;
	
	switch ([UIDevice currentDevice].orientation)
	{
		case UIDeviceOrientationPortrait:
			orient = UIInterfaceOrientationPortrait;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			orient = UIInterfaceOrientationPortraitUpsideDown;
			break;
		case UIDeviceOrientationLandscapeLeft:
			orient = UIInterfaceOrientationLandscapeLeft;
			break;
		case UIDeviceOrientationLandscapeRight:
			orient = UIInterfaceOrientationLandscapeRight;
			break;
		default:
			orient = UIInterfaceOrientationPortrait;
			break;
	}
	
	return (orient);
}

// 現在のデバイスの向きが横向きか
+ (BOOL) isDeviceLandscape
{
	UIInterfaceOrientation orient 
		= [UtilHardCopySupport getNowDeviceOrientation];
	
	return ( (orient == UIInterfaceOrientationLandscapeLeft) ||
			 (orient == UIInterfaceOrientationLandscapeRight) );
}

// 画面キャプチャの取得
+ (UIImage*) getScreenCapture
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
	
    if ([MainViewController isNowDeviceOrientationPortrate])
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

#pragma mark UIPrintInteractionControllerDelegate
+ (void)printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController *)printInteractionController
{
	
}

#pragma mark public_methods_static

// ハードコピープリントの開始
+ (void) startHardCopy:(CGRect)rect inView:(UIView *)view 
	 completionHandler:(UIPrintInteractionCompletionHandler)completionHandler
{
	// Obtain the shared UIPrintInteractionController
	UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
	if(!controller){
		NSLog(@"Couldn't get shared UIPrintInteractionController!");
		return;
	}
	
	// We need a completion handler block for printing.
	if (! completionHandler)
	{
		completionHandler 
			= ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) 
				{
					if(completed && error)
						NSLog(@"FAILED! due to error in domain %@ with error code %ld",
								error.domain, (long)error.code);
				};
	}
	
	// Obtain a printInfo so that we can set our printing defaults.
	UIPrintInfo *printInfo = [UIPrintInfo printInfo];
		// UIImage *image = ((UIImageView *)self.view).image;
  	
	// This application prints photos. UIKit will pick a paper size and print
	// quality appropriate for this content type.
	printInfo.outputType = UIPrintInfoOutputGeneral; //UIPrintInfoOutputPhoto
	// The path to the image may or may not be a good name for our print job
	// but that's all we've got.
	printInfo.jobName = @"CaLuLu_print";
	
	// If we are performing drawing of our image for printing we will print
	// landscape photos in a landscape orientation.
	// if(!controller.printingItem && image.size.width > image.size.height)
	// if ([UtilHardCopySupport isDeviceLandscape])
		// printInfo.orientation = UIPrintInfoOrientationLandscape;
    // 印字方向の設定 : デバイスの向きで決定
    printInfo.orientation = ([MainViewController isNowDeviceOrientationPortrate])?
        UIPrintInfoOrientationPortrait : UIPrintInfoOrientationLandscape;
	
	// Use this printInfo for this print job.
	controller.printInfo = printInfo;
	
	//  Since the code below relies on printingItem being zero if it hasn't
	//  already been set, this code sets it to nil. 
	controller.printingItem = nil;
	
	// If we aren't doing direct submission of the image or for some reason we don't
	// have an ALAsset or URL for our image, we'll draw it instead.
	if(!controller.printingItem){
		// Create an instance of our PrintPhotoPageRenderer class for use as the
		// printPageRenderer for the print job.
		PrintPhotoPageRenderer *pageRenderer = [[PrintPhotoPageRenderer alloc]init];
		// The PrintPhotoPageRenderer subclass needs the image to draw. If we were taking 
		// this path we use the original image and not the fullScreenImage we obtained from 
		// the ALAssetRepresentation.
		
		// pageRenderer.imageToPrint = ((UIImageView *)self.view).image;
		// 画面キャプチャの取得
		pageRenderer.imageToPrint = [UtilHardCopySupport getScreenCapture];
		controller.printPageRenderer = pageRenderer;
		[pageRenderer release];
	}
	
	// controller.delegate = delegate;
	
	// The method we use presenting the printing UI depends on the type of 
	// UI idiom that is currently executing. Once we invoke one of these methods
	// to present the printing UI, our application's direct involvement in printing
	// is complete. Our delegate methods (if any) and page renderer methods (if any)
	// are invoked by UIKit.
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[controller presentFromRect:rect inView:view animated:YES completionHandler:completionHandler];  // iPad
	}else
		[controller presentAnimated:YES completionHandler:completionHandler];  // iPhone
}

@end
