//
//  userDbManager.h
//  iPadCamera
//
//  Created by MacBook on 10/10/20.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "defines.h"
#import "def64bit_common.h"

#ifndef SAMPLE_DATA_DOWNLOAD
#define DB_FILE_NAME		@"cameraApp.db"
#else
#define DB_FILE_NAME		@"cameraApp_trial.db"
#endif

#ifdef CLOUD_SYNC
#define DB_RESOURCE_FILE_NAME    @"cloudSync.db"
#endif

#define MST_USER_TABLE		@"mst_user"

typedef void (^CompletionBlock)(BOOL completed);

// 項目編集のテーブル名
#define	ITEM_EDIT_USER_WORK1_TABLE			@"mst_user_work_item"		// 施術内容1マスタ
#define	ITEM_EDIT_USER_WORK2_TABLE			@"mst_user_work_item2"		// 施術内容2マスタ
#define ITEM_EDIT_USER_WORK3_TABLE          @"mst_user_work_item3"      // Webメールテンプレート汎用ボタン１
#define ITEM_EDIT_USER_WORK4_TABLE          @"mst_user_work_item4"      // Webメールテンプレート汎用ボタン２
#define ITEM_EDIT_USER_WORK5_TABLE          @"mst_user_work_item5"      // Webメールテンプレート汎用ボタン３
#define	ITEM_EDIT_PICTUE_NAME_TABLE			@"mst_user_picture_item"	// 写真の名称マスタ
#define	ITEM_EDIT_USER_WORK1_FC_TABLE		@"fc_user_work_item"		// 施術内容1状態
#define	ITEM_EDIT_USER_WORK2_FC_TABLE		@"fc_user_work_item2"		// 施術内容2状態
#define	ITEM_EDIT_PICTUE_NAME_FC_TABLE		@"fc_user_picture_item"		// 写真の名称状態
#define ITEM_EDIT_USER_TEMPLATE_TABLE		@"mst_user_template"		// テンプレート
#define ITEM_EDIT_CATEGORY_INFO_TABLE		@"category_info"			// カテゴリー情報
#define ITEM_EDIT_GEN_FIELD_INFO_TABLE		@"gen_field_info"			// 汎用フィールド情報
#define ITEM_EDIT_GEN_FIELD_ITEM_TABLE      @"gen_field_item"           // テンプレート作成の日付・汎用ボタンのマスタ
#define ITEM_EDIT_PICT_INFO_TABLE			@"template_pict_info"		// 写真情報
#define ITEM_EDIT_CAPTURE_PICT_INFO_TABLE	@"capture_pict_info"		// テンプレート用取り込み画像情報

#define	ITEM_EDIT_NAME_FIELD			@"item_name"				// 項目編集のテーブルの名前field
#define	ITEM_EDIT_ORDER_FIELD			@"order_num"				// 項目編集のテーブルの順番field

#define DUPLICATE_USER_NAME_ID          NSIntegerMin

// テンプレート用カテゴリーの初期値(カテゴリーなし)のUUID
#define TEMPLATE_CATEGORY_NOTHING		@"30ADDBD2-A503-495E-8994-F3B691B809F7"

@class mstUser;
@class fcUserWorkItem;
@class TemplateInfoListManager;

// データベース管理クラス
@interface userDbManager : NSObject 
{
	sqlite3*	db;
	NSString*	dbPath;
	
}

// 初期化（コンストラクタ）
- (id)init;
// データベースをOPENして初期化（コンストラクタ）
- (id)initWithDbOpen;

- (void)myInit;
// データベースをDocmentフォルダにコピー
- (void)copyDataBase2DocDir;
// データベースのクリア
- (void)clearDataBase;
// データベースのOPEN
- (BOOL)openDataBase;
// データベースのCLOSE
- (void)closeDataBase;
// データベースエラーのalert表示
- (void)errDataBase;

// sqlite3_stmtよりNSStringのオブジェクトを生成
- (NSString*) makeSqliteStmt2String : (sqlite3_stmt*)sqlstmt index:(u_int)idx;

