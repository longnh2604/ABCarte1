//
//  TemplateInfoListManager.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/05.
//
//

/*
 ** IMPORT
 */
#import "TemplateInfoListManager.h"
#import "userDbManager.h"

@implementation TemplateInfoListManager

/*
 ** PROPERTY
 */
@synthesize dicTemplateInfo = _dicTemplateInfo;

#pragma mark iOS_Frmaework
/**
 dealloc
 */
- (void) dealloc
{
	// テンプレートリストの解放
	[_dicTemplateInfo removeAllObjects];
	[_dicTemplateInfo release];
	[super dealloc];
}


#pragma mark LocalMethod
/**
 initWithDelegate
 */
- (id) initWithDelegate:(id) delegate
{
	self = [super init];
	if ( self )
	{
		// テンプレートリストの確保
		_dicTemplateInfo = [[NSMutableDictionary alloc] init];
	}
	return self;
}

/**
 全てのデータを削除する
 */
- (void) removeAllObjects
{
	[_dicTemplateInfo removeAllObjects];
}

/**
 setTemplateInfo
 */
-(BOOL) setTemplateInfo:(TemplateInfo*) templInfo
{
	if ( templInfo == nil ) return NO;

	// テンプレートリストに追加
	NSString* categoryId = [templInfo categoryId];
	NSString* strCategory = nil;
	if ( categoryId == nil )
	{
		// カテゴリーが設定されていない
		strCategory = @"カテゴリーなし";
	}
	else
	{
		// カテゴリーが設定されている
		userDbManager* userDbMng = [[userDbManager alloc] initWithDbOpen];
		strCategory = [userDbMng getCategoryTitleAtID:categoryId];
		[userDbMng closeDataBase];
		[userDbMng release];
	}

	// 設定
	NSMutableArray* infoList = [_dicTemplateInfo objectForKey:strCategory];
	if ( infoList == nil )
	{
		// カテゴリーがない
		infoList = [[[NSMutableArray alloc] init] autorelease];
	}
	[infoList addObject:templInfo];
	[_dicTemplateInfo setValue:infoList forKey:strCategory];
	return YES;
}

/**
 */
- (BOOL) setTemplateList:(NSMutableArray*) templateList
{
	if ( templateList == nil ) return NO;
	[_dicTemplateInfo removeAllObjects];

	// DBを開く
	userDbManager* userDbMng = [[userDbManager alloc] initWithDbOpen];

	// infoを設定
	NSString* strCategory = nil;
	for ( TemplateInfo* info in templateList )
	{
		// カテゴリー
		NSString* categoryId = [info categoryId];
		if ( categoryId == nil )
		{
			// カテゴリーが設定されていない
			strCategory = @"なし";
			[info setCategoryId:[userDbMng getCategoryID:strCategory]];
		}
		else
		{
			// カテゴリーが設定されている
			strCategory = [userDbMng getCategoryTitleAtID:categoryId];
			if ( [strCategory length] > 0  )
			{
				// カテゴリーが見つかった
				[info setCategoryName:strCategory];
			}
			else
			{
				// カテゴリーが見つからなかった
				strCategory = @"なし";
				[info setCategoryId:[userDbMng getCategoryID:strCategory]];
			}
		}

		// 画像URL
		[[info pictureUrls] removeAllObjects];
		[userDbMng getTemplatePictureUrls:[info tmplId] PictUrls:[info pictureUrls]];
		NSLog(@"id:%@ %@", [info tmplId], [info pictureUrls]);
		
		// 設定
		NSMutableArray* infoList = [_dicTemplateInfo objectForKey:strCategory];
		if ( infoList == nil )
		{
			// カテゴリーがない
			infoList = [[[NSMutableArray alloc] init] autorelease];
		}
		[infoList addObject:info];
		[_dicTemplateInfo setValue:infoList forKey:strCategory];
	}

	// DBを閉じる
	[userDbMng closeDataBase];
	[userDbMng release];
	
	return YES;
}

