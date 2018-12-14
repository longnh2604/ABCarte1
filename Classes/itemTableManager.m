//
//  itemTabelManager.m
//  iPadCamera
//
//  Created by MacBook on 11/06/26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "userDbManager.h"

#import "itemTableManager.h"
#import "itemTableField.h"
#import "CommonPopupInfoManager.h"

///
/// 項目テーブル管理クラス
///
@implementation itemTableManager

@synthesize itemTable = _itemTable;
@synthesize orderNumTable = _orderNumTable;

#pragma mark private_methods

// 選択文字列一覧より配列を生成
- (void) makeStrArrayWithSelStrings:(NSString*)strings
{
	if (_itemListStrings)
	{	return; }
	
	_itemListStrings = [NSMutableArray array];
	[_itemListStrings retain];
	// [_itemListStrings autorelease];
	
	NSCharacterSet	*chSet 
	= [NSCharacterSet characterSetWithCharactersInString:@"・"];
	NSScanner		*scanner = [NSScanner scannerWithString:strings];
	NSString		*scanned;
	while (! [scanner isAtEnd]) {
		// tokenで取り出し
		if ([scanner scanUpToCharactersFromSet:chSet intoString:&scanned])
		{
			[_itemListStrings addObject:scanned];
		}
		[scanner scanCharactersFromSet:chSet intoString:nil];
	}
	
}

// マスタテーブルより項目を取得
- (void) getItems2MstTbl :(ITEM_EDIT_KIND)editKind
{
	// データベースの初期化
	userDbManager *dbMng = [[userDbManager alloc] init];
    NSInteger idx = 0;
    itemTableField *field = nil;

    switch (editKind) {
        case ITEM_EDIT_USER_WORK1:;
        case ITEM_EDIT_USER_WORK2:;
        case ITEM_EDIT_PICTUE_NAME:;
            
            // 項目マスタテーブルよりitemを取得 : key -> itemID   value -> itemName
            NSDictionary *dictItems
            = [dbMng getItems2TableWithEditKind:editKind];
            if (! dictItems)
            {
                [dbMng release];
                return;
            }
            
            // keyを昇順に並び替える
            NSArray *keys = [dictItems allKeys];
            NSMutableArray *ids = [NSMutableArray array];
            for (id key in keys)
            {	[ids addObject:key]; }
            
            [ids sortUsingComparator:^(id obj1, id obj2)
             {
                 // return [obj1 compare:obj2];
                 NSComparisonResult result;
                 NSInteger sub = [obj1 intValue] - [obj2 intValue];
                 if (sub < 0) result = NSOrderedAscending;
                 else if (sub > 0) result = NSOrderedDescending;
                 else result = NSOrderedSame;
                 
                 return (result);
             }];
            
            // itemIDとnameを取得
            for ( NSString *mstID in ids) {
                field = [[itemTableField alloc] initWithIndex:idx++
                                                     itemName:[dictItems objectForKey:mstID]
                                                   dataBaseID:(NSUInteger)[mstID intValue]];
                // 項目テーブルに加える：マスタデータ管理領域
                [_itemTable addObject:field];
                [field release];
            }
            break;
            
        case ITEM_EDIT_DATE:;
            //  変更負荷プリセット登録
            if( _presets == nil )
            {
                _presets = [[NSMutableDictionary alloc] init];
                [_presets setObject:@"{__DATE+YEAR__}" forKey:@"１年後"];
                [_presets setObject:@"{__DATE__}" forKey:@"当日"];
            }
            if( [_itemTable count] == 0 )
            {
                NSArray *presetList = [_presets  allKeys];
                for( NSString *preset in presetList )
                {
                    field = [[itemTableField alloc] initWithIndex:[_itemTable count]
                                                         itemName:preset
                                                       dataBaseID:PRESET_DB_ID];
                    [_itemTable addObject:field];
                    [field release];
                }
            }
        case ITEM_EDIT_GENERAL1:;
        case ITEM_EDIT_GENERAL2:;
        case ITEM_EDIT_GENERAL3:;
            NSMutableArray *templateItems = [NSMutableArray array];
            [dbMng loadGeneralFieldItemType:editKind-ITEM_EDIT_DATE
                                   NameData:&templateItems];
            
            if( _commonInfoMgr == nil )
            {   //  日付、汎用フィールド
                _commonInfoMgr = [[CommonPopupInfoManager alloc] init];
            }
            [_commonInfoMgr removeAll];
            for( NSArray* item in templateItems )
            {
                // 設定
                CommonPopupInfo* _commonInfo = [[[CommonPopupInfo alloc] init] autorelease];
                [_commonInfo setCommonId:[item objectAtIndex:0]];
                [_commonInfo setStrTitle:[item objectAtIndex:1]];
                [_commonInfo setUpdateTime:[(NSNumber*)[item objectAtIndex:2] doubleValue]];
                [_commonInfo setSelected:NO];
                
                NSString *itemName = [item objectAtIndex:1];
                if( editKind == ITEM_EDIT_DATE )
                {
                    itemName = [NSString stringWithFormat:@"%@日後", itemName];
                }
                
                field = [[itemTableField alloc] initWithIndex:[_itemTable count]
                                                     itemName:itemName
                                                   dataBaseID:[_commonInfoMgr getCommonInfoCounts]];
                
                // 追加
                [_commonInfoMgr setCommonInfo:_commonInfo];
                // 項目テーブルに加える：マスタデータ管理領域
                [_itemTable addObject:field];
                [field release];
            }
            
            break;
        default:
            break;
    }
	[dbMng release];
}

