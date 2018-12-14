//
//  ShopManager.m
//  iPadCamera
//
//  Created by 強 片山 on 12/05/11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ShopManager.h"

#import "ShopItem.h"

#import "../userDbManager.h"

// 唯一のインスタンス
static ShopManager *__shopManager__ = nil;

@implementation ShopManager

#pragma mark private_methods


// 店舗IDより店舗名を取得
- (NSString*) _getShopNameWithShopID:(SHOPID_INT)sID
                           dbManager:(userDbManager*)dbMng
{
    __block NSString* shopName = nil;
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT shop_name FROM mst_shop"];
    [sql appendString:@"  WHERE shop_id = ?"];
    [dbMng _selectSqlTemplateWithSql:sql 
                         bindHandler:^(sqlite3_stmt* sqlstmt)
     {  
         sqlite3_bind_int(sqlstmt, 1, sID);
     }
                    iterationHandler:^(sqlite3_stmt* sqlstmt)
     {
         u_int idx = 0;
         shopName = [dbMng makeSqliteStmt2String:sqlstmt index:idx++];
         
         return (NO);
     }
     ];
    
    return (shopName);
}

#pragma mark life_cycle

- (id) init
{
    if ( (self = [super init]) )
    {
        _accountShopID = SHOP_ID_INVALID;
        _userIDBase = SHOP_ID_INVALID;
        
        _selectedShopIDs = [NSMutableArray array];
        [_selectedShopIDs retain];
    }
    
    return (self);
}


#pragma mark public_methods

/**
 * インスタンスの取得 : singlton
 */
+ (ShopManager*) defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __shopManager__ = [[ShopManager alloc] init];
    });
    return __shopManager__;
}

/**
 * アカウント店舗IDの取得
 */
- (SHOPID_INT) getAccountShopID
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (_accountShopID == SHOP_ID_INVALID) {
        @synchronized(self) {
            
            // 一度もまだ取得されていない
            if (_accountShopID == SHOP_ID_INVALID)
            {
                if ([defaults objectForKey:ACCOUNT_SHOP_ID_KEY])
                {
                    // user定義に登録されていたので取得する
                    _accountShopID 
                        = (SHOPID_INT)[defaults integerForKey:ACCOUNT_SHOP_ID_KEY];
                }
            }
        }
    }

    return ((_accountShopID != SHOP_ID_INVALID)? 
                    _accountShopID : SHOP_COMMON_ID);
}

- (SHOPID_INT) getShopLevelWithShopID:(SHOPID_INT)sID
{
    __block SHOPID_INT shopLevel = 0;
    
    userDbManager * dbMng = nil;
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT shop_level FROM mst_shop"];
    [sql appendString:@"  WHERE shop_id = ?"];
    @try {
        dbMng = [[userDbManager alloc] initWithDbOpen];

        [dbMng _selectSqlTemplateWithSql:sql 
                            bindHandler:^(sqlite3_stmt* sqlstmt)
        {  
            sqlite3_bind_int(sqlstmt, 1, sID);
        }
                        iterationHandler:^(sqlite3_stmt* sqlstmt)
        {
            shopLevel = sqlite3_column_int(sqlstmt, 0);
            return (YES);
        }
        ];
    }
    @catch (NSException *exception) {
        NSLog(@"getChildIDsByAccountShop(0): Caught %@: %@",
              [exception name], [exception reason]);
    }
    @finally {
        [dbMng closeDataBase];
        [dbMng release];
        dbMng = nil;
    }
    return shopLevel;
}
/**
 * 店舗毎のuserID基準数の取得
 */
- (USERID_INT) getUserIDBase
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (_userIDBase == SHOP_ID_INVALID) {
        @synchronized(self) {
            
            // 一度もまだ取得されていない
            if (_userIDBase == SHOP_ID_INVALID)
            {
                if ([defaults objectForKey:SHOP_USER_ID_KEY])
                {
                    // user定義に登録されていたので取得する
                    _userIDBase 
                        = (USERID_INT)[defaults integerForKey:SHOP_USER_ID_KEY];
                }
            }
        }
    }
    
    return ((_userIDBase != SHOP_ID_INVALID)?
                _userIDBase : SHOP_USER_ID_DEFAULT);
}

