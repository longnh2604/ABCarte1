//
//  AppStoreConnector.m
//  iPadCamera
//
//  Created by 聡史 伊藤 on 12/06/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "AppStoreConnector.h"
#import "defines.h"
#import "ShopManager.h"

#import "Reachability.h"

#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"

#import "UserInfoListViewController.h"

#ifdef CLOUD_SYNC
#import "AccountManager.h"
#endif

// アカウント店舗IDのdefaultのkey名
#define ACCOUNT_SHOP_ID_KEY             @"account_shop_id"
// 店舗毎のuserID基準数のdefaultのkey名
#define SHOP_USER_ID_KEY                @"user_id_at_shop"

@interface AppStoreConnector ()

@end

@implementation AppStoreConnector

// - (void)registApp{

// アプリ内課金の実行
-(void)registAppWithParentView:(UIView*)parentView
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* userId  = [defaults stringForKey:@"accountIDSave"];
    if ([userId length] > 0){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"アカウント登録"
                                                            message:@"既にアカウント登録は完了しています。"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];	 
        return;
    }
    
    // ネットワークの接続を確認
    REACHABLE_STATUS rStat 
        = [ReachabilityManager reachabilityStatusWithHostName: ACCOUNT_HOST_URL];
	if (rStat != REACHABLE_HOST)
	{	
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"アカウント登録"
                                                            message:@"ネットワークに接続できません"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];	 
        return;
    }
    
    NSLog(@"Apple Storeと接続");
    // アプリ内課金が許可されているかを確認
    if ([SKPaymentQueue canMakePayments] == NO) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"アカウント登録"
                                                            message:@"機能制限:App内での購入がオフにされています。"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];	 
        return;
    }
    
    // アプリ内課金のポップアップ表示
    [self inAppPurchases:parentView];
    // アプリ内課金のActionSheetの表示
//    [self showActionSheet:parentView];
}

/**
 * アプリ内課金ポップアップ表示
 */
- (void) inAppPurchases:(UIView*)view
{
    //日付の設定ポップアップViewControllerのインスタンス生成
    AppPurchasesDialog *appVc
    = [[AppPurchasesDialog alloc] initWithPopUpViewContoller:111
                                           popOverController:nil
                                                    callBack:self];
    appVc.appdelegate = self;
    
    // ポップアップViewの表示
    UIPopoverController *popC = [[UIPopoverController alloc]
                                 initWithContentViewController:appVc];
    appVc.popoverController = popC;
    CGRect r = view.frame;
    
    [popC presentPopoverFromRect:CGRectMake((r.size.width-500)/2, 100, 500, 300)
                          inView:view
        permittedArrowDirections:UIPopoverArrowDirectionUp
                        animated:YES];
    [popC setPopoverContentSize:CGSizeMake(500.0f, 300.0f)];
    
    [popC release];
    [appVc release];
}

#define ACCOUNT_PURCHASES_ACTION  64

// アプリ内課金のActionSheetの表示
- (void)showActionSheet:(UIView*)view
{
    UIActionSheet *sheet =
    [[UIActionSheet alloc] initWithTitle:@"ABCarteのアカウント購入方法を\n選んでください"
                                delegate:self 
                       cancelButtonTitle:@"キャンセル"
                  destructiveButtonTitle:nil
#ifndef CALULU_IPHONE
                       otherButtonTitles:@"新規にアカウントを購入", @"購入済みアカウントを復元", @"キャンセル", nil];
#else
                       otherButtonTitles:@"新規にアカウントを購入", @"購入済みアカウントを復元", nil];
#endif
    sheet.tag = ACCOUNT_PURCHASES_ACTION;
    
    [sheet autorelease];
    sheet.actionSheetStyle = UIActionSheetStyleDefault;
    
    
    // アクションシートを表示する
    [sheet showInView:view];
    
}

#pragma mark AppPurchasesDialogDelegate