// 履歴IDに該当する項目名一覧の取得
- (NSDictionary*) getItemNamesByHistID: (NSMutableArray**) sortedKey
{
	// データベースの初期化
	userDbManager *dbMng = [[userDbManager alloc] init];
	
	// 履歴IDに該当する項目名一覧の取得: key -> orderNum   value -> itemName
	NSDictionary *itemNames
	= [dbMng getItemNamesByHistID:_histID itemEditKind:_editKind];
	
	[dbMng release];
	
	if (! itemNames)
	{
		// stringList = nil;
		return (nil);
	}
	
	// key(orderNum)を昇順に並び替える
	NSArray *keys = [itemNames allKeys];
	*sortedKey = [NSMutableArray array];
	for (id key in keys)
	{	[*sortedKey addObject:key]; }
	[*sortedKey sortUsingComparator:^(id obj1, id obj2)
	 {
		 return [obj1 compare:obj2];
	 }];
	
	return (itemNames);
}

// 該当histIDの項目を取得
- (void) getItems2HistID
{
	// 履歴IDに該当する項目名一覧の取得
	/*
	NSMutableArray *orders;
	NSDictionary *itemNames = [self getItemNamesByHistID:&orders];
	if (! itemNames)
	{	return; }
	*/
		
	// 項目テーブルにない名前を追加する：ユーザ固有領域
	// for (NSString* order in orders)
	NSInteger order = 0;
	for (NSString* name in _itemListStrings)
	{
		NSInteger findIdx = NSIntegerMin;
		// NSString *name = [itemNames objectForKey:order];
		for (itemTableField* field in _itemTable)
		{
			if ( [name isEqualToString:field.name])
			{
				findIdx = field.index;
				break;
			}
		}
		
		itemTableField *field = nil;
		
		if (findIdx != NSIntegerMin)
		{
			// 項目テーブルに名前があったので、選択フラグをセット
			field = [_itemTable objectAtIndex:findIdx];
			[field setSelectedFlag];
			field.orderNum = order;
		}
		else 
		{
			// 項目テーブルに名前がなかったので、fieldを追加
			field 
				= [[itemTableField alloc] initWithIndex4UserOnly:(NSInteger)[_itemTable count]
														orderNum:order
														itemName:name];
			[_itemTable addObject:field];
            [field release];
		}
			
		// 順序テーブルへの追加
		[_orderNumTable addObject:name];
			// [_orderNumTable addObject:[itemNames objectForKey:order]];
					
		order++;
	}
		
}

// テーブル類の初期化
- (void) tablesInit
{
	// マスタテーブルより項目を取得
	[self getItems2MstTbl :_editKind];
	
	// マスタデータ管理領域を設定
	_mstDataMngArea = [_itemTable count];
	
	// 該当histIDの項目を取得
    switch(_editKind){
    case ITEM_EDIT_USER_WORK1:
    case ITEM_EDIT_USER_WORK2:
    case ITEM_EDIT_PICTUE_NAME:;
        [self getItems2HistID];
        break;
    default:;
        break;
    }
}

#pragma mark life_cycle