// トランザクション付きでデータベースをOPENする
- (BOOL) dataBaseOpen4Transaction;
// トランザクションを完了しデータベースをCLOSEする
- (void) dataBaseClose2TransactionWithState:(BOOL)isTrue;

// openとcloseの単純なTemplate
- (id) _simpleOpenCloseTemplateWithArg:(id)argss procHandler:(id (^)(id args))handler;

// SELECT処理のTemplate
- (void) _selectSqlTemplateWithSql:(NSString*)selectsql 
					   bindHandler:(void (^)(sqlite3_stmt* sqlstmt)) hBind
				  iterationHandler:(BOOL (^)(sqlite3_stmt* sqlstmt)) hIterate;

// 更新処理系のTemplate
- (BOOL) executeSqlTemplateWithSql:(NSString*)selectsql
                       bindHandler:(void (^)(sqlite3_stmt* sqlstmt)) hBind;

// 文字列のバインド：空文字が設定されていればdbNullを設定する
- (void) setBindTextWithString:(NSString*)setValue
					pStatement:(sqlite3_stmt*)stmt setPositon:(NSUInteger)pos;

// 新規ユーザの登録
- (USERID_INT)registNewUser:(mstUser*)newUser;
// 最大のuser_idを取得する
- (USERID_INT)getMaxUserID;

// 最後に挿入したuser_idを取得する
- (NSInteger)getLastInsertRowId;
// ユーザ一覧の全取得
- (NSMutableArray*)getAllUsers;
// 検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListBySearch:(NSString*) statement;

// 検索に該当するユーザ一数の取得
- (NSInteger)getUserInfoListCountBySearch:(NSString*) statement;

// 写真のurl(Documentフォルダ以下)より履歴IDを取得する
- (HISTID_INT) getHistIDByPictURL4PictTable:(NSString*)pictUrl;
// 動画のurl(Documentフォルダ以下)より履歴IDを取得する
- (HISTID_INT) getHistIDByVideoURL4PictTable:(NSString*)pictUrl;
// 日付検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListBySearchDate:(NSString*)searchDate optional:(NSString*) statement;
// 年月検索に該当するユーザー一覧の取得
- (NSMutableArray*)getUserInfoListBySearchStart:(NSString*)startDate EndDate:(NSString*)endDate optional:(NSString*) statement;
// メモ1検索に該当するユーザー一覧の取得
- (NSMutableArray*)getUserInfoListByWorkItemArray:(NSArray*)arrayMemo AndSearch:(BOOL)andSearch optional:(NSString*)addState;
// メモ2検索に該当するユーザー一覧の取得
- (NSMutableArray*)getUserInfoListByWorkItem2Array:(NSArray*)arrayMemo AndSearch:(BOOL)andSearch optional:(NSString*)addState;
// フリーメモ検索に該当するユーザー一覧の取得
- (NSMutableArray*)getUserInfoListByMemoArray:(NSArray*)arrayMemo AndSearch:(BOOL)andSearch optional:(NSString*)addState;
// 誕生日検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListByBirthDay:(NSString*)searchDate optional:(NSString*) statement;
// 誕生年検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListByBirthMonth:(NSString*)startDate And:(NSString*)endDate optional:(NSString*) statement;
// 誕生年検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListByBirthYear:(NSString*)startDate And:(NSString*)endDate optional:(NSString*) statement;

// お客様番号検索に該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListByUserRegistNumber:(NSInteger)registNumber isAsc:(BOOL)isAsc optional:(NSString*)addState;
- (NSMutableArray*)getUserInfoListByUserRegistNumberNew:(NSString*)registNumber isAsc:(BOOL)isAsc optional:(NSString*)addState;

// メール送信エラーに該当するユーザ一覧の取得
- (NSMutableArray*)getUserInfoListByMailSendError:(NSString*)addState;

