//
//  CloudSyncUtility.h
//  iPadCamera
//
//  Created by  on 12/04/01.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// #import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef CLOUD_SYNC

#import "SyncCommon.h"

@interface CloudSyncUtility : NSObject
{
    SYNC_RESPONSE_STATE     _state;
    BOOL                    _isDialogShow;
}

/**
 * 同期処理・通信処理の結果によりダイアログを表示
 *  @param state            同期処理・通信処理の結果
 *  @return                 YES=表示      NO=既に表示されているので表示しない
 */
+ (BOOL) SyncResultDialogShowWithState:(SYNC_RESPONSE_STATE)state;

/**
 * 同期処理・通信処理の結果の文字列を取得
 *  @param state            同期処理・通信処理の結果
 *  @return                 同期処理・通信処理の結果の文字列
 */
+ (NSString*) getSyncResponseStateWithState:(SYNC_RESPONSE_STATE)state;


@end

#else
@interface CloudSyncUtility : NSObject
@end

#endif