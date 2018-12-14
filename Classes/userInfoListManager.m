//
//  userInfoListManager.m
//  iPadCamera
//
//  Created by MacBook on 10/10/20.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "defines.h"

#import "userInfoListManager.h"

#import "userDbManager.h"
#import "userInfo.h"

#import "WebMailUserStatus.h"

#ifdef CLOUD_SYNC
#import "shop/ShopManager.h"
#endif

@implementation userInfoListManager

#pragma mark private_methods

#ifdef CLOUD_SYNC
    
// 現在選択中の店舗IDによる条件の追加
- (void) addWhereStatementWithStringBuffer:(NSMutableString*)sqlAdd
{
    ShopManager *shopMng = [ShopManager defaultManager];
    
    // 店舗アカウントでない場合は追加しない
    if (! [shopMng isAccountShop] )
    {   return; }
    
    // 現在選択中の店舗ID一覧の取得
    NSArray *selectedShops = [shopMng getSeletedShopIDs];
    
    // 一覧がない場合は追加しない
    if ([selectedShops count] <= 0)
    {   return; }
    
    NSMutableString *shops = [NSMutableString string];
    for (NSString* sID in selectedShops)
    {   
        if ([shops length] > 0)
        {   [shops appendString:@" OR "]; }
            
        [shops appendFormat:@"mst_user.shop_id = %@", sID]; 
    }

    [sqlAdd appendString:@" AND ("];
    [sqlAdd appendString:shops];
    [sqlAdd appendString:@" ) "];
}

#endif

// 現在選択中の店舗IDによる条件の追加
- (void) addWhereStatementForCustomerNum:(NSMutableString*)sqlAdd
{
    ShopManager *shopMng = [ShopManager defaultManager];
    
    // 店舗アカウントでない場合は追加しない
    if (! [shopMng isAccountShop] )
    {   return; }
    
    // 現在選択中の店舗ID一覧の取得
    NSArray *selectedShops = [shopMng getSeletedShopIDs];
    
    // 一覧がない場合は追加しない
    if ([selectedShops count] <= 0)
    {   return; }
    
    NSMutableString *shops = [NSMutableString string];
    for (NSString* sID in selectedShops)
    {
        if ([shops length] > 0)
        {   [shops appendString:@" OR "]; }
        
        [shops appendFormat:@"mst_user.shop_id = %@", sID];
    }
    
    [sqlAdd appendString:@" ("];
    [sqlAdd appendString:shops];
    [sqlAdd appendString:@" ) "];
}

// 初期化（コンストラクタ）
- (id) init
{
	self = [super init];
	
	// ユーザ情報リストの初期化
	userInfoListArray = [NSMutableArray array];
	for (NSInteger i = 0; i < SECTION_MAX; i++) 
	{
		[userInfoListArray addObject:[NSMutableArray array]];
	}
	[userInfoListArray retain];
	
	// 全検索時のタイトルリストの初期化
#ifdef TABLE_INDEX
    jtitleLists = @[@"あ", @"い", @"う", @"え", @"お",
                    @"か", @"き", @"く", @"け", @"こ",
                    @"さ", @"し", @"す", @"せ", @"そ",
                    @"た", @"ち", @"つ", @"て", @"と",
                    @"な", @"に", @"ぬ", @"ね", @"の",
                    @"は", @"ひ", @"ふ", @"へ", @"ほ",
                    @"ま", @"み", @"む", @"め", @"も",
                    @"や", @"ゆ", @"よ",
                    @"ら", @"り", @"る", @"れ", @"ろ",
                    @"わ", @"を", @"ん",
                    @"A", @"B", @"C", @"D", @"E",
                    @"F", @"G", @"H", @"I", @"J",
                    @"K", @"L", @"M", @"N", @"O",
                    @"P", @"Q", @"R", @"S", @"T",
                    @"U", @"V", @"W", @"X", @"Y",
                    @"Z",
                    @"お客様番号"];
    etitleLists = @[@"A", @"B", @"C", @"D", @"E",
                    @"F", @"G", @"H", @"I", @"J",
                    @"K", @"L", @"M", @"N", @"O",
                    @"P", @"Q", @"R", @"S", @"T",
                    @"U", @"V", @"W", @"X", @"Y",
                    @"Z",
                    @"あ",
                    @"か",
                    @"さ",
                    @"た",
                    @"な",
                    @"は",
                    @"ま",
                    @"や",
                    @"ら",
                    @"わ",
                    @"number"];
	indexLists = [NSArray arrayWithObjects:
                  @"あ行", @"か行", @"さ行", @"た行", @"な行",
                  @"は行", @"ま行", @"や行", @"ら行", @"わ行",
                  @"お客様番号のみ", nil];
    [indexLists retain];
#else
	titleLists = [NSArray arrayWithObjects:
				   @"あ行", @"か行", @"さ行", @"た行", @"な行",
				   @"は行", @"ま行", @"や行", @"ら行", @"わ行", 
				   @"お客様番号のみ", nil];
#endif
	[jtitleLists retain];
    [etitleLists retain];
	
	// 五十音検索のタイトルリストの初期化:空のNSMutableStringで作成
	gojyuonTitleLists = [NSMutableArray array];
	for (NSInteger i = 0; i < SECTION_MAX; i++)
	{
		[gojyuonTitleLists addObject:[NSMutableString string]];
	}
	[gojyuonTitleLists retain];
	
	////////////////////////////////////
	// 各行のSQLステートメントの初期化
	////////////////////////////////////
	colStatements_j = [NSMutableArray array];
    colStatements_e = [NSMutableArray array];
    NSArray *cols_j = @[@"あ", @"い", @"う", @"え", @"お",
                        @"か_が", @"き_ぎ", @"く_ぐ", @"け_げ", @"こ_ご",
                        @"さ_ざ", @"し_じ", @"す_ず", @"せ_ぜ", @"そ_ぞ",
                        @"た_だ", @"ち_ぢ", @"つ_づ", @"て_で", @"と_ど",
                        @"な", @"に", @"ぬ", @"ね", @"の",
                        @"は_ば_ぱ", @"ひ_び_ぴ", @"ふ_ぶ_ぷ", @"へ_べ_ぺ", @"ほ_ぼ_ぽ",
                        @"ま", @"み", @"む", @"め", @"も",
                        @"や", @"ゆ", @"よ",
                        @"ら", @"り", @"る", @"れ", @"ろ",
                        @"わ", @"を", @"ん",
                        @"A", @"B", @"C", @"D", @"E",
                        @"F", @"G", @"H", @"I", @"J",
                        @"K", @"L", @"M", @"N", @"O",
                        @"P", @"Q", @"R", @"S", @"T",
                        @"U", @"V", @"W", @"X", @"Y",
                        @"Z",
                        @"nn"];
    NSArray *cols_e = @[@"A", @"B", @"C", @"D", @"E",
                        @"F", @"G", @"H", @"I", @"J",
                        @"K", @"L", @"M", @"N", @"O",
                        @"P", @"Q", @"R", @"S", @"T",
                        @"U", @"V", @"W", @"X", @"Y",
                        @"Z",
                        @"あ_い_う_え_お",
                        @"か_が_き_ぎ_く_ぐ_け_げ_こ_ご",
                        @"さ_ざ_し_じ_す_ず_せ_ぜ_そ_ぞ",
                        @"た_だ_ち_ぢ_つ_づ_て_で_と_ど",
                        @"な_に_ぬ_ね_の",
                        @"は_ば_ぱ_ひ_び_ぴ_ふ_ぶ_ぷ_へ_べ_ぺ_ほ_ぼ_ぽ",
                        @"ま_み_む_め_も",
                        @"や_ゆ_よ",
                        @"ら_り_る_れ_ろ",
                        @"わ_を_ん",
                        @"nn"];

    // あ行〜わ行（五十音）でのSQLステートメント（WHERE句以降）の作成
    [self makeSqlState:cols_j sqlStateMents:colStatements_j SectionMax:SECTION_MAX];
    [self makeSqlState:cols_e sqlStateMents:colStatements_e SectionMax:SECTION_EMAX];
	
	// [cols release];
	
	return (self);
}

- (void)makeSqlState:(NSArray *)cols sqlStateMents:(NSMutableArray *)stateArray SectionMax:(NSInteger)max
{
    // あ行〜わ行（五十音）でのSQLステートメント（WHERE句以降）の作成
    for (NSUInteger i = 0; i < (max - 1); i++)
    {
        NSLog(@"vao day nhe 1");
        // 各行のSQLステートメント文字取り出し:あ,い,う,え,お
        NSString *stStr = (NSString*)[cols objectAtIndex:i];
        
        // SQLステートメントを生成
        NSCharacterSet	*chSet
        = [NSCharacterSet characterSetWithCharactersInString:@"_"];
        NSScanner		*scanner = [NSScanner scannerWithString:stStr];
        NSString		*scanned;
        NSMutableString *sqlState = [NSMutableString string];
        [sqlState appendString:@"( "];
        while (! [scanner isAtEnd]) {
            if ([sqlState length] > 2)
            { [sqlState appendString:@" OR"]; }
            
            // tokenで取り出し
            if ([scanner scanUpToCharactersFromSet:chSet intoString:&scanned])
            {
                // first_name_kana LIKE 'あ%' OR ......
                [sqlState appendFormat:
                 @" first_name_kana LIKE '%@%%'", scanned];
            }
            [scanner scanCharactersFromSet:chSet intoString:nil];
        }
        [sqlState appendString:@" )"];
        
        // [sqlState appendString:@" ORDER BY first_name_kana"];
        [stateArray addObject:sqlState];
    }
    // お客様番号でのSQLステートメント（WHERE句以降）の作成
    /*WHERE  (0 <= regist_number AND regist_number <= 99999999)
     AND (first_name_kana IsNull)
	    ORDER BY regist_number*/
    NSMutableString *sqlState = [NSMutableString string];
    [sqlState appendString:@"(0 <= regist_number AND "];
    [sqlState appendString:@" regist_number <= 99999999) "];
    [sqlState appendString:@"    AND (first_name_kana IsNull)"];
    // [sqlState appendString:@"  ORDER BY regist_number"];
    [stateArray addObject:sqlState];
    
    [stateArray retain];
}

// リストの全クリア
- (void) allListClear
{
	for (id usrList in userInfoListArray)
	{
		[ (NSMutableArray*)usrList removeAllObjects];
	}
}
				  
// ユーザー情報リストの設定:searchKeyword=検索文字（LIKE）空文字で全検索
- (void) setUserInfoList:(NSString*)searchKeyword selectKind:(SELECT_JYOUKEN_KIND)kind
{
	//リストの全クリア
	[self allListClear];
	
	// 全検索か？
	searchKind = ([searchKeyword length] <= 0)? 
		SEARCH_KIND_ALL : SEARCH_KIND_ONE_STRING;
	
	// データベースの初期化
	userDbManager *dbMng = [[userDbManager alloc] init];
	
	// 該当行のuser一覧
	NSMutableArray *users;

	if (searchKind == SEARCH_KIND_ALL)
	{
	// 全検索
		for (NSUInteger i = 0; i < [self getSectionMax]; i++)
		{
			// 各行のSQLステートメント文字取り出し:あ,い,う,え,お
            NSString *sqlState = [self checkLanguage]?
            (NSString*)[colStatements_j objectAtIndex:i] : (NSString*)[colStatements_e objectAtIndex:i];
            
            NSMutableString *sqlAdd = [NSMutableString string];
            [sqlAdd appendString:sqlState];
#ifdef CLOUD_SYNC
            // 現在選択中の店舗IDによる条件の追加
            [self addWhereStatementWithStringBuffer:sqlAdd];
#endif		
            if (i < ([self getSectionMax] - 1) ) {
                // お客様番号でのSQLステートメントがない場合のみ適用する
                [sqlAdd appendString:@" ORDER BY first_name_kana, second_name_kana"];
            }
            else {
                [sqlAdd appendString:@" ORDER BY regist_number"];
            }
			NSLog(@"vao day nhe 3");
            // 該当行のユーザ情報一覧の取得
			users = [dbMng getUserInfoListBySearch:sqlAdd];
			
			// 指定行のリストを取り出して、ユーザ一覧を加える
			NSMutableArray	*list 
				= [userInfoListArray objectAtIndex:i];
			for (id user in users)
			{ [list addObject:user]; }
		}
	}
	else 
	{
	// 検索指定
		
		// 検索文字よりSQLステートメントを生成
		// first_name_kana LIKE 'けんさく%'
		NSMutableString *sqlState = nil;
		switch (kind) {
			case SELECT_FIRST_NAME_KANA:
				sqlState
					= [NSMutableString stringWithFormat:@" first_name_kana LIKE '%@%%'",
						searchKeyword];
				break;
			case SELECT_FIRST_NAME:
				sqlState
					= [NSMutableString stringWithFormat:@" first_name LIKE '%@%%'",
						searchKeyword];
				break;
			case SELECT_LAST_WORK_DATE:
				// 将来対応
				break;
			default:
				break;
		}
        
		if (! sqlState)
		{   
            [dbMng release];
            return;}
		
#ifdef CLOUD_SYNC
        // 現在選択中の店舗IDによる条件の追加
        [self addWhereStatementWithStringBuffer:sqlState];
#endif	
		// 検索文字に該当するのユーザ情報一覧の取得
		[sqlState appendString:@" ORDER BY first_name_kana"];
		users = [dbMng getUserInfoListBySearch:sqlState];
		// 検索指定の場合は、先頭リストを取り出して、ユーザ一覧を加える
		NSMutableArray	*list 
			= [userInfoListArray objectAtIndex:0];
		for (id user in users)
		{ [list addObject:user]; }

        if ([searchKeyword length] > 0) {
            searchNameTitle = [NSString stringWithFormat:@"お客様名「%@」で検索　　%lu 件",
                               searchKeyword, (unsigned long)[users count]];
            [searchNameTitle retain];
        } else {
            searchNameTitle = @"";
        }
    }
    [dbMng release];

}