// IDによるユーザ（マスタ）の取得
- (mstUser*)getMstUserByID:(USERID_INT)userID;
// IDによるユーザの写真urlの取得
- (NSString*)getMstUserPictureUrlByID:(USERID_INT)userID;

- (BOOL)deleteUserPicture:(USERID_INT)userID pictureURL:(NSString*)url;
// ユーザ情報(マスタ)の更新
- (BOOL)updateMstUser:(mstUser*)user4Update;

// ユーザの写真更新
- (BOOL)updateUserPicture:(USERID_INT)userID pictureURL:(NSString*)url;
- (BOOL)updateUserPictureNew:(USERID_INT)userID pictureURL:(NSString*)url complete:(CompletionBlock)completed;
// ユーザの元urlによる写真更新
- (BOOL)updateUserPictureByNewUrl:(NSString*)oridinalUrl newUrl:(NSString*)url;

// NSDateから文字列を取得
- (NSString*) makeDateStringByNSDate:(NSDate*)date;

// IDによる施術内容の取得
// 2016/6/1 TMS メモリ使用率抑制対応
- (fcUserWorkItem*) getUserWorkItemByID:(USERID_INT)usrID userName:(NSString*)usrName:(fcUserWorkItem*)workItem;
// IDによる施術内容一覧の取得
- (NSMutableArray*) getUserWorkItemsByID:(USERID_INT)usrID;
// 施術内容の文字列一覧の取得
- (NSMutableArray*) getWorkItemStrings:(NSString *)tableName;
// 施術マスタの文字列テーブルの取得：key=ID object=施術内容（文字列）
- (NSMutableDictionary*) getWorkItemTable:(NSString *)tableName;

// 施術内容の更新
- (BOOL) updateUserWorkItem:(fcUserWorkItem*) workItem;

// 施術内容リストの更新
- (BOOL) updateUserWorkItemList:(HISTID_INT)histID workItemListNumber:(NSMutableArray*)numbers;
// 施術内容文字の更新
- (BOOL) updateUserItemEditWithString:(HISTID_INT)histID
							itemKinds:(ITEM_EDIT_KIND*)kinds
                            itemEdits:(NSArray*)items;
// 施術メモリストの更新
- (BOOL) updateUserWorkMemoList:(HISTID_INT)histID userMemos:(NSMutableArray*)userMemos;

// 最新施術内容をすべて削除する
- (BOOL) deleteNewWorkItem:(fcUserWorkItem*)workItem;
// mstUserの最終施術日の更新
- (BOOL) updateMstUserLastWorkDate:(NSString*)userID lastWorkDate:(NSString*)workDate;

// ユーザ情報（マスタ）と施術内容の削除
- (BOOL) deleteUserInfoWorkItems:(USERID_INT)userID;
// 履歴IDにて施術内容を全て削除する
- (BOOL) deleteAllWorkItems:(NSString*)histID tableName:(NSString*)tableName;

// 日付とユーザIDよりhist_ID(履歴ID)を作成する
// 引数：userID＝ユーザID date＝日付 isMakeNoRecord＝hist_user_workに該当レコードがない場合に作成するか？
// 戻り値：hist_ID(履歴ID)
- (HISTID_INT) getHistIDWithDateUserID:(USERID_INT)userID
                              workDate:(NSDate*)wDate
                        isMakeNoRecord:(BOOL)isMake;

// ユーザIDと日付よりhistIDを取得
- (HISTID_INT) getHistIDByDateUserID:(USERID_INT)userID
                            workDate:(NSDate*)wDate;

// 新規に指定日付のレコードをfc_user_workに作成
- (BOOL) makeNewHistUserworkWithDateUserID:(USERID_INT)userID
                                  workDate:(NSDate*)wDate;

// 履歴用のユーザ写真を追加:urlはDocumentフォルダ以下のファイル名とする
- (BOOL) insertHistUserPicture:(HISTID_INT)histID
                    pictureURL:(NSString*)url;

