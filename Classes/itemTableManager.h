//
//  itemTabelManager.h
//  iPadCamera
//
//  Created by MacBook on 11/06/26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defines.h"
#import "def64bit_common.h"

@class itemTableField;
@class CommonPopupInfoManager;

///
/// 項目テーブル管理クラス
///
@interface itemTableManager : NSObject {
	
@private 
	
	NSMutableArray	*_itemTable;				// 項目テーブル
	NSUInteger		_mstDataMngArea;			// マスタデータ管理領域:マスタデータのfield個数
	NSMutableArray	*_orderNumTable;			// 順序テーブル
	
	HISTID_INT		_histID;					// histID
	ITEM_EDIT_KIND	_editKind;					// 項目編集種別
	NSMutableArray	*_itemListStrings;			// クライアントクラスで設定されているitem文字の一覧
    
    CommonPopupInfoManager  *_commonInfoMgr;    //  日付、汎用フィールドの情報を管理
    NSMutableDictionary     *_presets;          //  日付、汎用フィールドのプリセットデータ
}

@property(nonatomic, assign)	NSMutableArray *itemTable;
@property(nonatomic, assign)	NSMutableArray *orderNumTable;

// 初期化
- (id) initTableWithHistID:(HISTID_INT)histID
			itemListString:(NSString*)strings
			  itemEditKind:(ITEM_EDIT_KIND)editKind;

// 有効な項目のリスト（一覧リスト）の取得
- (NSArray*) getValidList;

// 選択されている項目のindexのリストを取得
- (NSArray*) getSelectedIndexList;

// 選択状態の切り替え　戻り値：選択されているitemの一覧
- (NSArray*) swicthSelectedState:(NSUInteger)index;

// 項目のindex番目の名前を取得する
-(NSString*) getItemNameIndex:(NSInteger)index;

// 選択状態を全て解除する
- (void) allResetSelectedState;

// 項目テーブルに編集用選択を通知　戻り値：前回の編集用選択のindex
- (NSInteger) setEditSelectedState:(NSInteger)index;

// 編集または追加する名前が既存でないかを確認
- (NSInteger) isExistName:(NSString*)name index:(NSInteger)index;

// 項目の追加
- (itemTableField*) insertItemWithName:(NSString*)name;

// 項目の編集
- (itemTableField*) editItemWithIndex:(NSInteger)index editName:(NSString*)name;

// 項目の削除
- (void) deleteItemWithIndex:(NSInteger)index;

// 項目の全削除
- (void) deleteAllItem;

// 全項目の更新: 戻り値：ユーザ管理領域での変更があったか？
- (BOOL) updateAllItem;

// 全項目の取消
- (void) chancelAllItem;

// 編集可能
-(BOOL) enabledEdit:(NSInteger)index;

@end