- (void)procNewPurchases
{
    // 課金処理中の対応
    [self productsRequestProcWithFlag:YES];
    
    // 新規にアカウントを購入
    [self newAppPurchases];
}

- (void)procRestorePurchases
{
    // 課金処理中の対応
    [self productsRequestProcWithFlag:YES];
    
    // 以前に購入したアカウントを復元
    [self restoreAppPurchases];
}

#pragma mark UIActionSheetDelegate

// アクションシート（設定ボタンによる）delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag != ACCOUNT_PURCHASES_ACTION)
    {   return; }
    
    switch (buttonIndex) {
        case 0:
        // 新規にアカウントを購入する
            
            // 課金処理中の対応
            [self productsRequestProcWithFlag:YES];
            
            // 新規にアカウントを購入
            [self newAppPurchases];
            
            break;
        case 1:
        // 以前に購入したアカウントを復元する
            
            // 課金処理中の対応
            [self productsRequestProcWithFlag:YES];
            
            // 以前に購入したアカウントを復元
            [self restoreAppPurchases];
            
            break;
        default:
            break;
    }
}


//  新規にアカウントを購入
- (void) newAppPurchases
{
    NSSet *productIds = [NSSet setWithObjects:PRODUCT_ID,nil];
    SKProductsRequest* productsRequest 
        = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
    productsRequest.delegate = self;
    [productsRequest start];
}

// 以前に購入したアカウントを復元
- (void)restoreAppPurchases
{
    // オブザーバーを起動
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    _isCompleteRegist = NO;
    _isCompletRestore = NO;
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    // httpサーバの管理：課金処理中にBonjourサービスでエラーとなるため
    iPadCameraAppDelegate* app = (iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate];
    // [app httpServerControlWithFlag: !isProc];
    
    // 画面のスクロールのロック
    MainViewController *mainVC = app.viewController;
    [mainVC viewScrollLock:NO];
    
    // レスポンスが空
    if (response == nil) {
        NSLog(@"Product Response is nil");
        return;
    }
    
    // 確認できなかったidentifierをログに記録
    if ([response.invalidProductIdentifiers count] > 0) {
        for (NSString *identifier in response.invalidProductIdentifiers) {
            NSLog(@"invalid product identifier: %@", identifier);
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"アカウント購入ができませんでした\n(恐れ入りますがもう一度\n操作をお願いします。)"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
        
        return;
    }
    
    _isCompleteRegist = NO;
    
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    for (SKProduct *product in response.products ) {
        NSLog(@"valid product identifier: %@", product.productIdentifier);
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

#pragma mark SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    BOOL purchasing = YES;
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
                // 購入中
            case SKPaymentTransactionStatePurchasing: {
                NSLog(@"Payment Transaction Purchasing");
                break;
            }
                // 購入成功
            case SKPaymentTransactionStatePurchased: {
                NSLog(@"Payment Transaction END Purchased: %@", transaction.transactionIdentifier);
                
                [queue finishTransaction:transaction];
                
                purchasing = NO;
                [self completeRegist];
                
                break;
            }
                // 購入失敗
            case SKPaymentTransactionStateFailed: {
                NSLog(@"Payment Transaction END Failed: %@ %@", transaction.transactionIdentifier, transaction.error);
                purchasing = NO;
                // エラーアラート
                if (transaction.error.code != SKErrorPaymentCancelled)
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"アカウント購入ができませんでした"
                                                                    message:[transaction.error localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil];
                    [alert show];
                    [alert release];
                }
                [queue finishTransaction:transaction];
                // 途中でキャンセルまたは失敗した時に、Observerを削除しておかないと、
                // Observerの処理が複数行われるようになってしまう。
                [[SKPaymentQueue defaultQueue] removeTransactionObserver: self];
                break;
            }
                // 購入履歴復元
            case SKPaymentTransactionStateRestored: {
                NSLog(@"Payment Transaction END Restored: %@", transaction.transactionIdentifier);
                
                [queue finishTransaction:transaction];
                
                purchasing = NO;
                [self completeRegist];
                
                break;
            }
            default:
                NSLog(@"Payment Transaction onther case!! %@", transaction.transactionIdentifier);
                [queue finishTransaction:transaction];
                [[SKPaymentQueue defaultQueue] removeTransactionObserver: self];
                break;
        }
    }
    
    if (purchasing == NO) {
        // [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        // 課金処理中の対応
        [self productsRequestProcWithFlag:NO];
        
        _isCompletRestore = YES;
    }
}