/**
 * アカウント店舗IDと店舗毎のuserID基準数の設定
 */
- (void) setAccountShopID:(SHOPID_INT)sID shopPwd:(NSString *)sPwd userIDBase:(USERID_INT)uid
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    @synchronized(self) {
        // user定義に登録する
        [defaults setInteger:sID forKey:ACCOUNT_SHOP_ID_KEY];
        [defaults setObject:sPwd forKey:ACCOUNT_SHOP_PWD_KEY];
        [defaults setInteger:uid forKey:SHOP_USER_ID_KEY];
        [defaults synchronize];
    }
}

/**
 * アカウント店舗IDと店舗毎のuserID基準数の初期化
 */
- (void) resetAccountShopID
{
    [self setAccountShopID:SHOP_COMMON_ID shopPwd:SHOP_COMMON_PWD userIDBase:SHOP_USER_ID_DEFAULT];
}

/**
 * ログアウト時のアカウント情報の初期化
 */
- (void) initAccountShopID
{
    _accountShopID = SHOP_ID_INVALID;
    _userIDBase = SHOP_ID_INVALID;
    
    _selectedShopIDs = [NSMutableArray array];
    [_selectedShopIDs retain];

}
/**
 * アカウントが店舗対応であるか
 */
- (BOOL) isAccountShop
{
    // 一旦、メンバに反映させるために以下のメソッドをコールする
    [self getAccountShopID];
    
    return ((_accountShopID != SHOP_ID_INVALID) 
                && (_accountShopID != SHOP_COMMON_ID) );
}

/**
 * 現在選択中の店舗ID一覧の取得
 */
-(NSArray*) getSeletedShopIDs
{
    return (_selectedShopIDs);
}

/**
 * 現在選択中の店舗IDの初期化：選択可能な店舗をすべて選択する
 */
-(void) setSelectedShopIDsDefault
{
    // 最初にリストをクリア
    [_selectedShopIDs removeAllObjects];
    
    // 店舗アカウントでない場合はここで抜ける
    if (! [self isAccountShop])
    {
        // 共通店舗を追加
        [_selectedShopIDs addObject:[NSString stringWithFormat:@"%d", SHOP_COMMON_ID]];
        return;
    }

    // UserDefaultsにショップ選択リストが保存されているか確認
    if ([self getSelectedShopsFromUD]) {
        return;
    }
    
    // 共通店舗を追加
    [_selectedShopIDs addObject:[NSString stringWithFormat:@"%d", SHOP_COMMON_ID]];

    // 店舗アカウントIDを追加
    [_selectedShopIDs addObject:
        [NSString stringWithFormat:@"%d", _accountShopID]];
    
    // アカウント店舗IDにて可能な店舗一覧を取得して追加
    NSArray *childShop = [self getAllShopList:([self getShopLevelWithShopID:_accountShopID] + 1)];
    for (ShopItem* sItem in childShop)
    {
        [_selectedShopIDs addObject:[NSString stringWithFormat:@"%d",sItem.shopID]];
    }
}

/*
 * UserDefaultsに保存されているショップ選択リストを優先する
 * （これが無いと、アプリが再起動するたびに全ショップ選択状態になる）
 */
- (BOOL)getSelectedShopsFromUD
{
    BOOL result = NO;

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    NSArray *ar = [ud arrayForKey:@"SEL_SHOPS_ARRAY"];
    
    if (ar) {
        for (NSString *shopID in ar) {
            [_selectedShopIDs addObject:shopID];
#ifdef DEBUG
            NSLog(@"shopID : %@", shopID);
#endif
        }
        result = YES;
    }
    
    return result;
}

/**
 * 指定された階層以下の選択可能な店舗をすべて取得する。
 */