// 初期化
- (id) initTableWithHistID:(HISTID_INT)histID
            itemListString:(NSString*)strings
              itemEditKind:(ITEM_EDIT_KIND)editKind
{
	if ( (self = [super init]) )
	{
		// 項目テーブルのインスタンス作成
		_itemTable = [NSMutableArray array];
		[_itemTable retain];
		
		// 順序テーブルのインスタンス作成
		_orderNumTable = [NSMutableArray array];
		[_orderNumTable retain];
		
		// item文字の一覧をここで設定
		[self makeStrArrayWithSelStrings:strings];
		
		// メンバの保存
		_histID = histID;
		_editKind = editKind;
		
		// テーブル類の初期化
		[self tablesInit];
	}
	
	return (self);
}

- (void)dealloc {
    
	if (_itemTable)
	{
        [_itemTable removeAllObjects];
		[_itemTable release];
		_itemTable = nil;
	}
	
	if (_orderNumTable)
	{
		[_orderNumTable removeAllObjects];
		[_orderNumTable release];
		_orderNumTable = nil;
	}
	
	if (_itemListStrings)
	{
		[_itemListStrings removeAllObjects];
		[_itemListStrings release];
		_itemListStrings = nil;
	}
	
	if(_commonInfoMgr)
    {
        [_commonInfoMgr release];
        _commonInfoMgr = nil;
    }
    
    if( _presets )
    {
        [_presets removeAllObjects];
        [_presets release];
        _presets = nil;
    }
	[super dealloc];
}

#pragma mark pubic_methods

// 有効な項目のリスト（一覧リスト）の取得:削除フラグであるものを除く
- (NSArray*) getValidList
{
	NSMutableArray *list = [NSMutableArray array];
	// [list autorelease];
	
	for (itemTableField* filed in _itemTable)
	{
		if (filed.isDeleted)
		{	continue; }
		
		[list addObject:filed];
	}
	
	return (list);
}

// 選択されている項目のindexのリストを取得
- (NSArray*) getSelectedIndexList
{
	NSMutableArray *list = [NSMutableArray array];
	// [list autorelease];
	
	for (itemTableField* filed in _itemTable)
	{
		if (filed.isDeleted)
		{	continue; }
		
		if (! filed.isSelected)
		{	continue; }
			
		[list addObject:filed];
	}
	
	return (list);	
}

// 選択状態の切り替え　戻り値：選択されているitemの一覧
- (NSArray*) swicthSelectedState:(NSUInteger)index
{
	if (index >= [ _itemTable count] )
	{	return (nil); }		// 念のため長さチェック
	
	// 先に指定indexの選択を切り替え
	itemTableField *field = [_itemTable objectAtIndex:index];
	[field setSelectedFlag];
	
	// 順序テーブルの更新
	if (field.isSelected)
	{
		// 選択されているので順序テーブルに追加
		if(! [_orderNumTable containsObject:field.name])
		{	[_orderNumTable addObject:field.name]; }
	}
	else {
		// 選択されていないので順序テーブルより削除
		[_orderNumTable removeObject:field.name];
	}

	// 順序テーブルを返す
	return (_orderNumTable);	
}

-(NSString*) getItemNameIndex:(NSInteger)index
{
    if (index >= [ _itemTable count] )  return nil;	// 念のため長さチェック
    
    NSString *name = nil;
    itemTableField *field = [_itemTable objectAtIndex:index];
    NSInteger dbId = [field dbID];
    
    switch (_editKind) {
        case ITEM_EDIT_USER_WORK1:;
        case ITEM_EDIT_USER_WORK2:;
        case ITEM_EDIT_PICTUE_NAME:;
            name = field.name;
            break;
            
        case ITEM_EDIT_DATE:;
            if( dbId == PRESET_DB_ID ){
                name = [_presets objectForKey:field.name];
            }
            else
            {
                name = [NSString stringWithFormat:@"{__DATE+%@__}", [_commonInfoMgr getCommonInfoTitleByRow:dbId]];
            }
            break;
            
        case ITEM_EDIT_GENERAL1:;
        case ITEM_EDIT_GENERAL2:;
        case ITEM_EDIT_GENERAL3:;
            if( dbId == PRESET_DB_ID ){
                name = [_presets objectForKey:field.name];
            }
            else
            {
                name = [_commonInfoMgr getCommonInfoTitleByRow:dbId];
            }
            break;
            
        default:
            break;
    }
    
    
    return name;
}