// ユーザー情報リストの設定:searchKeyword1=検索文字姓（LIKE）searchKeyword1=検索文字名（LIKE）
- (void) setUserInfoList:(NSString*)searchKeyword1 :(NSString*)searchKeyword2 selectKind:(SELECT_JYOUKEN_KIND)kind selectKind2:(SELECT_JYOUKEN_KIND)kind2
{
    //リストの全クリア
    [self allListClear];
    
    searchKind = SEARCH_KIND_ONE_STRING;
    // データベースの初期化
    userDbManager *dbMng = [[userDbManager alloc] init];
    
    // 該当行のuser一覧
    NSMutableArray *users;
    
    // 検索文字よりSQLステートメントを生成
    // first_name_kana LIKE 'けんさく%'
    NSMutableString *sqlState = nil;
    
    if(searchKeyword1.length > 0){
        switch (kind) {
            case SELECT_FIRST_NAME_KANA:
                sqlState
                = [NSMutableString stringWithFormat:@" first_name_kana LIKE '%@%%'",
                   searchKeyword1];
                break;
            case SELECT_FIRST_NAME:
                sqlState
                = [NSMutableString stringWithFormat:@" first_name LIKE '%@%%'",
                   searchKeyword1];
                break;
            case SELECT_LAST_WORK_DATE:
                // 将来対応
                break;
            default:
                break;
        }
    }
    
    if(searchKeyword2.length > 0){
        if(searchKeyword1.length > 0){
            switch (kind2) {
                case SELECT_FIRST_NAME_KANA:
                    [sqlState appendString:[NSMutableString stringWithFormat:@" AND second_name_kana LIKE '%@%%'",
                       searchKeyword2]];
                    break;
                case SELECT_FIRST_NAME:
                    [sqlState appendString:[NSMutableString stringWithFormat:@" AND second_name LIKE '%@%%'",
                                            searchKeyword2]];
                    break;
                case SELECT_LAST_WORK_DATE:
                    // 将来対応
                    break;
                default:
                    break;
            }
        }else{
            switch (kind2) {
                case SELECT_FIRST_NAME_KANA:
                    sqlState
                    = [NSMutableString stringWithFormat:@" second_name_kana LIKE '%@%%'",
                       searchKeyword2];
                    break;
                case SELECT_FIRST_NAME:
                    sqlState
                    = [NSMutableString stringWithFormat:@" second_name LIKE '%@%%'",
                       searchKeyword2];
                    break;
                case SELECT_LAST_WORK_DATE:
                    // 将来対応
                    break;
                default:
                    break;
            }
        }
    }
    
    if (! sqlState)
    {
        [dbMng release];
        return;}
    
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementWithStringBuffer:sqlState];
#endif
    // 検索文字に該当するのユーザ情報一覧の取得
    [sqlState appendString:@" ORDER BY first_name_kana"];
    users = [dbMng getUserInfoListBySearch:sqlState];
    
    // 検索指定の場合は、先頭リストを取り出して、ユーザ一覧を加える
    NSMutableArray	*list
    = [userInfoListArray objectAtIndex:0];
    for (id user in users)
    { [list addObject:user]; }
    
    searchKeyword1 = [searchKeyword1 stringByAppendingString:searchKeyword2];

    if ([searchKeyword1 length] > 0) {
        searchNameTitle = [NSString stringWithFormat:@"お客様名「%@」で検索　　%d 件",
                           searchKeyword1, [users count]];
        [searchNameTitle retain];
    } else {
        searchNameTitle = @"";
    }
    [dbMng release];
    
}

// ユーザー情報リストの設定:responsibleName=検索文字担当者（LIKE）
- (void) setUserInfoList:(NSString*)responsibleName{
    //リストの全クリア
    [self allListClear];
    
    searchKind = SEARCH_KIND_ONE_STRING;
    // データベースの初期化
    userDbManager *dbMng = [[userDbManager alloc] init];
    
    // 該当行のuser一覧
    NSMutableArray *users;
    
    // 検索文字よりSQLステートメントを生成
    // first_name_kana LIKE 'けんさく%'
    NSMutableString *sqlState = nil;
    
    
    sqlState = [NSMutableString stringWithFormat:@" responsible LIKE '%@%%'",
                   responsibleName];

    if (! sqlState)
    {
        [dbMng release];
        return;}
    
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementWithStringBuffer:sqlState];
#endif
    // 検索文字に該当するのユーザ情報一覧の取得
    [sqlState appendString:@" ORDER BY first_name_kana"];
    users = [dbMng getUserInfoListBySearch:sqlState];
    
    // 検索指定の場合は、先頭リストを取り出して、ユーザ一覧を加える
    NSMutableArray	*list
    = [userInfoListArray objectAtIndex:0];
    for (id user in users)
    { [list addObject:user]; }
    
    searchNameTitle = [NSString stringWithFormat:@"担当者「%@」で検索　　%d 件",
                           responsibleName, [users count]];
    [searchNameTitle retain];
    
    [dbMng release];
    
}

// ユーザー情報リストの設定(五十音検索Version)
//	searchStrings:	[0]:あ行、 [1]:か行、 [2]:さ行、 ..... [9]:わ行 の各行に
//					ひらがなを設定する。（例：あ行=あ_い_う_え_お）
//					必ず10個の要素とし、該当行のない箇所は空文字を設定する
- (void) setUserInfoListWithGojyuon:(NSMutableArray*)searchStrings
{
	//リストの全クリア
	[self allListClear];
	
	// 検索種別＝五十音
	searchKind = SEARCH_KIND_GOJYUON;
	
	// 五十音タイトルリストのクリア
	// [gojyuonTitleLists removeAllObjects];
	
	// データベースの初期化
	userDbManager *dbMng = [[userDbManager alloc] init];
	
	// 該当行のuser一覧
	NSMutableArray *users;
    NSInteger sMax;
#ifdef TABLE_INDEX
    sMax = INDEX_MAX;
#else
    sMax = SECTION_MAX;
#endif
	for (NSUInteger i = 0; i < (sMax - 1) && i < [searchStrings count]; i++)
	{
		// 各行のSQLステートメント文字取り出し:あ_い_う_え_お
		NSString *stStr = (NSString*)[searchStrings objectAtIndex:i];
		
		if ([stStr length] <= 0)
		{
			// 該当行なし:userInfoListArrayの該当Indexに空のリストとなる
			[gojyuonTitleLists replaceObjectAtIndex:i withObject:[NSMutableString string]];
			continue;
		}
		
		// 五十音タイトルリスト取り出しと設定
		NSMutableString *title = [NSMutableString string];
			// = (NSMutableString*)[gojyuonTitleLists objectAtIndex:i];
#ifndef CALULU_IPHONE
#ifdef TABLE_INDEX
		[title appendFormat:@"%@(「", (NSString*)[indexLists objectAtIndex:i]];
#else
		[title appendFormat:@"%@(「", (NSString*)[titleLists objectAtIndex:i]];
#endif // TABLE_INDEX
#else
   		[title appendFormat:@"「%@", (NSString*)[titleLists objectAtIndex:i]];
#endif
		// SQLステートメントを生成
		NSCharacterSet	*chSet 
			= [NSCharacterSet characterSetWithCharactersInString:@"_"];
		NSScanner		*scanner = [NSScanner scannerWithString:stStr];
		NSString		*scanned;
		NSMutableString *sqlState = [NSMutableString string];
		while (! [scanner isAtEnd]) {
			if ([sqlState length] > 0)
			{ 
				[sqlState appendString:@" OR"];
            } else {
                // 複数選択した五十音の or 条件をひとまとまりにする為
                [sqlState appendString:@" ( "];
            }
			
			// tokenで取り出し
			if ([scanner scanUpToCharactersFromSet:chSet intoString:&scanned])
			{
				// first_name_kana LIKE 'あ%' OR ......
				[sqlState appendFormat:
				 @" first_name_kana LIKE '%@%%'", scanned];
#ifndef CALULU_IPHONE
				// if ([title length] < 13 )
				// 濁音であるものはタイトルには追加しない:NFD(正規化形式D)による
				if ([scanned length] 
						== [[scanned decomposedStringWithCanonicalMapping] length] )
				{ 
					[title appendString:scanned]; 
					
					if ([title length] > 0 )
					{ [title appendString:@"・"]; }
				}
#endif
			}
			[scanner scanCharactersFromSet:chSet intoString:nil];
		}
        // 複数選択した五十音の or 条件をひとまとまりにする為
        [sqlState appendString:@" ) "];

#ifdef CLOUD_SYNC
        // 現在選択中の店舗IDによる条件の追加
        [self addWhereStatementWithStringBuffer:sqlState];
#endif	
		// 該当行のユーザ情報一覧の取得
		[sqlState appendString:@" ORDER BY first_name_kana"];
		users = [dbMng getUserInfoListBySearch:sqlState];
		// 指定行のリストを取り出して、ユーザ一覧を加える
		NSMutableArray	*list 
			= [userInfoListArray objectAtIndex:i];
		for (id user in users)
		{ [list addObject:user]; }
			
		// 五十音タイトルリストに設定
#ifndef CALULU_IPHONE
		[title appendString:[NSString stringWithFormat:@"」で始まるお客様)  % 4ld件", (long)[list count]]];
#else
		[title appendString:@"」で始まるお客様"];
#endif
		// 末尾文字で「・」の場合は、除去
		// [gojyuonTitleLists replaceObjectAtIndex:i withObject:title];
		[gojyuonTitleLists replaceObjectAtIndex:i 
									 withObject:[title stringByReplacingOccurrencesOfString:@"・」" withString:@"」"]];
		
	}
	
	// ][dbMng release];
}

/**
 * ユーザテーブルリストのインデックス更新
 */
- (void)refreshIndexList
{
    // データベースの初期化
    userDbManager *dbMng = [[userDbManager alloc] init];

//    if (titleLists) {
//        [titleLists release];
//    }
//    titleLists = [dbMng getJapaneseUserListIndex];
}

/**
 * 言語設定の状況確認
 */
- (BOOL)checkLanguage
{
    // ユーザ設定を取得
    BOOL isJapanese = NO;
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
	NSString *country = [df stringForKey:@"USER_COUNTRY"];
	// 2015/10/27 TMS iOS9対応
    if ([country isEqualToString:@"ja-JP"] || [country isEqualToString:@"ja"] || [country isEqualToString:@"en-JP"]) {
        isJapanese = YES;
    }
    return isJapanese;
}

/**
 */
- (NSInteger)getSectionMax
{
    NSInteger max = SECTION_MAX;
    
    if (![self checkLanguage]) {
        max = SECTION_EMAX;
    }

    return max;
}

// セクション番号より有効なリストのIndexを取得
- (NSUInteger) getIndexBySectionNum:(NSInteger)section isSorceUserInfo:(BOOL)isUserInfo
{
	NSUInteger validIdx = NSUIntegerMax;
	NSInteger index = 0;
	
	for (NSUInteger i = 0; i < [self getSectionMax]; i++)
	{
        NSLog(@"vao day nhe 10");
		BOOL valid = NO;
		if (isUserInfo)
		{
			NSMutableArray *list = [userInfoListArray objectAtIndex:(NSUInteger)i];
			valid = ([list count] > 0);
		}
		else 
		{
			NSMutableString *title = [gojyuonTitleLists objectAtIndex:i];
			valid = ( (title) && ([title length] > 0) );
		}

		if (valid)
		{ 
			if ( index == section) 
			{
				// 該当するリスト
				validIdx = i;
				break;
			}
			// 次の有効なリストへ
			index++;
		}
	}
	
	return (validIdx);
}

