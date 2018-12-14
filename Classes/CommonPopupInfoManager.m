//
//  CommonPopupInfoManager.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/06.
//
//

/*
 ** IMPORT
 */
#import "CommonPopupInfoManager.h"

@implementation CommonPopupInfoManager


#pragma mark iOS_Framework
/**
 init
 */
- (id) init
{
	self = [super init];
	if ( self )
	{
		// 共通情報の確保
		_arrayCommonInfo = [[NSMutableArray alloc] init];
	}
	return self;
}

/**
 dealloc
 */
- (void) dealloc
{
	// 共通情報の解放
	[_arrayCommonInfo removeAllObjects];
	[_arrayCommonInfo release];
	[super dealloc];
}


#pragma mark LocalMethod
/**
 setCommonInfo
 */
- (BOOL) setCommonInfo:(CommonPopupInfo*) commonInfo
{
	if ( commonInfo == nil ) return NO;
	// 共通情報の追加
	[_arrayCommonInfo addObject:commonInfo];
	return YES;
}

/**
 setCommonInfoInArray
 */
- (BOOL) setCommonInfoInArray:(NSMutableArray*) arrayInfo
{
	if ( arrayInfo == nil ) return NO;
	// 共通情報の追加
	[_arrayCommonInfo addObject:arrayInfo];
	return YES;
}

/**
 getCommonInfoCounts
 */
- (NSInteger) getCommonInfoCounts
{
	// 共通情報の数を取得
	return [_arrayCommonInfo count];
}

/**
 getCommonInfoByRow
 */
- (CommonPopupInfo*) getCommonInfoByRow:(NSInteger) row
{
	// 共通情報を取得
	if ( row < 0 ) return nil;
	return (CommonPopupInfo*)[_arrayCommonInfo objectAtIndex:row];
}

/**
 getCommonInfoArrayBySection
 */
- (NSMutableArray*) getCommonInfoArrayBySection:(NSInteger) section
{
	// 共通情報を取得
	return (NSMutableArray*)[_arrayCommonInfo objectAtIndex:section];
}

/**
 getCommonInfoByRow
 共通情報の取得
 @param section セクション
 @return 共通情報
 */
- (CommonPopupInfo*) getCommonInfoArrayBySection:(NSInteger) section Row:(NSInteger) row
{
	NSMutableArray* infos = [self getCommonInfoArrayBySection:section];
	return [infos objectAtIndex:row];
}

/**
 getCommonInfoTitleAll
 */
- (NSArray*) getCommonInfoTitleAll
{
	NSMutableArray* _srcArray = [NSMutableArray array];
	for ( CommonPopupInfo* commonInfo in _arrayCommonInfo )
	{
		// タイトルを入力していく
		[_srcArray addObject: [commonInfo strTitle]];
	}

	// NSMutableArray -> NSArray
	NSArray* _dstArray = [_srcArray copy];
	return _dstArray;
}

/**
 getCommonInfoTitleByRow
 */
- (NSString*) getCommonInfoTitleByRow:(NSInteger) row
{
	// 共通情報のタイトルを取得
	if ( row < 0 ) return nil;
	return [[self getCommonInfoByRow:row] strTitle];
}

/**
 */
- (NSString*) getCommonInfoTmplIdByRow:(NSInteger) row
{
	return [[self getCommonInfoByRow:row] CommonId];
}

/**
 setSelect
 */
- (void) setSelectAll:(BOOL) select
{
	for ( CommonPopupInfo* commonInfo in _arrayCommonInfo )
	{
		// 選択
		[commonInfo setSelected:select];
	}
}

/**
 setSelectByRow
 */
- (void) setSelectByRow:(BOOL) select RowNum:(NSInteger)row
{
	// 選択
	[[self getCommonInfoByRow:row] setSelected:select];
}

/**
 getSelectByRow
 */
- (BOOL) getSelectByRow:(NSInteger) row
{
	CommonPopupInfo* info = [self getCommonInfoByRow:row];
	return info.selected;
}

/**
 removeAll
 */
- (void) removeAll
{
    [_arrayCommonInfo removeAllObjects];
}

@end
