//
//  WebCameraDeamon.h
//  iPadCamera
//
//  Created by 強 片山 on 13/01/08.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// Webカメラ状態通知のイベントハンドラ定義
typedef void (^onWebCamStateNotify)(BOOL isError, NSString* message);

// Webカメラ写真保存のイベントハンドラ定義
typedef void (^onWebCamPhoteSave)(BOOL isError, UIImage *pictureImage);

// 状態通知を行った内容
typedef enum
{
    WEB_CAM_STATE_NOTIFY_NAUTRAL = 0,           // 初期
    WEB_CAM_STATE_NOTIFY_OK = 0x10,             // 正常を通知
    WEB_CAM_STATE_NOTIFY_ERROR_404 = 0x1004,    // ホスト不明の異常を通知
    WEB_CAM_STATE_NOTIFY_ERROR_OTHER = 0x1010,  // その他の異常を通知
} WEB_CAM_STATE_NOTIFY_PHASE;

#define WEB_CAMERA_URL      @"192.168.152.50"       // デフォルトのURL
#define WEB_CAMERA_COMMAND  @"SnapshotJPEG?Resolution=800x600&Quality=Clarit"   // デフォルトのコマンド
#define WEB_CAMERA_PREV_WAIT    0.15f                // 正常時プレビュー待機時間:150[mSec]
#define WEB_CAMERA_PREV_WAIT_ERROR   2.0f           // 異常時プレビュー待機時間:2000[mSec]
#define WEB_CAMERA_HTTP_STATE_GOOD 200              // HTTPステータスの正常値

#ifndef CAM_VIEW_PICTURE_WIDTH
#define		CAM_VIEW_PICTURE_WIDTH		960.0f			// 画像横サイズ(for iPad2)
#endif
#ifndef CAM_VIEW_PICTURE_HEIGHT
#define		CAM_VIEW_PICTURE_HEIGHT		720.0f			// 画像縦サイズ(for iPad2)
#endif

/**
 * Webカメラ操作クラス
 */
@interface WebCameraDeamon : NSObject
{
    NSString        *_webCameraUrl;             // WebカメラのURL(コマンド込み)
    NSURLRequest    *_webCamRequest;
    BOOL            _isWebCameraEnable;         // Webカメラが有効か?
    NSTimeInterval  _prevWaitInterval;          // プレビューの更新間隔
    BOOL            _isPreview;                 // プレビュー中であるかどうか？ : メインスレッドのみで設定すること
    onWebCamStateNotify  _hEvent;               // Webカメラ状態通知のイベントハンドラ
    WEB_CAM_STATE_NOTIFY_PHASE  _notifyPhase;   // 状態通知を行った内容
    BOOL            canErrorDisp;               // エラー通知の表示許可フラグ
}

@property (nonatomic, retain) UIImageView       *vwImage4Prev;      // プレビュー用UIImageView
@property (nonatomic, readonly) BOOL            isWebCameraEnable;  // Webカメラが有効か?
@property (nonatomic, readonly) BOOL            isPreview;          // プレビュー中であるかどうか？
@property (nonatomic) UIInterfaceOrientation    deviceOrientation;	// デバイスの向き

/**
 *  初期化
 *  @param      vwImage：プレビュー用UIImageView
 *  @param      serverUrl:同期ホストURL
 *  @param      hStateNotify:Webカメラ状態通知のイベントハンドラ
 *  @return     self
 *  @remarks    なし
 */
- (id) initWithPrevView:(UIImageView*)vwImage hStateNotify:(onWebCamStateNotify)hEvent;

/**
 *  プレビューの開始
 *  @param      hNotify:Webカメラ到達結果のハンドラ
 *  @return     なし
 *  @remarks    なし
 */
- (void) startPreviewWithReachNotify:(onWebCamStateNotify)hNotify;

/**
 *  プレビューの停止
 *  @param      なし
 *  @return     void
 *  @remarks    なし
 */
- (void) stopPreview;

/**
 *  写真の保存
 *  @param      hSave:Webカメラ写真保存のハンドラ
 *  @return     void
 *  @remarks    なし
 */
- (void) savePhoteWithSaveHandler:(onWebCamPhoteSave)hSave;

/**
 *  Webカメラの有効化
 *  @param      isEnable  YES=有効　NO=無効
 *  @return     void
 *  @remarks    なし
 */
- (void) setWebCameraEnableWithFlag:(BOOL)isEnable;

@end
