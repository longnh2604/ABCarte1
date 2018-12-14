//
//  appCapacityManager.h
//  iPadCamera
//
//  Created by OP067 on 13/12/19.
//
//

#import <Foundation/Foundation.h>

/**
 * ユーザ設定値のアプリケーション使用容量の設定キー
 */
#define USER_DEFAULT_APP_USING_CAPACITY_KEY     @"local_capacity"

/**
 * デバイスの空き容量下限[GB]：これ以下の場合は、コンテンツの保存をできなくする
 */
#define DEVICE_FREE_CAPACITY_MIN        1.0f

/**
 * 使用容量の設定値のデフォルト[GB]：但し、空き容量以下とすること
 */
#define APP_USINNG_CAPACITY_DEFAULT     5.0f

/**
 * 設定値と利用可能フラグの構造体
 */
struct APCValueEnable {
    CGFloat     settingValue;           /* 設定された値 */
    BOOL        isEnable;               /* 利用可能  YES:利用可能 　NO:利用不可（空き容量なし）*/
    CGFloat     freeDevSpace;           /* 空き容量(MB) */
};
typedef struct APCValueEnable APCValueEnable;

/**
 * アプリケーションとデバイスの空き容量管理クラス
 */
@interface appCapacityManager : NSObject

/**
 *  アプリケーション使用容量設定値の自動設定
 *  @param      なし
 *  @return     設定値と利用可能フラグの構造体
 *  @remarks    コンテンツ保存開始前（撮影画面前）にこのメソッドにて自動設定する
 *              VideoSyncLibraryにて動画保存時に使用容量の設定値とサンドバッグ内を比較し削除している
 *              (removeVideosUntilCapacityLimitメソッドを参照)
 */
+ (APCValueEnable) setAutoAppUsingCapacity;

// デバイスのストレージ情報の取得(MB)

/**
 *  デバイスの空き容量の取得
 *  @param      なし
 *  @return     デバイスの空き容量[MB]
 *  @remarks
 */
+ (CGFloat) getDeviceStorageFreeSpace;


/**
 *  デバイスの総容量の取得
 *  @param      なし
 *  @return     デバイスの総容量[MB]
 *  @remarks
 */
+ (CGFloat) getDeviceStorageAllSpace;

@end
