//
//  ThumbnailViewController.h
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OKDThumbnailItemView.h"
#import "def64bit_common.h"

#ifdef CALULU_IPHONE
// サムネイルitemの幅
#define ITEM_WITH	64.0f
// サムネイルitemの高さ -> サムネイル=48 ＋　タイトル高さ=10
#define ITEM_HEIGHT	58.0f
#else
// サムネイルitemの幅
#define ITEM_WITH	128.0f
// サムネイルitemの高さ -> サムネイル=96 ＋　タイトル高さ=10
#define ITEM_HEIGHT	106.0f
#endif

// 写真フォルダのパス
#define PICTURE_FOLDER		@"%@/Documents/User%08d"

@protocol ThumbnailVCDelegate;

@interface ThumbnailViewController : UIViewController 
				<OKDThumbnailItemViewDelegate, UIScrollViewDelegate, UIAlertViewDelegate>
{

    IBOutlet UIToolbar *toolbarTop;
    IBOutlet UIToolbar *toolbarBottom;
    bool	_isBackCameraView;							// 画面遷移でカメラ画面へ戻るか？
	
	NSMutableArray *tumbnailItems;						// サムネイルItemのリスト
	
	UIScrollView *_scrollView;							// スクロールビュー
	UIView	*_drawView;									// 描画View

	UIAlertView *deleteNoAlert;							// 削除なしAlertダイアログ
	UIAlertView *deleteCheckAlert;						// 削除確認Alertダイアログ
	
	NSMutableArray *selectItemOrder;					// 選択サムネイルItemの順序Table
	
	USERID_INT		_selectedUserID;					// 選択されたユーザのID
	
	BOOL			_isThumbnailRedraw;					// サムネイルの再描画を行うかを判定する
	
    IBOutlet UIBarButtonItem *btnTrash;
    IBOutlet UIBarButtonItem            *btnUserName;	// ユーザ名
	IBOutlet UIActivityIndicatorView	*actIndView;
	IBOutlet UIToolbar                  *tlbSecurity;	// セキュリティ表示用ツールバー
	// NSString		*_userName;
	
	UIColor			*_userNameColor;					// ユーザ名の色
#ifdef CLOUD_SYNC
    BOOL            _isImageReading;                    // イメージを読み込み中か？
#endif
    BOOL            memWarning;                         // メモリワーニングが出ているか
}
// @property(nonatomic)		NSInteger	_selectedUserID;
@property(nonatomic, retain) UIColor			*userNameColor;

@property(nonatomic, assign) id<ThumbnailVCDelegate>	delegate;

@property(nonatomic, copy) NSString		*_userName;
@property(nonatomic, assign) BOOL       isFinishDidLoad;

// 選択ユーザIDの設定:サムネイルも再描画を行うかも判定する
- (void) setSelectedUserID:(USERID_INT)userID;

// 選択されたユーザ名
- (void)setSelectedUserName:(NSString*)userName nameColor:(UIColor*)color;

// サムネイルItemリストの作成
- (BOOL) tumbnailItemsMake;

// ScrollViewと描画Viewの作成
- (void) makeScrDrawView;

// サムネイルItemのレイアウト isPortrait=縦向き(isPortrait)でTRUE
- (void) thumbnailItemsLayout:(BOOL)isPortrait;

- (void)SelectThumbnail:(NSUInteger)tagID image:(UIImage*)image select:(BOOL)isSelect;

// tagIDによりサムネイルItemを取り出す
- (OKDThumbnailItemView*) searchThnmbnailItemByTagID:(NSUInteger)tagID;

// サムネイルの更新
- (void) refreshThumbNail;
// 画像一覧表示の場合に選択画像のタグを修正するため
- (void) refreshThumbNail:(BOOL)addPict;

- (BOOL) _isSelectItem;

// フルパスのファイル名からサムネイルのタイトル［yy年mm月dd日 HH時MM分］を取得する
- (NSString*) makeThumbNailTitle:(NSString*)fullPath;

- (NSDate*) setDateTime:(NSString*)fullPath;

- (IBAction)OnCameraView;								// カメラ画面へ戻る
- (IBAction)OnSelectPictView;							// 選択画像一覧へ

- (IBAction)OnSetUserPicture;							// 選択画像をお客様写真に設定
- (IBAction)OnDeleteThubnails;							// 選択画像を削除
- (IBAction)OnChancel;									// キャンセル

// アプリがスリープされた時に、一旦メモりワーニングフラグをクリアする
- (void)willResignActive;

@end

@protocol ThumbnailVCDelegate<NSObject>

@optional

// サムネイルの削除イベント
- (void) didDeletedThumbnails:(id)sender deletedFiles:(NSArray*)files;

@end