// 選択状態を全て解除する
- (void) allResetSelectedState
{
	// 全てのfieldの選択をクリア
	for (itemTableField* filed in _itemTable)
	{
		if (filed.isDeleted)
		{	continue; }
		
		if (! filed.isSelected)
		{	continue; }
		
		[filed setSelectedFlag];
	}

	// 順序テーブルのクリア
	[_orderNumTable removeAllObjects];
	
}

// 項目テーブルに編集用選択を通知　戻り値：前回の編集用選択のindex
- (NSInteger) setEditSelectedState:(NSInteger)index
{
	NSInteger beforeIndex = NSIntegerMin;
	
	if (index >= [ _itemTable count] )
	{	return (beforeIndex); }		// 念のため長さチェック
	
	// 先に前回の編集用選択をリセットする
	for (itemTableField* filed in _itemTable)
	{
		if (filed.isEditSelected)
		{	
			// 前回の編集用選択
			filed.isEditSelected = NO;
			if (index != filed.index) 
			{ beforeIndex = filed.index;}	// 自分のIndexは除く
			break;
		}
	}
	
	// 指定indexのfield
	itemTableField *field = [_itemTable objectAtIndex:index];
	// fieldの編集用選択の設定
	field.isEditSelected = YES;
	
	return (beforeIndex);
}

// 編集または追加する名前が既存でないかを確認
- (NSInteger) isExistName:(NSString*)name index:(NSInteger)index
{
	NSInteger existIdx = INDEX_INVALID;
	
	for (itemTableField* filed in _itemTable)
	{
		if (filed.isDeleted)
		{	continue; }		// 削除済みは除く
		
		//if (filed.index == index)
		// {	continue; }		// 同じindexは除く
		
		if ([filed.name isEqualToString:name])
		{
			existIdx = filed.index;
			break;
		}
	}
	
	return (existIdx);
	
}

// 項目の追加
- (itemTableField*) insertItemWithName:(NSString*)name
{
	// 新規にfieldを作成
	itemTableField *field 
		= [[itemTableField alloc] initWithIndex:[_itemTable count]
								   itemName:name
								 dataBaseID:DB_ID_INVALID];
	// 追加フラグを設定
	[field setInsertedFlag];
	
	// 項目テーブルに加える
	[_itemTable addObject:field];
	
	// 該当fieldを返す
	return (field);
}

// 項目の編集
- (itemTableField*) editItemWithIndex:(NSInteger)index editName:(NSString*)name
{
	if (index >= [ _itemTable count] )
	{	return (nil); }		// 念のため長さチェック
	
	// 指定indexのfield
	itemTableField *field = [_itemTable objectAtIndex:index];
	
	// 先に順序テーブルを変更
	for (NSUInteger i = 0; i < [_orderNumTable count]; i++)
	{
		if ([field.name isEqualToString:[_orderNumTable objectAtIndex:i]])
		{
			[_orderNumTable replaceObjectAtIndex:i withObject:name];
			break;
		}
	}
	
	// fieldの編集の設定
	[field setEditedWithName:name];
	
	// fieldの編集用選択フラグをリセット
	field.isEditSelected = NO;

	// 該当fieldを返す
	return ( field );
	
}

// 項目の削除
- (void) deleteItemWithIndex:(NSInteger)index
{
	if (index >= [ _itemTable count] )
	{	return; }		// 念のため長さチェック
	
	// 指定indexのfield
	itemTableField *field = [_itemTable objectAtIndex:index];
	
	// fieldの削除の設定
	[field setDeletedFlag];
	
	// fieldの編集用選択フラグをリセット
	field.isEditSelected = NO;
}

// 項目の全消去
-(void) deleteAllItem
{
    for( itemTableField *field in _itemTable )
    {
        if( [field dbID] == PRESET_DB_ID )  continue;
        [field setDeletedFlag];
        field.isEditSelected = NO;
    }
}

