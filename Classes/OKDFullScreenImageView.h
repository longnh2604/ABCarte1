//
//  OKDFullScreenImageView.h
//  iPadCamera
//
//  Created by MacBook on 10/09/08.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// 全画面表示を行うViewクラス

@interface OKDFullScreenImageView : UIView {
	
@package
	
	UIButton	*btnSelected;						//選択ボタン
	UIImageView	*imgView;							//Image表示
		
	BOOL		isImagePortrait;					// 設定されたImageが縦型(Portrait)か
}

// 親Viewを指定して初期化
- (id) initWithParent:(UIView*)parent;

// ImageのContenModeの設定
-(void)setImageContentMode:(UIViewContentMode)mode;
// Imageの設定
-(void) setImage:(UIImage*)img;
// 表示更新（画面回転時）
-(void) refresh:(BOOL)isPortrait;
// 本画面を消去する
-(void) hideFullScreenImageView;

@end

// 全画面表示のImageをフィットさせるViewクラス
@interface OKDFullScreenFitImageView: OKDFullScreenImageView

@end