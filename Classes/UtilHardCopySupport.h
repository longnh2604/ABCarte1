//
//  UtilHardCopySupport.h
//  iPadCamera
//
//  Created by MacBook on 11/05/12.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

///
/// ハードコピーをサポートするユーティリティークラス
@interface UtilHardCopySupport : NSObject
{

}

// ハードコピープリントの開始
+ (void) startHardCopy:(CGRect)rect inView:(UIView *)view 
	 completionHandler:(UIPrintInteractionCompletionHandler)completionHandler;

// 画面キャプチャの取得
+ (UIImage*) getScreenCapture;

@end
