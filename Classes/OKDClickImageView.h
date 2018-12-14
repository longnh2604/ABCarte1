//
//  OKDClickImageView.h
//  iPadCamera
//
//  Created by MacBook on 10/09/08.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@protocol OKDClickImageViewDelegate;

#import <UIKit/UIKit.h>

#ifndef SELECT_NUMBER_SIZE
#ifdef CALULU_IPHONE
#define	SELECT_NUMBER_SIZE			18.0f		// 選択番号のサイズ
#else
#define	SELECT_NUMBER_SIZE			32.0f		// 選択番号のサイズ
#endif
#endif

#define SELECT_NUMBER_SHIFT_BIT		16			// 選択番号のビットシフト位置：　selectNum << 16 | FLICK_NEXT_PREV_VIEW

@class UIFlickerButton;

@interface OKDClickImageView : UIView {
	
@private
	
	UIView *selectedView;							//背景View(選択時に表示される)
	UIView *backgroundView;							//背景View(選択時に表示される)
	UIImageView *imgView;							//画像View
	UIFlickerButton	*btnSelected;					//選択ボタン
	
	UIImageView *imgSelectNumber;					//選択番号（ImageView）
	UILabel		*lblSelectNumber;					//選択番号（Label）
    CGSize      orgSize;                            // 貼付けられたオリジナルサイズ
}

-(id)init:(UIImage*)image selectedNumber:(u_int)number ownerView:(id)ownerView;

// サイズの設定
-(void)setSize:(CGRect)frame;

// サイズの設定 モーフィング用
-(void)setSizeMorphing:(CGRect)frame;

// Viewに設定された画像サイズを返す
- (CGSize)getSize;

// Imageの生成
-(UIImage*) makeImage:(UIImage*)oriImage imgWidth:(CGFloat)width imgHeight:(CGFloat)height;

// 選択番号の非表示の設定
-(void) setSelectNumberHidden:(BOOL)isHidden;

// 選択状態の設定
-(void) setSelected:(BOOL)isSelected frameColor:(UIColor*)color numberSelected:(NSInteger)number;

@property(nonatomic,assign)    id <OKDClickImageViewDelegate> delegate;
@property		BOOL	IsSelected;					// 選択されているか


@end

@protocol OKDClickImageViewDelegate<NSObject>
@optional
// 選択イベント
- (void)OnOKDClickImageViewSelected:(NSUInteger)tagID image:(UIImage*)image;

// Touchイベント
//- (void)OnOKDClickImageViewTouched:(NSUInteger)tagID;
- (void)OnOKDClickImageViewTouched:(id)sender;
- (void) setImageNumber:(int)number;
@end
