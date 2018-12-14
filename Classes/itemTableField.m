//
//  itemTableField.m
//  iPadCamera
//
//  Created by MacBook on 11/06/26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "itemTableField.h"

///
/// 項目テーブルのfieldを表現するクラス
///
@implementation itemTableField

@synthesize dbID;
@synthesize index;
@synthesize orderNum;
@synthesize name;
@synthesize isSelected;
@synthesize isEditSelected;
@synthesize isDeleted;
@synthesize isInserted;
@synthesize isEdited;

#pragma mark local_methds

// メンバ初期化
- (void) initMember
{
	// self.dbID = DB_ID_INVALID;
	isSelected = NO;
	isEditSelected = NO;
	isDeleted = NO;
	isInserted = NO;
	isEdited = NO;
}

#pragma mark life_cycle

// 初期化
- (id) initWithIndex:(NSInteger)idx
			itemName:(NSString*)iName
		  dataBaseID:(NSUInteger)ID
{
	if ( (self = [super init]))
	{
		dbID = ID;
		index = idx;
		self.name = iName; 
		
		// メンバ初期化
		[self initMember];
	}
	
	return (self);
}

// 初期化(ユーザ固有)
- (id) initWithIndex4UserOnly:(NSInteger)idx
					 orderNum:(NSUInteger)order
					 itemName:(NSString*)iName
{
	if ( (self = [self initWithIndex:idx 
							 itemName:iName dataBaseID:DB_ID_INVALID]) )
	{
		// 選択フラグを設定
		isSelected = YES;
		// 順序を設定
		orderNum = order;
	}
	
	return (self);
}

#pragma mark public_methods

// 選択フラグの設定
- (void) setSelectedFlag
{	isSelected = ! isSelected; }

// 編集用選択フラグの設定
- (void) setEditSelectedFlag
{	isEditSelected = ! isEditSelected; }

// 削除フラグの設定
- (void) setDeletedFlag
{	
	isDeleted = YES; 
	
	// 追加と編集フラグをここでリセット（優先度：高） 
	isInserted = isEdited = NO;
}

// 追加フラグの設定
- (void) setInsertedFlag
{	
	// 削除済みには適用しない
	if (isDeleted)
	{	return; }
	
	isInserted = YES; 
	
	// 編集フラグをここでリセット（優先度：中） 
	isEdited = NO;
}

// 編集の設定
- (void) setEditedWithName:(NSString*)iName
{	
	// 削除済みには適用しない
	if ( isDeleted)
	{	return; }
	
	// 追加済みでなければ編集フラグをセット
	if (! isInserted)
	{	isEdited = YES;}
	
	// 名前の設定
	self.name = iName;
}

// ユーザ固有領域であるか
- (BOOL)isUserArea
{
	return ( (! isInserted) && (dbID == DB_ID_INVALID) );
}

@end