// ユーザ管理領域の保存と順序テーブルの更新
- (NSArray*) saveUserAreaOrderNumUpdate:(BOOL*)isChangeUserArea
{
	NSMutableArray *userAreaList = [NSMutableArray array];
	for (itemTableField *filed in _itemTable)
	{
		// 削除の確認
		if (filed.isDeleted)
		{
			// 順序テーブルより削除
			if ([_orderNumTable containsObject:filed.name])
			{	
				[_orderNumTable removeObject:filed.name]; 
				
				*isChangeUserArea = YES;
			}
			
			continue;
		}
		// 項目編集の確認
		if (filed.isEdited)
		{
			if ([_orderNumTable containsObject:filed.name])
			{			
				*isChangeUserArea = YES;
			}
		}
		
		// ユーザ領域の確認
		if ([filed isUserArea])
		{	
			[userAreaList addObject:filed];
		}
	}
	
	return (userAreaList);
}

// マスタ管理領域のみ更新内容をデータベースに反映する
- (BOOL) updateItems2Database
{
	NSMutableArray *deleteIDs = [NSMutableArray array];
	NSMutableArray *insertNames = [NSMutableArray array];
	NSMutableDictionary *updateList = [NSMutableDictionary dictionary];
	for (itemTableField *filed in _itemTable)
	{
		// ユーザ固有領域は除く
		if ([filed isUserArea])
		{	continue;}
		
		// 削除の確認
		if (filed.isDeleted)
		{
			[deleteIDs addObject:[NSString stringWithFormat:@"%ld", (long)filed.dbID]];
			continue;
		}
		
		// 挿入の確認
		if (filed.isInserted)
		{
			[insertNames addObject:filed.name];
			continue;
		}
		
		// 更新の確認
		if (filed.isEdited)
		{
			[updateList setObject:filed.name
						   forKey:[NSString stringWithFormat:@"%ld", (long)filed.dbID]];
		}
	}
	
	// データベースの初期化
	userDbManager *dbMng = [[userDbManager alloc] init];
	
	BOOL dbStat;
	
	// トランザクション付きでデータベースをOPENする
	if ( [dbMng dataBaseOpen4Transaction] )
	{
        switch (_editKind) {
            case ITEM_EDIT_PICTUE_NAME:;
            case ITEM_EDIT_USER_WORK1:;
            case ITEM_EDIT_USER_WORK2:;
                dbStat = NO;
                if ( // 項目マスタテーブルよりitemを削除
                    ([dbMng itemEditTableDeleteWithItemIDList:deleteIDs
                                                 itemEditKind:_editKind]) &&
                    // 項目マスタテーブルよりitemを挿入
                    ([dbMng itemEditTableInsertWithNameList:insertNames
                                               itemEditKind:_editKind]) &&
                    // 項目マスタテーブルよりitemを更新 key => itemID value => name
                    ([dbMng itemEditTableUpdateWithItemList:updateList
                                               itemEditKind:_editKind]) )
                {
                    dbStat = YES;
                }
                break;
                
            case ITEM_EDIT_DATE:;
            case ITEM_EDIT_GENERAL1:;
            case ITEM_EDIT_GENERAL2:;
            case ITEM_EDIT_GENERAL3:;
                
                NSInteger type = _editKind - ITEM_EDIT_DATE;
                dbStat = YES;
                
                // 項目マスタテーブルよりitemを削除
                if( [deleteIDs count] > 0 ){
                NSMutableArray *fieldIdList = [NSMutableArray array];
                    for( NSString* delete in deleteIDs)
                    {
                        NSString* genFieldId = [[_commonInfoMgr getCommonInfoByRow:[delete intValue]] CommonId];
                        if( _editKind == ITEM_EDIT_DATE ){
                            // 汎用フィールドが他のテンプレートで使用されているかを取得する
                            //                        BOOL isUsed = [dbMng isGenFieldUsed:genFieldId TmplId:tmplId Error:&error];
                        }
                        [fieldIdList addObject:genFieldId];
                    }
                    dbStat = [dbMng deleteGeneralFieldItemList:fieldIdList];
                    if( !dbStat )break;
                }
                // 項目マスタテーブルよりitemを挿入
                if( [insertNames count] > 0 ){
                    if(_editKind == ITEM_EDIT_DATE)
                    {
                        //  DBには日数だけ保存する
                        NSArray *insertNamesBuf = insertNames;
                        insertNames = [NSMutableArray array];
                        for( NSString *days in insertNamesBuf )
                        {
                            [insertNames addObject:[days stringByReplacingOccurrencesOfString:@"日後" withString:@""]];
                        }
                    }
                    dbStat = [dbMng insertGeneralFieldItemList:insertNames
                                                          Type:type];
                    if(!dbStat) break;
                }
                // 項目マスタテーブルよりitemを更新
                if( [updateList count] > 0 ){
                    NSMutableArray *updateDataList = [NSMutableArray array];
                    NSArray *keys = [updateList allKeys];
                    for( NSString *key in keys )
                    {
                        NSMutableArray *data = [NSMutableArray array];
                        [data addObject:[_commonInfoMgr getCommonInfoTmplIdByRow:[key intValue]]];
                        if(_editKind == ITEM_EDIT_DATE)
                        {
                            [data addObject:[[updateList objectForKey:key] stringByReplacingOccurrencesOfString:@"日後" withString:@""]];
                        }
                        else
                        {
                            [data addObject:[updateList objectForKey:key]];
                        }
                        [updateDataList addObject:data];
                    }
                    dbStat = [dbMng updateGeneralFieldItemList:updateDataList];
                    if(!dbStat)break;
                }
                break;
                
            default:
                break;
        }
		
		// トランザクションを完了しデータベースをCLOSEする
		[dbMng dataBaseClose2TransactionWithState:dbStat];
	}
	
	[dbMng release];
	
	// updateList = nil;
	// insertNames = nil;
	// deleteIDs = nil;
	
	return (dbStat);
	
}

