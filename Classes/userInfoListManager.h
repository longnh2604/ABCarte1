//
//  userInfoListManager.h
//  iPadCamera
//
//  Created by MacBook on 10/10/20.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// セクション最大数
#ifdef TABLE_INDEX
#define SECTION_MAX		46+26
#define SECTION_EMAX    26+11
#define INDEX_MAX       11
#else
#define SECTION_MAX		11
#endif

// 検索条件の種別定義
typedef enum
{
	SELECT_FIRST_NAME_KANA		= 0x0001,		// 姓（ひらがな）
	SELECT_FIRST_NAME			= 0x0010,		// 姓（漢字）
    SELECT_GOJYUON_NAME         = 0x0020,       // 五十音検索
    SELECT_CUSTOMER_ID          = 0x0040,       // お客様番号検索
    SELECT_MEMO                 = 0x0080,       // メモ検索
    SELECT_MAIL_ERROR           = 0x0100,       // メール送信エラー検索
    SELECT_MAIL_UNREAD          = 0x0200,       // メール未開封者検索
    //2016/4/9 TMS 顧客検索条件追加
    SELECT_MAIL_TENPO_UNREAD_IDX= 0x0300,       // 店舗側メール未開封者検索
    SELECT_MAIL_TENPO_ANSWER    = 0x0400,       // 要対応メール検索
	SELECT_LAST_WORK_DATE		= 0x1000,		// 最終施術日（以降）
    SELECT_WORK_DATE            = 0x1010,       // 施術日検索
    SELECT_START_WORK_DATE      = 0x1020,      // 初回施術日検索
	SELECT_BIRTY_DAY			= 0x2000,		// 誕生日
	SELECT_BIRTY_MONTH			= 0x2001,		// 誕生月
	SELECT_BIRTY_YEAR			= 0x2002,		// 誕生年
	SELECT_TERM_DATE			= 0x4000,		// 期間検索（年／月／日）
	SELECT_TERM_MONTH			= 0x4001,		// 期間検索（年／月）
	SELECT_TERM_YEAR			= 0x4002,		// 期間検索（年）
	SELECT_TERM_START_NONE		= 0x4004,		// 開始なし
	SELECT_TERM_ERROR			= 0x4008,		// 検索できない
	SELECT_SINGLE_TERM_DATE		= 0x4010,		// 年／月／日付検索
	SELECT_SINGLE_TERM_MONTH	= 0x4011,		// 年／月検索
	SELECT_SINGLE_TERM_YEAR		= 0x4012,		// 年検索
	SELECT_NONE					= 0xffff,		// 検索なし（デフォルト）
} SELECT_JYOUKEN_KIND;

// 検索対象の定義
typedef enum
{
	SEARCH_KIND_ALL,						// 全検索
	SEARCH_KIND_ONE_STRING,					// 検索指定(個別文字)
	SEARCH_KIND_GOJYUON,					// 五十音検索
	SEARCH_KIND_WORK_DATE,					// 施術日による検索
	SEARCH_KIND_REGIST_NUMBER,				// お客様番号による検索
	SEARCH_KIND_BIRTHDAY,					// 誕生日による検索
	SEARCH_KIND_LASTWORK_TERM,				// 最新施術日を期間で検索
	SEARCH_KIND_MEMO,						// メモで検索
	SEARCH_KIND_MAIL_SEND_ERROR,			// メール送信エラーで検索
    SEARCH_KIND_MAIL_UNREAD,                // メール未読者で検索
    //2016/4/9 TMS 顧客検索条件追加
    SEARCH_KIND_MAIL_TENPO_UNREAD,          // 店舗側メール未読で検索
    SEARCH_KIND_MAIL_TENPO_ANSWER           // 要対応メールで検索
} SEARCH_KIND_TYPE;

@class userInfo;

// ユーザ情報リストの管理クラス：UITableViewDataSourceに基づき動作する
@interface userInfoListManager : NSObject 
{
	// 0:あ行、1:か行、2:さ行、3:た行、4:な行、5:は行、6:ま行、7:や行、8:ら行、9:わ行、10:その他
	NSMutableArray		*userInfoListArray;		// ユーザ情報リスト
	
	// BOOL				isAllSearch;			// 全検索であるか？
	SEARCH_KIND_TYPE	searchKind;				// 検索対象の定義(全検索など)
	NSArray				*jtitleLists;			// 全検索時のタイトルリスト(日本語メイン)
    NSArray				*etitleLists;			// 全検索時のタイトルリスト(英語メイン)
    NSArray             *indexLists;            // 五十音代表リスト
	NSMutableArray		*colStatements_j;		// 各行のSQLステートメント(日本語環境)
    NSMutableArray		*colStatements_e;		// 各行のSQLステートメント(英語環境)
	NSMutableArray		*gojyuonTitleLists;		// 五十音検索のタイトルリスト(NSMutableString)
	
	NSString			*workDateSearchTitle;	// 施術日による検索時のタイトル
	NSInteger			lastRegistNumber;		// 前回のお客様番号検索の値
	NSInteger			selectCondition;		// 選択した検索条件
    NSString            *searchNameTitle;       // 名前検索時の検索文字列
}

// 初期化（コンストラクタ）
- (id) init;

// リストの全クリア
- (void) allListClear;

