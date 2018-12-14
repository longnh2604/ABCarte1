//
//  appCapacityManager.m
//  iPadCamera
//
//  Created by OP067 on 13/12/19.
//
//

#import "appCapacityManager.h"

/**
 * アプリケーションとデバイスの空き容量管理クラス
 */
@implementation appCapacityManager

#pragma mark private_methods_static

// デバイスのストレージ情報の取得(MB)
+ (CGFloat) _getDeviceStorageInfoWithFlag:(BOOL)isTotalGet
{
    CGFloat storageSize = (isTotalGet)? 12 : 0;
    
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        storageSize = (isTotalGet)?
            [[dictionary objectForKey: NSFileSystemSize] floatValue]/1024/1024 :
            [[dictionary objectForKey: NSFileSystemFreeSize] floatValue]/1024/1024;
    } else {
        NSLog(@"Error Obtaining File System Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    
    return (storageSize);
}

#pragma mark public_methods_static

/**
 *  アプリケーション使用容量設定値の自動設定
 *  @param      なし
 *  @return     設定値と利用可能フラグの構造体
 *  @remarks    コンテンツ保存開始前（撮影画面前）にこのメソッドにて自動設定する
 *              VideoSyncLibraryにて動画保存時に使用容量の設定値とサンドバッグ内を比較し削除している
 *              (removeVideosUntilCapacityLimitメソッドを参照)
 */
+ (APCValueEnable) setAutoAppUsingCapacity
{
    APCValueEnable valEnable;
    valEnable.isEnable = YES;
    valEnable.settingValue = 1.0f;
    
    @try {
        // 現在のデバイス空き容量の８０％値[GB]
        CGFloat freeSpace = ([appCapacityManager getDeviceStorageFreeSpace] / 1024.0f)* 0.8f;
        valEnable.freeDevSpace = [appCapacityManager getDeviceStorageFreeSpace];
        if (freeSpace < 1) {
            freeSpace = 1;
            valEnable.isEnable = NO;
        }
        
        // ユーザ設定を取得
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        CGFloat localCapacity = [df floatForKey:USER_DEFAULT_APP_USING_CAPACITY_KEY];
        
        BOOL isSetted = YES;
        if (localCapacity <= 0) {
            // 未設定の場合(0.00)、仮にデフォルト値を設定
            localCapacity = APP_USINNG_CAPACITY_DEFAULT;
            isSetted = NO;
        }
        
        // ユーザ設定値がデバイス空き容量８０％以上であるかを評価
        if (localCapacity > freeSpace) {
            // ユーザ設定値は空き容量を超えているので修正
            localCapacity = freeSpace;
            isSetted = NO;
        }
        
        // 修正した(もしくは未設定)場合ユーザ設定を更新
        if (! isSetted) {
            [df setFloat:localCapacity forKey:USER_DEFAULT_APP_USING_CAPACITY_KEY];
            [df synchronize];
        }
        
        // 正常な設定値を返す
        valEnable.settingValue = localCapacity;
        
    }
    @catch (NSException *exception) {
        NSLog(@"setAutoAppUsingCapacity: Caught %@: %@",
              [exception name], [exception reason]);

    }
    return (valEnable);
}

/**
 *  デバイスの空き容量の取得
 *  @param      なし
 *  @return     デバイスの空き容量[MB]
 *  @remarks
 */
+ (CGFloat) getDeviceStorageFreeSpace
{
    return ([appCapacityManager _getDeviceStorageInfoWithFlag:NO]);
}

/**
 *  デバイスの総容量の取得
 *  @param      なし
 *  @return     デバイスの総容量[MB]
 *  @remarks
 */
+ (CGFloat) getDeviceStorageAllSpace
{
    return ([appCapacityManager _getDeviceStorageInfoWithFlag:YES]);
}

@end