// 保存したユーザ管理領域を項目テーブルに反映する
- (void) addUserArea2ItemTable:(NSArray*)userAreaList
{
	// 最初に保存してあるユーザ管理を項目テーブルに加える
	NSInteger addIndex = [_itemTable count];
	for (itemTableField *field in userAreaList)
	{	
		// 更新後の新indexでfieldを追加する
		itemTableField *newField 
			= [[itemTableField alloc] initWithIndex:addIndex++
									   itemName:field.name
									 dataBaseID:DB_ID_INVALID];
		
		[_itemTable addObject:newField]; 
        [newField release];
	}
	
	// 順序テーブルの選択を項目テーブルに反映する
	NSUInteger order = 0;
	for (NSString* ordName in _orderNumTable)
	{
		NSInteger findIdx = NSIntegerMin;
		for (itemTableField* field in _itemTable)
		{
			if ( [ordName isEqualToString:field.name])
			{
				findIdx = field.index;
				break;
			}
		}
		
		itemTableField *field = nil;
		if (findIdx != NSIntegerMin)
		{
			// 項目テーブルに名前があったので、選択フラグをセット
			field = [_itemTable objectAtIndex:findIdx];
			field.isSelected = YES;
			field.orderNum = order;
		}
		else 
		{
			// 項目テーブルに名前がなかったので、fieldを追加 : 通常はない
			field = [[itemTableField alloc] 
						initWithIndex4UserOnly:(NSInteger)[_itemTable count]
								orderNum:order itemName:ordName];
			[_itemTable addObject:field];
            [field release];
		}
		order++;
	}
}

// 全項目の更新: 戻り値：ユーザ管理領域での変更があったか？
- (BOOL) updateAllItem
{
	BOOL isChangeUserArea = NO;
	
	// ユーザ管理領域の保存と順序テーブルの更新
	NSArray *userAreaList = [self saveUserAreaOrderNumUpdate:&isChangeUserArea];
	
	// マスタ管理領域のみデータベースに反映する
	if ( ! [self updateItems2Database] )
	{	return (NO); }
		
	// 項目テーブルをクリアする
	[_itemTable removeAllObjects];
	
	// マスタテーブルより項目を取得
	[self getItems2MstTbl :_editKind];
	// マスタデータ管理領域を設定
	_mstDataMngArea = [_itemTable count];
	
	// 保存したユーザ管理領域を項目テーブルに反映する
	[self addUserArea2ItemTable:userAreaList];
	
	// userAreaList = nil;
	
	return (isChangeUserArea);
}

// 全項目の取消
- (void) chancelAllItem
{
	// 項目テーブルのクリア
	[_itemTable removeAllObjects];
	// 順序テーブルのクリア
	[_orderNumTable removeAllObjects];
	
	// テーブル類の初期化
	[self tablesInit];
}

-(BOOL) enabledEdit:(NSInteger)index
{
    return ([[_itemTable objectAtIndex:index] dbID] != PRESET_DB_ID );
}
@end