// 和暦表示
- (void) dispJapaneseDate:(NSInteger)searchSelect SearchStart:(NSDate*)searchStart SearchEnd:(NSDate*)searchEnd Title:(NSString*) title
{
	// 時刻書式指定子を設定
    NSDateFormatter* form = [[NSDateFormatter alloc] init];
    [form setDateStyle:NSDateFormatterFullStyle];
    [form setTimeStyle:NSDateFormatterNoStyle];
    
    // ロケールを設定
    NSLocale* loc = [[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"];
    [form setLocale:loc];
    
    // カレンダーを指定
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier: NSJapaneseCalendar];
    [form setCalendar: cal];
    
    //西暦出力用format
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy年"];
    
    /*
     年検索や、月検索で2014年~2012年、8月~3月という検索でき、
     SearchStartの方が数字が大きい事があるのでその辺りを修正する
     */
    NSDate* dateStart = searchStart;
    NSDate* dataEnd = searchEnd;
    if( searchStart != nil && searchEnd != nil ){
        if( [searchStart compare:searchEnd] == NSOrderedDescending ){
            dateStart = searchEnd;
            dataEnd = searchStart;
        }
    }
    else if( searchStart == nil ){
        dateStart = searchEnd;
        dataEnd = nil;
    }
    
    [workDateSearchTitle release];
    switch (searchSelect) {
        case SELECT_LAST_WORK_DATE:
        case SELECT_BIRTY_DAY:
            // 和暦を出力するように書式指定:曜日まで出す
            [form setDateFormat:@"MM月dd日　EEEE"];
            NSLog(@"met moi vai 5");
            workDateSearchTitle = [NSString stringWithFormat:@"%@　%@%@　のお客様  % 4ld件",
                                   title,
                                   [formatter stringFromDate:dateStart],
                                   [form stringFromDate:dateStart],
                                   (long)[[userInfoListArray objectAtIndex:0] count]];
            break;
            
        case SELECT_BIRTY_MONTH:
            
            // 和暦を出力するように書式指定:曜日まで出す
            [form setDateFormat:@"MM月"];
            NSLog(@"met moi vai 6");
            if( dataEnd != nil ){
                NSDateComponents* dateStartComponents = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit) fromDate:dateStart];
                NSDateComponents* dateEndComponents = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit) fromDate:dataEnd];
                
                workDateSearchTitle = [NSString stringWithFormat:@"%@　%ld月 ~ %ld月　のお客様  % 4ld件",
                                       title,
                                       (long)dateStartComponents.month,
                                       (long)dateEndComponents.month,
                                       (long)[[userInfoListArray objectAtIndex:0] count]];
            }
            else{
                NSDateComponents* dateStartComponents = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit) fromDate:dateStart];
                
                workDateSearchTitle = [NSString stringWithFormat:@"%@　%ld月　のお客様  % 4ld件",
                                       title,
                                       (long)dateStartComponents.month,
                                       (long)[[userInfoListArray objectAtIndex:0] count]];
            }
            break;
            
        case SELECT_BIRTY_YEAR:
            // 和暦を出力するように書式指定:曜日まで出す
            if( dataEnd != nil ){
                workDateSearchTitle = [NSString stringWithFormat:@"%@　%@ ~ %@　のお客様  % 4ld件",
                                       title,
                                       [formatter stringFromDate:dateStart],
                                       [formatter stringFromDate:dataEnd],
                                       (long)[[userInfoListArray objectAtIndex:0] count]];
            }
            else{
                workDateSearchTitle = [NSString stringWithFormat:@"%@　%@　のお客様  % 4ld件",
                                       title,
                                       [formatter stringFromDate:dateStart],
                                       (long)[[userInfoListArray objectAtIndex:0] count]];
            }
            break;
            
    }
    [workDateSearchTitle retain];
	
	[formatter release];
	[form release];
    [cal release];
    [loc release];
}

/**
 日付の取得
 */
- (NSString*) getDateStringDay:(NSDate*)date
{
	return [self getDateString:date dateFormat:@"yyyy-MM-dd"];
}

/**
 日付の取得（月まで）
 */
- (NSString*) getDateStringMonth:(NSDate*)date Start:(BOOL) start
{
	NSCalendar* calendar = [NSCalendar currentCalendar];
	NSDateComponents* dateComps = [calendar components:NSMonthCalendarUnit fromDate:date];
	if ( start == YES )
		return [NSString stringWithFormat:@"2014-%02ld-01", (long)[dateComps month]];
	else
		return [NSString stringWithFormat:@"2014-%02ld-31", (long)[dateComps month]];
}

/**
 日付の取得（年まで）
 */
- (NSString*) getDateStringYear:(NSDate*)date Start:(BOOL) start
{
	NSCalendar* calendar = [NSCalendar currentCalendar];
	NSDateComponents* dateComps = [calendar components:NSYearCalendarUnit fromDate:date];
	if ( start == YES )
		return [NSString stringWithFormat:@"%ld-01-01", (long)[dateComps year]];
	else
		return [NSString stringWithFormat:@"%ld-12-31", (long)[dateComps year]];
}

/**
 日付の取得
 */
- (NSString*) getDateString:(NSDate*)date dateFormat:(NSString*)fomratString
{
	NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
	fmt.dateFormat = fomratString;
	NSString* str = ( [fmt stringFromDate:date] );
	[fmt release];
	return (str);
}

// ユーザー情報リストの設定(施術日による検索Version)
- (void) setUserInfoListWithWorkDate:(NSDate*)workDate : (NSInteger)mode
{
		
	//リストの全クリア
	[self allListClear];
	
	// 検索種別＝施術日
	searchKind = SEARCH_KIND_WORK_DATE;
	
	// データベースの初期化
	userDbManager *dbMng = [[userDbManager alloc] init];
	
	// 該当行のuser一覧
	NSMutableArray *users;
	// 検索文字列 : last_work_date = julianday(date(?))
	/*
	NSMutableString *sqlState = [NSMutableString string];
	[sqlState appendString:@"last_work_date = julianday(date('"];
	[sqlState appendString:[self getDateString:workDate]];
	[sqlState appendString:@"'))"];
	[sqlState appendString:@" ORDER BY first_name_kana"];
	*/

    NSMutableString *opt = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementWithStringBuffer:opt];
#endif	
    [opt appendString:@" ORDER BY first_name_kana"];
    
	users = [dbMng getUserInfoListBySearchDate:[self getDateStringDay:workDate]
									  optional:opt];   // @" ORDER BY first_name_kana" -> opt
	
   
    if(mode == SELECT_START_WORK_DATE){
        // 先頭リストにユーザー一覧を加える（初回登録日でのフィルターを掛ける）
        [self detectFirstDay:users
                                  startDay:[self getDateStringDay:workDate]
                                    endDay:[self getDateStringDay:workDate]
                                 dbManager:dbMng];
    }else if(mode == SELECT_LAST_WORK_DATE){
        [self detectLatestDay:users
                     startDay:[self getDateStringDay:workDate]
                       endDay:[self getDateStringDay:workDate]
                    dbManager:dbMng
                     isLatest:YES];
    }else{
        // 先頭リストを取り出して、ユーザ一覧を加える
        NSMutableArray	*list
            = [userInfoListArray objectAtIndex:0];
        NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
        [inputFormatter setDateFormat:@"yyyy-MM-dd"];
        [dbMng openDataBase];
        for (id user in users){
            ((userInfo *)user).lastWorkDate = [inputFormatter dateFromString:[dbMng getMaxNewWorkDateWithUserID:((userInfo *)user).userID]];
            [list addObject:user];
        }
    }
	// タイトルの設定
	[self dispJapaneseDate:SELECT_LAST_WORK_DATE SearchStart:workDate SearchEnd:nil Title:@"施術日"];
    [dbMng release];
}

// ユーザー情報リストの設定(お客様番号による検索Version) registNumber:REGIST_NUMBER_INVALIDで全番号
- (void) setUserInfoListWithRegistNumberNew:(NSString*)registNumber
{
    //リストの全クリア
    [self allListClear];
    
    // 検索種別＝お客様番号
    searchKind = SEARCH_KIND_REGIST_NUMBER;
    
    // データベースの初期化
    userDbManager *dbMng = [[userDbManager alloc] init];
    
    NSMutableString *addState = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementWithStringBuffer:addState];
#endif
    
    // 該当行のuser一覧
    NSMutableArray *users;
    users = [dbMng getUserInfoListByUserRegistNumber:registNumber isAsc:YES optional:addState];
    
    // 先頭リストを取り出して、ユーザ一覧を加える
    NSMutableArray    *list
    = [userInfoListArray objectAtIndex:0];
    for (id user in users)
    { [list addObject:user]; }
    
    // 前回のお客様番号検索の値の保存
    lastRegistNumber = registNumber;
    [dbMng release];
    
}

- (void) setUserInfoListWithRegistNumber:(NSInteger)registNumber
{
	//リストの全クリア
	[self allListClear];
	
	// 検索種別＝お客様番号
	searchKind = SEARCH_KIND_REGIST_NUMBER;
	
	// データベースの初期化
	userDbManager *dbMng = [[userDbManager alloc] init];
    
    NSMutableString *addState = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementWithStringBuffer:addState];
#endif	

	// 該当行のuser一覧
	NSMutableArray *users;
	users = [dbMng getUserInfoListByUserRegistNumber:registNumber isAsc:YES optional:addState];
	
	// 先頭リストを取り出して、ユーザ一覧を加える
	NSMutableArray	*list 
		= [userInfoListArray objectAtIndex:0];
	for (id user in users)
	{ [list addObject:user]; }
	
	// 前回のお客様番号検索の値の保存
	lastRegistNumber = registNumber;
    [dbMng release];

}

// ユーザー情報リストの設定(誕生日による検索Version)
- (void) setUserInfoListWithBirthDate:(NSDate*)searchStart
								 From:(NSDate*)searchEnd
						 SearchSelect:(NSInteger)searchSelect;
{
	// どちらもnilの場合は何もしない
	if ( searchStart == nil && searchEnd == nil )
		return;

	//リストの全クリア
	[self allListClear];

	// 検索種別＝誕生日
	searchKind = SEARCH_KIND_BIRTHDAY;

	// 検索条件の設定
	selectCondition = searchSelect;

	// データベースの初期化
	userDbManager* dbMng = [[userDbManager alloc] init];

	// ユーザー
	NSMutableArray* users;

	// 文字列
    NSMutableString* opt = [NSMutableString string];
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementWithStringBuffer:opt];

	// 検索
	if ( searchSelect == SELECT_BIRTY_DAY )
	{
		/*
		 ** 誕生日による検索
		 */
		users = [dbMng getUserInfoListByBirthDay:[self getDateStringDay:searchStart]
										optional:opt];
		
		// 先頭リストを取り出して、ユーザ一覧を加える
		NSMutableArray* list = [userInfoListArray objectAtIndex:0];
		for ( id user in users )
		{
			[list addObject:user];
		}

		// タイトルの設定
		[self dispJapaneseDate:searchSelect SearchStart:searchStart SearchEnd:searchEnd Title:@"誕生日"];
	}
	else
	if ( searchSelect == SELECT_BIRTY_MONTH )
	{
		NSString* startMonth = nil;
		NSString* endMonth = nil;

		/*
		 検索開始月と検索終了月の文字列を作成
		 */
		if ( searchStart == nil || searchEnd == nil )
		{
			// どちらか片方がnilの場合は単月の検索
			if ( searchStart != nil )
			{
				// searchStartで月を取得
				startMonth = [self getDateStringMonth:searchStart Start:YES];
				endMonth = [self getDateStringMonth:searchStart Start:NO];
			}
			else if ( searchEnd != nil )
			{
				// searchEndで月を取得
				startMonth = [self getDateStringMonth:searchEnd Start:YES];
				endMonth = [self getDateStringMonth:searchEnd Start:NO];
			}
			else
			{
				// エラー
				return;
			}
		}
		else
		{
			// 月単位の期間検索
			NSCalendar* calendar = [NSCalendar currentCalendar];
			NSDateComponents* Comps1 = [calendar components:NSMonthCalendarUnit fromDate:searchStart];
			NSDateComponents* Comps2 = [calendar components:NSMonthCalendarUnit fromDate:searchEnd];
			if ( [Comps1 month] < [Comps2 month] )
			{
				startMonth = [self getDateStringMonth:searchStart Start:YES];
				endMonth = [self getDateStringMonth:searchEnd Start:NO];
			}
			else
			{
				startMonth = [self getDateStringMonth:searchEnd Start:YES];
				endMonth = [self getDateStringMonth:searchStart Start:NO];
			}
		}

		/*
		 **	誕生月による検索
		 */
		users = [dbMng getUserInfoListByBirthMonth:startMonth
											   And:endMonth
										  optional:opt];
		
		// 先頭リストを取り出して、ユーザ一覧を加える
		NSMutableArray* list = [userInfoListArray objectAtIndex:0];
		for ( id user in users )
		{
			[list addObject:user];
		}
		
		// タイトルの設定
		[self dispJapaneseDate:searchSelect SearchStart:searchStart SearchEnd:searchEnd Title:@"誕生月"];
	}
	else
	if ( searchSelect == SELECT_BIRTY_YEAR )
	{
		NSString* startYear = nil;
		NSString* endYear = nil;

		/*
		 検索開始年と検索終了年の文字列を作成
		 */
		if ( searchStart == nil || searchEnd == nil )
		{
			// どちらか片方がnilの場合は単年の検索
			if ( searchStart != nil )
			{
				// searchStartで年を取得
				startYear = [self getDateStringYear:searchStart Start:YES];
				endYear = [self getDateStringYear:searchStart Start:NO];
			}
			else if ( searchEnd != nil )
			{
				// searchEndで年を取得
				startYear = [self getDateStringYear:searchEnd Start:YES];
				endYear = [self getDateStringYear:searchEnd Start:NO];
			}
			else
			{
				// エラー
				return;
			}
		}
		else
		{
			// 年単位の期間検索
			NSCalendar* calendar = [NSCalendar currentCalendar];
			NSDateComponents* Comps1 = [calendar components:NSYearCalendarUnit fromDate:searchStart];
			NSDateComponents* Comps2 = [calendar components:NSYearCalendarUnit fromDate:searchEnd];
			if ( [Comps1 year] < [Comps2 year] )
			{
				startYear = [self getDateStringYear:searchStart Start:YES];
				endYear = [self getDateStringYear:searchEnd Start:NO];
			}
			else
			{
				startYear = [self getDateStringYear:searchEnd Start:YES];
				endYear = [self getDateStringYear:searchStart Start:NO];
			}
		}

		/*
		 **	誕生年による検索
		 */
		users = [dbMng getUserInfoListByBirthYear:startYear
											  And:endYear
										 optional:opt];
		
		// 先頭リストを取り出して、ユーザ一覧を加える
		NSMutableArray* list = [userInfoListArray objectAtIndex:0];
		for ( id user in users )
		{
			[list addObject:user];
		}
		
		// タイトルの設定
		[self dispJapaneseDate:searchSelect SearchStart:searchStart SearchEnd:searchEnd Title:@"誕生年"];
	}
	else
	{
		// なんもない
	}
	[dbMng release];
}

