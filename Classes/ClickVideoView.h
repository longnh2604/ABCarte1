//
//  OKDClickImageView.h
//  iPadCamera
//
//  Created by MacBook on 10/09/08.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@protocol ClickVideoViewDelegate;

#import <UIKit/UIKit.h>
#import "MovieResource.h"
#import "SimplePlayer.h"

#ifndef SELECT_NUMBER_SIZE
#ifdef CALULU_IPHONE
#define	SELECT_NUMBER_SIZE			18.0f		// 選択番号のサイズ
#else
#define	SELECT_NUMBER_SIZE			32.0f		// 選択番号のサイズ
#endif
#endif

#define SELECT_NUMBER_SHIFT_BIT		16			// 選択番号のビットシフト位置：　selectNum << 16 | FLICK_NEXT_PREV_VIEW

@class UIFlickerButton;

@interface ClickVideoView : UIView {
	
@private
	
	UIView *selectedView;							//背景View(選択時に表示される)
	UIView *backgroundView;							//背景View(選択時に表示される)
	UIImageView *imgView;							//画像View
    MovieResource *movie;                           //動画
    SimplePlayer *player;
	UIFlickerButton	*btnSelected;					//選択ボタン
	
	UIImageView *imgSelectNumber;					//選択番号（ImageView）
	UILabel		*lblSelectNumber;					//選択番号（Label）
}

-(id)init:(MovieResource *)movie selectedNumber:(u_int)number;

// サイズの設定
-(void)setSize:(CGRect)frame;

// Imageの生成
-(UIImage*) makeImage:(UIImage*)oriImage imgWidth:(CGFloat)width imgHeight:(CGFloat)height;

// 選択番号の非表示の設定
-(void) setSelectNumberHidden:(BOOL)isHidden;

// 選択状態の設定
-(void) setSelected:(BOOL)isSelected frameColor:(UIColor*)color;

-(BOOL)isPortrait; // 縦長か？
@property(nonatomic,assign)    id <ClickVideoViewDelegate> delegate;
@property		BOOL	IsSelected;					// 選択されているか
@property(nonatomic, assign)    BOOL readError;     // 読み込み時にエラーが起きたか？

@end

@protocol ClickVideoViewDelegate<NSObject>
@optional
// 選択イベント
- (void)OnClickVideoViewSelected:(NSUInteger)tagID;

// Touchイベント
//- (void)OnOKDClickImageViewTouched:(NSUInteger)tagID;
- (void)OnClickVideoViewTouched:(id)sender;

@end
