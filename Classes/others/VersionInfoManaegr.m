//
//  VersionInfoManaegr.m
//  CaLuLu_forAderans
//
//  Created by 強 片山 on 12/10/31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "VersionInfoManaegr.h"

#import "Reachability.h"

#import "UIAleartViewCallback.h"

#import "MainViewController.h"
#import "iPadCameraAppDelegate.h"

@implementation VersionInfoManaegr

#ifdef MDM_DISTRIBUTION_VERSION

#pragma mark - private_ methods

// バージョン情報（番号）を取得する
+ (CGFloat)getVersionNumber
{
    CGFloat verNumber = -1.0f;
    
    // バージョンアップの情報ファイルのURL
    NSString* address = [NSString stringWithFormat:@"%@%@", VERSION_UP_URL_DEFAULT,VER_INFO_URL];
    
    NSURL* url = [NSURL URLWithString:address];
    NSURLRequest* request = [NSURLRequest
                             requestWithURL:url
                             cachePolicy:NSURLRequestReloadIgnoringCacheData    // NSURLRequestUseProtocolCachePolicy
                             timeoutInterval:5.0f]; 
    
    NSURLResponse* response = nil;
    NSError *error = nil;
    // NSLog(@"getVersionNumber:%@",url);
    
    NSData* data = [NSURLConnection
                    sendSynchronousRequest:request
                    returningResponse:&response
                    error:&error];
    NSString* result = [[NSString alloc]
                        initWithData:data
                        encoding:NSUTF8StringEncoding];
    
    if(error){
        NSLog(@"getVersionNumber:error = %@", error);
    }
    else{
        NSInteger statCode = [(NSHTTPURLResponse*)response statusCode];
        if (statCode / 100 == 4 || statCode / 100 == 5) {
            NSLog(@"getVersionNumber Status Code Error : %ld", (long)statCode);
        }else{
            // NSLog(@"getVersionNumber Connect-OK:%@", result);
          
            verNumber = [result floatValue];
        }
    }

    [result release];
    return (verNumber);
}

// 指定WebクリップのURLにてURLに飛ぶ（Safariが開く）
+ (void) openWebCilp:(CGFloat)verNum
{
    // 設定ファイル管理インスタンスを取得して、WebクリップのURLを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
    
    NSMutableString *serverUrl = [NSMutableString string];
    if (! [defaluts stringForKey:VERSION_UP_URL_KEY])
    {
        [defaluts setValue:VERSION_UP_URL_DEFAULT forKey: VERSION_UP_URL_KEY];
        [defaluts synchronize];
    }
    
    [serverUrl appendString:[defaluts stringForKey:VERSION_UP_URL_KEY]];
    
    // URLに遷移しない設定（空文字 or none）
    if ( ([serverUrl length] <= 0) || ([serverUrl hasPrefix:@"none"]) )
    {   return; }
    
    // verによるurlの組み立て ...../verxxx/aCalulu.ipa => 直接ダウンロードできない？
    /*NSInteger VNum = (((NSInteger)(verNum*100.0f)) % 100);
    [serverUrl appendFormat:@"ver%d%02d/aCalulu.ipa", (NSInteger)verNum, VNum];*/

#ifdef FOR_GRANT
    NSString *ver = [[NSString stringWithFormat:@"%.2f",verNum] stringByReplacingOccurrencesOfString:@"." withString:@""];
    [serverUrl appendFormat:@"ver%@/",ver];
#endif
    
    NSString *msg 
        = [NSString stringWithFormat:@"%@の\n新しいバージョン(Ver%.2f)が\n公開されています\n今すぐダウンロードしますか？",
            VERSION_TITLE, verNum];
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if(iOSVersion<8.0) {
        [[[UIAlertView alloc]
          initWithTitle: [NSString stringWithFormat:@"%@からのお知らせ", VERSION_TITLE]
          message:msg
          callback:^(NSInteger buttonIndex) {
              if(buttonIndex != 0) {
                  // [キャンセル]処理
              } else {
                  // [OK]処理
                  [[UIApplication sharedApplication] openURL:
                   [NSURL URLWithString:serverUrl]];
                  
              }
          }
          cancelButtonTitle:@"OK"
          otherButtonTitles:@"キャンセル", nil]
         show];
    } else {
#ifdef SUPPORT_IOS8
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@からのお知らせ", VERSION_TITLE]
                                            message:msg
                                     preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    // [OK]処理
                                                    NSLog(@"serverUrl %@",serverUrl);
                                                    [[UIApplication sharedApplication] openURL:
                                                     [NSURL URLWithString:serverUrl]];
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"キャンセル"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    
                                                }]];
        
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;

        [mainVC presentViewController:alert animated:YES completion:nil];
#endif
    }
}


#pragma mark - public_methods

// バージョン情報を取得して相違があれば、アップデートを促す
+(VERSION_INFO_RESULT) getVersionInfo
{
    VERSION_INFO_RESULT result = VERSION_INFO_UNKNOWN;
    
    @try {
        dispatch_queue_t queue =
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            
            // ネットワークの接続を確認する
            REACHABLE_STATUS nwStat
                = [ReachabilityManager reachabilityStatusWithHostName: VER_INFO_SITE];
            
            if (nwStat != REACHABLE_HOST)
            {   return; }
            
            // バージョン情報（番号）を取得する
            CGFloat verNumber = [VersionInfoManaegr getVersionNumber];
            if (verNumber <= 0.0f)
            {   return; }
            
            // info.plistよりバージョン番号を取得:Bundle Versionキーで設定
            NSString *ver
                = [ [[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            CGFloat devVer = [ver floatValue];
            
            if (verNumber <= devVer)
            {
                // 既に最新バージョンがダウンロードされている
                return;
            }
            
            // メインスレッドに通知
            dispatch_async(dispatch_get_main_queue(), ^{
                // 新しいバージョンがリリースされているので、指定URLに飛ぶ
                [ VersionInfoManaegr openWebCilp:verNumber];
            });
        } );
        
    }
    @catch (NSException *exception) {
        result = VERSION_INFO_ERROR;
        
        NSLog(@"getVersionInfo: Caught %@: %@", [exception name], [exception reason]);
    }
    
    return (result);
}

#endif

// Webクリップ用のURL : WEB_CLIP_URL

@end