// 履歴テーブル(hist_user_work)の代表画像の更新:urlはDocumentフォルダ以下のファイル名とする
- (BOOL) updateHistHeadPicture:(HISTID_INT)histID
                    pictureURL:(NSString*)url
               isEnforceUpdate:(BOOL)isEnforce;

// 履歴テーブル(hist_user_work)の代表画像の元urlによる更新:urlはDocumentフォルダ以下のファイル名とする
- (BOOL) updateHistHeadPictureByNewUrl:(NSString*)oridinalUrl newUrl:(NSString*)url;
- (BOOL) deleteHistHeadPicture:(NSString*)oridinalUrl pictureURL:(NSString*)url;
// 履歴用のユーザ写真を削除:urlはDocumentフォルダ以下のファイル名とする
- (BOOL) deleteHistUserPicture:(HISTID_INT)histID pictureURL:(NSString*)url;
// 履歴用のユーザ動画を削除:urlはDocumentフォルダ以下のファイル名とする
- (BOOL) deleteHistUserVideo:(HISTID_INT)histID videoURL:(NSString*)url;

// 履歴用のユーザ写真リストの取得
- (BOOL) getHistPictureUrls:(fcUserWorkItem*)workItem;
// 履歴用のユーザ動画リストの取得
- (BOOL) getHistVideoUrls:(fcUserWorkItem*)workItem;
// データベースより履歴（とその関連情報）の削除
- (BOOL) deleteHistWithHistID:(HISTID_INT)histID;

// 施術マスタの更新：editedTableは更新分のみで、key=ID object=施術内容（文字列）となる
- (BOOL) updateWorkItemMstWithEditedTable:(NSMutableDictionary*)editedTable
								tableName:(NSString *)tableName;

// 施術内容の文字列一覧の取得
- (void) getWorkItemListWithWorkItem:(fcUserWorkItem*)workItem;

// 指定テーブル名で列名の存在を確認 : isColumnMake = 存在しない場合は、列を追加する
- (BOOL) checkExistColumnWithTableName:(NSString*)tableName
                            columnName:(NSString*)colName
						  isColumnMake:(BOOL)isMake
                            columnType:(NSString*)type;

//START, 2011.06.19, chen, ADD
- (BOOL) checkExistTableMemo2;
// 施術内容リストの更新
- (BOOL) updateUserWorkItemList2:(HISTID_INT)histID
              workItemListNumber:(NSMutableArray*) numbers;
// 施術内容の文字列一覧の取得
- (void) getWorkItemListWithWorkItem2:(fcUserWorkItem*)workItem;
- (BOOL) createTableMemo2;
- (BOOL) createFcUserVideoTableMake;
//END

// Calulu1 向けのテーブル追加
- (BOOL)createMstShopTableMake;
- (BOOL)createFcBinaryUploadMngTableMake;
- (BOOL)createFcHistInfoUpdateMngTableMake;
- (BOOL)createFcParentChildShopTableMake;
- (BOOL)createFcUpdateMngTimeDeleteTableMake;
- (BOOL)createFcUserInfoUpdateMngTableMake;
- (BOOL)createFcUserWorkItemUpdateMngTableMake;


// 項目編集テーブル	のアップグレード：Ver105
- (BOOL) itemEditTableUpgrade4Ver105;

// Webメールのテンプレートで使用する汎用ボタンテーブル追加
// mst_user_work_item3 - mst_user_work_item5
// 2014/07/25 K.N
- (BOOL) itemEditTableUpgrade4Ver150;

// 項目マスタテーブルよりitemを取得 : key -> itemID   value -> itemName
- (NSDictionary*) getItems2TableWithEditKind:(ITEM_EDIT_KIND)editKind;

// 履歴IDに該当する項目名一覧の取得 : key -> orderNum   value -> itemName
- (NSDictionary*) getItemNamesByHistID:(HISTID_INT)histID itemEditKind:(ITEM_EDIT_KIND)editKind;