-(NSArray*)getAllShopList:(NSInteger)level{
    ShopManager *shopMng = [ShopManager defaultManager];
    SHOPID_INT currentAcount = [shopMng getAccountShopID];
    NSInteger currentLevel = (level);
    NSMutableArray *selectArray = [NSMutableArray array];
    NSMutableArray * resultList = [NSMutableArray array];
    
    [selectArray addObjectsFromArray:[shopMng getChildShopList:currentAcount level:currentLevel++]];
    [resultList addObjectsFromArray:selectArray];
    while([selectArray count] > 0){
        NSMutableArray* selectNumArray = [NSMutableArray array];
        while ([selectNumArray count] < [selectArray count]) {
            ShopItem * sItem = [selectArray objectAtIndex:[selectNumArray count]];
            [selectNumArray addObject:[NSNumber numberWithInt:sItem.shopID]];
        }
        [selectArray removeAllObjects];
        [selectArray addObjectsFromArray: [shopMng getMultiChildShopList:selectNumArray level:currentLevel++]];
        [resultList addObjectsFromArray:selectArray];        
    }
    return resultList;
}

/**
 * 現在選択中の店舗IDの設定
 */
-(void) setSelectedShopIDsWithArray:(NSArray*)IDs
{
    // 最初にリストをクリア
    [_selectedShopIDs removeAllObjects];
    
    // そのまま追加する
    for (id sID in IDs)
    {
        [_selectedShopIDs addObject:sID];
    }
    
}

// アカウント店舗IDにて可能な店舗一覧を取得
- (NSArray*) getChildIDsByAccountShop
{
    NSMutableArray *array = [NSMutableArray array];
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT child_shop_id FROM fc_parent_child_shop"];
    [sql appendString:@"  WHERE parent_shop_id = ? ORDER BY child_shop_id"];
    
    userDbManager *dbMng = nil;
    @try {
        dbMng = [[userDbManager alloc] initWithDbOpen];
        
        [dbMng _selectSqlTemplateWithSql:sql 
                             bindHandler:^(sqlite3_stmt* sqlstmt)
         {  
             sqlite3_bind_int(sqlstmt, 1, _accountShopID);
         }
                        iterationHandler:^(sqlite3_stmt* sqlstmt)
         {
             u_int idx = 0;
             SHOPID_INT sID = sqlite3_column_int(sqlstmt, idx++);
             [array addObject:[NSString stringWithFormat:@"%d", sID]]; 
             
             return (YES);
         }
         ];
        
    }
    @catch (NSException *exception) {
        NSLog(@"getChildIDsByAccountShop(1): Caught %@: %@",
              [exception name], [exception reason]);
    }
    @finally {
        [dbMng closeDataBase];
        [dbMng release];
        dbMng = nil;
    }
    
    return (array);
}

/**
 * アカウント店舗IDにて可能な店舗Item一覧を取得
 */
- (NSArray*) getChilidShopItemsByAccountShop
{
    NSMutableArray *array = [NSMutableArray array];
    
    userDbManager *dbMng = nil;
    @try {
        dbMng = [[userDbManager alloc] initWithDbOpen];
        
        // 共通店舗を追加
        NSString *comName = [self _getShopNameWithShopID:SHOP_COMMON_ID 
                                               dbManager:dbMng];
        ShopItem *comItem = [[ShopItem alloc] initWithShopID:SHOP_COMMON_ID 
                                                    shopName:comName];
        [array addObject:comItem];
        [comItem release];
        if ([comName length] > 0)
        {   [comName release]; }
        
        // 店舗アカウントでない場合はここで抜ける
        if (! [self isAccountShop])
        {   return (array); }
        
        // 店舗アカウントIDを追加
        NSString *accName = [self _getShopNameWithShopID:_accountShopID 
                                               dbManager:dbMng];
        ShopItem *accItem = [[ShopItem alloc] initWithShopID:_accountShopID 
                                                    shopName:accName];
        [array addObject:accItem];
        [accItem release];
        if ([accName length] > 0)
        {   [accName release]; }
        
        //  親ー子店舗関連テーブルより一覧を取得する
        NSMutableString *sql = [NSMutableString string];
        [sql appendString:@"SELECT child_shop_id, mst_shop.shop_name "];
        [sql appendString:@"  FROM fc_parent_child_shop "];
        [sql appendString:@"	LEFT OUTER JOIN mst_shop"];
        [sql appendString:@"		ON fc_parent_child_shop.child_shop_id = mst_shop.shop_id"];
        [sql appendString:@"	WHERE parent_shop_id = ?"];
        [dbMng _selectSqlTemplateWithSql:sql 
                             bindHandler:^(sqlite3_stmt* sqlstmt)
         {  
             sqlite3_bind_int(sqlstmt, 1, _accountShopID);
         }
                        iterationHandler:^(sqlite3_stmt* sqlstmt)
         {
             u_int idx = 0;
             SHOPID_INT sID = sqlite3_column_int(sqlstmt, idx++);
             NSString *sName = [dbMng makeSqliteStmt2String:sqlstmt index:idx++];
             
             ShopItem *sItem = [[ShopItem alloc] initWithShopID:sID 
                                                       shopName:sName];
             [array addObject:sItem];
             [sItem release];
             if ([sName length] > 0)
             {   [sName release]; }
             
             return (YES);
         }
         ];
        
    }
    @catch (NSException *exception) {
        NSLog(@"getChilidShopItemsByAccountShop: Caught %@: %@", 
              [exception name], [exception reason]);
    }
    @finally {
        [dbMng closeDataBase];
        [dbMng release];
        dbMng = nil;
    }
    
    return (array);
}


