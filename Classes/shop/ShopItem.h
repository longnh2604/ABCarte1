//
//  ShopItem.h
//  iPadCamera
//
//  Created by 強 片山 on 12/05/11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "def64bit_common.h"

// 店舗レベルの倍率
#define SHOP_LEVEL_RATIO        1000000

// 全店舗共通（店舗を持たない）のID
#define SHOP_COMMON_ID          0
#define SHOP_COMMON_PWD         @""

// 店舗IDの無効
#define SHOP_ID_INVALID         NSUIntegerMax

// 店舗毎のuserIDの基準数の初期値
#define SHOP_USER_ID_DEFAULT    0

/**
 *  店舗を表すItemクラス
 */
@interface ShopItem : NSObject

// 店舗レベル　1:トップレベル〜99:（２桁）
@property (nonatomic) NSUInteger shopLevel;
// 店舗番号　：　グループ＋グループ毎の通し番号　1〜999999 : （６桁） 
@property (nonatomic) NSUInteger shopNumber;
// 店舗名
@property (nonatomic, copy) NSString *shopName;

// 店舗ID
@property (nonatomic) SHOPID_INT shopID;

@property (nonatomic) SHOPID_INT parentShopId;
/**
 * 店舗IDによるコンストラクタ
 * @param      shopID       店舗ID
 * @param      shopName     店舗名
 * @return     インスタンス
 * @remarks    店舗IDより、店舗レベルと店舗番号が自動設定される
 */
-(id) initWithShopID:(SHOPID_INT)shopID
            shopName:(NSString*)sName;

/**
 * 店舗レベルと店舗番号によるコンストラクタ
 * @param      shopLevel    店舗レベル
 * @param      shopNumber   店舗番号
 * @param      shopName     店舗名
 * @return     インスタンス
 * @remarks    店舗IDより、店舗レベルと番号が自動設定される
 */
-(id) initWithShopID:(NSUInteger)shopLevel
          shopNumber:(NSUInteger)sNum
            shopName:(NSString*)sName;

@end