// ユーザー情報リストの設定（最新施術日を期間で検索するVersion）
- (BOOL) setUserInfoListWithLastWorkTerm:(NSDateComponents*)start
                                     End:(NSDateComponents*)end
                                isLatest:(BOOL)isLatest
{
	BOOL stat = YES;
	NSMutableArray* users = nil;

	//リストの全クリア
	[self allListClear];

	// 通常の期間検索
	searchKind = SEARCH_KIND_LASTWORK_TERM;

	// DBオープン
	userDbManager* userDbMng = [[userDbManager alloc]initWithDbOpen];

    NSMutableString *addState = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementWithStringBuffer:addState];
#endif
	
	// 期間チェック
	NSInteger selectSearch = [self checkTerm:start End:end];
	switch ( selectSearch )
	{
	case SELECT_TERM_ERROR:
		{
			// error
			stat = NO;
		}
		break;

	case SELECT_NONE:
		{
			// DBクローズ
			[userDbMng closeDataBase];
			[userDbMng release];

			// 期限が入ってないので全検索
			[self setUserInfoList:nil selectKind:SELECT_NONE];
		}
		return stat;
		
	case SELECT_TERM_DATE:
		{
			// 期間検索（年／月／日）
			BOOL startEarly = [self checkStartDate:start End:end];

			// 文字列に変換
			NSDateComponents* startDate = startEarly ? start : end;
			NSDateComponents* endDate = startEarly ? end : start;
			NSString* strStart = [NSString stringWithFormat:@"%04ld-%02ld-%02ld",
                                  (long)startDate.year, (long)startDate.month, (long)startDate.day];
			NSString* strEnd   = [NSString stringWithFormat:@"%04ld-%02ld-%02ld",
                                  (long)endDate.year, (long)endDate.month, (long)endDate.day];
			
			/*
			 年／月検索(指定範囲に該当する施術履歴一覧が返ってくる)
			 */
			users = [userDbMng getUserInfoListBySearchStart:strStart
													EndDate:strEnd
												   optional:addState];
            // 先頭リストにユーザー一覧を加える（最新施術日でのフィルターを掛ける）
            NSInteger count = [self detectLatestDay:users
                                           startDay:strStart
                                             endDay:strEnd
                                          dbManager:userDbMng
                                           isLatest:isLatest];
            
			// タイトルの設定
			[workDateSearchTitle release];
			workDateSearchTitle =
                [NSString stringWithFormat:@"%@ %04ld年%02ld月%02ld日 〜 %04ld年%02ld月%02ld日 のお客様  % 4ld件",
                                            (isLatest)? @"最新来店日が" : @"",
                                            (long)startDate.year, (long)startDate.month, (long)startDate.day,
                                            (long)endDate.year, (long)endDate.month, (long)endDate.day, (long)count];
			[workDateSearchTitle retain];
		}
		break;
			
	case SELECT_TERM_MONTH:
		{
			// 期間検索（年／月）
			BOOL startEarly = [self checkStartDate:start End:end];
			
			// 文字列に変換
			NSDateComponents* startDate = startEarly ? start : end;
			NSDateComponents* endDate = startEarly ? end : start;
			NSInteger lastDay = [self getMonthLastDay:endDate];
			NSString* strStart = [NSString stringWithFormat:@"%04ld-%02ld-01", (long)startDate.year, (long)startDate.month];
			NSString* strEnd   = [NSString stringWithFormat:@"%04ld-%02ld-%02ld", (long)endDate.year, (long)endDate.month, (long)lastDay];
			
			/*
			 年／月検索
			 */
			users = [userDbMng getUserInfoListBySearchStart:strStart
													EndDate:strEnd
												   optional:addState];
            
            // 先頭リストにユーザー一覧を加える（最新施術日でのフィルターを掛ける）
            NSInteger count = [self detectLatestDay:users
                                           startDay:strStart
                                             endDay:strEnd
                                          dbManager:userDbMng
                                           isLatest:isLatest];
			
			// タイトルの設定
			[workDateSearchTitle release];
			workDateSearchTitle =
                [NSString stringWithFormat:@"%@ %04ld年%02ld月%02d日 〜 %04ld年%02ld月%02ld日 のお客様　% 4ld件",
                                            (isLatest)? @"最新来店日が" : @"",
                                            (long)startDate.year, (long)startDate.month, 1,
                                            (long)endDate.year, (long)endDate.month, (long)lastDay, (long)count];
			[workDateSearchTitle retain];
		}
		break;
			
	case SELECT_TERM_YEAR:
		{
			// 期間検索（年）
			BOOL startEarly = [self checkStartDate:start End:end];
			
			// 文字列に変換
			NSDateComponents* startDate = startEarly ? start : end;
			NSDateComponents* endDate = startEarly ? end : start;
			NSString* strStart = [NSString stringWithFormat:@"%04ld-01-01", (long)startDate.year];
			NSString* strEnd   = [NSString stringWithFormat:@"%04ld-12-31", (long)endDate.year];
			
			/*
			 年／月検索
			 */
			users = [userDbMng getUserInfoListBySearchStart:strStart
													EndDate:strEnd
												   optional:addState];
			
            // 先頭リストにユーザー一覧を加える（最新施術日でのフィルターを掛ける）
            NSInteger count = [self detectLatestDay:users
                                           startDay:strStart
                                             endDay:strEnd
                                          dbManager:userDbMng
                                           isLatest:isLatest];
			
			// タイトルの設定
			[workDateSearchTitle release];
			workDateSearchTitle =
                [NSString stringWithFormat:@"%@ %04ld年%02d月%02d日 〜 %04ld年%02d月%02d日 のお客様　% 4ld件",
                                            (isLatest)? @"最新来店日が" : @"",
                                            (long)startDate.year, 1, 1,
                                            (long)endDate.year, 12, 31, (long)count];
			[workDateSearchTitle retain];
		}
		break;
			
	case SELECT_SINGLE_TERM_DATE:
		{
			// DBクローズ
			[userDbMng closeDataBase];
			[userDbMng release];

			// 日付チェック(この場合どちらか片方が空の状態なはず)
			NSDateComponents* cmp = start;
			if ( [self isDateEmpty:start] == YES )
			{
				// startが使えないので
				cmp = end;
			}

			// NSDateに変換
			NSCalendar* cal = [NSCalendar currentCalendar];
			NSDate* dateObj = [cal dateFromComponents:cmp];

			/*
			 年／月／日付検索 == 施術日による検索と同一
			 */
            
            [self setUserInfoListWithWorkDate:dateObj:(isLatest)? SELECT_LAST_WORK_DATE : SELECT_WORK_DATE];
		}
		return stat;
			
	case SELECT_SINGLE_TERM_MONTH:
		{
			// 日付チェック(この場合どちらか片方が空の状態なはず)
			NSDateComponents* cmp = start;
			if ( [self isDateEmpty:start] == YES )
			{
				// startが使えないので
				cmp = end;
			}

			// NSStringに変換
			NSString* startDate = [NSString stringWithFormat:@"%04ld-%02ld-01", (long)cmp.year, (long)cmp.month];
			NSString* endDate = nil;
			NSInteger lastDay = [self getMonthLastDay:cmp];
			if ( [self isLeapYear:cmp.year] == YES && cmp.month == 2 )
			{
				// 2月のみ
				endDate = [NSString stringWithFormat:@"%04ld-%02d-%02d", (long)cmp.year, 2, 29];
			}
			else
			{
				// その他
				endDate = [NSString stringWithFormat:@"%04ld-%02ld-%02ld", (long)cmp.year, (long)cmp.month, (long)lastDay];
			}

			/*
			 年／月検索
			 */
			users = [userDbMng getUserInfoListBySearchStart:startDate EndDate:endDate
												   optional:addState];

            // 先頭リストにユーザー一覧を加える（最新施術日でのフィルターを掛ける）
            NSInteger count = [self detectLatestDay:users
                                           startDay:startDate
                                             endDay:endDate
                                          dbManager:userDbMng
                                           isLatest:isLatest];

			// タイトルの設定
			[workDateSearchTitle release];
			workDateSearchTitle = [NSString stringWithFormat:@"%@ %04ld年%02ld月 のお客様　% 4ld件",
                                   (isLatest)? @"最新来店日が" : @"",
                                   (long)cmp.year, (long)cmp.month, (long)count];
			[workDateSearchTitle retain];
		}
		break;
			
	case SELECT_SINGLE_TERM_YEAR:
		{
			// 日付チェック(この場合どちらか片方が空の状態なはず)
			NSDateComponents* cmp = start;
			if ( [self isDateEmpty:start] == YES )
			{
				// startが使えないので
				cmp = end;
			}
			
			// NSStringに変換
			NSString* startDate = [NSString stringWithFormat:@"%04ld-01-01", (long)cmp.year];
			NSString* endDate = [NSString stringWithFormat:@"%04ld-12-31", (long)cmp.year];
			
			/*
			 年検索
			 */
			users = [userDbMng getUserInfoListBySearchStart:startDate EndDate:endDate
												   optional:addState];
			
            // 先頭リストにユーザー一覧を加える（最新施術日でのフィルターを掛ける）
            NSInteger count = [self detectLatestDay:users
                                           startDay:startDate
                                             endDay:endDate
                                          dbManager:userDbMng
                                           isLatest:isLatest];

			// タイトルの設定
			[workDateSearchTitle release];
			workDateSearchTitle = [NSString stringWithFormat:@"%@ %04ld年 のお客様　% 4ld件",
                                   (isLatest)? @"最新来店日が" : @"",
                                   (long)cmp.year, (long)count];
			[workDateSearchTitle retain];
		}
		break;
			
	default:
		break;
	}

	// DBクローズ
	[userDbMng closeDataBase];
	[userDbMng release];

	return stat;
}

/**
 指定範囲で最新施術日の条件が一致しているユーザーを抜き出してリストに加える
 */
- (NSInteger)detectLatestDay:(NSMutableArray*)users
                    startDay:(NSString *)strStart
                      endDay:(NSString *)strEnd
                   dbManager:(userDbManager *)userDbMng
                    isLatest:(BOOL)isLatest
{
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    [inputFormatter setDateFormat:@"yyyy-MM-dd"];
    [userDbMng openDataBase];
    NSMutableArray* list = [userInfoListArray objectAtIndex:0];
    if (!isLatest) {
        for ( id user in users ){
            ((userInfo *)user).lastWorkDate = [inputFormatter dateFromString:[userDbMng getMaxNewWorkDateWithUserID:((userInfo *)user).userID]];
            [list addObject:user];
        }
        return [list count];
    }

    NSDate *rtDate;                                             // 範囲検索の結果日付
    NSDate *stDate = [inputFormatter dateFromString:strStart];  // 検索開始範囲
    NSDate *edDate = [inputFormatter dateFromString:strEnd];    // 検索終了範囲
    
    // 先頭リストを取り出して、ユーザ一覧を加える
    for ( id user in users )
    {
        NSString *maxDate = [userDbMng getMaxNewWorkDateWithUserID:((userInfo *)user).userID];
        rtDate = [inputFormatter dateFromString:maxDate];
        NSComparisonResult resultStart = [rtDate compare:stDate];
        NSComparisonResult resultEnd   = [rtDate compare:edDate];
        // 指定範囲に施術履歴を持つユーザから最新施術履歴で一致しているユーザだけを抜き出す
        if ((resultStart==NSOrderedDescending && resultEnd==NSOrderedAscending) ||
            resultStart==NSOrderedSame || resultEnd==NSOrderedSame) {
            [list addObject:user];
        }
    }
    [inputFormatter release];
    
    return [list count];
}

// ユーザー情報リストの設定（初回施術日を期間で検索するVersion）
- (BOOL) setUserInfoListWithFirstWorkTerm:(NSDateComponents*)start End:(NSDateComponents*)end
{
    BOOL stat = YES;
    NSMutableArray* users = nil;
    
    //リストの全クリア
    [self allListClear];
    
    // 通常の期間検索
    searchKind = SEARCH_KIND_LASTWORK_TERM;
    
    // DBオープン
    userDbManager* userDbMng = [[userDbManager alloc]initWithDbOpen];
    
    NSMutableString *addState = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementWithStringBuffer:addState];
