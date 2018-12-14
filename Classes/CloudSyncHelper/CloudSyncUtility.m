//
//  CloudSyncUtility.m
//  iPadCamera
//
//  Created by  on 12/04/01.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CloudSyncUtility.h"
#import <SystemConfiguration/CaptiveNetwork.h>

#ifdef CLOUD_SYNC

#define MESSGAE_ALERT_VIEW_TAG          100

@implementation CloudSyncUtility

#pragma mark private_methods

// ダイアログが表示できるかを確認
- (BOOL) checkDisplayDialogWithState:(SYNC_RESPONSE_STATE)state
{
    if ((_state == SYNC_RSP_OK) && (state != SYNC_RSP_OK) )
    {   return (YES); }
    
    return (! _isDialogShow);
}

// ダイアログを表示
- (void) showDialogWithState:(SYNC_RESPONSE_STATE)state dialogTag:(NSInteger)tag
{
    _isDialogShow = YES;
    
    // stateを保存
    _state = state;
    
    // 結果メッセージを取得
    NSString *message = [CloudSyncUtility getSyncResponseStateWithState:state];
    
    // ダイアログを表示
    UIAlertView *alert =[ [UIAlertView alloc]initWithTitle:@"クラウド同期の結果"
                                      message:message
                                     delegate:self
                            cancelButtonTitle:@"O K"
                            otherButtonTitles:nil];
    alert.tag = tag;
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [alert show];
        [alert release];
    });
    
    /*[alert show];
    [alert release];*/
}

#pragma mark life_cycle
/**
 * コンストラクタ
 *  @param state            同期処理・通信処理の結果
 */

- (id) init
{
    if ((self = [super init]))
    {
        // _state = state;
        _isDialogShow = NO;
    }
    
    return (self);
}

#pragma mark UIAlertViewDelegate

// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag != MESSGAE_ALERT_VIEW_TAG)
    {   return; }
    
    _isDialogShow = NO;
}

#pragma mark public_methods

static CloudSyncUtility     *__DIALOG_INSTANCE__ = nil;

/**
 * 同期処理・通信処理の結果によりダイアログを表示
 *  @param state            同期処理・通信処理の結果
 *  @return                 YES=表示      NO=既に表示されているので表示しない
 */
+ (BOOL) SyncResultDialogShowWithState:(SYNC_RESPONSE_STATE)state
{
    // インスタンスの生成
    if (! __DIALOG_INSTANCE__)
    {
        __DIALOG_INSTANCE__ = [[CloudSyncUtility alloc] init];
    }
    
    // 既にダイアログを表示しているか？
    /*if (__DIALOG_INSTANCE__->_isDialogShow)
    {   return (NO); }*/
    if (! [__DIALOG_INSTANCE__ checkDisplayDialogWithState:state] )
    {   return (NO); }
    
    // ダイアログを表示する
    [__DIALOG_INSTANCE__ showDialogWithState:state dialogTag:MESSGAE_ALERT_VIEW_TAG];
    
    return (YES);
}

/**
 * 同期処理・通信処理の結果の文字列を取得
 *  @param state            同期処理・通信処理の結果
 *  @return                 同期処理・通信処理の結果の文字列
 */