/**
 getCategoryTitle
 */
- (NSArray*) getCategoryTitle
{
    // sortedArrayUsingComparatorを使ってキーをソート
    NSArray *keys = [_dicTemplateInfo allKeys];
    keys = [keys sortedArrayUsingComparator:^(id o1, id o2) {
        return [o1 compare:o2];
    }];
	return keys;
}

/**
 getSectionCounts
 */
- (NSInteger) getSectionCounts
{
	NSArray* _arrayCategory = [self getCategoryTitle];
	return [_arrayCategory count];
}

/**
 getTemplateInfoCountsWithSection
 */
- (NSInteger) getTemplateInfoCountsWithSection:(NSInteger) section
{
	NSString* _strKey = [self getSectionTitle:section];
	NSMutableArray* _arrayCategory = [_dicTemplateInfo objectForKey:_strKey];
	return [_arrayCategory count];
}

/**
 getSectionTitle
 */
- (NSString*) getSectionTitle:(NSInteger) section
{
	NSArray* _arrayKeys = [self getCategoryTitle];
	NSString* _strKey = [_arrayKeys objectAtIndex:section];
	return _strKey;
}

/**
 getTemplateInfoBySection
 */
- (TemplateInfo*) getTemplateInfoBySection:(NSInteger) section
									RowNum:(NSInteger) row
{
	NSString* _strKey = [self getSectionTitle:section];
	NSMutableArray* _arrayCategory = [_dicTemplateInfo objectForKey:_strKey];
	return [_arrayCategory objectAtIndex:row];
}

/**
 removeTemplateInfoBySection
 */
- (void) removeTemplateInfoBySection:(NSInteger) section
							  RowNum:(NSInteger) row
{
	NSString* _strKey = [self getSectionTitle:section];
	NSMutableArray* _arrayCategory = [_dicTemplateInfo objectForKey:_strKey];
	[_arrayCategory removeObjectAtIndex:row];
}

/**
 UnselectedAll
 */
- (void) UnselectedAll
{
	// キーを取得する
	NSArray* _arrayKeys = [self getCategoryTitle];
	for ( NSString* strKey in _arrayKeys )
	{
		// キーからカテゴリーを取得する
		NSMutableArray* _arrayCategory = [_dicTemplateInfo objectForKey:strKey];
		for ( TemplateInfo* info in _arrayCategory )
		{
			// 選択状態を解除する
			[info setSelected:NO];
		}
	}
}

/**
 getSelectedInfo
 */
- (BOOL) getSelectedInfo:(NSInteger*) section RowNum:(NSInteger*) row
{
	if ( section == nil || row == nil )
		return NO;

	// キーを取得する
	NSInteger i = 0, j = 0;
	NSArray* _arrayKeys = [self getCategoryTitle];
	for ( NSString* strKey in _arrayKeys )
	{
		j = 0;
		// キーからカテゴリーを取得する
		NSMutableArray* _arrayCategory = [_dicTemplateInfo objectForKey:strKey];
		for ( TemplateInfo* info in _arrayCategory )
		{
			// 選択状態を解除する
			if ( [info selected] == YES )
			{
				*section = i;
				*row = j;
				return YES;
			}
			j++;
		}
		i++;
	}
	return NO;
}

/**
 selecteInfo
 */
- (void) selecteInfo:(NSInteger) section RowNum:(NSInteger) row
{
	// キーを取得する
	NSInteger i = 0, j = 0;
	NSArray* _arrayKeys = [self getCategoryTitle];
	for ( NSString* strKey in _arrayKeys )
	{
		j = 0;
		// キーからカテゴリーを取得する
		NSMutableArray* _arrayCategory = [_dicTemplateInfo objectForKey:strKey];
		for ( TemplateInfo* info in _arrayCategory )
		{
			// 選択する
			if ( i == section && j == row )
			{
				[info setSelected:YES];
				return;
			}
			j++;
		}
		i++;
	}
}


@end