#endif
    
    // 期間チェック
    NSInteger selectSearch = [self checkTerm:start End:end];
    switch ( selectSearch )
    {
        case SELECT_TERM_ERROR:
        {
            // error
            stat = NO;
        }
            break;
            
        case SELECT_NONE:
        {
            // DBクローズ
            [userDbMng closeDataBase];
            [userDbMng release];
            
            // 期限が入ってないので全検索
            [self setUserInfoList:nil selectKind:SELECT_NONE];
        }
            return stat;
            
        case SELECT_TERM_DATE:
        {
            // 期間検索（年／月／日）
            BOOL startEarly = [self checkStartDate:start End:end];
            
            // 文字列に変換
            NSDateComponents* startDate = startEarly ? start : end;
            NSDateComponents* endDate = startEarly ? end : start;
            NSString* strStart = [NSString stringWithFormat:@"%04ld-%02ld-%02ld",
                                  (long)startDate.year, (long)startDate.month, (long)startDate.day];
            NSString* strEnd   = [NSString stringWithFormat:@"%04ld-%02ld-%02ld",
                                  (long)endDate.year, (long)endDate.month, (long)endDate.day];
            
            /*
             年／月検索(指定範囲に該当する施術履歴一覧が返ってくる)
             */
            users = [userDbMng getUserInfoListBySearchStart:strStart
                                                    EndDate:strEnd
                                                   optional:addState];
            
            // 先頭リストにユーザー一覧を加える（初回登録日でのフィルターを掛ける）
            NSInteger count = [self detectFirstDay:users
                                          startDay:strStart
                                            endDay:strEnd
                                         dbManager:userDbMng];
            
            // タイトルの設定
            [workDateSearchTitle release];
            workDateSearchTitle =
                [NSString stringWithFormat:@"初回来店日が %04ld年%02ld月%02ld日 〜 %04ld年%02ld月%02ld日 のお客様  % 4ld件",
                                            (long)startDate.year, (long)startDate.month, (long)startDate.day,
                                            (long)endDate.year, (long)endDate.month, (long)endDate.day, (long)count];
            [workDateSearchTitle retain];
        }
            break;
            
        case SELECT_TERM_MONTH:
        {
            // 期間検索（年／月）
            BOOL startEarly = [self checkStartDate:start End:end];
            
            // 文字列に変換
            NSDateComponents* startDate = startEarly ? start : end;
            NSDateComponents* endDate = startEarly ? end : start;
            NSInteger lastDay = [self getMonthLastDay:endDate];
            NSString* strStart = [NSString stringWithFormat:@"%04ld-%02ld-01", (long)startDate.year, (long)startDate.month];
            NSString* strEnd   = [NSString stringWithFormat:@"%04ld-%02ld-%02ld", (long)endDate.year, (long)endDate.month, (long)lastDay];
            
            /*
             年／月検索
             */
            users = [userDbMng getUserInfoListBySearchStart:strStart
                                                    EndDate:strEnd
                                                   optional:addState];
            
            // 先頭リストにユーザー一覧を加える（初回登録日でのフィルターを掛ける）
            NSInteger count = [self detectFirstDay:users
                                          startDay:strStart
                                            endDay:strEnd
                                         dbManager:userDbMng];
            // タイトルの設定
            [workDateSearchTitle release];
            workDateSearchTitle =
                [NSString stringWithFormat:@"初回来店日が %04ld年%02ld月%02d日 〜 %04ld年%02ld月%02ld日 のお客様　% 4ld件",
                                            (long)startDate.year, (long)startDate.month, 1,
                                            (long)endDate.year, (long)endDate.month, (long)lastDay, (long)count];
            [workDateSearchTitle retain];
        }
            break;
            
        case SELECT_TERM_YEAR:
        {
            // 期間検索（年）
            BOOL startEarly = [self checkStartDate:start End:end];
            
            // 文字列に変換
            NSDateComponents* startDate = startEarly ? start : end;
            NSDateComponents* endDate = startEarly ? end : start;
            NSString* strStart = [NSString stringWithFormat:@"%04ld-01-01", (long)startDate.year];
            NSString* strEnd   = [NSString stringWithFormat:@"%04ld-12-31", (long)endDate.year];
            
            /*
             年／月検索
             */
            users = [userDbMng getUserInfoListBySearchStart:strStart
                                                    EndDate:strEnd
                                                   optional:addState];
            
            // 先頭リストにユーザー一覧を加える（初回登録日でのフィルターを掛ける）
            NSInteger count = [self detectFirstDay:users
                                          startDay:strStart
                                            endDay:strEnd
                                         dbManager:userDbMng];
            // タイトルの設定
            [workDateSearchTitle release];
            workDateSearchTitle =
                [NSString stringWithFormat:@"初回来店日が %04ld年%02d月%02d日 〜 %04ld年%02d月%02d日 のお客様　% 4ld件",
                                            (long)startDate.year, 1, 1,
                                            (long)endDate.year, 12, 31, (long)count];
            [workDateSearchTitle retain];
        }
            break;
            
        case SELECT_SINGLE_TERM_DATE:
        {
            // DBクローズ
            [userDbMng closeDataBase];
            [userDbMng release];
            
            // 日付チェック(この場合どちらか片方が空の状態なはず)
            NSDateComponents* cmp = start;
            if ( [self isDateEmpty:start] == YES )
            {
                // startが使えないので
                cmp = end;
            }
            
            // NSDateに変換
            NSCalendar* cal = [NSCalendar currentCalendar];
            NSDate* dateObj = [cal dateFromComponents:cmp];
            
            /*
             年／月／日付検索 == 施術日による検索と同一
             */
            [self setUserInfoListWithWorkDate:dateObj:SELECT_START_WORK_DATE];
        }
            return stat;
            
        case SELECT_SINGLE_TERM_MONTH:
        {
            // 日付チェック(この場合どちらか片方が空の状態なはず)
            NSDateComponents* cmp = start;
            if ( [self isDateEmpty:start] == YES )
            {
                // startが使えないので
                cmp = end;
            }
            
            // NSStringに変換
            NSString* startDate = [NSString stringWithFormat:@"%04ld-%02ld-01", (long)cmp.year, (long)cmp.month];
            NSString* endDate = nil;
            NSInteger lastDay = [self getMonthLastDay:cmp];
            if ( [self isLeapYear:cmp.year] == YES && cmp.month == 2 )
            {
                // 2月のみ
                endDate = [NSString stringWithFormat:@"%04ld-%02d-%02d", (long)cmp.year, 2, 29];
            }
            else
            {
                // その他
                endDate = [NSString stringWithFormat:@"%04ld-%02ld-%02ld", (long)cmp.year, (long)cmp.month, (long)lastDay];
            }
            
            /*
             年／月検索
             */
            users = [userDbMng getUserInfoListBySearchStart:startDate EndDate:endDate
                                                   optional:addState];
            
            // 先頭リストにユーザー一覧を加える（初回登録日でのフィルターを掛ける）
            NSInteger count = [self detectFirstDay:users
                                          startDay:startDate
                                            endDay:endDate
                                         dbManager:userDbMng];
            // タイトルの設定
            [workDateSearchTitle release];
            workDateSearchTitle =
                [NSString stringWithFormat:@"初回来店日が %04ld年%02ld月 のお客様　% 4ld件",
                                            (long)cmp.year, (long)cmp.month, (long)count];
            [workDateSearchTitle retain];
        }
            break;
            
        case SELECT_SINGLE_TERM_YEAR:
        {
            // 日付チェック(この場合どちらか片方が空の状態なはず)
            NSDateComponents* cmp = start;
            if ( [self isDateEmpty:start] == YES )
            {
                // startが使えないので
                cmp = end;
            }
            
            // NSStringに変換
            NSString* startDate = [NSString stringWithFormat:@"%04ld-01-01", (long)cmp.year];
            NSString* endDate = [NSString stringWithFormat:@"%04ld-12-31", (long)cmp.year];
            
            /*
             年検索
             */
            users = [userDbMng getUserInfoListBySearchStart:startDate EndDate:endDate
                                                   optional:addState];
            
            // 先頭リストにユーザー一覧を加える（初回登録日でのフィルターを掛ける）
            NSInteger count = [self detectFirstDay:users
                                          startDay:startDate
                                            endDay:endDate
                                         dbManager:userDbMng];
            // タイトルの設定
            [workDateSearchTitle release];
            workDateSearchTitle =
                [NSString stringWithFormat:@"初回来店日が %04ld年 のお客様　% 4ld件", (long)cmp.year, (long)count];
            [workDateSearchTitle retain];
        }
            break;
            
        default:
            break;
    }
    
    // DBクローズ
    [userDbMng closeDataBase];
    [userDbMng release];
    
    return stat;
}

/**
 指定範囲で最新施術日の条件(初回登録日)が一致しているユーザーを抜き出してリストに加える
 */
- (NSInteger)detectFirstDay:(NSMutableArray*)users
                   startDay:(NSString *)strStart
                     endDay:(NSString *)strEnd
                  dbManager:(userDbManager *)userDbMng
{
    NSMutableArray* list = [userInfoListArray objectAtIndex:0];
    
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    [inputFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *rtDate;                                             // 範囲検索の結果日付
    NSDate *stDate = [inputFormatter dateFromString:strStart];  // 検索開始範囲
    NSDate *edDate = [inputFormatter dateFromString:strEnd];    // 検索終了範囲
    
    [userDbMng openDataBase];
    
    // 先頭リストを取り出して、ユーザ一覧を加える
    for ( id user in users )
    {
        NSString *maxDate = [userDbMng getFirstWorkDateWithUserID:((userInfo *)user).userID];
        rtDate = [inputFormatter dateFromString:maxDate];
        NSComparisonResult resultStart = [rtDate compare:stDate];
        NSComparisonResult resultEnd   = [rtDate compare:edDate];
        // 指定範囲に施術履歴を持つユーザから最新施術履歴で一致しているユーザだけを抜き出す
        if ((resultStart==NSOrderedDescending && resultEnd==NSOrderedAscending) ||
            resultStart==NSOrderedSame || resultEnd==NSOrderedSame) {
            ((userInfo *)user).lastWorkDate = [inputFormatter dateFromString:[userDbMng getMaxNewWorkDateWithUserID:((userInfo *)user).userID]];
            [list addObject:user];
        }
    }
    [inputFormatter release];
    
    return [list count];
}

// startが早いかチェックする
- (BOOL) checkStartDate:(NSDateComponents*)start End:(NSDateComponents*)end
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *date1 = [cal dateFromComponents:start];
    NSDate *date2 = [cal dateFromComponents:end];
    
    NSComparisonResult result = [date1 compare:date2];
    BOOL val = NO;
    
    switch (result) {
        case NSOrderedSame:         // 同一
            val = YES;
            break;
        case NSOrderedAscending:    // date1が過去
            val =  YES;
            break;
        case NSOrderedDescending:   // date2が過去
            val =  NO;
        default:
            break;
    }
    return val;
}


// うるう年チェック
- (BOOL) isLeapYear:(NSInteger)year
{
	BOOL ret = NO;
	if ( (year % 4) == 0 )
	{
		if ( (year % 100) == 0 )
		{
			ret = ((year % 400) == 0) ? YES : NO;
		}
	}
	return ret;
}

// 月末を取得
- (NSInteger) getMonthLastDay:(NSDateComponents*) cmp
{
	if ( cmp.day == 0 ) cmp.day = 1;
	NSCalendar* cal = [NSCalendar currentCalendar];
	NSDate* date = [cal dateFromComponents:cmp];
	NSRange range = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:date];
	return range.length;
}

