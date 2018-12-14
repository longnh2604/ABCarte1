//
//  defines.h
//  Pattoru
//
//  Created by MacBook on 11/01/28.
//  Copyright 2011 Okada denshi.Co.Ltd. All rights reserved.
//


/*
 *  各種定数を定義
 */

#ifndef __DEFINE_DEFINES__

#define __DEFINE_DEFINES__ 

// デフォルトフォルダ名：必ずサンドバック内に存在している（消去不可とする）
#define	DEFAULT_FOLDER_NAME		@"マイアルバム"

//APPLE STORE 購入用ID
#ifdef DEF_ABCARTE

//#define PRODUCT_ID              @"jp.okada.denshi.co.ltd.ABCarte.1Month"
#ifdef IN_APP_PURCHASES_TEST
#define PRODUCT_ID              @"ABCartePro.1Year"
#else
#define PRODUCT_ID              @"ABCarte.1Year"
#endif

#elif CALULU_IPHONE
#define PRODUCT_ID              @"jp.okada.denshi.co.ltd.calulu.initial.purchase"   
#else
#define PRODUCT_ID              @"jp.okada.denshi.co.ltd.calulu.iphone.initial.purchase"
#endif

#ifdef DEF_ABCARTE
#define MYAPP_NAME          @"ABCarte"
#elif AIKI_CUSTOM
#define MYAPP_NAME          @"CaLuLu for BMK"
#else
#define MYAPP_NAME          @"CaLuLu"
#endif

#define SHOPREGIST_FROM_APPSTORE 10999                              //購入時初期shop_id
#define USERREGIST_FROM_APPSTORE 999                                //購入時初期userIDBase
// Download写真ファイルの格納位置:Libray/Cachesフォルダ
// Downloadファイルはここに保存（iOSデータ保管ガイドライン 2.23に基づく）
#define DOWNLOAD_PICTURE_CACHES_FOLDER  @"Library/Caches/Pictures"

// 実サイズ版の拡張子
#define REAL_SIZE_EXT		@".jpg"
// 縮小版の拡張子
#define THUMBNAIL_SIZE_EXT	@".tmb"

#define REAL_MOVIE_EXT      @".mp4"

// サムネイルitemの幅
#define THUBNAIL_WITH	128.0f
// サムネイルitemの高さ
#define THUBNAIL_HEIGHT	96.0f

// ファイル名の生成書式
#define	FILE_NAME_FORMAT	@"yyMMdd_HHmmss"

// 拡張子を含むファイル名の文字数:13 + 1 + 3 = 17
#define FILE_NAME_LEN_EXT	17

// ユーザIDによるフォルダ名
#define FOLDER_NAME_USER_ID		@"User%08d"

// テンプレートのフォルダ名
#define FOLDER_NAME_TEMPLATE_ID	@"Common/%@"


/* -----------------------------------------------------------
 * お客様番号関連の定義
 * ----------------------------------------------------------- */

// お客様番号の無効値
#define REGIST_NUMBER_INVALID			-1
// お客様番号の文字列書式：NSInteger
#define	REGIST_NUMBER_STRING_FORMAT		@"%08ld"
// お客様番号の長さ(桁数)
#define REGIST_NUMBER_LENGTH			8

/* -----------------------------------------------------------
 * 端末固有ID付加の際の桁数倍率
 * ----------------------------------------------------------- */

#define USER_ID_BASE_DIGHT          100000


/* -----------------------------------------------------------
 * 項目編集関連の定義
 * ----------------------------------------------------------- */

// 項目編集種別
typedef enum
{
	ITEM_EDIT_USER_WORK1		= 0x0001,		// 施術内容1
	ITEM_EDIT_USER_WORK2		= 0x0002,		// 施術内容2
	ITEM_EDIT_PICTUE_NAME		= 0x0011,		// 写真の名称
    
    //  テンプレート作成画面
    ITEM_EDIT_DATE              = 0x0100,       // 日付フィールド
    ITEM_EDIT_GENERAL1,                         // 汎用フィールド１
    ITEM_EDIT_GENERAL2,                         // 汎用フィールド２
    ITEM_EDIT_GENERAL3,                         // 汎用フィールド３
} ITEM_EDIT_KIND;

/* -----------------------------------------------------------
 * httpサーバ関連の定義
 * ----------------------------------------------------------- */

// 完了通知のNotification名称
#define HTTP_UP_DOWN_LOAD_COMPLITE		@"UP_DOWN_LOAD_COMPLITE"

// 完了種別
typedef NS_ENUM(NSInteger, HTTP_COMPLITE_KIND)
{
	HTTP_UP_LOAD_COMPLITE		= 0x0011,		// アップロード完了
	HTTP_DOWN_LOAD_COMPLITE		= 0x0012,		// ダウンロード完了
} ;

/* -----------------------------------------------------------
 * アカウント管理関連の定義
 * ----------------------------------------------------------- */
#ifdef USE_ACCOUNT_MANAGER

#ifdef  DEBUG_IN_LOCAL
//#define ACCOUNT_HOST_URL				@"http://calulu.jp"//
//#define ACCOUNT_HOST_URL				@"http://ec2-54-250-11-236.ap-northeast-1.compute.amazonaws.com"//@"http://192.168.99.191"//
#define ACCOUNT_HOST_URL				@"http://192.168.99.172"
#elif DEF_ABCARTE
  #define ACCOUNT_HOST_URL				@"http://abcarte.jp"
#else
  #define ACCOUNT_HOST_URL				@"http://calulu.jp"//
#endif

#define ACCOUNT_CONTINUE_ERROR_NOIFY	@"Account_continue_error_notify"	// アカウント継続でのエラー通知

#ifdef DEF_ABCARTE  // 問い合わせ先メールアドレス
    #define CONTACT_MAIL_SEND_ADDR      @"info@abcarte.jp"
#else
    #define CONTACT_MAIL_SEND_ADDR      @"contact@calulu.jp"
#endif

#endif

#ifdef FOR_SALES
#define MDM_MAILTO_SITE_URL     @"http://abcarte.jp/_waccount/mdmmailto.php"
#endif

/* -----------------------------------------------------------
 * Viewのサイズ関連の定義
 * ----------------------------------------------------------- */
#ifdef CALULU_IPHONE
#define VIEW_SIZE_WIDTH			320.0f		// view横サイズ
#define VIEW_SIZE_HEIGHT		460.0f		// view縦サイズ
#else
#define VIEW_SIZE_WIDTH			768.0f		// view横サイズ
#define VIEW_SIZE_HEIGHT		1004.0f		// view縦サイズ
#endif

#define STATUS_BAR_HEIGHT		20.0f		// ステータスバー高さ

#endif			// __DEFINE_DEFINES__
