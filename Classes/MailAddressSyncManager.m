//
//  MailAddressSyncManager.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/24.
//
//

#import "MailAddressSyncManager.h"
#import "Common.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation MailAddressSyncManager

/**
 *  クラウドよりお客様のメールアドレスを取得し、異なればローカルDBのメールアドレス１のみを更新する
 *  @param      userId：取得するお客様のuserID
 *  @return     YES:成功  NO:失敗
 *  @remarks    失敗時にはアラートを表示する
 */
+ (BOOL)syncMailAddresses:(USERID_INT)userId{

#ifndef WEB_MAIL_FUNC
    return (YES);
#endif
    
    SelectMailAddress *selectMailAddressManager = [[SelectMailAddress alloc] initWithDelegate:self];
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    BOOL stat = YES;
    @try {
        // サーバからuser info(アドレス)をとってくる
        NSString *address = [selectMailAddressManager syncSelectMailAddress: userId];
/*        if ([address length] <= 0) {
            return (YES);       // サーバで取得できなかった
        }
*/
        if (!address) {
            [Common showDialogWithTitle:@"サーバーエラー"
                                message:@"サーバとの通信でエラーが発生しました。"];
            [NSException raise:@"サーバーエラー" format:@"ユーザー情報エラー"];
        }
        // 複数台数契約で、他の端末で削除されたユーザ情報にアクセスした場合に実行される
        else if ([address isEqualToString:@"This User maybe deleted(9999)"]) {
            [Common showDialogWithTitle:@"データエラー"
                                message:@"このお客様の情報は削除されている可能性があります。\n一度クラウド同期を行って最新の情報を反映してください。"];
            [NSException raise:@"データエラー" format:@"ユーザー情報なし"];
        }
        // ローカルからuser infoをとってくる
        mstUser *user = [usrDbMng getMstUserByID:userId];
        if (![user.email1 isEqualToString:address]) {
            // ローカルとクラウドが異なる場合は、ローカルのemal1フィールドのみ更新
            [ MailAddressSyncManager _updateMail1FieldWithDb:usrDbMng mailAddr:address userID:userId];
        }
    }
    @catch (NSException *exception) {
        // インターネット接続が切れている
        if ([exception.name isEqualToString:@"-1009"]){
            stat = NO;
        }
    }
    @finally {
        ;
    }
    [usrDbMng release];
    [selectMailAddressManager release];
    
    // 失敗時はエラー表示
    if (! stat) {
        // 3G接続の場合はnilが戻されるので、以降のコードで注意する。
        CFArrayRef interfaces = CNCopySupportedInterfaces();
        CFDictionaryRef dicRef = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(interfaces, 0));
        NSString *ssid = nil;
        if (dicRef) {
            ssid = CFDictionaryGetValue(dicRef, kCNNetworkInfoKeySSID);
        }
        NSString *erMsg;
        erMsg = (ssid)? [NSString stringWithFormat:@"インターネット接続が不安定なため\nお客様の最新メールアドレスの\n取得に失敗しました\n現在のWiFi接続先は %@ です", ssid] :
        @"インターネット接続が不安定なため\nお客様の最新メールアドレスの\n取得に失敗しました";

        [Common showDialogWithTitle:@"接続エラー"
                            message:erMsg];
    }
    
    return (stat);
}

/**
 *  設定されたお客様のメールアドレスが異なれば、ローカルDBのメールアドレス１のみを更新して、クラウドに通知する
 *  @param      userId：対象となるお客様のuserID
 *              mailAddress:設定されたメールアドレス
 *              updateHandler:クラウド通知完了後のハンドラ
 *  @return     なし
 *  @remarks    
 */
+ (void)updateUserLocalAndWeb:(USERID_INT)userId
                  mailAddress:(NSString *)mailAddress
                updateHandler:(void (^)(BOOL result))updateHandler{
#ifndef WEB_MAIL_FUNC
    return;
#endif
    
    // クライアントDBとフォームに入力された値に違いがあるかを確認
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    mstUser *user = [usrDbMng getMstUserByID: userId];
    //
    if (![user.email1 isEqualToString:mailAddress]) {
        // 異なれば、ローカルを更新：同期のため全フィールドを更新
        user.email1 = mailAddress;
        [usrDbMng updateMstUser:user];
    
        // 異なれば、さらにクラウドも更新する
        [CloudSyncClientManager clientUserInfoSyncProc: ^(SYNC_RESPONSE_STATE result)
         {
             if (result == SYNC_RSP_OK)
             {
                 updateHandler(YES);
             }else {
                 updateHandler(NO);
             }
         }
         userId:userId
         ];
    }
    else {
        // 同じ場合でも更新ハンドラはコールする
        updateHandler(YES);
    }
    
    [user release];
    [usrDbMng release];
}

#pragma mark - private_methods

// メール１フィールドのみ更新する
+(BOOL) _updateMail1FieldWithDb:(userDbManager*)dbMng mailAddr:(NSString*)mAdr userID:(USERID_INT)uID
{
    BOOL stat = YES;
    
    // トランザクションで開始
    if (! [dbMng dataBaseOpen4Transaction] ) {
        return (NO);
    }
    
    // 更新するSQL文字列
    NSMutableString *sql = [NSMutableString string];
    [sql appendString:@"UPDATE mst_user "];
    [sql appendString:@"  SET email1=? "];
    [sql appendString:@" WHERE user_id = ?"];
    
    // DBの更新
    stat = [dbMng executeSqlTemplateWithSql:sql
                                bindHandler:^(sqlite3_stmt* sqlstmt)
                 {
                     u_int idx = 1;
                     [dbMng setBindTextWithString:mAdr
                                       pStatement:sqlstmt setPositon:idx++];
                     sqlite3_bind_int(sqlstmt, idx++, uID);
                 }
            ];

    
    
    // トランザクションを完了しデータベースをcloseする
    [dbMng dataBaseClose2TransactionWithState:stat];
    
    return (stat);
}

@end
