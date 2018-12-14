//
//  ShopManager.h
//  iPadCamera
//
//  Created by 強 片山 on 12/05/11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "userDbManager.h"

// アカウント店舗IDのdefaultのkey名
#define ACCOUNT_SHOP_ID_KEY             @"account_shop_id"
#define ACCOUNT_SHOP_PWD_KEY            @"account_shop_pwd"
// 店舗毎のuserID基準数のdefaultのkey名
#define SHOP_USER_ID_KEY                @"user_id_at_shop"

@class ShopItem;

/**
 * 店舗管理クラス　Singleton
 */
@interface ShopManager : NSObject {
    
    // アカウント店舗ID
    SHOPID_INT      _accountShopID;
    // 店舗毎のuserID基準数
    USERID_INT       _userIDBase;
    
    // 選択中の店舗IDリスト
    NSMutableArray  *_selectedShopIDs;
}


/**
 * インスタンスの取得
 */
+ (ShopManager*) defaultManager;

/**
 * アカウント店舗IDの取得
 */
- (SHOPID_INT) getAccountShopID;

/**
 * アカウントIDから店舗階層を取得
 */
- (SHOPID_INT) getShopLevelWithShopID:(SHOPID_INT)sID;
/**
 * 店舗毎のuserID基準数の取得
 */
- (USERID_INT) getUserIDBase;

/**
 * アカウント店舗IDと店舗毎のuserID基準数の設定
 */
- (void) setAccountShopID:(SHOPID_INT)sID shopPwd:(NSString *)sPwd userIDBase:(USERID_INT)uid;

/**
 * アカウント店舗IDと店舗毎のuserID基準数の初期化
 */
- (void) resetAccountShopID;

/**
 * ログアウト時のアカウント情報の初期化
 */
- (void) initAccountShopID;

/**
 * アカウントが店舗対応であるか
 */
- (BOOL) isAccountShop;

/**
 * 現在選択中の店舗ID一覧の取得
 */
-(NSArray*) getSeletedShopIDs;

/**
 * 現在選択中の店舗IDの初期化：選択可能な店舗をすべて選択する
 */
-(void) setSelectedShopIDsDefault;

/**
 * アカウント店舗より下の下層の店舗をすべて取得する
 */
-(NSArray*)getAllShopList:(NSInteger)level;

/**
 * 現在選択中の店舗IDの設定
 */
-(void) setSelectedShopIDsWithArray:(NSArray*)IDs;

/**
 * アカウント店舗IDにて可能な店舗一覧を取得:(IDのみ)
 */
- (NSArray*) getChildIDsByAccountShop;

/**
 * アカウント店舗IDにて可能な店舗Item一覧を取得
 */
- (NSArray*) getChilidShopItemsByAccountShop;


/**
 * リスト内の親店舗IDの子店舗をすべて表示
 *parentShopList内にはNSNumberオブジェクトの配列を格納
 */
- (NSArray*) getMultiChildShopList:(NSArray*)parentShopIdList
                             level:(NSInteger)level;

/**
 * 親店舗IDから子店舗を検索
 *
 */
- (NSArray*) getChildShopList:(SHOPID_INT)parentShopId
                        level:(NSInteger)level;

@end