// 項目マスタテーブルよりitemを削除
- (BOOL) itemEditTableDeleteWithItemIDList:(NSArray*)itemIDList itemEditKind:(ITEM_EDIT_KIND)editKind;
// 項目マスタテーブルよりitemを更新 key => itemID value => name
- (BOOL) itemEditTableUpdateWithItemList:(NSDictionary*)itemList itemEditKind:(ITEM_EDIT_KIND)editKind;
// 項目マスタテーブルよりitemを挿入
- (BOOL) itemEditTableInsertWithNameList:(NSArray*)nameList itemEditKind:(ITEM_EDIT_KIND)editKind;

// PCバックアップ情報テーブルの作成：Ver108
- (BOOL) createBackUpInfoTable;

// ピクチャーテーブル	のアップグレード：Ver114
- (BOOL) userpictureUpgradeVer114;
-(NSArray *)getImageProfile:(NSString*)fileURL;
-(NSArray *)getVideoProfile:(NSString*)fileURL;
-(BOOL)setImageProfile:(NSString*)title
                  memo:(NSString*)memo
               fileURL:(NSString*)fileURL
                histID:(HISTID_INT)histID;
-(BOOL)setVideoProfile:(NSString*)title
                  memo:(NSString*)memo
               fileURL:(NSString*)fileURL
                histID:(HISTID_INT)histID;
// mst_user のアップグレード：Ver122
// GigasJapan sekine 2013/6/18追加
// メール機能追加 ユーザー情報にemail1,email2追加
//      TableName:mst_user   column:email1 type:text
//      TableName:mst_user   column:email2 type:text
- (BOOL) mstuserUpgradeVer122;

/**
 * mst_user のアップグレード：ver140
 * 郵便番号・住所・電話番号の追加
 */
- (BOOL) mstuserUpgradeVer140;

/**
 * mst_user のアップグレード：ver172
 * ミドルネームの追加
 */
- (BOOL) mstuserUpgradeVer172;

/**
 * mst_user のアップグレード：ver215
 * 担当者の追加
 */
- (BOOL) mstuserUpgradeVer215;

// お客様総数など現在の状況を取得する
- (NSDictionary*) getAllUsersNumNowState;

/*
 ** TEMPLATE用に追加
 */

/**
 createTemplateDB
 テンプレート用データベースの作成
 @return YES:作成成功 NO:作成失敗
 */
- (BOOL) createTemplateDB;

/**
 isExistTemplateDB
 テンプレートの存在確認
 @return YES:テンプレートDBあり NO:テンプレートDBなし
 */
- (BOOL) isExistTemplateDB;

/**
 テンプレートを挿入する
 @param textTitle テンプレートのタイトル
 @param textBody テンプレート本文
 @param data テンプレートのデータ
 @return YES:成功 NO:失敗
 */
- (BOOL) insertTemplateWithID:(NSString*) tmplUUID
						Title:(NSString*) textTitle
						 Body:(NSString*) textBody
						 Data:(NSMutableArray*) data;

/**
 テンプレートを削除する
 @param tmplUUID
 @return YES:成功 NO:失敗
 */
- (BOOL) deleteTemplateWithID:(NSString*) tmplUUID;

/**
 テンプレートを更新する
 @param templateId テンプレートID
 @param textTitle テンプレートのタイトル
 @param textBody テンプレート本文
 @param data テンプレートのデータ
 @return YES:成功 NO:失敗
 */
- (BOOL) updateTemplateWithID:(NSString*) templateId
						Title:(NSString*) textTitle
						 Body:(NSString*) textBody
						 Data:(NSMutableArray*) data;

/**
 指定したテンプレートのタイトルを取得する
 @param templateId
 @return テンプレートのタイトル
 */
- (NSString*) getTemplateTitleWithID:(NSString*) templateId;

/**
 テンプレートに設定されているカテゴリーIDを取得する
 */
- (NSString*) getCategoryIdWithTmplID:(NSString*) tmplId;

