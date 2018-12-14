//
//  AppStoreAPIHelper.m
//  AppVersion
//
//  Created by shuichi on 13/01/25.
//  Copyright (c) 2013年 Shuichi Tsutsumi. All rights reserved.
//

#import "AppStoreAPIHelper.h"
#import "UIAleartViewCallback.h"
#import "MainViewController.h"
#import "iPadCameraAppDelegate.h"

@implementation AppStoreAPIHelper

// バージョンアップチェック
+ (void) checkAppVersionWithId
{
    @try {
        dispatch_queue_t queue =
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            
            if (![self checkNewerVersion]) {
                return ;
            }
            
            NSString * appId = ABCARTE_APPLEID;
            NSString *countryCode = @"jp";
            
            // ---- APIのURLを生成 ----
            NSString *urlStr = [NSString stringWithFormat:@"%@?id=%@",
                                kAppStoreLookupURL, appId];
            
            if ([countryCode length] > 0) {
                
                urlStr = [urlStr stringByAppendingFormat:@"&country=%@", countryCode];
            }
            
            // ---- APIコール -----
            NSError *error = nil;
            NSURLResponse *response;
            NSURLRequest *request;
            request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]
                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                   timeoutInterval:60.0];
            
            NSData *data = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
            // data==nilの場合何もしない
            if (!data) {
                NSLog(@"AppStore Version Check error [%@]", error);
                return;
            }
            
            // ---- 結果のJSONをパース ----
            error = nil;
            NSDictionary *jsonDic;
            jsonDic = [NSJSONSerialization JSONObjectWithData:data
                                                      options:NSJSONReadingAllowFragments
                                                        error:&error];
            
            if (error) {
                
                NSLog(@"appstore version check error");
                
                return;
            }
            
            NSArray *results = [jsonDic objectForKey:@"results"];
            NSDictionary *resultDic;
            NSString *ver;
            
            if ([results count] > 0) {
                
                resultDic = [results objectAtIndex:0];
                
                ver = [resultDic objectForKey:@"version"];
                
                // AppStoreの最新バージョンを格納
                NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                [ud setObject:ver forKey:@"appStoreVersion"];
                [ud synchronize];
                
                NSLog(@"バージョン番号:%@", ver);
            }
            else {
                ver = @"0.0";
                NSLog(@"該当アプリなし");
            }
            // iPadCamera-info.plistよりバージョン番号を取得:Bundle Versionキーで設定
            NSString *curver
            = [ [[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
            
#ifdef DEBUG
            // メインスレッドに通知(デバッグ時動作確認用)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self verUpAlertDbg:ver.floatValue curVer:curver.floatValue];
            });
#endif
            
            if (ver.floatValue > curver.floatValue) {
                // メインスレッドに通知
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self verUpAlert:ver.floatValue];
                });
            }
            
        } );

    }
    @catch (NSException *exception) {
//        result = VERSION_INFO_ERROR;
        
        NSLog(@"getVersionInfo: Caught %@: %@", [exception name], [exception reason]);
    }
}

// バージョンアップチェックを行う必要が有るか
+ (BOOL) checkNewerVersion
{
    // バージョンチェック最終時間格納用
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate* lastcheck = [formatter dateFromString:[ud stringForKey:@"lastcheck"]];
    
    NSString* nowString = [formatter stringFromDate:[NSDate date]];
    NSDate *now = [formatter dateFromString:nowString];
    
#ifdef DEBUG
    NSLog(@"last[%@] : now[%@]", [formatter stringFromDate:lastcheck], nowString);
#endif
    
    // 最終時間登録がない場合チェックする
    if (!lastcheck) {
        [ud setObject:[formatter stringFromDate:[NSDate date]] forKey:@"lastcheck"];
        [ud synchronize];
        return YES;
    }
    float diff = [now timeIntervalSinceDate:lastcheck];
    
    int hh = (int)(diff / 3600);

    // チェックタイムインターバル(デフォルト48時間以上)
    if (hh > CHECK_INTERVAL) {
#ifdef DEBUG
        NSLog(@"CheckOverTime(AppStore) [%d]", hh);
#endif
        [ud setObject:[formatter stringFromDate:[NSDate date]] forKey:@"lastcheck"];
        [ud synchronize];
        return YES;
    }
#ifdef DEBUG
    NSLog(@"No verUp AppStore check [last check : %@ / %.2f]", [formatter stringFromDate:lastcheck], diff);
#endif
    return NO;

}

// バージョンアップアラート表示
+ (void) verUpAlert:(CGFloat)verNum
{
#ifdef FOR_SALES
    return;
#endif
    NSString *msg
    = [NSString stringWithFormat:@"%@の\n新しいバージョン(Ver%.2f)が\n公開されています\n今すぐダウンロードしますか？",
       VERSION_TITLE, verNum];

    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion<8.0) {
        [[[UIAlertView alloc]
          initWithTitle: [NSString stringWithFormat:@"%@からのお知らせ", VERSION_TITLE]
          message:msg
          callback:^(NSInteger buttonIndex) {
              if(buttonIndex == 0) {
                  // [キャンセル]処理
              } else {
                  // [OK]処理
                  [self doAppStore];
              }
          }
          cancelButtonTitle:@"キャンセル"
          otherButtonTitles:@"OK", nil]
         show];
    } else {
#ifdef SUPPORT_IOS8
        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@からのお知らせ", VERSION_TITLE]
                                            message:msg
                                     preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"キャンセル"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {

                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    [self doAppStore];
                                                }]];
        
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        
        [mainVC presentViewController:alert animated:YES completion:nil];
#endif
    }
}

#ifdef DEBUG
// バージョンアップアラート表示
+ (void) verUpAlertDbg:(CGFloat)verNum curVer:(CGFloat)curVer
{
    NSString *msg
    = [NSString stringWithFormat:@"AppStoreVer = %.2f\nCurrentVer = %.2f\nOKを押すとAppStoreが起動します",
       verNum, curVer];
    
    [[[UIAlertView alloc]
      initWithTitle:@"AppStoreバージョンチェック結果"
      message:msg
      callback:^(NSInteger buttonIndex) {
          if(buttonIndex == 0) {
              // [キャンセル]処理
          } else {
              // [OK]処理
              [self doAppStore];
          }
      }
      cancelButtonTitle:@"キャンセル"
      otherButtonTitles:@"OK", nil]
     show];
}
#endif

// App Storeアプリ呼び出し
+ (void) doAppStore
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", ABCARTE_APPLEID]];
    [[UIApplication sharedApplication] openURL:url];
}

@end
