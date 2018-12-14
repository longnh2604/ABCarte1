//
//  userFmdbManager.h
//  iPadCamera
//
//  Created by GIGASJAPAN on 13/06/13.
//
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "fcUserMailItemBean.h"
#import "mstUserMailItemBean.h"
#import "WebMail.h"
#import "WebMailUserStatus.h"
#import "def64bit_common.h"

#define ITEM_USER_MAIL_FC_TABLE	@"fc_user_mail_item" //メール本文履歴


@interface userFmdbManager : NSObject
{
    NSString *dbPath;
}
//初期化(コンストラクタ)
- (id)init;
// データベースに接続
- (FMDatabase *) databaseConnect;
//データベースの初期化
- (BOOL)initDataBase;
//メールの追加
- (BOOL)insertMail:(WebMail *)mail WithDb:(FMDatabase *)db;
/*
- (BOOL)insertMail:(NSInteger)mailId
             Title:(NSInteger)title
              Body:(NSString*)body
            Sender:(NSString*)sender
          FromUser:(BOOL)fromUser
            Unread:(BOOL)unread
             Check:(BOOL)chek
        UserUnread:(BOOL)userUnread
   ServerCreatedAt:(NSDate *)serverCreatedAt;*
            WithDb:(FMDatabase *)db;*/
// クライアントのあるユーザの情報の更新日時(unix time)をとる
-(NSInteger)selectUntilWithUserId:(USERID_INT)userId;
// クライアントのあるユーザの情報の更新日時(unix time)を更新
- (BOOL)updateUntil:(NSInteger)until userId:(USERID_INT)userId db:(FMDatabase *)db;
// あるユーザのある日時（unix time)以前のメールを取得する
- (NSArray *)selectMailsSince:(NSInteger)since userId:(USERID_INT)userId;
//メールタイトル追加
- (NSInteger)insertMailTitle:(NSString*)title;
//ユーザごとの既読情報などを取得
- (NSDictionary *)getStatuses;
//あるユーザの来独情報を取得
- (WebMailUserStatus *)getStatus: (USERID_INT)userId;
//メール本文テーブルにメール情報を追加
- (BOOL)insertUserMail:(NSInteger)smtpId
               TitleID:(NSInteger)titleId
             MailHead1:(NSString*)mailHead1
             MailHead2:(NSString*)mailHead2
         MailSignature:(NSString*)mailSignature
              MailText:(NSString*)mailText;

//smtp設定テーブルに設定情報を追加
- (BOOL)insertMailSmtpInfo:(NSString*)sendarAddr
                SmtpServer:(NSString*)smtpServer
                  SmtpUser:(NSString*)smtpUser
                  SmtpPass:(NSString*)smtpPass
                  SmtpPort:(NSInteger)smtpPort
                  SmtpAuth:(NSInteger)smtpAuth;
- (BOOL)insertMailSmtpInfo:(NSString*)sendarAddr
                  SmtpUser:(NSString*)smtpUser;
//smtp設定テーブルの設定情報を更新
- (BOOL)updateMailSmtpInfo:(NSString*)sendarAddr
                SmtpServer:(NSString*)smtpServer
                  SmtpUser:(NSString*)smtpUser
                  SmtpPass:(NSString*)smtpPass
                  SmtpPort:(NSInteger)smtpPort
                  SmtpAuth:(NSInteger)smtpAuth;
- (BOOL)updateMailSmtpInfo:(NSString*)sendarAddr
                  SmtpUser:(NSString*)smtpUser;
//メール本文テーブルのメール情報を更新
- (BOOL)updateUserMail:(NSInteger)smtpId
               TitleID:(NSInteger)titleId
             MailHead1:(NSString*)mailHead1
             MailHead2:(NSString*)mailHead2
         MailSignature:(NSString*)mailSignature
              MailText:(NSString*)mailText;

//  メール受信拒否状態更新
- (BOOL)updateWebMailBlockUser:(USERID_INT) userId
                    BlockState:(bool) blockState;

//全てのメールタイトル取得
- (NSMutableArray*)selectAllMailTitle;

//特定のIDのメールタイトル取得
- (NSString*)selectMailTitle:(NSInteger)titleId;

//該当するIDのsmtp設定情報を取得
- (NSMutableArray*)selectMailSmtpInfo:(NSInteger)smtpId;

//登録されているメール情報を取得
- (NSMutableArray*)selectUserMail;

/**
 メールIDからメールタイトル取得
 @param mailId
 @return メールのタイトル
 */
- (NSString*) selectMailTitleWhereMailId:(NSInteger)mailId;

/**
 メールIDからメール作成日時取得
 @param mailId
 @return メールの作成日時情報（UNIX）
 */
- (NSInteger) selectMailDateWhereMailId:(NSInteger)mailId;

/**
 登録されているメール情報を削除
 @param userId ユーザーID
 @return YES:削除成功 NO:削除失敗
 */
- (BOOL) removeUserMailInfo:(USERID_INT) userId;

/**
 指定メールを削除する
 @param mailId	メールID
 @return YES:削除成功 NO:削除失敗
 */
- (BOOL) removeWebMailWhereMailId:(NSInteger) mailId;

/**
 送信メールのエラー情報を登録する
 @param title メールタイトル
 @param sendCount 送信数
 @param errorCount エラー数
 @return YES:成功 NO:失敗
 */
- (BOOL) insertWebMailErrorWithTitle:(NSString*)title SendCount:(NSInteger)sendCount ErrorCount:(NSInteger)errorCount;

/**
 送信メールのエラー情報を削除する
 @return YES:成功 NO:失敗
 */
- (BOOL) removeAllWebMailError;

/**
 送信メールのエラー情報を取得する
 @return nil以外:成功 nil:失敗
 */
- (NSArray*) getWebMailError;

/**
 指定ユーザーの送信メールのエラー数を増加させる
 */
- (BOOL) insertWebMailErrorCountWithUserID:(USERID_INT)userID Error:(NSInteger)error;

/**
 指定ユーザーの送信メールのエラー数を削除する
 */
- (BOOL) removeWebMailErrorCountWithUserID:(USERID_INT)userID;

/**
 送信メールのエラー数を全て削除する
 */
- (BOOL) removeAllWebMailErrorUsers;

/**
 指定ユーザーの送信メールのエラー数を取得する
 @param userId ユーザーID
 @return 送信メールのエラー数
 */
- (NSInteger) getWebMailErrorCountByUserID:(USERID_INT)userId;

/**
 指定ユーザーの送信メール数を取得する
 @param userId ユーザーID
 @return 送信メール数
 */
- (NSInteger) getSendWebMailCounts:(USERID_INT)userId;

/**
 指定ユーザーがあるかどうか
 */
- (BOOL) isWebMailUser:(USERID_INT)userId;

/**
    端末のデータベースを参照して
    受信拒否ユーザーIDのリストを返す
 */
- (NSDictionary*) getWebMailBlockUserList;

/**
    端末のデータベースを参照して
    ユーザー受信拒否かどうかを返す。
 */
-(bool) isWebMailBlockUser:(USERID_INT) userId;

@end
