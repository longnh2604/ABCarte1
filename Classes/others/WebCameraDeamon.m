//
//  WebCameraDeamon.m
//  iPadCamera
//
//  Created by 強 片山 on 13/01/08.
//  Copyright (c) 2013年 __MyCompanyName__. All rights reserved.
//

#import "WebCameraDeamon.h"

#import "Reachability.h"
#import "AccountManager.h"

#import "Common.h"

/**
 * Webカメラ操作クラス
 */
@implementation WebCameraDeamon

@synthesize vwImage4Prev;
@synthesize isWebCameraEnable = _isWebCameraEnable;
@synthesize isPreview = _isPreview;
@synthesize deviceOrientation;

#pragma mark - private_methods

// WebカメラのURL（コマンド込み）を設定より読み込み
-(void) _readWebCameraUrl
{
    // 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    
    BOOL isSet = NO;
    
    // Webカメラが有効か無効か？
    if (! [defaluts objectForKey:@"web_camera_enable"])
    {
#ifdef AIKI_CUSTOM
        _isWebCameraEnable = YES;
#else
        _isWebCameraEnable =[AccountManager isWebCam];
//        [AccountManager isAccountManipulative];
#endif
        [defaluts setBool:self.isWebCameraEnable forKey:@"web_camera_enable"];
        isSet = YES;
    }
    else {
        _isWebCameraEnable = [defaluts boolForKey:@"web_camera_enable"];
#ifndef AIKI_CUSTOM
//        // 整体向けアカウントでない場合は、設定によらず無効
//        if (! [AccountManager isAccountManipulative])
//        {   _isWebCameraEnable = NO; }
        _isWebCameraEnable = [AccountManager isWebCam];
#endif
    }
    
    if (! self.isWebCameraEnable)
    {   return; }       // Webカメラが無効
    
    // WebカメラのURL
    NSString *url = nil;
    if (! [defaluts objectForKey:@"web_camera_url"])
    {
        url = WEB_CAMERA_URL;
        [defaluts setValue:url forKey:@"web_camera_url"];
        isSet = YES;
    }
    else {
        url = [defaluts stringForKey:@"web_camera_url"];
    }
    
    // Webカメラのコマンド
    NSString *cmd = nil;
    if (! [defaluts objectForKey:@"web_camera_command"])
    {
        cmd = WEB_CAMERA_COMMAND;
        [defaluts setValue:cmd forKey:@"web_camera_command"];
        isSet = YES;
    }
    else {
        cmd = [defaluts stringForKey:@"web_camera_command"];
        if (!cmd)
        {   cmd = @""; }
    }
    
    // プレビュー更新間隔
    if (! [defaluts objectForKey:@"web_camera_interval"])
    {
        _prevWaitInterval = WEB_CAMERA_PREV_WAIT;
        [defaluts setInteger:((CGFloat)_prevWaitInterval * 1000.0f) forKey:@"web_camera_interval"];
        isSet = YES;
    }
    else {
        NSInteger interval = [defaluts integerForKey:@"web_camera_interval"];
        _prevWaitInterval = ((CGFloat)interval / 1000.0f);
    }
    
    
    if (isSet)
    {   [defaluts synchronize]; }
    
    // メンバにコマンド付きのURLとして設定
    _webCameraUrl = [[NSString alloc] initWithFormat:@"http://%@%@%@", 
                        url, ([cmd length] > 0)? @"/" : @"" ,cmd];
    NSURL *nurl = [NSURL URLWithString:_webCameraUrl];
    _webCamRequest = [[NSURLRequest alloc] initWithURL:nurl];
}

// ネットワークの到達を確認
-(BOOL) nwReachble
{
    // ホスト名に変更
    NSURL *url = [NSURL URLWithString:_webCameraUrl];
    NSString *host = [url host];
    
    // ネットワークの接続を確認
    REACHABLE_STATUS rStat 
        = [ReachabilityManager reachabilityStatusWithHostName: host];
	BOOL stat = (rStat == REACHABLE_HOST);
    
    if (! stat)
    {   return (NO); }
    
    // 違うネットワーククラスでもREACHABLE_HOSTとなるので、一度だけ画像を取得
    NSInteger httpRsp = WEB_CAMERA_HTTP_STATE_GOOD;
    
    // プレビュー画像をWebカメラより同期で取得
    NSData *data = [self _getPrevImageWithRspBuf:&httpRsp];
    
    stat = ( (data) && (httpRsp == WEB_CAMERA_HTTP_STATE_GOOD));
    
    return (stat);
}

