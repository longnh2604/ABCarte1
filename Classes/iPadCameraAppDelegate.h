//
//  iPadCameraAppDelegate.h
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoUploader.h"

#ifdef USE_SPLASH_MOVIE
#import <MediaPlayer/MediaPlayer.h>
#endif
#import "ABCUINavigationController.h"

// 遷移画面定義
typedef enum {
	WIN_VIEW_USER_LIST					= 0x0001,	// 顧客一覧画面
	WIN_VIEW_HIST_LIST					= 0x0010,	// 履歴一覧画面
	WIN_VIEW_HIST_DETAIL				= 0x0020,	// 履歴詳細画面
	WIN_VIEW_CAMERA						= 0x0100,	// カメラ画面
	WIN_VIEW_THUMBNAIL_LIST				= 0x0200,	// 写真一覧画面
	WIN_VIEW_SELECT_PICTURE				= 0x0400,	// 選択画像一覧画面
    WIN_VIEW_SELECT_VIDEO				= 0x0500,	// 動画一覧画面
    WIN_VIEW_EDIT_PICTURE               = 0x0550,   // 写真編集画面
    WIN_VIEW_EDIT_VIDEO                 = 0x0600,   // 動画編集画面
    WIN_VIEW_COMP_PICTURE               = 0x0650,   // 写真比較画面
    WIN_VIEW_COMP_VIDEO                 = 0x0700,   // 動画比較画面
	WIN_VIEW_BROADCASTMAIL_USER_LIST	= 0x1000,	// 送信メール選択画面
	WIN_VIEW_TEMPLATE_MANAGE			= 0x2000,	// テンプレート管理画面
	WIN_VIEW_TEMPLATE_CREATOR			= 0x4000,	// テンプレート作成画面
} IPAD_CAMERA_WINDOW_VIEW;

// フリックボタンのタグID定義
typedef enum {
	FLICK_CAMERA_VIEW		= 16,					// カメラ画面へ
	FLICK_NEXT_PREV_VIEW	= 32,					// 前または次画面へ
	FLICK_USER_INFO_ON		= 256,					// ユーザ情報上のボタン
	FLICK_PICT_LIST_VIEW	= 257,					// 写真一覧表示へ
} FLICK_BUTTON_TAG_ID;

// Traial versionに関する定義
#ifdef TRIAL_VERSION
#define	TRIAL_VER_TAKE_PICTURE_NUM	10				// 写真撮影可能枚数
#define	TRIAL_VER_IMPORT_PICTURE_NUM	5			// 写真アルバム取り込み可能枚数
#endif

#ifdef USE_ACCOUNT_MANAGER 
#define	TRIAL_VER_TAKE_PICTURE_NUM	10				// 写真撮影可能枚数
#define	TRIAL_VER_IMPORT_PICTURE_NUM	5			// 写真アルバム取り込み可能枚数
#endif

// @class iPadCameraViewController;
@class MainViewController;

@class camaraViewController;

// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
@class BodyCheckViewController;
#endif

#ifdef HTTP_ON
@class HttpFileUpDownLoaderManager;
#endif

#ifdef USE_ACCOUNT_MANAGER 
@class AccountManager;
#endif

#ifdef CLOUD_SYNC
@class CloudSyncPictureUploadManager;
#endif

@interface iPadCameraAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow                    *window;
    // iPadCameraViewController *viewController;
	MainViewController          *viewController;
	ABCUINavigationController	*navigationController;

	camaraViewController        *cameraView;
    // 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
    BodyCheckViewController     *bodyCheckView;
#endif
#ifdef HTTP_ON
	HttpFileUpDownLoaderManager *httpServerManager;
#endif
#ifdef USE_ACCOUNT_MANAGER 
	AccountManager *accountCountine;
#endif

#ifdef CLOUD_SYNC
    CloudSyncPictureUploadManager   *cloudPictureUploader;
    UIBackgroundTaskIdentifier      backgroundTaskIdentifer;        // バックグラウンド処理ハンドル
#endif
    VideoUploader *videoUploader;

#ifdef USE_SPLASH_MOVIE
//    　RootViewController *rootViewController;
    MPMoviePlayerViewController *mpmPlayerViewController;
    UIImageView                 *uiSplashimg;
#endif
//2016/1/5 TMS ストア・デモ版統合対応 デモサンプルのダウンロード
#ifdef FOR_SALES
    CGFloat                     progressPos;
#endif
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
// @property (nonatomic, retain) IBOutlet iPadCameraViewController *viewController;
@property (nonatomic, retain) IBOutlet MainViewController   *viewController;
@property (nonatomic, retain) ABCUINavigationController     *navigationController;

@property (nonatomic, retain) camaraViewController          *cameraView;
// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
@property (nonatomic, retain) BodyCheckViewController   *bodyCheckView;
#endif
#ifdef HTTP_ON
@property (nonatomic, retain) HttpFileUpDownLoaderManager   *httpServerManager;
#endif
#ifdef USE_ACCOUNT_MANAGER
@property (nonatomic, retain) AccountManager *accountCountine;
#endif

#ifdef CLOUD_SYNC
@property (nonatomic, retain) CloudSyncPictureUploadManager   *cloudPictureUploader;
#endif
@property (nonatomic, retain) VideoUploader *videoUploader;

#ifdef USE_SPLASH_MOVIE
//@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;
@property (nonatomic, retain) MPMoviePlayerViewController *mpmPlayerViewController;
#endif

#ifdef HTTP_ON
// HttpServerのコントロール
- (void) httpServerControlWithFlag: (BOOL)isStart;
#endif

#ifdef CLOUD_SYNC
// 写真ファイルの自動アップロードの起動と停止
- (void) setSyncPictUploaderRun:(BOOL)isRun;
#endif
- (void) setSyncVideoUploaderRun:(BOOL)isRun;

// AppStoreサンプルデータのダウンロード
- (void) appStoreSampleDownload;

@end

