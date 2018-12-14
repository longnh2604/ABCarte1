//
//  SendMailHistoryInfoManager.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/06.
//
//

/*
 ** IMPORT
 */
#import "SendMailHistoryInfoManager.h"

@implementation SendMailHistoryInfoManager

#pragma mark iOS_Framework
/**
 init
 */
- (id) init
{
	self = [super init];
	if ( self )
	{
		// 送信履歴情報の確保
		_arrayHistoryInfo = [[NSMutableArray alloc] init];
	}
	return self;
}

/**
 dealloc
 */
- (void) dealloc
{
	// 送信履歴情報の解放
	[_arrayHistoryInfo removeAllObjects];
	[_arrayHistoryInfo release];
	[super dealloc];
}


#pragma mark SendMailHistoryInfoManager_Method
/**
 setMailHistoryInfo
 */
- (BOOL) setMailHistoryInfo:(SendMailHistoryInfo*) info
{
	if ( info == nil ) return NO;
    [_arrayHistoryInfo insertObject:info atIndex:0];
//	[_arrayHistoryInfo addObject:info];
	return YES;
}

/**
 getMailHistoryInfoByRow
 */
- (SendMailHistoryInfo*) getMailHistoryInfoByRow:(NSInteger) row
{
	if ( [_arrayHistoryInfo count] <= row )
		return nil;
	return (SendMailHistoryInfo*)[_arrayHistoryInfo objectAtIndex:row];
}

/**
 getHistoryCounts
 */
- (NSInteger) getHistoryCounts
{
	// 履歴の数
	return [_arrayHistoryInfo count];
}

/**
 removeAll
 */
- (void) removeAll
{
	// 履歴の全削除
	[_arrayHistoryInfo removeAllObjects];
}


@end;;

