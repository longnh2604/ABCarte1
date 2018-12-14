//
//  AppStoreAPIHelper.h
//  AppVersion
//
//  Created by shuichi on 13/01/25.
//  Copyright (c) 2013年 Shuichi Tsutsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kAppStoreLookupURL @"http://itunes.apple.com/lookup"
#ifdef DEF_ABCARTE
#ifdef IN_APP_PURCHASES_TEST
#define ABCARTE_APPLEID @"970812249"
#define VERSION_TITLE  @"ABCarte Pro"
#else
#define ABCARTE_APPLEID @"768547922"
#define VERSION_TITLE  @"ABCarte"
#endif
#else
#define ABCARTE_APPLEID @"517226289"
#define VERSION_TITLE  @"CaLuLuII"
#endif

#ifdef DEBUG
#define CHECK_INTERVAL  1   // バージョンアップ更新タイミング 48時間
#else
#define CHECK_INTERVAL  48  // バージョンアップ更新タイミング 48時間
#endif

@interface AppStoreAPIHelper : NSObject

+ (void) checkAppVersionWithId;

@end
