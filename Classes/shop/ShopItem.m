//
//  ShopItem.m
//  iPadCamera
//
//  Created by 強 片山 on 12/05/11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ShopItem.h"

@implementation ShopItem

@synthesize shopID;
@synthesize shopLevel;
@synthesize shopNumber;
@synthesize shopName;
@synthesize parentShopId;

/**
 * 店舗IDによるコンストラクタ
 * @param      shopID       店舗ID
 * @param      shopName     店舗名
 * @return     インスタンス
 * @remarks    店舗IDより、店舗レベルと店舗番号が自動設定される
 */
-(id) initWithShopID:(SHOPID_INT)sID
            shopName:(NSString*)sName
{
    if ( (self = [super init] ) )
    {
        self.shopID = sID;
        
        // 店舗レベルと店舗番号を設定する
        self.shopLevel = sID / SHOP_LEVEL_RATIO;
        self.shopNumber = sID % SHOP_LEVEL_RATIO;
        
        self.shopName = sName;
    }
    
    return  (self);
}

/**
 * 店舗レベルと店舗番号によるコンストラクタ
 * @param      shopLevel    店舗レベル
 * @param      shopNumber    店舗レベル
 * @param      shopName     店舗名
 * @return     インスタンス
 * @remarks    店舗IDより、店舗レベルと番号が自動設定される
 */
-(id) initWithShopID:(NSUInteger)sLevel
shopNumber:(NSUInteger)sNum
shopName:(NSString*)sName
{
    if ( (self = [super init] ) )
    {
        
        self.shopLevel = sLevel;
        self.shopNumber = sNum;
        
        // 店舗IDを設定する
        self.shopID = (SHOPID_INT)((sLevel * SHOP_LEVEL_RATIO) + sNum);
        
        self.shopName = sName;
    }
    
    return  (self);
}

- (void) dealloc
{
    [self.shopName release];
    
    [super dealloc];
}


@end
