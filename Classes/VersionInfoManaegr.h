//
//  VersionInfoManaegr.h
//  CaLuLu_forAderans
//
//  Created by 強 片山 on 12/10/31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// バージョン情報取得の結果
typedef enum{
    VERSION_INFO_OK = 0, 
    VERSION_INFO_NETWORK_ERROR = 0xff00,
    VERSION_INFO_ERROR = 0xfff0,
    VERSION_INFO_UNKNOWN = 0xffff,
}VERSION_INFO_RESULT;

// バージョン情報格納Uサイト
#ifdef NEWS_CUSTOM
#define VER_INFO_SITE       @"http://calulu.jp"
#endif
#ifdef BRANCHE_CUSTOM
#define VER_INFO_SITE       @"http://calulu.jp"
#endif
#ifdef AIKI_CUSTOM
#define VER_INFO_SITE       @"http://calulu4bmk.jp"
#endif
#ifdef DEF_ABCARTE
#define VER_INFO_SITE       @"http://abcarte.jp"
#endif
// バージョン情報URL
#define VER_INFO_URL        @"vernumber.txt"

// バージョンアップ用URLの設定ファイルキー
#define VERSION_UP_URL_KEY  @"version_up_url"

// バージョンアップ用URLの設定デフォルト値
#ifdef NEWS_CUSTOM
#define VERSION_UP_URL_DEFAULT  @"http://calulu.jp/application/calulu2/MDM/nCalulu/"
#endif
#ifdef BRANCHE_CUSTOM
#define VERSION_UP_URL_DEFAULT  @"http://calulu.jp/application/calulu2/MDM/aCalulu/"
#endif
#ifdef AIKI_CUSTOM
#define VERSION_UP_URL_DEFAULT  @"http://calulu4bmk.jp/application/calulu2/MDM/aCalulu/"
#endif
//2016/1/5 TMS ストア・デモ版統合対応　デモのパスを参照
#ifdef FOR_SALES
#define VERSION_UP_URL_DEFAULT  @"http://abcarte.jp/application/abcarte/MDM/demo/"
#elif DEF_IOS8
#define VERSION_UP_URL_DEFAULT  @"http://abcarte.jp/application/abcarte/MDM/ios8/"
#elif DEF_ABCARTE
#define VERSION_UP_URL_DEFAULT  @"http://abcarte.jp/application/abcarte/MDM/abcarte/"
#endif

// バージョンアップのタイトル
#ifdef NEWS_CUSTOM
#define VERSION_TITLE  @"Calulu for NEWS"
#endif
#ifdef BRANCHE_CUSTOM
#define VERSION_TITLE  @"Calulu for Branche"
#endif
#ifdef AIKI_CUSTOM
#define VERSION_TITLE  @"Calulu for BMK"
#endif
#ifdef DEF_ABCARTE
#define VERSION_TITLE  @"ABCarte"
#endif

@interface VersionInfoManaegr : NSObject

#ifdef MDM_DISTRIBUTION_VERSION

// バージョン情報を取得して相違があれば、アップデートを促す
+(VERSION_INFO_RESULT) getVersionInfo;

#endif

@end