+ (NSString*) getSyncResponseStateWithState:(SYNC_RESPONSE_STATE)state
{
    NSString *msg = nil;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    float size = [ud floatForKey:@"usedSize"];     // 写真使用容量
    float disk = [ud floatForKey:@"contractSize"]; // 契約ディスク容量
    float msize = [ud floatForKey:@"movieSize"];   // 動画使用容量
    float capacity;
    // 3G接続の場合はnilが戻されるので、以降のコードで注意する。
    CFArrayRef interfaces = CNCopySupportedInterfaces();
    CFDictionaryRef dicRef = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(interfaces, 0));
    NSString *ssid = nil;
    if (dicRef) {
        ssid = CFDictionaryGetValue(dicRef, kCNNetworkInfoKeySSID);
    }
    
    switch (state) {
        
        case (SYNC_RSP_OK) :    // エラーなし:SUCCESS
            msg = @"正常に完了しました";
            break;
    //--------------   結果XMLレスポンスの内容 -----------------------------------
    //------------------------------------------------------------------------
            
        case (SYNC_RSP_NO_REGIST_ACCOUNT):      // アカウントの登録なし
            msg = @"アカウントの登録がありません";
            break;
        case (SYNC_RSP_DIFFERENT_PWD):          // パスワードの相違
            msg = @"パスワードが異なります";
            break;
        case (SYNC_RSP_NO_REGIST_DEVICE):       // デバイスの登録なし
            msg = @"デバイスの登録がありません";
            break;
        case (SYNC_RSP_LICENSE_NUM_OVER):       // ライセンス数超過
            msg = @"ライセンス数が超過しています";
            break;
        case (SYNC_RSP_VALIDITY_ERROR):         // 有効性エラー（継続課金できていない）
            msg = @"アカウントは既に無効です";
            break;
        case (SYNC_RSP_NOT_LOGIN):              // 未ログイン
            msg = @"ログインしていません";
            break;
        case (SYNC_RSP_DIFF_LOGIN_AUTH_ID):     // ログインでの認証IDと異なる
            msg = @"ログインした認証IDと異なります";
            break;
        case (SYNC_RSP_DUPLICATE_LOGIN):        // ログインの重複
            msg = @"ログインが重複しています";
            break;
        case (SYNC_RSP_SITE_AUTH_ERROR):        // CaLuLu管理サイト認証エラー
            msg = @"ABCarte管理サイトの\n認証エラーです";
            break;
        case SYNC_RSP_SITE_NO_ANSWER:           // CaLuLu管理サイトが無応答
            msg = @"ABCarte管理サイトが応答しません";
            break;
        case SYNC_RSP_NO_SYNC_VERSION:          // 同期バージョンではない
            msg = @"このアカウントは\n同期バージョンではありません";
            break;
        case SYNC_RSP_DATABASE_ERROR:           // データベースエラー
            msg = @"データベースで\nエラーが発生しました";
            break;
        case SYNC_RSP_UPLOAD_MAKE_DIR_ERROR:    // ファイルアップロードのディレクトリ作成エラー
            msg = @"アップロードエラーです\n(ディレクトリ作成が\nできませんでした)";
            break;
        case SYNC_RSP_UPLOAD_FILE_SIZE_ERROR:   // ファイルアップロードサイズのエラー
            msg = @"アップロードエラーです\n(サイズエラーです)";
            break;
        case SYNC_RSP_UPLOAD_ERROR:             // ファイルアップロードのエラー
            msg = @"アップロードエラーです";
            break;
        case SYNC_RSP_DOWN_LOAD_ERROR:          // ファイルダウンロードのエラー
            msg = @"ダウンロードエラーです";
            break;
        case SYNC_RSP_DOWN_LOAD_SAVE_ERROR:     // ファイルダウンロードの保存エラー
            msg = @"ダウンロードエラーです\n(デバイスに\n保存できません)";
            break;
        case SYNC_RSP_REQUEST_PARAM_ERROR:      // リクエストパラメータエラー
            msg = @"リクエストパラメータの\nエラーです";
            break;
        case SYNC_RSP_REQUEST_XML_ERROR:        // リクエストしたXMLのエラー（パースエラー）など
            msg = @"リクエストのエラーです\n(XMLのパースエラー)";
            break;
        case SYNC_RSP_RESPONSE_XML_ERROR:       // レスポンスXMLのエラー（パースエラー）など
            msg = @"レスポンスのエラーです\n(XMLのパースエラー)";
            break;
        case SYNC_RSP_RESPONSE_XML_NULL:        // レスポンスXMLのNULLエラー
            msg = @"レスポンスのエラーです\n(XMLがありません)";
            break;
        case SYNC_RSP_UNKNWON_ERROR:            // その他のエラー（ネットワーク関連以外）
            msg = @"クラウド同期で\n何らかのエラーが\nありました";
            break;
        case SYNC_RSP_ID_MODIFY:                // ID修正 ：データベースの更新管理でリクエストしたIDとサーバで異なった場合
            msg = @"リクエストしたIDが\nサーバで異なります";
            break;
        case SYNC_RSP_PICTURE_GET_CALLBACK:     // 写真要求：物理データベースでのアップロードでサーバが写真を必要とした時
            msg = @"クラウドより\n写真データの要求が\nがありました";
            break;
        case SYNC_RSP_PICTURE_CAPACITY_OVER:    // クラウドの容量確認でオーバとなった場合
            capacity = (size + msize) / disk * 100;
            msg = [NSString stringWithFormat:@"クラウドに保存できる容量が\n契約容量超過しています。\n(いくつかの写真・動画を削除するか\n契約内容をご確認ください) \n総使用量%2.f%%",capacity];
            break;
        //--------------   ネットワーク関連の内容 --------------------------------
        //------------------------------------------------------------------------
        case SYNC_RSP_COMM_ERROR:               // 通信異常(総合)
            if (ssid) {
                msg = [NSString stringWithFormat:@"ネットワークエラーです\nWiFi接続先は %@ です", ssid];
            } else
                msg = @"ネットワークエラーです";
            break;
        case SYNC_RSP_NO_HOST_REACHABLE:        // HOST到達できない：WiFi切替え必要
            if (ssid) {
                msg = [NSString stringWithFormat:@"有効なネットワークに\n切り替えてください\n現在WiFi接続先は %@ です", ssid];
            } else
                msg = @"有効なネットワークに\n切り替えてください";
            break;
        case SYNC_RSP_HOST_NOT_FOUND:           // not found ホスト不明
            if (ssid) {
                msg = [NSString stringWithFormat:@"有効なネットワークに\n切り替えてください\n現在WiFi接続先は %@ です", ssid];
            } else
                msg = @"有効なネットワークに\n切り替えてください";
            break;
        case SYNC_RSP_NETWORK_TIMEOUT:          // タイムアウト：WiFi切替え必要
            if (ssid) {
                msg = [NSString stringWithFormat:@"有効なネットワークに\n切り替えてください\n現在WiFi接続先は %@ です", ssid];
            } else
                msg = @"有効なネットワークに\n切り替えてください";
            break;
        case SYNC_RSP_UNSUPPORTED_URL:          // サポートされていないURL
            if (ssid) {
                msg = [NSString stringWithFormat:@"有効なネットワークに\n切り替えてください\n現在WiFi接続先は %@ です", ssid];
            } else
                msg = @"有効なネットワークに\n切り替えてください";
            break;
        case SYNC_RSP_NETWORK_NO_CONNET:        // ネットワーク未接続：WiFi OFF
            if (ssid) {
                msg = [NSString stringWithFormat:@"有効なネットワークに\n切り替えてください\n現在WiFi接続先は %@ です", ssid];
            } else
                msg = @"有効なネットワークに\n切り替えてください";
            break;
        case SYNC_RES_NO_HOST_ADDRESS:          // ネットワークの設定関連に問題が有り、ホストにアクセス出来ない場合
            if (ssid) {
                msg = [NSString stringWithFormat:@"有効なネットワークに\n切り替えてください\n現在WiFi接続先は %@ です", ssid];
            } else
                msg = @"有効なネットワークに\n切り替えてください";
            break;
        case SYNC_RSP_UNKNOWN:                  // 定義されていないエラー
        default:
            if (ssid) {
                msg = [NSString stringWithFormat:@"予期しないエラーが\n発生しました\n(code=%d)\n現在WiFi接続先は %@ です", state, ssid];
            } else
                msg = [NSString stringWithFormat:@"予期しないエラーが\n発生しました\n(code=%d)", state];
            break;
    }
    
    return (msg);
}

@end

#else

@implementation CloudSyncUtility
@end

#endif

