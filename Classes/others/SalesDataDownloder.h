//
//  SalesDataDownloder.h
//  iPadCamera
//
//  Created by  on 11/12/01.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "def64bit_common.h"

#define SALES_ACCOUNT_LAST_WORD     @"P"        // 販社様アカウントIDの最後の文字
#define SALES_ACCOUNT_LAST_WORD_SMALL  @"p"     // 販社様アカウントIDの最後の文字(小文字)

#define APP_STORE_SALES_DEF_KEY     @"appstore_sales_download"      // 販社様サンプルデータのダウンロードを示すKey

#define APP_STORE_SALES_URL         @"_app_store_sales_data"
#ifndef CLOUD_SYNC
#define APP_STORE_SALES_DB_NAME     @"appstore_sales.db"
#else
#define APP_STORE_SALES_DB_NAME     @"appstore_sales_cloud.db"
#endif

///
/// 販社様用サンプルデータダウンロードクラス
///
@interface SalesDataDownloder : NSObject

// 販社様用サンプルデータのダウンロード
-(BOOL) doDownloadWithStartHandler:(void(^)(void))hStart 
                    comleteHandler:(void(^)(BOOL downloadStat)) hComplite
                     isInitRehresh:(BOOL*)pIsRefresh;

@end