// プレビュー画像をWebカメラより同期で取得
-(NSData*) _getPrevImageWithRspBuf:(NSInteger*) pHttpRsp
{
    NSData *data = nil;
    
	@try {
		
		/*NSURL *url = [NSURL URLWithString:_webCameraUrl];
		NSURLRequest *request = [NSURLRequest requestWithURL:url];*/
		NSHTTPURLResponse *response = nil;
		NSError *error = nil;
		
        /* NSLog(@"send request to web camera"); */
        
        data = [NSURLConnection sendSynchronousRequest:_webCamRequest
									 returningResponse:&response 
												 error:&error];
        /* NSLog(@"recv response from web camera"); */
        
		if (error)
		{
			NSLog(@"_getPrevImageWithRspBuf error -> %@", [error localizedDescription]);
			data = nil;
		}
        
        // HTTPレスポンスを取得
        *pHttpRsp = [response statusCode];
        
        // 正常またはホスト不明以外はネットワークエラーを設定
        if ((*pHttpRsp != WEB_CAMERA_HTTP_STATE_GOOD) &&
            (*pHttpRsp != 404) )
        {   *pHttpRsp = (error)? [error code] : kCFURLErrorUnknown; }
        
        if (*pHttpRsp != WEB_CAMERA_HTTP_STATE_GOOD)
        {   NSLog(@"web camera response => %ld", (long)*pHttpRsp);}
	}
	@catch (NSException *exception) {
		NSLog(@"getImageData exception: Caught %@: %@", 
			  [exception name], [exception reason]);
		data = nil;
	}
    
    
    return (data);
}

// 状態を通知
-(void) _notifyStateWithStateVal:(NSInteger) httpRsp
{
    WEB_CAM_STATE_NOTIFY_PHASE phase = WEB_CAM_STATE_NOTIFY_ERROR_OTHER;
    NSString *message = nil;
    
    switch (httpRsp) {
        case WEB_CAMERA_HTTP_STATE_GOOD:
            // 正常
            phase = WEB_CAM_STATE_NOTIFY_OK;
            // message = @"";
            break;
        case 404:
            // ホスト不明
            phase = WEB_CAM_STATE_NOTIFY_ERROR_404;
            message = @"Webカメラのネットワークを確認してください";
            break;
        case kCFURLErrorTimedOut:
            phase = WEB_CAM_STATE_NOTIFY_ERROR_OTHER;
            message = @"Webカメラが応答していません";
            break;
        default:
            phase = WEB_CAM_STATE_NOTIFY_ERROR_OTHER;
            message = @"Webカメラが動作していません";
            break;
    }
    
    if (_notifyPhase != phase)
    {
        // 前回行った通知内容と種類が異なる場合のみ通知する
        _notifyPhase = phase;
        
        if (phase == WEB_CAM_STATE_NOTIFY_OK) 
        { message = @"Webカメラに接続しました"; }
        
        // メインスレッド処理に移行して通知
        dispatch_async(dispatch_get_main_queue(), ^{
            _hEvent( (_notifyPhase != WEB_CAM_STATE_NOTIFY_OK), message);
        });
    }
}

// バイナリデータから画像オブジェクトへの変換(ポートレート時の中央切抜も含む)
- (UIImage*) _convImageWithBinary:(NSData*)data
{
    UIImage *defImg =  [UIImage imageWithData:data];
    
    // ランドスケープ時はそのままとする（切抜なし）
    if (UIInterfaceOrientationIsLandscape(self.deviceOrientation ))
    {   return (defImg); }
    
    // 画像サイズ
    CGFloat iWidth = defImg.size.width;
    CGFloat height = defImg.size.height;
    
    // 縦横比率
    CGFloat rait = height / iWidth;
    // 横向き画像から高さの同一比率の幅
    CGFloat width = rait * height;
    
    // グラフィックコンテキストを、倍率からの縮小サイズで作成
	UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    // 描画X座標
    CGFloat left = (iWidth - width) / 2.0f;
    left *= -1.0f;
    
    // グラフィックコンテキストに描画
	[defImg drawInRect:CGRectMake(left, 0.0f, iWidth, height)];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
    
    return (image);

}

