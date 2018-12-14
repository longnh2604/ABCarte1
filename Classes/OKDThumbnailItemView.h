//
//  OKDThumbnailItemView.h
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#define TITLE_HIGHT	10.0f

#ifdef CALULU_IPHONE
#define	SELECT_NUMBER_SIZE			18.0f		// 選択番号のサイズ
#else
#define	SELECT_NUMBER_SIZE			32.0f		// 選択番号のサイズ
#endif

@class OKDImageFileManager;
 
@protocol OKDThumbnailItemViewDelegate;

#import <UIKit/UIKit.h>


@interface OKDThumbnailItemView : UIView {
@public
	UIButton	*btnSelected;						//選択ボタン
	UILabel		*lblTitle;							//タイトル表示用ラベル
	UIImageView	*imgView;							//Image表示
	NSString	*_fileName;							//ファイル名（フルパス）
    UILabel    *dateTime;
@private
	
	UIImageView *imgSelectNumber;					//選択番号（ImageView）
	UILabel		*lblSelectNumber;					//選択番号（Label）
	
}
@property (assign, nonatomic) UILabel *finalDateTime;
@property(nonatomic,strong) NSDate *picDate;
@property		BOOL	IsSelected;					// 選択されているか
@property(nonatomic,assign)    id <OKDThumbnailItemViewDelegate> delegate;
@property(nonatomic, copy) NSString* imgId;
@property(nonatomic, copy) NSString* selectImgId;
@property(nonatomic, assign) NSTimeInterval updateTime;

// ファイル名によるImageの設定：スレッド起動バージョン
-(void) setImageWithFile:(NSString*)fileName;

// ファイル名の設定
-(void) setFileName:(NSString*)fileName;

// Imageの描画：ファイル名設定後のに実行
-(void) writeToImage;

// サムネイルImageの描画：ファイル名設定後のに実行
-(void) writeToThumbnail:(OKDImageFileManager*) imgFileMng;

// テンプレート用サムネイルImageの描画：ファイル名設定後のに実行
-(void) writeToTemplateThumbnail:(OKDImageFileManager*) imgFileMng;

// タイトルの設定
-(void) setTitle:(NSString*)title;

//set date time
-(void)setDate:(NSDate*)date;

// 実サイズImageの取得
-(UIImage*) getRealSizeImage:(OKDImageFileManager*) imgFileMng;

// サムネイルImageの取得
-(UIImage*) getThumbnailImage;

// Imageの取得
-(UIImage*) getImage;

// 選択の設定
-(void) setSelect:(BOOL)set;

// ファイル名の取得
-(NSString*) getFileName;

// ボタンの設定
- (void) setButtonState;

// 選択番号の設定：number=選択番号（０で非表示とする）
- (void) setSelectNumber:(u_int)number;

@end

@protocol OKDThumbnailItemViewDelegate<NSObject>
@optional
// サムネイル選択イベント
- (void)SelectThumbnail:(NSUInteger)tagID image:(UIImage*)image select:(BOOL)isSelect;
@end