// リストアの失敗
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    if (_isCompletRestore)
    {   return; }
    
    // リストアの完了
    _isCompletRestore = YES;
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver: self];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"復元に失敗しました"
                                                        message:@"以前に購入したアカウントは\n復元できませんでした"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];	
    
    // 課金処理中の対応
    [self productsRequestProcWithFlag:NO];
    
    return;
}

// 全てのリストア処理が終了
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue 
{
    NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
    
    // リストアの完了
    if ( (_isCompleteRegist) || (_isCompletRestore) )
    {   return; }
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver: self];
    
    // リストアが完了していない場合はメッセージ表示
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"復元は完了できませんでした"
                                                        message:@"以前に購入したアカウントを\nもう一度確認してください"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];	
    
    
    // 課金処理中の対応
    [self productsRequestProcWithFlag:NO];
}


#pragma mark private_methods

// 課金が行われた後、呼び出す
- (void)completeRegist {
    
    NSLog(@"completeRegist check _isCompleteRegist before");
    
    if (_isCompleteRegist)
    {   return; }
    _isCompleteRegist = YES;
    
    [[NSRunLoop currentRunLoop]
     runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
    
    NSLog(@"completeRegist _isCompleteRegist is true");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"RegistFromAppleStore" forKey:@"accountIDSave"];
    [defaults setObject:@"0000" forKey:@"accountPwdSave"];
    [defaults setObject:@"0" forKey:@"isShop"];
    [defaults setObject:@"999" forKey:@"userIDBase"];
    
    // 継続課金処理が、とりあえず発生しないように25年先にする： TODO:
    NSDate* aft25Years = [NSDate dateWithTimeIntervalSinceNow:25*365*24*60*60];
    [defaults setObject:aft25Years forKey:@"accountUpdateSave"];
    
    [defaults synchronize];
    
    // 店舗は非対応
    ShopManager *shopMng = [ShopManager defaultManager];
    [shopMng resetAccountShopID];
    
#ifdef CLOUD_SYNC
    // クラウドに通知
    AccountManager *actMng = [[AccountManager alloc]initWithServerHostName:ACCOUNT_HOST_URL];
	ACCOUNT_RESPONSE response = [actMng newlyAppStoreWithAccountID:@"RegistFromAppleStore"
                                                          passWord:@"0000"];
	if (response != ACCOUNT_RSP_SUCCESS) {
        NSLog(@"fail newlyAppStoreWithAccountID:%ld", (long)response);
    }
#endif
    
    // ログイン完了後の処理
    MainViewController *mainVC 
    = ( (iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    UserInfoListViewController *userInfoVc 
    = (UserInfoListViewController*)[mainVC getVC4ViewControllersWithClass:[UserInfoListViewController class]];
    if (userInfoVc)
    {   [userInfoVc loginedProc]; }
    
    UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:@"ご購入いただきありがとうございました"
							  message:@"ご登録いただきまして\n誠にありがとうございます\nABCarteの全ての機能が\nご利用いただけます"
                              delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
    [alertView show];
	[alertView release];
    
}

// 課金処理中の対応
- (void) productsRequestProcWithFlag:(BOOL)isProc
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = isProc;
    
    // httpサーバの管理：課金処理中にBonjourサービスでエラーとなるため
    iPadCameraAppDelegate* app = (iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate];
    // [app httpServerControlWithFlag: !isProc];
    
    // 画面のスクロールのロック
    MainViewController *mainVC = app.viewController;
    [mainVC viewScrollLock:isProc];
}

@end