// 画像を写真サイズに調整
-(UIImage*) _adjustImage:(NSData*)data
{
    if (! data)
    {   return nil; }       // 念のため
    
    // 画像オブジェクトに変換(ポートレート時の中央切抜も含む)
    UIImage *oriImage = [self _convImageWithBinary:data];
    
    // 画像の倍率
    CGFloat raito;
    if (UIInterfaceOrientationIsLandscape(self.deviceOrientation ))
    {
        // ランドスケープ時は、縦と横の倍率でいずれか大きいほうで画像の倍率を求める
        CGFloat widthRatio = oriImage.size.width / CAM_VIEW_PICTURE_WIDTH;
        CGFloat heightRatio = oriImage.size.height / CAM_VIEW_PICTURE_HEIGHT;

        raito = (widthRatio >= heightRatio)? widthRatio : heightRatio;
    }
    else 
    {
        // ポートレート時は、高さより倍率を求める
        raito = oriImage.size.height / CAM_VIEW_PICTURE_HEIGHT;
    }
    
    // 倍率より縮小後のサイズを求める
    CGFloat width  = oriImage.size.width / raito;
    CGFloat height = oriImage.size.height / raito;
    
    // グラフィックコンテキスト用の描画幅
    CGFloat dWidth = width;
//    CGFloat dWidth = UIInterfaceOrientationIsLandscape(self.deviceOrientation )?
//        width : CAM_VIEW_PICTURE_WIDTH;
    
    // グラフィックコンテキストを、倍率からの縮小サイズで作成    
	UIGraphicsBeginImageContext(CGSizeMake(dWidth, height));
    
    // 描画X座標 : ポートレート時は中央表示
    CGFloat left = (UIInterfaceOrientationIsLandscape(self.deviceOrientation ))?
        0.0f : (dWidth - width) / 2.0f;
    
    // グラフィックコンテキストに描画
	[oriImage drawInRect:CGRectMake(left, 0.0f, width, height)];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
    
    return (image);
}

// シャッター音を鳴らす
-(void) _playSoundShutter
{
    // 画面をフラッシュする
    UIView *flashView = [[UIView alloc] initWithFrame:self.vwImage4Prev.frame];
    flashView.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.7f];
    // _flashView.hidden = YES;
	[self.vwImage4Prev addSubview:flashView];
    
    [UIView animateWithDuration:0.75f animations:^{
        flashView.alpha = 0.5f;
    } completion:^(BOOL finished) {
        flashView.alpha = 0.0f;
        [flashView removeFromSuperview];
        [flashView release];
    }];   
    
    // シャッター音の再生
    [Common playSoundWithResouceName:@"shutterSound" ofType:@"mp3"];
}

#pragma mark - life_cycle

/**
 *  初期化
 *  @param      vwImage：プレビュー用UIImageView
 *  @param      serverUrl:同期ホストURL
 *  @param      hStateNotify:Webカメラ状態通知のイベントハンドラ
 *  @return     self
 *  @remarks    なし
 */
- (id) initWithPrevView:(UIImageView*)vwImage hStateNotify:(onWebCamStateNotify)hEvent
{
    if ((self = [super init]) )
    {
        self.vwImage4Prev = vwImage;
        // contentモード設定（画像を縦横比固定でフィットさせる）
        [self.vwImage4Prev setContentMode:UIViewContentModeScaleAspectFit];
        
        // WebカメラのURL（コマンド込み）を設定より読み込み
        [self _readWebCameraUrl];
        
        _hEvent = Block_copy(hEvent);
        
        _isPreview = NO;
        _notifyPhase = WEB_CAM_STATE_NOTIFY_OK;
    }
    
    return (self);
}

- (void) dealloc
{
    Block_release(_hEvent);
    
    [_webCamRequest release];
    [_webCameraUrl release];
    
    [self.vwImage4Prev release];
    
    [super dealloc];
}

#pragma mark - public_methods

/**
 *  プレビューの開始
 *  @param      hNotify:Webカメラ到達結果のハンドラ
 *  @return     なし
 *  @remarks    なし
 */