// 複数指定した店舗の子IDを取得
- (NSArray*) getMultiChildShopList:(NSArray*)parentShopIdList
                             level:(NSInteger)level
{
    NSMutableArray *array = [NSMutableArray array];

    if([parentShopIdList count] == 0){
        return array;
    }
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"SELECT shop_id , shop_name ,shop_level ,parent_shop_id"];
    [sql appendString:@" FROM mst_shop"];
    [sql appendString:@" LEFT JOIN fc_parent_child_shop ON shop_id = child_shop_id"];
    [sql appendString:@" WHERE ("];
    
    int num = 0;
    while (num < [parentShopIdList count]) {
        if (num > 0) {
            [sql appendString:@" OR "];
        }
        [sql appendString:@"parent_shop_id = ?"];
        num++;
    }
    [sql appendString:@") AND shop_level = ? "];
//    [sql appendString:@" ORDER BY parent_shop_id "];
#ifdef DEBUG
    NSLog(@"%@",sql);
#endif
    userDbManager *dbMng = nil;
    @try {
        dbMng = [[userDbManager alloc] initWithDbOpen];
        [dbMng _selectSqlTemplateWithSql:sql 
                             bindHandler:^(sqlite3_stmt* sqlstmt)
        { 
            int idx = 0;
            NSNumber *iId;
            while (idx < num) {
                iId = [parentShopIdList objectAtIndex:idx];
                sqlite3_bind_int(sqlstmt, idx + 1, [iId intValue]);
#ifdef DEBUG
                NSLog(@"%d:%d",idx,[iId intValue]);
#endif
                idx++;
            }
            sqlite3_bind_int(sqlstmt, idx + 1, (int)level);
        }
                        iterationHandler:^(sqlite3_stmt* sqlstmt)
        {
            ShopItem *tmpShopItem = [ShopItem alloc];
            [tmpShopItem init];
            u_int idx = 0;
            tmpShopItem.shopID = sqlite3_column_int(sqlstmt, idx++);
            const unsigned char *cShopeName = sqlite3_column_text(sqlstmt, idx++);
            tmpShopItem.shopName = [[NSString alloc]initWithUTF8String:(const char*)cShopeName];
            tmpShopItem.shopLevel = sqlite3_column_int(sqlstmt, idx++);
            tmpShopItem.parentShopId = sqlite3_column_int(sqlstmt, idx++);
            [array addObject:tmpShopItem]; 
            [tmpShopItem release];
            return (YES);
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"getChildIDsByAccountShop(2): Caught %@: %@", 
              [exception name], [exception reason]);
    }
    @finally {
        [dbMng closeDataBase];
        [dbMng release];
        dbMng = nil;
    }
    return (array);
}

//指定した店舗の子IDを取得
-(NSArray*) getChildShopList:(SHOPID_INT)parentShopId
                       level:(NSInteger)level
{
    NSNumber *targetID = [[NSNumber alloc]initWithUnsignedInteger:parentShopId];
    NSArray *reqList = [[NSArray alloc]initWithObjects:targetID, nil];
    NSArray* array = [self getMultiChildShopList:reqList level:level];
    [targetID release];
    [reqList release];
    return array;
}

@end
