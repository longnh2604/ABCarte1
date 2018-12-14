//
//  MailAddressSyncManager.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/24.
//
//

#import <Foundation/Foundation.h>
#import "SelectMailAddress.h"
#import "mstUser.h"
#import "userDbManager.h"
#import "CloudSyncClientManager.h"

@interface MailAddressSyncManager : NSObject {
}

/**
 *  クラウドよりお客様のメールアドレスを取得し、異なればローカルDBのメールアドレス１のみを更新する
 *  @param      userId：取得するお客様のuserID
 *  @return     YES:成功  NO:失敗
 *  @remarks    失敗時にはアラートを表示する
 */
+ (BOOL)syncMailAddresses:(USERID_INT)userId;

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
                updateHandler:(void (^)(BOOL result))updateHandler;
@end