/**
 テンプレートに設定されている汎用フィールドIDを
 */
- (NSDictionary*) getGenFieldIdWithTmplID:(NSString*) tmplId;

/**
 テンプレートを全てロードする
 @return TemplateInfo*をまとめて返す
 */
- (NSMutableArray*) loadTemplateDatabase;

// 2016/5/10 TMS テンプレートの並び順をタイトル順にする
/**
 テンプレートを全てロードする
 @return TemplateInfo*をまとめて返す
 */
- (NSMutableArray*) loadTemplateDatabaseOrderBy;

/**
 カテゴリーで絞り込み検索してロードする
 @return TemplateInfo*をまとめて返す
 */
- (NSMutableArray*) refiningTemplateDatabaseWithCategory:(NSString*) strCategory;

// 2016/5/10 TMS テンプレートの並び順をタイトル順にする
/**
 並び順を指定してカテゴリーで絞り込み検索を行う
 */
- (NSMutableArray*) refiningTemplateDatabaseWithCategoryOrderBy:(NSString*) strCategory;

/**
 insertCategory
 カテゴリーテーブルに文字列を追加する
 @param strCategory カテゴリー名
 @return YES:SUCCESS NO:FAIL
 */
- (BOOL) insertCategory:(NSString*) strCategory Date:(NSTimeInterval) date;

/**
 deleteCategory
 カテゴリーテーブルから削除する
 @param strCategory カテゴリー名
 @return YES:SUCCESS NO:FAIL
 */
- (BOOL) deleteCategory:(NSString*) strCategoryId;

/**
 deleteAllCategories
 カテゴリーテーブルから全て削除する
 */
- (BOOL) deleteAllCategories;

/**
 updateCategory
 カテゴリーテーブルの更新
 @param strCategoryId カテゴリーID
 @param date 更新日時
 @param newValue 変更する値
 @return YES:SUCCESS NO:FAIL
 */
- (BOOL) updateCategory:(NSString*) strCategoryId Date:(NSTimeInterval) date NewValue:(NSString*) newValue;

/**
 loadCategoryName
 カテゴリー名を取得する
 @param _arrayCategory カテゴリーへのポインタ
 @return 文字列が入ったNSMutableArray
 */
- (BOOL) loadCategoryName:(NSMutableArray**) _arrayCategory;

/**
 chkCategoryName
 カテゴリの存在をチェックする
 */
- (BOOL) chkCategoryName : (NSString*) categoryName;

/**
 カテゴリーIDを取得する
 @param strCategory カテゴリー名
 @return IDを取得する
 */
- (NSString*) getCategoryID:(NSString*) strCategory;

/**
 カテゴリーIDからカテゴリー名を取得する
 @param categoryId カテゴリーID
 @return カテゴリー名
 */
- (NSString*) getCategoryTitleAtID:(NSString*) categoryId;

/**
 カテゴリーIDがデフォルト値（”なし”）かどうかの判定
 */
- (BOOL) isCategoryDefaultWithID:(NSString*) categoryId;

/**
 insertGeneralField
 汎用フィールドテーブルに文字列を追加する
 @param strFieldData 挿入するフィールドデータ
 @return YES:SUCCESS NO:FAIL
 */
- (BOOL) insertGeneralField:(NSString*) strFieldData Date:(NSTimeInterval) date;

/**
 deleteGeneralField
 汎用フィールドから指定データを削除する
 @param strGenFieldId 削除するフィールドID
 @return YES:SUCCESS NO:FAIL
 */
- (BOOL) deleteGeneralField:(NSString*) strGenFieldId;

/**
 deleteAllGeneralFields
 全ての汎用フィールドを削除する
 */
- (BOOL) deleteAllGeneralFields;

/**
 updateGeneralField
 汎用フィールドテーブルの更新
 @param strGenFieldId 汎用フィールド名
 @param date 更新日時
 @paran newValue 新しい値
 @return YES:SUCCESS NO:FAIL
 */