// 検索期間をチェックする
- (NSInteger) checkTerm:(NSDateComponents*) start End:(NSDateComponents*) end
{
	/*
	 start:
	 YEAR / MONTH / DAY
	 -------------------
	 XXXX / XX / XX => SELECT_TERM_DATE (date search)
	 XXXX / XX / -- => SELECT_TERM_MONTH (month search)
	 XXXX / -- / -- => SELECT_TERM_YEAR (year search)
	 ---- / -- / -- => SELECT_TERM_START_NONE (-->end)
	 ---- / -- / XX => SELECT_NONE
	 ---- / XX / -- => SELECT_NONE
	 ---- / XX / XX => SELECT_NONE
	 XXXX / -- / XX => SELECT_NONE
	 */
	NSInteger startCheck = 0;
	if ( start.year > 0 && start.month > 0 && start.day > 0 )
		startCheck = SELECT_TERM_DATE;
	else if ( start.year > 0 && start.month > 0 && start.day == 0 )
		startCheck = SELECT_TERM_MONTH;
	else if ( start.year > 0 && start.month == 0 && start.day == 0 )
		startCheck = SELECT_TERM_YEAR;
	else if ( start.year == 0 && start.month == 0 && start.day == 0 )
		startCheck = SELECT_TERM_START_NONE;
	else
		startCheck = SELECT_NONE;

	/*
	 end: start(SELECT_TERM_START_NONE)
	 YEAR / MONTH / DAY
	 -------------------
	 XXXX / XX / XX => SELECT_SINGLE_TERM_DATE (date search)
	 XXXX / XX / -- => SELECT_SINGLE_TERM_MONTH (month search)
	 XXXX / -- / -- => SELECT_SINGLE_TERM_YEAR (year search)
	 ---- / -- / -- => SELECT_NONE (ALL)
	 ---- / -- / XX => SELECT_TERM_ERROR
	 ---- / XX / -- => SELECT_TERM_ERROR
	 ---- / XX / XX => SELECT_TERM_ERROR
	 XXXX / -- / XX => SELECT_TERM_ERROR

	 end: start(SELECT_TERM_DATE)
	 YEAR / MONTH / DAY
	 -------------------
	 XXXX / XX / XX => SELECT_TERM_DATE (date search)
	 XXXX / XX / -- => SELECT_TERM_MONTH (month search)
	 XXXX / -- / -- => SELECT_TERM_YEAR (year search)
	 ---- / -- / -- => YES (-->single)
	 ---- / -- / XX => SELECT_TERM_ERROR
	 ---- / XX / -- => SELECT_TERM_ERROR
	 ---- / XX / XX => SELECT_TERM_ERROR
	 XXXX / -- / XX => SELECT_TERM_ERROR

	 end: start(SELECT_TERM_MONTH)
	 YEAR / MONTH / DAY
	 -------------------
	 XXXX / XX / XX => SELECT_TERM_MONTH (month search)
	 XXXX / XX / -- => SELECT_TERM_MONTH (month search)
	 XXXX / -- / -- => SELECT_TERM_YEAR (year search)
	 ---- / -- / -- => YES (-->single)
	 ---- / -- / XX => SELECT_TERM_ERROR
	 ---- / XX / -- => SELECT_TERM_ERROR
	 ---- / XX / XX => SELECT_TERM_ERROR
	 XXXX / -- / XX => SELECT_TERM_ERROR

	 end: start(SELECT_TERM_YEAR)
	 YEAR / MONTH / DAY
	 -------------------
	 XXXX / XX / XX => SELECT_TERM_YEAR (year search)
	 XXXX / XX / -- => SELECT_TERM_YEAR (year search)
	 XXXX / -- / -- => SELECT_TERM_YEAR (year search)
	 ---- / -- / -- => YES (-->single)
	 ---- / -- / XX => SELECT_TERM_ERROR
	 ---- / XX / -- => SELECT_TERM_ERROR
	 ---- / XX / XX => SELECT_TERM_ERROR
	 XXXX / -- / XX => SELECT_TERM_ERROR

	 */
	if ( startCheck == SELECT_TERM_START_NONE )
	{
		if ( end.year > 0 && end.month > 0 && end.day > 0 )
			return SELECT_SINGLE_TERM_DATE;
		else if ( end.year > 0 && end.month > 0 && end.day == 0 )
			return SELECT_SINGLE_TERM_MONTH;
		else if ( end.year > 0 && end.month == 0 && end.day == 0 )
			return SELECT_SINGLE_TERM_YEAR;
		else if ( end.year == 0 && end.month == 0 && end.day == 0 )
			return SELECT_NONE;
		else
			return SELECT_TERM_ERROR;
	}
	else
	if ( startCheck == SELECT_TERM_DATE )
	{
		if ( end.year > 0 && end.month > 0 && end.day > 0 )
			return SELECT_TERM_DATE;
		else if ( end.year > 0 && end.month > 0 && end.day == 0 )
			return SELECT_TERM_MONTH;
		else if ( end.year > 0 && end.month == 0 && end.day == 0 )
			return SELECT_TERM_YEAR;
		else if ( end.year == 0 && end.month == 0 && end.day == 0 )
			return startCheck + 0x10; // ->single
		else
			return SELECT_TERM_ERROR;
	}
	else
	if ( startCheck == SELECT_TERM_MONTH )
	{
		if ( end.year > 0 && end.month > 0 && end.day > 0 )
			return SELECT_TERM_MONTH;
		else if ( end.year > 0 && end.month > 0 && end.day == 0 )
			return SELECT_TERM_MONTH;
		else if ( end.year > 0 && end.month == 0 && end.day == 0 )
			return SELECT_TERM_YEAR;
		else if ( end.year == 0 && end.month == 0 && end.day == 0 )
			return startCheck + 0x10; // ->single
		else
			return SELECT_TERM_ERROR;
	}
	else
	if ( startCheck == SELECT_TERM_YEAR )
	{
		if ( end.year > 0 && end.month > 0 && end.day > 0 )
			return SELECT_TERM_YEAR;
		else if ( end.year > 0 && end.month > 0 && end.day == 0 )
			return SELECT_TERM_YEAR;
		else if ( end.year > 0 && end.month == 0 && end.day == 0 )
			return SELECT_TERM_YEAR;
		else if ( end.year == 0 && end.month == 0 && end.day == 0 )
			return startCheck + 0x10; // ->single
		else
			return SELECT_TERM_ERROR;
	}
	else
	{
		return SELECT_TERM_ERROR;
	}
}

// 日付が空かの判定
- (BOOL) isDateEmpty:(NSDateComponents*)date
{
	return (date.year > 0 || date.month > 0 || date.day > 0) ? NO : YES;
}

// ユーザー情報リストの設定（メモで検索するVersion）
- (BOOL) setUserInfoListWithMemo:(NSDictionary*) arrayMemo And:(BOOL)isAndSearch
{
	BOOL stat = YES;
	NSMutableArray* users1 = nil;
	NSMutableArray* users2 = nil;
    NSMutableArray* users3 = nil;

	// 選択されていなかったらアウト
	if ( arrayMemo == nil
	||  [arrayMemo count] < 1 )
		return NO;

	// メモを取得
	NSArray* arrayMemo1 = [arrayMemo objectForKey:@"0"];
	NSArray* arrayMemo2 = [arrayMemo objectForKey:@"1"];
    NSArray* arrayMemo3 = [arrayMemo objectForKey:@"2"];
	
	//リストの全クリア
	[self allListClear];
	
	// 通常の期間検索
	searchKind = SEARCH_KIND_MEMO;
	
	// DBオープン
	userDbManager* userDbMng = [[userDbManager alloc]initWithDbOpen];
	
    NSMutableString *addState = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementWithStringBuffer:addState];
#endif

	// メモ1の検索
	if ( arrayMemo1 != nil )
	{
		users1 = [userDbMng getUserInfoListByWorkItemArray:arrayMemo1
												 AndSearch:isAndSearch
												  optional:addState];
	}
	
	// メモ2の検索
	if ( arrayMemo2 != nil )
	{
		users2 = [userDbMng getUserInfoListByWorkItem2Array:arrayMemo2
												  AndSearch:isAndSearch
												   optional:addState];
	}

    // フリーメモの検索
    if ( arrayMemo3 != nil )
    {
        users3 = [userDbMng getUserInfoListByMemoArray:arrayMemo3
                                             AndSearch:isAndSearch
                                              optional:addState];
    }

	// メモ１、メモ２とフリーメモのユーザーを合わせる
    NSMutableSet* users = nil;
    NSMutableArray *tmpusers = nil;
	if ( isAndSearch == NO )
	{
		if ( [users1 count] == 0 && [users2 count] == 0  && [users3 count] == 0)
		{
			// nothing
			users = [NSMutableSet set];
		}
		else
		if ( [users1 count] > 0 && [users2 count] == 0 && [users3 count] == 0)
		{
			// only USER1
			users = [NSMutableSet setWithArray:users1];
		}
		else
		if ( [users1 count] == 0 && [users2 count] > 0  && [users3 count] == 0)
		{
			// only USER2
			users = [NSMutableSet setWithArray:users2];
		}
        else
        if ( [users1 count] == 0 && [users2 count] == 0  && [users3 count] > 0)
        {
            // only USER3
            users = [NSMutableSet setWithArray:users3];
        }
		else
		{
            if (users1 != nil && users2 != nil && users3 != nil)
            {
                tmpusers = [self PrecombineUsers:users1 second:users2];
                users = [self combineUsers:tmpusers second:users3];
            }
            else if (users1 != nil && users2 != nil)
            {
                users = [self combineUsers:users1 second:users2];
            }
            else if (users2 != nil && users3 != nil)
            {
                users = [self combineUsers:users2 second:users3];
            }
            else if (users1 != nil && users3 != nil)
            {
                users = [self combineUsers:users1 second:users3];
            }
//			users = [NSMutableSet setWithArray:users1];
		}
	}
	else
	{
		if ( [users1 count] == 0 && [users2 count] == 0 )
		{
			// nothing
			users = [NSMutableSet set];
		}
		else
		if ( [arrayMemo1 count] > 0 && [arrayMemo2 count] == 0 )
		{
			// only USER1
			users = [NSMutableSet setWithArray:users1];
		}
		else
		if ( [arrayMemo1 count] == 0 && [arrayMemo2 count] > 0 )
		{
			// only USER2
			users = [NSMutableSet setWithArray:users2];
		}
		else
		{
			// AND検索に掛かったユーザーを抽出
			users = [NSMutableSet set];
			for ( userInfo* info1 in users1 )
			{
				for ( userInfo* info2 in [users2 reverseObjectEnumerator] )
				{
					if ( [info1 userID] == [info2 userID]
					&&   [info1 lastWorkDate] == [info2 lastWorkDate] )
					{
						[users addObject:info1];
						[users2 removeObject:info2];
						break;
					}
				}
			}

			// 同一ユーザーがいないか？
			for ( userInfo* src in users )
			{
				for ( userInfo* dst in users )
				{
					if ( src == dst )
						continue;

					if ( [src userID] == [dst userID] )
					{
						// 同一ユーザーの最新を残す
						if ( [src lastWorkDate] < [dst lastWorkDate] )
						{
							// dstが最新
							[users removeObject:src];
						}
						else
						{
							// srcが最新
							[users removeObject:dst];
						}
						break;
					}
				}
			}
		}
	}
	
	// 2016/1/18 TMS ストア・デモ版統合対応 ソート対応
	// 先頭リストを取り出して、ユーザ一覧を加える
    NSMutableArray* tmpList =  [NSMutableArray array];
	NSMutableArray* list = [userInfoListArray objectAtIndex:0];

	for ( id user in users )
	{
		[tmpList addObject:user];
	}
	
    
    // ソート条件を定義
    NSSortDescriptor *firstNameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self.firstName" ascending:YES];
    NSSortDescriptor *secondNameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self.secondName" ascending:YES];
    tmpList = (NSMutableArray *)[tmpList sortedArrayUsingDescriptors:@[firstNameSortDescriptor,secondNameSortDescriptor]];
    
    for ( id user in tmpList )
    {
        [list addObject:user];
    }
    
	// タイトルの設定
	[workDateSearchTitle release];
	workDateSearchTitle = [NSString stringWithFormat:@"メモ検索結果のお客様  % 4ld件", (long)[list count]];
	[workDateSearchTitle retain];

	// DBクローズ
	[userDbMng closeDataBase];
	[userDbMng release];
	
	return stat;
}

- (NSMutableArray *) PrecombineUsers:(NSMutableArray *)users1 second:(NSMutableArray *)users2
{
    NSMutableArray* users = nil;
    
    NSMutableArray *tmpUsers = [users1 mutableCopy];
    for ( userInfo* info1 in [tmpUsers reverseObjectEnumerator] )
    {
        for ( userInfo* info2 in [users2 reverseObjectEnumerator] )
        {
            if ( [info1 userID] == [info2 userID] )
            {
                if ( [info1 lastWorkDate] < [info2 lastWorkDate] )
                {
                    [tmpUsers removeObject:info1];
                    [tmpUsers addObject:info2];
                    [users2 removeObject:info2];
                    break;
                }
                else
                {
                    // info1が最新の場合はinfo2の同一ユーザーは削除する
                    [users2 removeObject:info2];
                    break;
                }
            }
        }
    }
    users = tmpUsers;

    for ( userInfo* info in users2 )
    {
        [users addObject:info];
    }
    return users;
}

- (NSMutableSet *) combineUsers:(NSMutableArray *)users1 second:(NSMutableArray *)users2
{
    NSMutableSet* users = nil;
    
    NSMutableArray *tmpUsers = [users1 mutableCopy];
    for ( userInfo* info1 in [tmpUsers reverseObjectEnumerator] )
    {
        for ( userInfo* info2 in [users2 reverseObjectEnumerator] )
        {
            if ( [info1 userID] == [info2 userID] )
            {
                if ( [info1 lastWorkDate] < [info2 lastWorkDate] )
                {
                    [tmpUsers removeObject:info1];
                    [tmpUsers addObject:info2];
                    [users2 removeObject:info2];
                    break;
                }
                else
                {
                    // info1が最新の場合はinfo2の同一ユーザーは削除する
                    [users2 removeObject:info2];
                    break;
                }
            }
        }
    }
    users = [NSMutableSet setWithArray:tmpUsers];
    
    for ( userInfo* info in users2 )
    {
        [users addObject:info];
    }
    return users;
}

// ユーザー情報リストの設定（メール送信エラーで検索するVersion）
- (BOOL) setUserInfoListWithMailSendError:(NSDictionary *)mailSendErrorUserList
{
	BOOL stat = YES;
	
	//  リストの全クリア
	[self allListClear];
	
	//  通常の期間検索
	searchKind = SEARCH_KIND_MAIL_SEND_ERROR;
	
	//  DBオープン
	userDbManager* userDbMng = [[userDbManager alloc]initWithDbOpen];
	
    NSMutableString *addState = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementForCustomerNum:addState];
#endif
    
	NSMutableArray* list = [userInfoListArray objectAtIndex:0];

 	//  端末のデータベースからメール送信エラーのユーザーを取得
    NSMutableArray* users = nil;
    users = [userDbMng getUserInfoListByMailSendError:addState];
    
	//  先頭リストを取り出して、ユーザ一覧を加える
	for ( id user in users )
	{
        if( user == nil ){
            break;
        }
        
        WebMailUserStatus* userStatus = [mailSendErrorUserList objectForKey:[NSNumber numberWithInteger:[user userID]]];
        
        if( userStatus != nil && [userStatus notification_error] > 0 ){
            [list addObject:user];
        }
	}
	
	//  タイトルの設定
	[workDateSearchTitle release];
	workDateSearchTitle = [NSString stringWithFormat:@"メール送信にエラーの有るお客様  % 4ld件", (long)[list count]];
	[workDateSearchTitle retain];
    
	//  DBクローズ
	[userDbMng closeDataBase];
	[userDbMng release];
	
	return stat;
}

// ユーザー情報リストの設定（メール未開封者で検索するVersion）
// アクションシートのリスト名はメール未開封者にしているが、プログラム上ではUNREADで未読者という扱いにする。
- (BOOL) setUserInfoListWithMailUnRead:(NSDictionary *)userMailStatusList
{
	BOOL stat = YES;
	
	//  リストの全クリア
	[self allListClear];
	
	//  通常の期間検索
	searchKind = SEARCH_KIND_MAIL_UNREAD;
	
	//  DBオープン
	userDbManager* userDbMng = [[userDbManager alloc]initWithDbOpen];
	
    NSMutableString *addState = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementForCustomerNum:addState];
