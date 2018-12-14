//
//  SendMailHistoryInfoManager.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/06.
//
//

/*
 ** IMPORT
 */
#import <Foundation/Foundation.h>
#import "SendMailHistoryInfo.h"

/*
 ** INTERFACE
 */
@interface SendMailHistoryInfoManager : NSObject
{
	NSMutableArray* _arrayHistoryInfo;
}

/*
 ** METHOD
 */

/**
 setMailHistoryInfo
 送信履歴の設定
 @param info 送信履歴
 */
- (BOOL) setMailHistoryInfo:(SendMailHistoryInfo*) info;

/**
 getMailHistoryInfoByRow
 選択行から送信履歴を求める
 */
- (SendMailHistoryInfo*) getMailHistoryInfoByRow:(NSInteger) row;

/**
 getHistoryCounts
 送信履歴の数
 */
- (NSInteger) getHistoryCounts;

/**
 removeAll
 送信履歴の全削除
 */
- (void) removeAll;

@end
