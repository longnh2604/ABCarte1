//
//  itemTableField.h
//  iPadCamera
//
//  Created by MacBook on 11/06/26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DB_ID_INVALID		NSUIntegerMax		// DataBase上のID無効値（ユーザ固有領域）
#define ORDER_NUM_INVALID	NSUIntegerMax		// 選択順序無効値
#define INDEX_INVALID		NSIntegerMin		// index無効値
#define PRESET_DB_ID        10000               // データベースに保存しないプリセットのDBID

///
/// 項目テーブルのfieldを表現するクラス
///
@interface itemTableField : NSObject {
	
// @private
	
	NSUInteger		dbID;				// DataBase上のID
	NSInteger		index;				// index:0始まり
	NSUInteger		orderNum;			// 選択順序:0始まり
	NSString		*name;				// 項目の名前
	BOOL			isSelected;			// 選択／非選択
	BOOL			isEditSelected;		// 編集用選択／非選択
	BOOL			isDeleted;			// 削除フラグ	：優先度=高
	BOOL			isInserted;			// 追加フラグ	：優先度=中
	BOOL			isEdited;			// 編集フラグ	：優先度=低
}

@property(nonatomic, readonly)		NSUInteger		dbID;
@property(nonatomic, readonly)		NSInteger		index;
@property(nonatomic)		NSUInteger		orderNum;
@property(nonatomic, copy)	NSString		*name;
@property(nonatomic)		BOOL			isSelected;
@property(nonatomic)		BOOL			isEditSelected;
@property(nonatomic)	BOOL		isDeleted;
@property(nonatomic, readonly)	BOOL		isInserted;
@property(nonatomic, readonly)	BOOL		isEdited;


// 初期化
- (id) initWithIndex:(NSInteger)idx
			itemName:(NSString*)name
		  dataBaseID:(NSUInteger)dbID;

// 初期化(ユーザ固有)
- (id) initWithIndex4UserOnly:(NSInteger)idx
					 orderNum:(NSUInteger)order
					 itemName:(NSString*)name;

// 選択フラグの設定
- (void) setSelectedFlag;

// 編集用選択フラグの設定
- (void) setEditSelectedFlag;

// 削除フラグの設定
- (void) setDeletedFlag;

// 追加フラグの設定
- (void) setInsertedFlag;

// 編集の設定
- (void) setEditedWithName:(NSString*)iName;

// ユーザ固有領域であるか
- (BOOL)isUserArea;

@end