#endif
    
	NSMutableArray* list = [userInfoListArray objectAtIndex:0];
    
 	//  端末のデータベースからメール送信エラーのユーザーを取得
    NSMutableArray* users = nil;
    /**
     取得データがメール送信エラーと同じだった為そのままメール送信エラーのものを使用しています。
     */
    users = [userDbMng getUserInfoListByMailSendError:addState];
    
	//  先頭リストを取り出して、ユーザ一覧を加える
	for ( userInfo* user in users )
	{
        if( user == nil ){
            break;
        }
        
        WebMailUserStatus* userStatus = [userMailStatusList objectForKey:[NSNumber numberWithInteger:[user userID]]];
        
        if( userStatus != nil && [userStatus userUnread] > 0 ){
            [list addObject:user];
        }
	}
	
	//  タイトルの設定
	[workDateSearchTitle release];
	workDateSearchTitle = [NSString stringWithFormat:@"未開封状態のメールが有るお客様  % 4ld件", (long)[list count]];
	[workDateSearchTitle retain];
    
	//  DBクローズ
	[userDbMng closeDataBase];
	[userDbMng release];
	
	return stat;
}

//2016/4/9 TMS 顧客検索条件追加
// ユーザー情報リストの設定（店舗側メール未読で検索するVersion）
- (BOOL) setUserInfoListWithMailTenpoUnRead:(NSDictionary *)userMailStatusList
{
    BOOL stat = YES;
    
    //  リストの全クリア
    [self allListClear];
    
    //  通常の期間検索
    searchKind = SEARCH_KIND_MAIL_TENPO_UNREAD;
    
    //  DBオープン
    userDbManager* userDbMng = [[userDbManager alloc]initWithDbOpen];
    
    NSMutableString *addState = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementForCustomerNum:addState];
#endif
    
    NSMutableArray* list = [userInfoListArray objectAtIndex:0];
    
    //  端末のデータベースからメール送信エラーのユーザーを取得
    NSMutableArray* users = nil;
    /**
     取得データがメール送信エラーと同じだった為そのままメール送信エラーのものを使用しています。
     */
    users = [userDbMng getUserInfoListByMailSendError:addState];
    
    //  先頭リストを取り出して、ユーザ一覧を加える
    for ( userInfo* user in users )
    {
        if( user == nil ){
            break;
        }
        
        WebMailUserStatus* userStatus = [userMailStatusList objectForKey:[NSNumber numberWithInteger:[user userID]]];
        
        if( userStatus != nil && [userStatus unread] > 0 ){
            [list addObject:user];
        }
    }
    
    //  タイトルの設定
    [workDateSearchTitle release];
    workDateSearchTitle = [NSString stringWithFormat:@"店舗側にて未開封状態のメールが有るお客様  % 4ld件", (long)[list count]];
    [workDateSearchTitle retain];
    
    //  DBクローズ
    [userDbMng closeDataBase];
    [userDbMng release];
    
    return stat;
}

//2016/4/9 TMS 顧客検索条件追加
// ユーザー情報リストの設定（要対応メールで検索するVersion）
- (BOOL) setUserInfoListWithMailTenpoAnswer:(NSDictionary *)userMailStatusList
{
    BOOL stat = YES;
    
    //  リストの全クリア
    [self allListClear];
    
    //  通常の期間検索
    searchKind = SEARCH_KIND_MAIL_TENPO_UNREAD;
    
    //  DBオープン
    userDbManager* userDbMng = [[userDbManager alloc]initWithDbOpen];
    
    NSMutableString *addState = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementForCustomerNum:addState];
#endif
    
    NSMutableArray* list = [userInfoListArray objectAtIndex:0];
    
    //  端末のデータベースからメール送信エラーのユーザーを取得
    NSMutableArray* users = nil;
    /**
     取得データがメール送信エラーと同じだった為そのままメール送信エラーのものを使用しています。
     */
    users = [userDbMng getUserInfoListByMailSendError:addState];
    
    //  先頭リストを取り出して、ユーザ一覧を加える
    for ( userInfo* user in users )
    {
        if( user == nil ){
            break;
        }
        
        WebMailUserStatus* userStatus = [userMailStatusList objectForKey:[NSNumber numberWithInteger:[user userID]]];
        
        if( userStatus != nil && [userStatus check] > 0 ){
            [list addObject:user];
        }
    }
    
    //  タイトルの設定
    [workDateSearchTitle release];
    workDateSearchTitle = [NSString stringWithFormat:@"要対応状態のメールが有るお客様  % 4ld件", (long)[list count]];
    [workDateSearchTitle retain];
    
    //  DBクローズ
    [userDbMng closeDataBase];
    [userDbMng release];
    
    return stat;
}

/*
 userListを書き換えずに全ユーザーの情報を取得する
 */
-(NSDictionary *)getAllUserInfo
{
	//  DBオープン
	userDbManager* userDbMng = [[userDbManager alloc]initWithDbOpen];
	
    NSMutableString *addState = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementWithStringBuffer:addState];
#endif
    
 	//  端末のデータベースからメール送信エラーのユーザーを取得
    NSMutableArray* users = nil;
    users = [userDbMng getAllUsers];
    
	//  DBクローズ
	[userDbMng closeDataBase];
	[userDbMng release];
	
	return (NSDictionary *)users;
}

// ショップに属するユーザー数を取得する
- (NSInteger) getShopUserInfo
{
    // データベースの初期化
    userDbManager *dbMng = [[userDbManager alloc] init];
    
    NSMutableString *addState = [NSMutableString string];
#ifdef CLOUD_SYNC
    // 現在選択中の店舗IDによる条件の追加
    [self addWhereStatementForCustomerNum:addState];
#endif
    
    // 該当行のuser数
    NSInteger count = [dbMng getUserInfoListCountBySearch:addState];
    [dbMng release];
    return count;
}

//--------------------------------------------------
// 以下のgetterはsetUserListの実行後の状態を返すものとする
//--------------------------------------------------

// 行数(セクション数)の取得
- (NSInteger) getSectionNum
{
	NSInteger num = 0;
	
	switch ( searchKind )
	{
		case SEARCH_KIND_ALL:
			// 全検索
			num = [self getSectionMax];
			break;
		case SEARCH_KIND_ONE_STRING:
		case SEARCH_KIND_WORK_DATE:
		case SEARCH_KIND_REGIST_NUMBER:
			// 検索指定と施術日、お客様番号による検索の場合は、１行とする
		case SEARCH_KIND_BIRTHDAY:                  // 誕生日による検索
		case SEARCH_KIND_LASTWORK_TERM:             // 最新施術日を期間で検索
		case SEARCH_KIND_MEMO:                      // メモで検索
		case SEARCH_KIND_MAIL_SEND_ERROR:           // メール送信エラーで検索
        case SEARCH_KIND_MAIL_UNREAD:               // メール未読者で検索
        //2016/4/9 TMS 顧客検索条件追加
        case SEARCH_KIND_MAIL_TENPO_UNREAD:         // 店舗側メール未読で検索
        case SEARCH_KIND_MAIL_TENPO_ANSWER:         // 要対応メールで検索
			num = 1;
			break;
		case (NSUInteger)SEARCH_KIND_GOJYUON:
			// 五十音検索：有効な行を探す
			for (NSUInteger i = 0; i < [self getSectionMax]; i++)
			{
				NSMutableString *title = [gojyuonTitleLists objectAtIndex:i];
				if((title) && ([title length] > 0)  )
				{ num++;}
			}
			break;
			
		default:
			break;
	}
		
	return ( num);
}

// 行数(セクション数)の取得
- (NSInteger) getSectionNum2
{
    NSLog(@"met moi vai 7");
	NSInteger num = 0;
	
	switch ((NSUInteger)searchKind)
	{
		case (NSUInteger)SEARCH_KIND_ALL:
			// 全検索
			num = [self getSectionMax];
			break;
		case (NSUInteger)SEARCH_KIND_ONE_STRING:
		case (NSUInteger)SEARCH_KIND_WORK_DATE:
		case (NSUInteger)SEARCH_KIND_REGIST_NUMBER:
			// 検索指定と施術日、お客様番号による検索の場合は、１行とする
			num = 1;
			break;
		case (NSUInteger)SEARCH_KIND_GOJYUON:
			// 五十音検索：有効な行を探す
            num = 1;
//			for (NSUInteger i = 0; i < SECTION_MAX; i++)
//			{
//				NSMutableString *title = [gojyuonTitleLists objectAtIndex:i];
//				if((title) && ([title length] > 0)  )
//				{ num++;}
//			}
			break;
		case SEARCH_KIND_BIRTHDAY:
			// 誕生日による検索
			num = 1;
			break;
            
		case SEARCH_KIND_LASTWORK_TERM:
			// 最新施術日を期間で検索
			num = 1;
			break;
            
		case SEARCH_KIND_MEMO:
			// メモで検索
			num = 1;
			break;
			
		default:
			break;
	}
    
	return ( num);
}

// 各行でのユーザ数（セル数）の取得
- (NSInteger) getUserNum:(NSInteger)section
{
	NSMutableArray *list = nil;
	NSUInteger idx;
	
	switch ((NSUInteger)searchKind) 	
	{
		case (NSUInteger)SEARCH_KIND_ALL:
		case (NSUInteger)SEARCH_KIND_ONE_STRING:
		case (NSUInteger)SEARCH_KIND_WORK_DATE:
		case (NSUInteger)SEARCH_KIND_REGIST_NUMBER:
		case (NSUInteger)SEARCH_KIND_BIRTHDAY:
		case (NSUInteger)SEARCH_KIND_LASTWORK_TERM:
		case (NSUInteger)SEARCH_KIND_MEMO:
        case (NSUInteger)SEARCH_KIND_MAIL_SEND_ERROR:
        case (NSUInteger)SEARCH_KIND_MAIL_UNREAD:
        //2016/4/9 TMS 顧客検索条件追加
        case (NSUInteger)SEARCH_KIND_MAIL_TENPO_UNREAD:
        case (NSUInteger)SEARCH_KIND_MAIL_TENPO_ANSWER:
			// 五十音検索以外は指定行のリストを取り出す
//            #ifdef DEBUG
//            NSLog(@"userinfo = %@",userInfoListArray);
//            NSLog(@"section = %ld",(long)section);
//            #endif
            
			list = [userInfoListArray objectAtIndex:(NSUInteger)section];
			break;
		case (NSUInteger)SEARCH_KIND_GOJYUON:
			// 五十音検索：有効な行を探す
			idx = [self getIndexBySectionNum:section isSorceUserInfo:NO];
			if (idx < [self getSectionMax])
			{
				list = [userInfoListArray objectAtIndex:idx];
			}
			break;
		default:
			break;
	}
	return ( (list)? (NSInteger)[list count] : 0);
}

// 行（セクション）のタイトル取得
- (NSString*) getSectionTitle:(NSInteger)section
{
	NSString *title = nil;
	NSUInteger idx;
	
	switch ((NSUInteger)searchKind) 
	{
		case (NSUInteger)SEARCH_KIND_ALL:
			// 全検索
			title 
				= [self checkLanguage]?
            (NSString*)[jtitleLists objectAtIndex:(NSUInteger)section] : (NSString*)[etitleLists objectAtIndex:(NSUInteger)section];
			break;
		case (NSUInteger)SEARCH_KIND_ONE_STRING:
			// 検索指定の場合
            
			title = searchNameTitle;
			break;
		case (NSUInteger)SEARCH_KIND_GOJYUON:
			// 五十音検索：有効な行を探す
			idx = [self getIndexBySectionNum:section isSorceUserInfo:NO];
			if (idx < [self getSectionMax])
			{
				title 
					= (NSString*)[gojyuonTitleLists objectAtIndex:idx];
			}			
			break;
		case (NSUInteger)SEARCH_KIND_WORK_DATE:
			// 施術日による検索
			title = [NSString stringWithString: workDateSearchTitle];
			break;
		case (NSUInteger)SEARCH_KIND_REGIST_NUMBER:
			// お客様番号による検索
			title = (lastRegistNumber != REGIST_NUMBER_INVALID)?
				[NSString stringWithFormat:@"「%ld」の番号に該当するお客様", (long)lastRegistNumber]:
				[NSString stringWithFormat:@"お客様番号の一覧  % 4ld件", (long)[[userInfoListArray objectAtIndex:0] count]];
			break;
		case (NSUInteger)SEARCH_KIND_BIRTHDAY:
			// 誕生日による検索
			title = [NSString stringWithString: workDateSearchTitle];
			break;

		case (NSUInteger)SEARCH_KIND_LASTWORK_TERM:
			// 最新施術日を期間で検索
			title = [NSString stringWithString: workDateSearchTitle];
			break;
			
		case (NSUInteger)SEARCH_KIND_MEMO:
			// メモで検索
			title = [NSString stringWithString: workDateSearchTitle];
			break;
            
        case (NSUInteger)SEARCH_KIND_MAIL_SEND_ERROR:
			// メール送信エラー
			title = [NSString stringWithString: workDateSearchTitle];
			break;

        case (NSUInteger)SEARCH_KIND_MAIL_UNREAD:
			// メール未開封者で検索
			title = [NSString stringWithString: workDateSearchTitle];
			break;
        //2016/4/9 TMS 顧客検索条件追加
        case (NSUInteger)SEARCH_KIND_MAIL_TENPO_UNREAD:
            // 店舗側メール未読で検索
            title = [NSString stringWithString: workDateSearchTitle];
            break;
        case (NSUInteger)SEARCH_KIND_MAIL_TENPO_ANSWER:
            // 要対応メールで検索
            title = [NSString stringWithString: workDateSearchTitle];
            break;
            
		default:
			break;
	}			
	
	return(title);

}