- (BOOL) updateGeneralField:(NSString*) strGenFieldId Date:(NSTimeInterval) date NewValue:(NSString*) newValue;

/**
 loadGeneralFieldName
 カテゴリー名を取得する
 @param _arrayCategory カテゴリーへのポインタ
 @return 文字列が入ったNSMutableArray
 */
- (BOOL) loadGeneralFieldName:(NSMutableArray**) arrayFieldName;

/**
 テンプレートのデータを取得する
 */
- (BOOL) getGenFieldIdByTemplateId:(NSString*)templateId
					   Gen1FieldId:(NSString**)gen1FieldId
					   Gen2FieldId:(NSString**)gen2FieldId
					   Gen3FieldId:(NSString**)gen3FieldId;

/**
 汎用フィールドIDを取得する
 @param strCategory 汎用フィールド名
 @return IDを取得する
 */
- (NSString*) getGenFieldID:(NSString*) strGenField;

/**
 汎用フィールドIDから汎用フィールドデータを取得する
 */
- (NSString*) getGenFieldDataByID:(NSString*) genFieldId;

/**
 指定フィールドが指定テンプレート以外で使用されているかの判定
 @param genFieldId 汎用フィールドID
 @param tmplId テンプレートID
 @param error エラー
 @return YES:使用中 NO:使用なし
 */
- (BOOL) isGenFieldUsed:(NSString*) genFieldId TmplId:(NSString*)tmplId Error:(BOOL*) error;

/**
 汎用フィールド追加
 汎用ボタンの仕様変更により新たに追加されたテーブルに追加する（2014/08/05）
 @param fieldDataList 追加される汎用フィールドデータリスト
 @param Type 汎用ボタンのタイプ（日付=0・汎用１=1・汎用２=2・汎用３=3）
 @return YES:成功 NO:失敗
 */
- (BOOL) insertGeneralFieldItemList:(NSArray*) fieldDataList Type:(NSInteger) type;

/**
 汎用フィールド追加
 汎用ボタンの仕様変更により新たに追加されたテーブルを更新する（2014/08/05）
 @param updateData 更新される汎用フィールドデータリスト(genFieldIdと更新するgenFieldNameをまとめた配列)
 @return YES:成功 NO:失敗
 */
- (BOOL) updateGeneralFieldItemList:(NSArray*) updateDataList;

/**
 汎用フィールド名を取得
 汎用ボタンの仕様変更により新たに追加されたテーブルからデータを取得する（2014/08/05）
 @param Type 汎用ボタンのタイプ（日付=0・汎用１=1・汎用２=2・汎用３=3）
 @param arrayFieldName [out] 汎用フィールド名のデータを格納する
 @return YES:成功 NO:失敗
 */
- (BOOL) loadGeneralFieldItemType:(NSInteger)type NameData:(NSMutableArray **)arrayFieldName;

/**
 汎用フィールド追加
 汎用ボタンの仕様変更により新たに追加されたテーブルにのdelete_flgカラムに1を入れる（2014/08/05）
 @param updateData 消去される汎用フィールドIDデータリスト
 @return YES:成功 NO:失敗
 */
- (BOOL) deleteGeneralFieldItemList:(NSArray*) genFieldIdList;

/**
 画像の場所をDBに登録する
 @param pictUrl 画像の場所
 @param templId テンプレートID
 @return YES:成功 NO:失敗
 */
- (BOOL) insertPictureUrl:(NSMutableArray*) pictUrl TemplateId:(NSString*) templId;

/**
 複数の画像の場所をDBに登録する
 @param pictUrl 画像の場所
 @param templId テンプレートID
 @return YES:成功 NO:失敗
 */
- (BOOL) insertPictureUrls:(NSMutableArray*) pictUrls TemplateId:(NSString*) templId;

/**
 DBから画像場所を削除する
 @param pictUrl 画像のID
 @return YES:成功 NO:失敗
 */
- (BOOL) deletePictureUrl:(NSString*) pictUrl;

