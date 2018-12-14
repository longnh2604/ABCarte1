//
//  CommonPopupInfoManager.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/06.
//
//

/*
 ** IMPORT
 */
#import <Foundation/Foundation.h>
#import "CommonPopupInfo.h"

/*
 ** INTERFACE
 */
@interface CommonPopupInfoManager : NSObject
{
	NSMutableArray* _arrayCommonInfo;	// CommonPopupInfoの集まり
}

/*
 ** METHOD
 */

/**
 setCommonInfo
 共通情報の設定
 */
- (BOOL) setCommonInfo:(CommonPopupInfo*) commonInfo;

/**
 setCommonInfo
 共通情報の設定
 */
- (BOOL) setCommonInfoInArray:(NSMutableArray*) arrayInfo;

/**
 getCommonInfoCounts
 共通情報の数を取得
 */
- (NSInteger) getCommonInfoCounts;

/**
 getCommonInfoByRow
 共通情報の取得
 @param row 行
 @return 共通情報
 */
- (CommonPopupInfo*) getCommonInfoByRow:(NSInteger) row;

/**
 getCommonInfoByRow
 共通情報の取得
 @param section セクション
 @return 共通情報
 */
- (NSMutableArray*) getCommonInfoArrayBySection:(NSInteger) section;

/**
 getCommonInfoByRow
 共通情報の取得
 @param section セクション
 @return 共通情報
 */
- (CommonPopupInfo*) getCommonInfoArrayBySection:(NSInteger) section Row:(NSInteger) row;

/**
 getCommonInfoTitleAll
 共通情報のタイトルを全て取得する
 @return 共通情報のタイトル
 */
- (NSArray*) getCommonInfoTitleAll;

/**
 getCommonInfoTitleByRow
 共通情報のタイトルを取得する
 @param selection セレクション
 @return 共通情報のタイトル
 */
- (NSString*) getCommonInfoTitleByRow:(NSInteger) row;

/**
 getCommonInfoTmplIdByRow
 共通情報のテンプレートIDを取得する
 @param selection セレクション
 @return 共通情報のID
 */
- (NSString*) getCommonInfoTmplIdByRow:(NSInteger) row;

/**
 setSelect
 全て選択を設定する
 @param select YES:選択 NO:非選択
 */
- (void) setSelectAll:(BOOL) select;

/**
 setSelectByRow
 指定したデータを選択する
 @param select 選択フラグ
 @param selection セレクション
 */
- (void) setSelectByRow:(BOOL) select RowNum:(NSInteger) row;

/**
 getSelectByRow
 指定したデータを取得する
 @param row 選択行
 @return YES:選択状態 NO:非選択状態
 */
- (BOOL) getSelectByRow:(NSInteger) row;

/**
 removeAll
 全データを消去する
 */
- (void) removeAll;

@end
