//
//  grantFmdbManager.m
//  iPadCamera
//
//  Created by GIGASJAPAN on 13/06/13.
//
//

#import "grantFmdbManager.h"

/*
 ** DEFINE
 */
#define FMDB_FILE_NAME			@"cameraApp_FMDB.db"

@implementation grantFmdbManager

- (id)init
{
	self = [super init];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //データベースのパス取得
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	dbPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:FMDB_FILE_NAME];
	BOOL success = [fileManager fileExistsAtPath:dbPath];
    //無ければコピー
    if(!success){
        NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:FMDB_FILE_NAME];
        NSError *error = nil;
        success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
        if(!success){
            NSLog(@"%@",[error localizedDescription]);
        }
    }
    
	return self;
}

//データベース初期化
- (BOOL)initDataBase
{
    BOOL result = FALSE;
    FMDatabase *db = [grantFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    //データベース存在チェック
    //商品マスタテーブルの存在チェック
    //テーブルが無ければ生成する
    NSString *createTableSql = @"CREATE TABLE IF NOT EXISTS product_mst('product_id' INTEGER PRIMARY KEY , 'product_name' TEXT , 'brand_id' INTEGER , 'file_name' TEXT);";
    result = [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
 
    //サイズマスタテーブルの存在チェック
    //テーブルが無ければ生成する
    createTableSql = @"CREATE TABLE IF NOT EXISTS size_mst('product_id' INTEGER , 'size_id' INTEGER , 'size_name' TEXT  , 'price' INTEGER , PRIMARY KEY('product_id','size_id'));";
    result = [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
 
    //カラーマスタテーブルの存在チェック
    //テーブルが無ければ生成する
    createTableSql = @"CREATE TABLE IF NOT EXISTS color_mst('product_id' INTEGER , 'color_id' INTEGER , 'color_name' TEXT , PRIMARY KEY('product_id','color_id'));";
    result = [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }

    //ブランドマスタテーブルの存在チェック
    //テーブルが無ければ生成する
    createTableSql = @"CREATE TABLE IF NOT EXISTS brand_mst('brand_id' INTEGER PRIMARY KEY , 'brand_name' TEXT);";
    result = [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
    
    //価格マスタテーブルの存在チェック
    //テーブルが無ければ生成する
    createTableSql = @"CREATE TABLE IF NOT EXISTS price_mst('product_id' INTEGER , 'size_id' INTEGER , 'price' INTEGER , PRIMARY KEY('product_id','size_id'));";
    result = [db executeUpdate:createTableSql];
    if(!result)
    {
        NSLog(@"DB CREATE TABLE ERROR");
        [db close];
        return FALSE;
    }
    
    [db close];
    return TRUE;
}
//データベースにコネクションする
+ (FMDatabase*) databaseConect:(NSString*)dbPath
{
    FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
    
    return db;
}
- (FMDatabase *) databaseConnect{
    return [grantFmdbManager databaseConect:dbPath];
}

/**
 商品マスタにデータを登録
 */
- (BOOL) insertProductMst:(NSMutableArray *)productList
{
    FMDatabase *db = [grantFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    
    NSMutableString* sqlCmd = [NSMutableString stringWithString:@"DELETE FROM product_mst "];
    [db executeUpdate:sqlCmd];
    
    for(productM *proM in productList){
        NSMutableString* sqlCmd = [NSMutableString stringWithString:@"INSERT INTO product_mst "];
        [sqlCmd appendString:@"VALUES ( ?, ?, ?, ? );"];
        BOOL result =  [db executeUpdate:sqlCmd, [NSNumber numberWithInteger:proM.product_id],proM.product_name,[NSNumber numberWithInteger:proM.brand_id],proM.file_name];
        if( !result )
        {
            NSLog(@"DB INSERT ERROR insertProductMst");
            [db close];
            return FALSE;
        }
    }
    [db close];
    
    return YES;
}

/**
 サイズマスタにデータを登録
 */
- (BOOL) insertSizeMst
{
    FMDatabase *db = [grantFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    
    NSMutableString* sqlCmd = [NSMutableString stringWithString:@"DELETE FROM size_mst "];
    [db executeUpdate:sqlCmd];
    
    for(sizeM *sizem in sizeList){
        NSMutableString* sqlCmd = [NSMutableString stringWithString:@"INSERT INTO size_mst "];
        [sqlCmd appendString:@"VALUES ( ?, ?, ?, ?);"];
        BOOL result =  [db executeUpdate:sqlCmd, [NSNumber numberWithInteger:sizem.product_id],[NSNumber numberWithInteger:sizem.size_id],sizem.size_name,[NSNumber numberWithInteger:sizem.price]];
        if( !result )
        {
            NSLog(@"DB INSERT ERROR insertSizeMst");
            [db close];
            return FALSE;
        }
    }
    [db close];
    
    return YES;
}

/**
 カラーマスタにデータを登録
 */
- (BOOL) insertColorMst
{
    FMDatabase *db = [grantFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    NSMutableString* sqlCmd = [NSMutableString stringWithString:@"DELETE FROM color_mst "];
    [db executeUpdate:sqlCmd];
    for(colorM *colorm in colorList){
        NSMutableString* sqlCmd = [NSMutableString stringWithString:@"INSERT INTO color_mst "];
        [sqlCmd appendString:@"VALUES ( ?, ?, ?);"];
        BOOL result =  [db executeUpdate:sqlCmd, [NSNumber numberWithInteger:colorm.product_id],[NSNumber numberWithInteger:colorm.color_id],colorm.color_name];
        if( !result )
        {
            NSLog(@"DB INSERT ERROR");
            [db close];
            return FALSE;
        }
    }
    [db close];
    
    return YES;
}

/**
 ブランドマスタにデータを登録
 */
- (BOOL) insertBrandMst:(NSMutableArray *)brandList
{
    FMDatabase *db = [grantFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    
    NSMutableString* sqlCmd = [NSMutableString stringWithString:@"DELETE FROM brand_mst "];
    [db executeUpdate:sqlCmd];
    
    for(int i = 0;i < [brandList count];i++){
        NSMutableString* sqlCmd = [NSMutableString stringWithString:@"INSERT INTO brand_mst "];
        [sqlCmd appendString:@"VALUES ( ?, ?);"];
        brandM *brandm = [brandList objectAtIndex:i];
        BOOL result =  [db executeUpdate:sqlCmd, [NSNumber numberWithInteger:brandm.brand_id],brandm.brand_name];
        if( !result )
        {
            NSLog(@"DB INSERT ERROR");
            [db close];
            return FALSE;
        }
    }
    [db close];
    
    return YES;
}

/**
 価格マスタにデータを登録
 */
- (BOOL) insertPriceMst:(NSMutableArray *)priceList
{
    FMDatabase *db = [grantFmdbManager databaseConect:dbPath];
    if(![db open])
    {
        NSLog(@"DB OPEN ERROR");
        return FALSE;
    }
    
    for(priceM *pricem in priceList){
        NSMutableString* sqlCmd = [NSMutableString stringWithString:@"INSERT INTO price_mst "];
        [sqlCmd appendString:@"VALUES ( ?, ?, ?);"];
        BOOL result =  [db executeUpdate:sqlCmd, [NSNumber numberWithInteger:pricem.product_id],[NSNumber numberWithInteger:pricem.size_id],pricem.price];
        if( !result )
        {
            NSLog(@"DB INSERT ERROR");
            [db close];
            return FALSE;
        }
    }
    [db close];
    
    return YES;
}

/**
 商品マスタよりデータを取得
 */
- (NSMutableArray*) getProductMst:(NSInteger)brand_id
{
    NSMutableArray*    list = [[NSMutableArray alloc] init];
 
    // DB OPEN
    FMDatabase *db = [grantFmdbManager databaseConect:dbPath];
    if( ![db open] )
    {
        NSLog(@"DB OPEN ERROR");
        return nil;
    }

    NSString*   sqlCmd = @"SELECT product_id,product_name,brand_id,file_name FROM product_mst WHERE brand_id = ?";
	FMResultSet *results = [db executeQuery:sqlCmd,[NSNumber numberWithInteger:brand_id]];
	while ( [results next] )
	{
        productM *proM = [productM alloc];
        proM.product_id = [[results stringForColumn:@"product_id"]integerValue];
        proM.product_name = [results stringForColumn:@"product_name"];
        proM.brand_id = [[results stringForColumn:@"brand_id"]integerValue];
        proM.file_name = [results stringForColumn:@"file_name"];
        
        [list addObject:proM];
	}
    
    // DB CLOSE
	[db close];
    
    return list;
}

/**
 サイズマスタよりデータを取得
 */
- (NSMutableArray*) getSizeMst:(NSInteger)product_id
{
    NSMutableArray*    list = [[NSMutableArray alloc] init];
    
    // DB OPEN
    FMDatabase *db = [grantFmdbManager databaseConect:dbPath];
    if( ![db open] )
    {
        NSLog(@"DB OPEN ERROR");
        return nil;
    }
    
    NSString*   sqlCmd = @"SELECT product_id,size_id,size_name,price FROM size_mst WHERE product_id = ?";
    FMResultSet *results = [db executeQuery:sqlCmd,[NSNumber numberWithInteger:product_id]];
    while ( [results next] )
    {
        sizeM *sizem = [sizeM alloc];
        sizem.product_id = [[results stringForColumn:@"product_id"]integerValue];
        sizem.size_id = [[results stringForColumn:@"size_id"]integerValue];
        sizem.size_name = [results stringForColumn:@"size_name"];
        sizem.price = [[results stringForColumn:@"price"]integerValue];
        
        [list addObject:sizem];
    }
    
    // DB CLOSE
    [db close];
    
    return list;
}

/**
 カラーマスタよりデータを取得
 */
- (NSMutableArray*) getColorMst:(NSInteger)product_id
{
    NSMutableArray*    list = [[NSMutableArray alloc] init];
    
    // DB OPEN
    FMDatabase *db = [grantFmdbManager databaseConect:dbPath];
    if( ![db open] )
    {
        NSLog(@"DB OPEN ERROR");
        return nil;
    }
    
    NSString*   sqlCmd = @"SELECT product_id,color_id,color_name FROM color_mst WHERE product_id = ?";
    FMResultSet *results = [db executeQuery:sqlCmd,[NSNumber numberWithInteger:product_id]];
    while ( [results next] )
    {
        colorM *colorm = [colorM alloc];
        colorm.product_id = [[results stringForColumn:@"product_id"]intValue];
        colorm.color_id = [[results stringForColumn:@"color_id"]intValue];
        colorm.color_name = [results stringForColumn:@"color_name"];
        
        [list addObject:colorm];
    }
    
    // DB CLOSE
    [db close];
    
    return list;
}

/**
 ブランドマスタよりデータを取得
 */
- (NSMutableArray*) getBrandMst
{
    NSMutableArray*    list = [[NSMutableArray alloc] init];
    
    // DB OPEN
    FMDatabase *db = [grantFmdbManager databaseConect:dbPath];
    if( ![db open] )
    {
        NSLog(@"DB OPEN ERROR");
        return nil;
    }
    
    NSString*   sqlCmd = @"SELECT brand_id,brand_name FROM brand_mst";
    FMResultSet *results = [db executeQuery:sqlCmd];
    while ( [results next] )
    {
        brandM *brandm = [brandM alloc];
        brandm.brand_id = [[results stringForColumn:@"brand_id"]intValue];
        brandm.brand_name = [results stringForColumn:@"brand_name"];
        
        [list addObject:brandm];
    }
    
    // DB CLOSE
    [db close];
    
    return list;
}

/**
 価格マスタよりデータを取得
 */
- (NSMutableArray*) getPriceMst : (NSInteger)product_id : (NSInteger)size_id
{
    NSMutableArray*    list = [[NSMutableArray alloc] init];
    
    // DB OPEN
    FMDatabase *db = [grantFmdbManager databaseConect:dbPath];
    if( ![db open] )
    {
        NSLog(@"DB OPEN ERROR");
        return nil;
    }
    
    NSString*   sqlCmd = @"SELECT product_id,size_id,price FROM price_mst WHERE product_id = ? AND size_id = ?";
    FMResultSet *results = [db executeQuery:sqlCmd,[NSNumber numberWithInteger:product_id],[NSNumber numberWithInteger:size_id]];
    while ( [results next] )
    {
        priceM *pricem = [priceM alloc];
        pricem.product_id = [[results stringForColumn:@"product_id"]intValue];
        pricem.size_id = [[results stringForColumn:@"size_id"]intValue];
        pricem.price = [results stringForColumn:@"price"];
        
        [list addObject:pricem];
    }
    
    // DB CLOSE
    [db close];
    
    return list;
}

/**
 ブランドデータを用意
 */
-(NSMutableArray*)getBrandData{
    NSMutableArray*    list = [[NSMutableArray alloc] init];
    NSInteger cnt = 1;
    NSInteger cnt2 = 1;
    NSArray *phrases = [BRAND componentsSeparatedByString:@","];
    for(NSString *str in phrases){
        brandM *brand = [brandM alloc];
        brand.brand_id = cnt;
        brand.brand_name = str;
        cnt = cnt + 1;
        brand.prdct = [[NSMutableArray alloc] init];
        brand.prdct = [self getPrdctData:brand.brand_id:cnt2];
        cnt2 = cnt2 + [brand.prdct count];
        [list addObject:brand];
    }
    return list;
    
}

/**
 商品データを用意
 */
-(NSMutableArray*)getPrdctData : (NSInteger)brand_id : (NSInteger)cnt{
    NSMutableArray*    list = [[NSMutableArray alloc] init];
    NSArray *prdctName;
    NSArray *prdctFileName;

    switch (brand_id) {
        case 1:
            prdctName = [PRDCT_NAME_BRAND1 componentsSeparatedByString:@","];
            prdctFileName = [PRDCT_FILE_NAME_BRAND1 componentsSeparatedByString:@","];
            break;
        case 2:
            prdctName = [PRDCT_NAME_BRAND2 componentsSeparatedByString:@","];
            prdctFileName = [PRDCT_FILE_NAME_BRAND2 componentsSeparatedByString:@","];
            break;
        case 3:
            prdctName = [PRDCT_NAME_BRAND3 componentsSeparatedByString:@","];
            prdctFileName = [PRDCT_FILE_NAME_BRAND3 componentsSeparatedByString:@","];
            break;
        case 4:
            prdctName = [PRDCT_NAME_BRAND4 componentsSeparatedByString:@","];
            prdctFileName = [PRDCT_FILE_NAME_BRAND4 componentsSeparatedByString:@","];
            break;
        case 5:
            prdctName = [PRDCT_NAME_BRAND5 componentsSeparatedByString:@","];
            prdctFileName = [PRDCT_FILE_NAME_BRAND5 componentsSeparatedByString:@","];
            break;
        case 6:
            prdctName = [PRDCT_NAME_BRAND6 componentsSeparatedByString:@","];
            prdctFileName = [PRDCT_FILE_NAME_BRAND6 componentsSeparatedByString:@","];
            break;
        case 7:
            prdctName = [PRDCT_NAME_BRAND7 componentsSeparatedByString:@","];
            prdctFileName = [PRDCT_FILE_NAME_BRAND7 componentsSeparatedByString:@","];
            break;
        // 2016/5/20 TMS ブランド追加対応
        case 8:
            prdctName = [PRDCT_NAME_BRAND8 componentsSeparatedByString:@","];
            prdctFileName = [PRDCT_FILE_NAME_BRAND8 componentsSeparatedByString:@","];
            break;
        case 9:
            prdctName = [PRDCT_NAME_BRAND9 componentsSeparatedByString:@","];
            prdctFileName = [PRDCT_FILE_NAME_BRAND9 componentsSeparatedByString:@","];
            break;
        case 10:
            prdctName = [PRDCT_NAME_BRAND10 componentsSeparatedByString:@","];
            prdctFileName = [PRDCT_FILE_NAME_BRAND10 componentsSeparatedByString:@","];
            break;
        default:
            return nil;
    }

    for(int i = 0;i < [prdctFileName count];i++){
        productM *product = [productM alloc];
        product.product_id = cnt;
        product.product_name = [prdctName objectAtIndex:i];
        product.file_name = [prdctFileName objectAtIndex:i];
        product.brand_id = brand_id;
        cnt = cnt + 1;
        product.size = [self getSizeMst:product.product_id];
        product.color = [self getColorMst:product.product_id];
        product.idx = i;
        product.num = 0;
        sizeM *size = [product.size objectAtIndex:0];
        product.selSize = size.size_name;
        product.selPrice = size.price;
        colorM *color = [product.color objectAtIndex:0];
        product.selColor = color.color_name;
        product.selSizeVal = 0;
        product.selColorVal = 0;
        [list addObject:product];
    }

    return list;
    
}

/**
 サイズデータを用意
 */
-(void)setSizeData
{
    sizeList = [[NSMutableArray alloc] init];
    
    [self setSizeM:SIZE_BRAND1_PRDCT1:PRICE_BRAND1_PRDCT1:1];
    [self setSizeM:SIZE_BRAND1_PRDCT2:PRICE_BRAND1_PRDCT2:2];
    [self setSizeM:SIZE_BRAND1_PRDCT3:PRICE_BRAND1_PRDCT3:3];
    [self setSizeM:SIZE_BRAND1_PRDCT4:PRICE_BRAND1_PRDCT4:4];
    [self setSizeM:SIZE_BRAND1_PRDCT5:PRICE_BRAND1_PRDCT5:5];
    [self setSizeM:SIZE_BRAND1_PRDCT6:PRICE_BRAND1_PRDCT6:6];
    
    [self setSizeM:SIZE_BRAND2_PRDCT1:PRICE_BRAND2_PRDCT1:7];
    [self setSizeM:SIZE_BRAND2_PRDCT2:PRICE_BRAND2_PRDCT2:8];
    [self setSizeM:SIZE_BRAND2_PRDCT3:PRICE_BRAND2_PRDCT3:9];
    [self setSizeM:SIZE_BRAND2_PRDCT4:PRICE_BRAND2_PRDCT4:10];
    
    [self setSizeM:SIZE_BRAND3_PRDCT1:PRICE_BRAND3_PRDCT1:11];
    [self setSizeM:SIZE_BRAND3_PRDCT2:PRICE_BRAND3_PRDCT2:12];
    [self setSizeM:SIZE_BRAND3_PRDCT3:PRICE_BRAND3_PRDCT3:13];
    [self setSizeM:SIZE_BRAND3_PRDCT4:PRICE_BRAND3_PRDCT4:14];
    
    [self setSizeM:SIZE_BRAND4_PRDCT1:PRICE_BRAND4_PRDCT1:15];
    [self setSizeM:SIZE_BRAND4_PRDCT2:PRICE_BRAND4_PRDCT2:16];
    [self setSizeM:SIZE_BRAND4_PRDCT3:PRICE_BRAND4_PRDCT3:17];
    [self setSizeM:SIZE_BRAND4_PRDCT4:PRICE_BRAND4_PRDCT4:18];
    [self setSizeM:SIZE_BRAND4_PRDCT5:PRICE_BRAND4_PRDCT5:19];
    [self setSizeM:SIZE_BRAND4_PRDCT6:PRICE_BRAND4_PRDCT6:20];
    [self setSizeM:SIZE_BRAND4_PRDCT7:PRICE_BRAND4_PRDCT7:21];
    [self setSizeM:SIZE_BRAND4_PRDCT8:PRICE_BRAND4_PRDCT8:22];
    [self setSizeM:SIZE_BRAND4_PRDCT9:PRICE_BRAND4_PRDCT9:23];
    [self setSizeM:SIZE_BRAND4_PRDCT10:PRICE_BRAND4_PRDCT10:24];
    [self setSizeM:SIZE_BRAND4_PRDCT11:PRICE_BRAND4_PRDCT11:25];
    [self setSizeM:SIZE_BRAND4_PRDCT12:PRICE_BRAND4_PRDCT12:26];
    [self setSizeM:SIZE_BRAND4_PRDCT13:PRICE_BRAND4_PRDCT13:27];
    
    [self setSizeM:SIZE_BRAND5_PRDCT1:PRICE_BRAND5_PRDCT1:28];
    [self setSizeM:SIZE_BRAND5_PRDCT2:PRICE_BRAND5_PRDCT2:29];
    [self setSizeM:SIZE_BRAND5_PRDCT3:PRICE_BRAND5_PRDCT3:30];
    [self setSizeM:SIZE_BRAND5_PRDCT4:PRICE_BRAND5_PRDCT4:31];
    [self setSizeM:SIZE_BRAND5_PRDCT5:PRICE_BRAND5_PRDCT5:32];
    [self setSizeM:SIZE_BRAND5_PRDCT6:PRICE_BRAND5_PRDCT6:33];
    [self setSizeM:SIZE_BRAND5_PRDCT7:PRICE_BRAND5_PRDCT7:34];
    [self setSizeM:SIZE_BRAND5_PRDCT8:PRICE_BRAND5_PRDCT8:35];
    [self setSizeM:SIZE_BRAND5_PRDCT9:PRICE_BRAND5_PRDCT9:36];
    [self setSizeM:SIZE_BRAND5_PRDCT10:PRICE_BRAND5_PRDCT10:37];
    [self setSizeM:SIZE_BRAND5_PRDCT11:PRICE_BRAND5_PRDCT11:38];
    [self setSizeM:SIZE_BRAND5_PRDCT12:PRICE_BRAND5_PRDCT12:39];
    [self setSizeM:SIZE_BRAND5_PRDCT13:PRICE_BRAND5_PRDCT13:40];
    // 2016/6/24 TMS 商品追加対応
    [self setSizeM:SIZE_BRAND5_PRDCT14:PRICE_BRAND5_PRDCT14:41];
    [self setSizeM:SIZE_BRAND5_PRDCT15:PRICE_BRAND5_PRDCT15:42];
    [self setSizeM:SIZE_BRAND5_PRDCT16:PRICE_BRAND5_PRDCT16:43];
    [self setSizeM:SIZE_BRAND5_PRDCT17:PRICE_BRAND5_PRDCT17:44];
    
    [self setSizeM:SIZE_BRAND6_PRDCT1:PRICE_BRAND6_PRDCT1:45];
    [self setSizeM:SIZE_BRAND6_PRDCT2:PRICE_BRAND6_PRDCT2:46];
    [self setSizeM:SIZE_BRAND6_PRDCT3:PRICE_BRAND6_PRDCT3:47];
    [self setSizeM:SIZE_BRAND6_PRDCT4:PRICE_BRAND6_PRDCT4:48];
    [self setSizeM:SIZE_BRAND6_PRDCT5:PRICE_BRAND6_PRDCT5:49];
    
    [self setSizeM:SIZE_BRAND7_PRDCT1:PRICE_BRAND7_PRDCT1:50];
    [self setSizeM:SIZE_BRAND7_PRDCT2:PRICE_BRAND7_PRDCT2:51];
    [self setSizeM:SIZE_BRAND7_PRDCT3:PRICE_BRAND7_PRDCT3:52];
    [self setSizeM:SIZE_BRAND7_PRDCT4:PRICE_BRAND7_PRDCT4:53];
    // 2016/5/20 TMS ブランド追加対応
    [self setSizeM:SIZE_BRAND7_PRDCT5:PRICE_BRAND7_PRDCT5:54];
    [self setSizeM:SIZE_BRAND7_PRDCT6:PRICE_BRAND7_PRDCT6:55];
    [self setSizeM:SIZE_BRAND7_PRDCT7:PRICE_BRAND7_PRDCT7:56];
    
    [self setSizeM:SIZE_BRAND8_PRDCT1:PRICE_BRAND8_PRDCT1:57];
    [self setSizeM:SIZE_BRAND8_PRDCT2:PRICE_BRAND8_PRDCT2:58];
    [self setSizeM:SIZE_BRAND8_PRDCT3:PRICE_BRAND8_PRDCT3:59];
    [self setSizeM:SIZE_BRAND8_PRDCT4:PRICE_BRAND8_PRDCT4:60];
    [self setSizeM:SIZE_BRAND8_PRDCT5:PRICE_BRAND8_PRDCT5:61];
    
    [self setSizeM:SIZE_BRAND9_PRDCT1:PRICE_BRAND9_PRDCT1:62];
    [self setSizeM:SIZE_BRAND9_PRDCT2:PRICE_BRAND9_PRDCT2:63];
    [self setSizeM:SIZE_BRAND9_PRDCT3:PRICE_BRAND9_PRDCT3:64];
    [self setSizeM:SIZE_BRAND9_PRDCT4:PRICE_BRAND9_PRDCT4:65];
    [self setSizeM:SIZE_BRAND9_PRDCT5:PRICE_BRAND9_PRDCT5:66];
    [self setSizeM:SIZE_BRAND9_PRDCT6:PRICE_BRAND9_PRDCT6:67];
    
    [self setSizeM:SIZE_BRAND10_PRDCT1:PRICE_BRAND10_PRDCT1:68];
    [self setSizeM:SIZE_BRAND10_PRDCT2:PRICE_BRAND10_PRDCT2:69];
    [self setSizeM:SIZE_BRAND10_PRDCT3:PRICE_BRAND10_PRDCT3:70];
    [self setSizeM:SIZE_BRAND10_PRDCT4:PRICE_BRAND10_PRDCT4:71];
    [self setSizeM:SIZE_BRAND10_PRDCT5:PRICE_BRAND10_PRDCT5:72];
    [self setSizeM:SIZE_BRAND10_PRDCT6:PRICE_BRAND10_PRDCT6:73];
    [self setSizeM:SIZE_BRAND10_PRDCT7:PRICE_BRAND10_PRDCT7:74];
    [self setSizeM:SIZE_BRAND10_PRDCT8:PRICE_BRAND10_PRDCT8:75];
    [self setSizeM:SIZE_BRAND10_PRDCT9:PRICE_BRAND10_PRDCT9:76];
    [self setSizeM:SIZE_BRAND10_PRDCT10:PRICE_BRAND10_PRDCT10:77];
    [self setSizeM:SIZE_BRAND10_PRDCT11:PRICE_BRAND10_PRDCT11:78];
    [self setSizeM:SIZE_BRAND10_PRDCT12:PRICE_BRAND10_PRDCT12:79];
    [self setSizeM:SIZE_BRAND10_PRDCT13:PRICE_BRAND10_PRDCT13:80];
    [self setSizeM:SIZE_BRAND10_PRDCT14:PRICE_BRAND10_PRDCT14:81];
    [self setSizeM:SIZE_BRAND10_PRDCT15:PRICE_BRAND10_PRDCT15:82];


    [self insertSizeMst];
}

-(void)setSizeM : (NSString*)str : (NSString*)str2 : (NSInteger)product_id{
    NSArray *sizeName = [str componentsSeparatedByString:@","];
    NSArray *priceName = [str2 componentsSeparatedByString:@","];
    NSInteger cnt = 1;
    for(int i = 0;i < [sizeName count];i++){
        sizeM *size = [sizeM alloc];
        size.product_id = product_id;
        size.size_id = cnt;
        cnt = cnt + 1;
        size.size_name = [sizeName objectAtIndex:i];
        size.price = [[priceName objectAtIndex:i] integerValue];
        [sizeList addObject:size];
    }
}

/**
 カラーデータを用意
 */
-(void)setColorData
{
    colorList = [[NSMutableArray alloc] init];

    [self setColorM:COLOR_BRAND1_PRDCT1:1];
    [self setColorM:COLOR_BRAND1_PRDCT2:2];
    [self setColorM:COLOR_BRAND1_PRDCT3:3];
    [self setColorM:COLOR_BRAND1_PRDCT4:4];
    [self setColorM:COLOR_BRAND1_PRDCT5:5];
    [self setColorM:COLOR_BRAND1_PRDCT6:6];
        
    [self setColorM:COLOR_BRAND2_PRDCT1:7];
    [self setColorM:COLOR_BRAND2_PRDCT2:8];
    [self setColorM:COLOR_BRAND2_PRDCT3:9];
    [self setColorM:COLOR_BRAND2_PRDCT4:10];
        
    [self setColorM:COLOR_BRAND3_PRDCT1:11];
    [self setColorM:COLOR_BRAND3_PRDCT2:12];
    [self setColorM:COLOR_BRAND3_PRDCT3:13];
    [self setColorM:COLOR_BRAND3_PRDCT4:14];
    
    [self setColorM:COLOR_BRAND4_PRDCT1:15];
    [self setColorM:COLOR_BRAND4_PRDCT2:16];
    [self setColorM:COLOR_BRAND4_PRDCT3:17];
    [self setColorM:COLOR_BRAND4_PRDCT4:18];
    [self setColorM:COLOR_BRAND4_PRDCT5:19];
    [self setColorM:COLOR_BRAND4_PRDCT6:20];
    [self setColorM:COLOR_BRAND4_PRDCT7:21];
    [self setColorM:COLOR_BRAND4_PRDCT8:22];
    [self setColorM:COLOR_BRAND4_PRDCT9:23];
    [self setColorM:COLOR_BRAND4_PRDCT10:24];
    [self setColorM:COLOR_BRAND4_PRDCT11:25];
    [self setColorM:COLOR_BRAND4_PRDCT12:26];
    [self setColorM:COLOR_BRAND4_PRDCT13:27];
        
    [self setColorM:COLOR_BRAND5_PRDCT1:28];
    [self setColorM:COLOR_BRAND5_PRDCT2:29];
    [self setColorM:COLOR_BRAND5_PRDCT3:30];
    [self setColorM:COLOR_BRAND5_PRDCT4:31];
    [self setColorM:COLOR_BRAND5_PRDCT5:32];
    [self setColorM:COLOR_BRAND5_PRDCT6:33];
    [self setColorM:COLOR_BRAND5_PRDCT7:34];
    [self setColorM:COLOR_BRAND5_PRDCT8:35];
    [self setColorM:COLOR_BRAND5_PRDCT9:36];
    [self setColorM:COLOR_BRAND5_PRDCT10:37];
    [self setColorM:COLOR_BRAND5_PRDCT11:38];
    [self setColorM:COLOR_BRAND5_PRDCT12:39];
    [self setColorM:COLOR_BRAND5_PRDCT13:40];
    // 2016/6/24 TMS 商品追加対応
    [self setColorM:COLOR_BRAND5_PRDCT14:41];
    [self setColorM:COLOR_BRAND5_PRDCT15:42];
    [self setColorM:COLOR_BRAND5_PRDCT16:43];
    [self setColorM:COLOR_BRAND5_PRDCT17:44];
    
    [self setColorM:COLOR_BRAND6_PRDCT1:45];
    [self setColorM:COLOR_BRAND6_PRDCT2:46];
    [self setColorM:COLOR_BRAND6_PRDCT3:47];
    [self setColorM:COLOR_BRAND6_PRDCT4:48];
    [self setColorM:COLOR_BRAND6_PRDCT5:49];
    
    [self setColorM:COLOR_BRAND7_PRDCT1:50];
    [self setColorM:COLOR_BRAND7_PRDCT2:51];
    [self setColorM:COLOR_BRAND7_PRDCT3:52];
    [self setColorM:COLOR_BRAND7_PRDCT4:53];
    // 2016/5/20 TMS ブランド追加対応
    [self setColorM:COLOR_BRAND7_PRDCT5:54];
    [self setColorM:COLOR_BRAND7_PRDCT6:55];
    [self setColorM:COLOR_BRAND7_PRDCT7:56];
    
    [self setColorM:COLOR_BRAND8_PRDCT1:57];
    [self setColorM:COLOR_BRAND8_PRDCT2:58];
    [self setColorM:COLOR_BRAND8_PRDCT3:59];
    [self setColorM:COLOR_BRAND8_PRDCT4:60];
    [self setColorM:COLOR_BRAND8_PRDCT5:61];
    
    [self setColorM:COLOR_BRAND9_PRDCT1:62];
    [self setColorM:COLOR_BRAND9_PRDCT2:63];
    [self setColorM:COLOR_BRAND9_PRDCT3:64];
    [self setColorM:COLOR_BRAND9_PRDCT4:65];
    [self setColorM:COLOR_BRAND9_PRDCT5:66];
    [self setColorM:COLOR_BRAND9_PRDCT6:67];
    
    [self setColorM:COLOR_BRAND10_PRDCT1:68];
    [self setColorM:COLOR_BRAND10_PRDCT2:69];
    [self setColorM:COLOR_BRAND10_PRDCT3:70];
    [self setColorM:COLOR_BRAND10_PRDCT4:71];
    [self setColorM:COLOR_BRAND10_PRDCT5:72];
    [self setColorM:COLOR_BRAND10_PRDCT6:73];
    [self setColorM:COLOR_BRAND10_PRDCT7:74];
    [self setColorM:COLOR_BRAND10_PRDCT8:75];
    [self setColorM:COLOR_BRAND10_PRDCT9:76];
    [self setColorM:COLOR_BRAND10_PRDCT10:77];
    [self setColorM:COLOR_BRAND10_PRDCT11:78];
    [self setColorM:COLOR_BRAND10_PRDCT12:79];
    [self setColorM:COLOR_BRAND10_PRDCT13:80];
    [self setColorM:COLOR_BRAND10_PRDCT14:81];
    [self setColorM:COLOR_BRAND10_PRDCT15:82];

    [self insertColorMst];
}

-(void)setColorM : (NSString*)str : (NSInteger)product_id{
    NSArray *colorName = [str componentsSeparatedByString:@","];
    NSInteger cnt = 1;
    for(int i = 0;i < [colorName count];i++){
        colorM *color = [colorM alloc];
        color.product_id = product_id;
        color.color_id = cnt;
        cnt = cnt + 1;
        color.color_name = [colorName objectAtIndex:i];
        [colorList addObject:color];
    }
}
@end
