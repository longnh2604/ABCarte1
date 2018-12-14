//
//  MicUtil.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/06/11.
//
//

#import "MicUtil.h"

@implementation MicUtil

+ (void)isMicAccessEnableWithIsShowAlert:(BOOL)_isShowAlert
                              completion:(IsMicAccessEnableWithIsShowAlertBlock)_completion
{
    //    // メソッドの存在チェック。存在しない場合はiOS7未満なのでYESを返す なぜか動作しなかった
    //    if (![AVCaptureDevice instancesRespondToSelector:@selector(authorizationStatusForMediaType:)]) {
    //        return YES;
    //    }
    
    IsMicAccessEnableWithIsShowAlertBlock completion = [_completion copy];
    
    // iOS7.0未満
    NSString *iOsVersion = [[UIDevice currentDevice] systemVersion];
    NSLog(@"iOsVersion = %@", iOsVersion);
    if ( [iOsVersion compare:@"7.0" options:NSNumericSearch] == NSOrderedAscending ) {
        completion(YES);
        return;
    }
    
    // このアプリマイクへの認証状態を取得する
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    
    switch (status) {
        case AVAuthorizationStatusAuthorized: // マイクへのアクセスが許可されている
            completion(YES);
            break;
        case AVAuthorizationStatusNotDetermined: // マイクへのアクセスを許可するか選択されていない
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                     completionHandler:
             ^(BOOL granted) {
                 // メインスレッド
                 dispatch_sync(dispatch_get_main_queue(), ^{
                     if(granted){
                         //許可完了
                         completion(YES);
                     } else {
                         //許可されなかった
                         completion(NO);
                         
                         UIAlertView *alertView = [[UIAlertView alloc]
                                                   initWithTitle:@"エラー"
                                                   message:@"マイクへのアクセスが許可されていません。\n設定 > プライバシー > マイクで許可してください。"
                                                   delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles:nil];
                         [alertView show];
                     }
                 });
             }];
            
        }
            break;
        case AVAuthorizationStatusRestricted: // 設定 > 一般 > 機能制限で利用が制限されている
        {
            if (_isShowAlert) {
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"エラー"
                                          message:@"マイクへのアクセスが許可されていません。\n設定 > 一般 > 機能制限で許可してください。"
                                          delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                [alertView show];
            }
            completion(NO);
        }
            break;
        case AVAuthorizationStatusDenied: // 設定 > プライバシー > で利用が制限されている
        {
            if (_isShowAlert) {
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"エラー"
                                          message:@"マイクへのアクセスが許可されていません。\n設定 > プライバシー > マイクで許可してください。"
                                          delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                [alertView show];
            }
            completion(NO);
        }
            break;
            
        default:
            break;
    }
}

@end