// ユーザー情報リストの設定:searchKeyword=検索文字（LIKE）空文字で全検索
- (void) setUserInfoList:(NSString*)searchKeyword selectKind:(SELECT_JYOUKEN_KIND)kind;
//2016/8/10 TMS お客様名検索対応
// ユーザー情報リストの設定:searchKeyword1=検索文字姓（LIKE）searchKeyword1=検索文字名（LIKE）
- (void) setUserInfoList:(NSString*)searchKeyword1 :(NSString*)searchKeyword2 selectKind:(SELECT_JYOUKEN_KIND)kind selectKind2:(SELECT_JYOUKEN_KIND)kind2;
// 2016/8/17 担当者検索機能の追加
// ユーザー情報リストの設定:responsibleName=検索文字担当者（LIKE）
- (void) setUserInfoList:(NSString*)responsibleName;

// ユーザー情報リストの設定(五十音検索Version)
//	searchStrings:	[0]:あ行、 [1]:か行、 [2]:さ行、 ..... [9]:わ行 の各行に
//					ひらがなを設定する。（例：あ行=あ_い_う_え_お）
//					必ず10個の要素とし、該当行のない箇所は空文字を設定する
- (void) setUserInfoListWithGojyuon:(NSMutableArray*)searchStrings;

// ユーザー情報リストの設定(施術日による検索Version)
- (void) setUserInfoListWithWorkDate:(NSDate*)workDate : (NSInteger)mode;

// ユーザー情報リストの設定(お客様番号による検索Version) registNumber:REGIST_NUMBER_INVALIDで全番号
- (void) setUserInfoListWithRegistNumber:(NSInteger)registNumber;
- (void) setUserInfoListWithRegistNumberNew:(NSString*)registNumber;

// ユーザー情報リストの設定(誕生日による検索Version)
- (void) setUserInfoListWithBirthDate:(NSDate*)searchStart From:(NSDate*)searchEnd SearchSelect:(NSInteger)searchSelect;

// ユーザー情報リストの設定（最新施術日を期間で検索するVersion）
// （最新施術以外も検索出来るようにisLatest追加）
- (BOOL) setUserInfoListWithLastWorkTerm:(NSDateComponents*)start
                                     End:(NSDateComponents*)end
                                isLatest:(BOOL)isLatest;

// ユーザー情報リストの設定（初回施術日を期間で検索するVersion）
- (BOOL) setUserInfoListWithFirstWorkTerm:(NSDateComponents*)start End:(NSDateComponents*)end;

// ユーザー情報リストの設定（メモで検索するVersion）
- (BOOL) setUserInfoListWithMemo:(NSDictionary*) arrayMemo And:(BOOL)isAndSearch;

// ユーザー情報リストの設定（メール送信エラーで検索するVersion）
- (BOOL) setUserInfoListWithMailSendError:(NSDictionary *)mailSendErrorUserList;

// ユーザー情報リストの設定（メール未開封者で検索するVersion）
- (BOOL) setUserInfoListWithMailUnRead:(NSDictionary *)userMailStatusList;
//2016/4/9 TMS 顧客検索条件追加
// ユーザー情報リストの設定（店舗側メール未読で検索するVersion）
- (BOOL) setUserInfoListWithMailTenpoUnRead:(NSDictionary *)userMailStatusList;
// ユーザー情報リストの設定（要対応メールで検索するVersion）
- (BOOL) setUserInfoListWithMailTenpoAnswer:(NSDictionary *)userMailStatusList;
// セクション番号より有効なリストのIndexを取得
- (NSUInteger) getIndexBySectionNum:(NSInteger)section isSorceUserInfo:(BOOL)isUserInfo;

//  全ユーザーリストを取得する（setUserInfoList~ 系のメソッドで設定した影響を受けない、与えない）
- (NSDictionary *)getAllUserInfo;

// ショップに属するユーザー数を取得する
- (NSInteger) getShopUserInfo;

// ユーザテーブルリストのインデックス更新
- (void)refreshIndexList;

//--------------------------------------------------
// 以下のgetterはsetUserListの実行後の状態を返すものとする
//--------------------------------------------------

// 行数(セクション数)の取得：10を返す
- (NSInteger) getSectionNum;

// 行数(セクション数)の取得
- (NSInteger) getSectionNum2;

// 各行でのユーザ数（セル数）の取得
- (NSInteger) getUserNum:(NSInteger)section;

// 行（セクション）のタイトル取得
- (NSString*) getSectionTitle:(NSInteger)section;

// セクションのタイトル配列取得
- (NSArray *)getSectionTitleArray;
// on reverse
- (NSArray *)getSectionTitleArray:(BOOL)onReverse;

// 指定行（セクション）におけるユーザ情報（セル）個数取得
- (NSInteger) getUserInfoNums:(NSInteger)section;

// 各行（セクション）でのユーザ情報（セル）の取得
- (userInfo*) getUserInfoBySection:(NSInteger)section rowNum:(NSInteger)row;

//ユーザー情報リストの並び替え
- (void) sortUserInfoList:(BOOL)conditions;

// ユーザIDによるIndexPathの取得
- (NSIndexPath*) getIndexPathWithUserID:(NSInteger)userID;

// リスト先頭のIndexPathを取得する
- (NSIndexPath*) getListTopIndexPath;

// リスト先頭のユーザ情報を取得する
- (userInfo*) getListTopUserInfo;

// 検索種別を取得する
- (NSInteger) getSearchKind;

// 検索結果のタイトルを設定する（後から変更したい場合など）
- (void)setTitle:(NSString *)str;

@end