/**
 DBから画像場所を全て削除する
 @param templId テンプレートID
 @return YES:成功 NO:失敗
 */
- (BOOL) deleteAllPictureUrls:(NSString*) templId;

/**
 DBからテンプレート用画像のURLを取得する
 @param arrayPictUrls 画像URL保存
 @return YES:成功 NO:失敗
 */
- (BOOL) getTemplatePictureUrls:(NSString*) templID PictUrls:(NSMutableArray*) arrayPictUrls;

/**
 テンプレート用画像が他のテンプレートで使用されているか判定する
 @param tmplPictID
 @param tmplId
 @param error
 */
- (BOOL) isTemplatePictureUsed:(NSString*) tmplPictID TmplId:(NSString*)tmplId Error:(BOOL*) error;

/**
 */
- (BOOL) isTemplatePictureUsedByUrl:(NSString*) tmplUrl TmplId:(NSString*)tmplId Error:(BOOL*)erro;

/**
 取り込み画像情報をDBに追加する
 @param accountId アカウントID
 @param pictUrl 画像URL
 @param date 画像の更新日時
 @return YES:成功 NO:失敗
 */
- (BOOL) insertCapturePictInfo:(NSString*)accountId PictUrl:(NSString*)pictUrl Date:(NSTimeInterval)date;

/**
 アカウント指定で取り込んだ画像を取得する
 @param accountId
 @param captureData
 @return 画像URLを返す
 */
- (BOOL) getCapturePictInfo:(NSString*)accountId Data:(NSMutableArray**)captureData;

/**
 画像ID指定で取り込んだ画像を取得する
 @param capturePictId
 @param captureData
 @return 画像URLを返す
 */
- (BOOL) getCapturePictInfoByPictId:(NSString*)capturePictId Data:(NSMutableArray**)captureData;

/**
 取り込み画像情報をDBから削除する
 @param capturePictId 取り込み画像ID
 */
- (BOOL) deleteCapturePictInfo:(NSString*)capturePictId;

/**
 画像取り込み用DBの作成
 */
- (BOOL) createCaptruePictInfoTable;

/**
 画像取り込み用DBの存在チェック
 */
-(BOOL) isExistCapturePictInfo;

// 該当ユーザの最新施術日を取得
- (NSString*)getMaxNewWorkDateWithUserID:(USERID_INT)userID;

// 該当ユーザの初回施術日を取得
- (NSString*)getFirstWorkDateWithUserID:(USERID_INT)userID;

// 全ユーザ一のインデックス生成(ふりがなあり)
- (NSMutableArray*)getJapaneseUserListIndex;

// 2016/6/24 TMS シークレットメモ対応
// シークレットメモを追加
- (BOOL) insertSecretMemoWithDateUserID:(USERID_INT)userID :(NSInteger*)secret_memo_id :(NSString*)memo :(NSDate*)wDate;
// シークレットメモを更新
//- (BOOL) updateSecretMemoWithDateUserID:(USERID_INT)userID :(NSInteger*)secret_memo_id :(NSString*)memo;
- (BOOL) updateSecretMemoWithDateUserID:(USERID_INT)userID :(NSInteger*)secret_memo_id :(NSString*)memo :(NSDate*)wDate;
// シークレットメモを削除
//- (BOOL) deleteSecretMemoWithDateUserID:(USERID_INT)userID :(NSInteger*)secret_memo_id;
- (BOOL) deleteSecretMemoWithDateUserID:(USERID_INT)userID :(NSInteger*)secret_memo_id :(NSDate*)wDate;
// secret_user_memoテーブルの作成
- (BOOL) secretUserMemoTableMake;
/**
 並び順を指定してシークレットメモを取得
 */
- (NSMutableArray*) selectSecretMemoOrderBy:(USERID_INT)userID : (int)OrderMode;
/**
 シークレットメモの最大値を取得
 */
- (NSString*) selectSecretMemoByMax;

- (NSString*)getMaxSecretID;
@end