//on Reverse
- (NSArray *)getSectionTitleArray:(BOOL)onReverse {
    NSArray *titles;
    NSArray* reversedJArray = [[jtitleLists reverseObjectEnumerator] allObjects];
    NSArray* reversedEArray = [[etitleLists reverseObjectEnumerator] allObjects];
    
    switch ((NSUInteger)searchKind)
    {
        case (NSUInteger)SEARCH_KIND_ALL:
            
            titles = [self checkLanguage]? reversedJArray : reversedEArray;
            break;
        case (NSUInteger)SEARCH_KIND_ONE_STRING:
            // 検索指定の場合は空文字とする
            titles = nil;
            break;
        case (NSUInteger)SEARCH_KIND_GOJYUON:
            // 五十音検索：有効な行を探す
            //            titles =gojyuonTitleLists;
            titles = nil;
            break;
        case (NSUInteger)SEARCH_KIND_WORK_DATE:
            // 施術日による検索
            titles = nil;
            break;
        case (NSUInteger)SEARCH_KIND_REGIST_NUMBER:
            // お客様番号による検索
            titles = nil;
            break;
        case (NSUInteger)SEARCH_KIND_BIRTHDAY:
            // 誕生日による検索
            titles = nil;
            break;
            
        case (NSUInteger)SEARCH_KIND_LASTWORK_TERM:
            // 最新施術日を期間で検索
            titles = nil;
            break;
        case (NSUInteger)SEARCH_KIND_MEMO:
            // メモで検索
            titles = nil;
            break;
        default:
            titles = nil;
            break;
    }
    
    return(titles);
}

// セクションのタイトル配列取得
- (NSArray *)getSectionTitleArray
{
    NSArray *titles;
	switch ((NSUInteger)searchKind)
	{
		case (NSUInteger)SEARCH_KIND_ALL:
			// 全検索
            titles = [self checkLanguage]? jtitleLists : etitleLists;
			break;
		case (NSUInteger)SEARCH_KIND_ONE_STRING:
			// 検索指定の場合は空文字とする
			titles = nil;
			break;
		case (NSUInteger)SEARCH_KIND_GOJYUON:
			// 五十音検索：有効な行を探す
//            titles =gojyuonTitleLists;
            titles = nil;
			break;
		case (NSUInteger)SEARCH_KIND_WORK_DATE:
			// 施術日による検索
			titles = nil;
			break;
		case (NSUInteger)SEARCH_KIND_REGIST_NUMBER:
			// お客様番号による検索
			titles = nil;
			break;
		case (NSUInteger)SEARCH_KIND_BIRTHDAY:
			// 誕生日による検索
			titles = nil;
			break;
            
		case (NSUInteger)SEARCH_KIND_LASTWORK_TERM:
			// 最新施術日を期間で検索
			titles = nil;
			break;
		case (NSUInteger)SEARCH_KIND_MEMO:
			// メモで検索
			titles = nil;
			break;
		default:
            titles = nil;
			break;
	}			
	
	return(titles);
    
}

// 指定行（セクション）におけるユーザ情報（セル）個数取得
- (NSInteger) getUserInfoNums:(NSInteger)section
{
	NSMutableArray	*list = nil;
	NSUInteger idx;
	
	switch ((NSUInteger)searchKind) 	
	{
		case (NSUInteger)SEARCH_KIND_ALL:
		case (NSUInteger)SEARCH_KIND_ONE_STRING:
		case (NSUInteger)SEARCH_KIND_WORK_DATE:
		case (NSUInteger)SEARCH_KIND_REGIST_NUMBER:
		case (NSUInteger)SEARCH_KIND_BIRTHDAY:
		case (NSUInteger)SEARCH_KIND_LASTWORK_TERM:
		case (NSUInteger)SEARCH_KIND_MEMO:
        case (NSUInteger)SEARCH_KIND_MAIL_SEND_ERROR:
        case (NSUInteger)SEARCH_KIND_MAIL_UNREAD:
        //2016/4/9 TMS 顧客検索条件追加
        case SEARCH_KIND_MAIL_TENPO_UNREAD:         // 店舗側メール未読で検索
        case SEARCH_KIND_MAIL_TENPO_ANSWER:         // 要対応メールで検索
			// 五十音検索以外は指定行のリストを取り出す
			list  
			= [userInfoListArray objectAtIndex:(NSUInteger)section];
			break;
			
		case (NSUInteger)SEARCH_KIND_GOJYUON:
			// 五十音検索：有効な行を探す
			idx = [self getIndexBySectionNum:section isSorceUserInfo:NO];
			if (idx < [self getSectionMax])
			{
				list = [userInfoListArray objectAtIndex:(NSUInteger)idx];
			}
			break;
			
		default:
			break;
	}
	
	return ( (list)? [list count] : 0);
}

// 各行（セクション）でのユーザ情報（セル）の取得
- (userInfo*) getUserInfoBySection:(NSInteger)section rowNum:(NSInteger)row
{
	NSMutableArray	*list = nil;
	NSUInteger idx;
	// 指定行のリストを取り出す
	switch ((NSUInteger)searchKind) 	
	{
		case (NSUInteger)SEARCH_KIND_ALL:
		case (NSUInteger)SEARCH_KIND_ONE_STRING:
		case (NSUInteger)SEARCH_KIND_WORK_DATE:
		case (NSUInteger)SEARCH_KIND_REGIST_NUMBER:
		case (NSUInteger)SEARCH_KIND_BIRTHDAY:
		case (NSUInteger)SEARCH_KIND_LASTWORK_TERM:
		case (NSUInteger)SEARCH_KIND_MEMO:
        case (NSUInteger)SEARCH_KIND_MAIL_SEND_ERROR:
        case (NSUInteger)SEARCH_KIND_MAIL_UNREAD:
        //2016/4/9 TMS 顧客検索条件追加
        case SEARCH_KIND_MAIL_TENPO_UNREAD:         // 店舗側メール未読で検索
        case SEARCH_KIND_MAIL_TENPO_ANSWER:         // 要対応メールで検索
			// 五十音検索以外は指定行のリストを取り出す
			list  
				= [userInfoListArray objectAtIndex:(NSUInteger)section];
			break;
		
		case (NSUInteger)SEARCH_KIND_GOJYUON:
			// 五十音検索：有効な行を探す

			idx = [self getIndexBySectionNum:section isSorceUserInfo:NO];
			if (idx < [self getSectionMax])
			{
				list = [userInfoListArray objectAtIndex:(NSUInteger)idx];
			}
			break;
		
		default:
			break;
	}
    
    if ((list) && [list count] > row) {
        return (userInfo*)[list objectAtIndex:(NSUInteger)row];
    } else {
        return nil;
    }
    
//    return ( ( (list) && ([list count] > row) )? (userInfo*)[list objectAtIndex:(NSUInteger)row] : nil);
}

//ユーザー情報リストの並び替え
- (void) sortUserInfoList:(BOOL)conditions{
    NSMutableArray		*newUserInfoListArray2 = [NSMutableArray array];
    if(searchKind == SEARCH_KIND_REGIST_NUMBER || (conditions == YES && searchKind != SEARCH_KIND_GOJYUON)){
        NSMutableArray		*list = [NSMutableArray array];
        NSMutableArray		*newUserInfoListArray = [NSMutableArray array];
        list = [userInfoListArray objectAtIndex:0];
        if([list count] > 0){
            for(int i2 = (int)[list count]-1;i2 >= 0;i2--){
                [newUserInfoListArray addObject:[list objectAtIndex:i2]];
            }
            [userInfoListArray replaceObjectAtIndex:0 withObject:newUserInfoListArray];
        }else{
            [newUserInfoListArray2 addObject:list];
        }
    }else if(searchKind == SEARCH_KIND_GOJYUON){
        if([gojyuonTitleLists count] > 1){
            int numS = -1;
            int numG = -1;
            for(int i4 = 0;i4 < (int)[gojyuonTitleLists count];i4++){
                NSMutableString *title = [gojyuonTitleLists objectAtIndex:i4];
                if((title) && ([title length] > 0)  ){
                    if(numS == -1){
                        numS = i4;
                    }else{
                        numG = i4;
                    }
                }
            }
            
            for(int i5 = numS;i5 < numG;i5++){
                if(i5 >= numG){
                    break;
                }
                [gojyuonTitleLists exchangeObjectAtIndex:i5 withObjectAtIndex:numG];
                [userInfoListArray exchangeObjectAtIndex:i5 withObjectAtIndex:numG];
                numG = numG - 1;
            }
            
            for(int i6 = 0;i6 < (int)[userInfoListArray count];i6++){
                NSMutableArray        *list = [NSMutableArray array];
                NSMutableArray        *newUserInfoListArray = [NSMutableArray array];
                list = [userInfoListArray objectAtIndex:i6];
                if([list count] > 0){
                    for(int i7 = (int)[list count]-1;i7 >= 0;i7--){
                        [newUserInfoListArray addObject:[list objectAtIndex:i7]];
                    }
                }
                
                [userInfoListArray replaceObjectAtIndex:i6 withObject:newUserInfoListArray];
            }
        }
    }else{
        for(int i = (int)[userInfoListArray count]-1;i >= 0;i--){
            NSMutableArray		*list = [NSMutableArray array];
            NSMutableArray		*newUserInfoListArray = [NSMutableArray array];
            list = [userInfoListArray objectAtIndex:i];
            if([list count] > 0){
                for(int i2 = (int)[list count]-1;i2 >= 0;i2--){
                    [newUserInfoListArray addObject:[list objectAtIndex:i2]];
                }
                [newUserInfoListArray2 addObject:newUserInfoListArray];
            }else{
                [newUserInfoListArray2 addObject:list];
            }
        }
        [userInfoListArray removeAllObjects];
        for(int i3 = 0;i3 < [newUserInfoListArray2 count];i3++){
            [userInfoListArray addObject:[newUserInfoListArray2 objectAtIndex:i3]];
        }
    }
}

// ユーザIDによるIndexPathの取得
- (NSIndexPath*) getIndexPathWithUserID:(NSInteger)userID
{
	NSIndexPath *path = nil;
	
	// ユーザ情報リストより全検索する
	NSUInteger section = 0;
	for (NSMutableArray* usrList in userInfoListArray)
	{
		NSUInteger row = 0;
		for (userInfo* info in usrList)
		{
			if (info.userID == userID)
			{
				path = [NSIndexPath indexPathForRow:row inSection:section];
				break;
			}
			if (path)
			{ break; }
			
			row++;
		}
		section++;
	}
	
	return (path);
}

// リスト先頭のIndexPathを取得する
- (NSIndexPath*) getListTopIndexPath
{
	NSIndexPath* topPath = nil;
	
	for (NSUInteger i = 0; i < [self getSectionMax]; i++)
	{
		// ユーザ情報リストの先頭を取得
		NSArray *topList = [userInfoListArray objectAtIndex:i];
		
		if ( (topList) && ([topList count] > 0 ) ) 
		{	
			// 先頭ユーザが格納されている
			topPath = [NSIndexPath indexPathForRow:0 inSection:i];
			break;
		}
		
		// 全検索と五十音検索以外は先頭リストのみが対象
		if ( (searchKind != SEARCH_KIND_ALL) &&
			 (searchKind != SEARCH_KIND_GOJYUON) &&
			 ( i == 0) )
		{	break; }
	}
	
	return (topPath);
}

// リスト先頭のユーザ情報を取得する
- (userInfo*) getListTopUserInfo
{
    NSLog(@"met moi vai 3");
	userInfo* topUser = nil;
	
	for (NSUInteger i = 0; i < [self getSectionMax]; i++)
	{
		// ユーザ情報リストの先頭を取得
		NSArray *topList = [userInfoListArray objectAtIndex:i];
		
		if ( (topList) && ([topList count] > 0 ) ) 
		{	
			// 先頭ユーザが格納されている
			topUser = [topList objectAtIndex:0];
			break;
		}
		
		// 全検索と五十音検索以外は先頭リストのみが対象
		if ( (searchKind != SEARCH_KIND_ALL) &&
			 (searchKind != SEARCH_KIND_GOJYUON) &&
			 ( i == 0) )
		{	break; }
	}
	
	return (topUser);
}

- (oneway void) release
{
	[colStatements_j release];
    [colStatements_e release];
	
	[jtitleLists release];
    [etitleLists release];
	
	if (userInfoListArray)
	{
		for (id usrList in userInfoListArray)
		{
			[ (NSMutableArray*)usrList removeAllObjects];
			[usrList release];
		}
		
		// [userInfoListArray release];
	}
	
	[super release];
}

- (NSInteger) getSearchKind
{
	return searchKind;
}

- (void)setTitle:(NSString *)str
{
    // タイトルの設定
    [workDateSearchTitle release];
    workDateSearchTitle = [NSString stringWithFormat:@"%@  %ld件",
                           str,
                           (long)[[userInfoListArray objectAtIndex:0] count]];
    [workDateSearchTitle retain];
}

@end