- (void) startPreviewWithReachNotify:(onWebCamStateNotify)hNotify
{
    // Global Queueの取得
	dispatch_queue_t queue = 
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    canErrorDisp = YES;
	
	// スレッド処理
    /////////////////////////////////////////////////
	dispatch_async(queue, ^{
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        BOOL hasError;
        
        // ネットワークの到達を確認
        if (! [self nwReachble])
        {
            // WEBカメラに到達できないので、以降のループを抜ける
            _isPreview = NO;
            hasError = YES;
        }
        else {
            // Webカメラに到達できたのでプレビューを開始
            _isPreview = YES;
            hasError = NO;
        }
        
        // メインスレッド処理に移行して到達結果を通知
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *msg = (_isPreview)?
                    @"" : @"Webカメラに接続できませんでした";
            if (canErrorDisp==YES) {
                hNotify(!_isPreview, msg);
            }
        });

        while (_isPreview)
		{
			NSAutoreleasePool *innnerPool = [[NSAutoreleasePool alloc] init];	// SIGBUS 10 error対応
			@try {
				
                NSInteger httpRsp = WEB_CAMERA_HTTP_STATE_GOOD;
                
				// プレビュー画像をWebカメラより同期で取得
                NSData *data = [self _getPrevImageWithRspBuf:&httpRsp];
                
                // 状態を通知
                [self _notifyStateWithStateVal:httpRsp];                                
                
                // メインスレッドにて画像を表示
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        // 画像オブジェクトに変換(ポートレート時の中央切抜も含む)
                        UIImage *image = ((httpRsp == WEB_CAMERA_HTTP_STATE_GOOD) && (data) )?
                                [self _convImageWithBinary:data] : nil;
                        
                        self.vwImage4Prev.image = image;
                    });
                }

                // スレッド待機：異常時は遅くする
                NSTimeInterval wait =  ((httpRsp == WEB_CAMERA_HTTP_STATE_GOOD) && (data) )?
                    _prevWaitInterval : WEB_CAMERA_PREV_WAIT_ERROR;
				[NSThread sleepForTimeInterval:wait];	
			}
			@catch (NSException *exception) {
				NSLog(@"WebCameraDaemon preview thread: Caught %@: %@", 
					  [exception name], [exception reason]);
			}
			[innnerPool release];
            
            // NSLog(@"web camera preview interval");
		}
        
        // プレビュー完了時は画像を消去
        if (! hasError)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.75f animations:^{
                    self.vwImage4Prev.alpha = 0.5f;
                } completion:^(BOOL finished) {
                    self.vwImage4Prev.alpha = 1.0f;
                    self.vwImage4Prev.image = nil;
                }];            
            });
        }
#ifdef DEBUG
        NSLog(@"web camera preview end.....");
#endif
        [pool release];
        
    });
    /////////////////////////////////////////////////
    
}

/**
 *  プレビューの停止
 *  @param      なし
 *  @return     void
 *  @remarks    なし
 */
- (void) stopPreview
{
    // プレビュー開始フラグをクリア
    _isPreview = NO;
    
    // エラー通知表示を禁止
    canErrorDisp = NO;
    
    // 通知内容をクリア
    _notifyPhase = WEB_CAM_STATE_NOTIFY_OK;
}

/**
 *  写真の保存
 *  @param      hSave:Webカメラ写真保存のハンドラ
 *  @return     void
 *  @remarks    なし
 */
- (void) savePhoteWithSaveHandler:(onWebCamPhoteSave)hSave
{
    // Global Queueの取得
	dispatch_queue_t queue = 
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	// スレッド処理
    /////////////////////////////////////////////////
	dispatch_async(queue, ^{
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        // ネットワークの到達を確認
        if (! [self nwReachble])
        {
            // メインスレッド処理に移行して到達結果を通知
            dispatch_async(dispatch_get_main_queue(), ^{
                hSave(YES, nil);
            });
            
            [pool release];
            return;
        }        

        @try {
            
            NSInteger httpRsp = WEB_CAMERA_HTTP_STATE_GOOD;
            // プレビュー画像をWebカメラより同期で取得
            NSData *data = [self _getPrevImageWithRspBuf:&httpRsp];
            
            UIImage *image = nil;
            BOOL isError = YES;
            if ( (httpRsp == WEB_CAMERA_HTTP_STATE_GOOD) && (data) )
            {
                // 画像を写真サイズに調整
                image = [self _adjustImage:data];
                isError = NO;
            }
            
            // メインスレッド処理に移行して取得を通知
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (! isError)
                {
                    // シャッター音を鳴らす
                    [self _playSoundShutter];
                }
                
                hSave(isError, image);
            });
        }
        @catch (NSException *exception) {
            NSLog(@"WebCameraDaemon savePhote thread: Caught %@: %@", 
                  [exception name], [exception reason]);
        }
            
                   
        [pool release];
        
    });
    /////////////////////////////////////////////////
}

/**
 *  Webカメラの有効化
 *  @param      isEnable  YES=有効　NO=無効
 *  @return     void
 *  @remarks    なし
 */
- (void) setWebCameraEnableWithFlag:(BOOL)isEnable
{
#ifdef AIKI_CUSTOM
    return;     // AIKIバージョンは変更の必要なし
#endif

    if (isEnable == _isWebCameraEnable)
    {   return; }       // 変更の必要なし
    
    // 設定ファイル管理インスタンスを取得して、有効（無効）を更新
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    [defaluts setBool:isEnable forKey:@"web_camera_enable"];
    [defaluts synchronize];
    
    // WebカメラのURL（コマンド込み）を設定より読み込み
    [self _readWebCameraUrl];
}

@end
