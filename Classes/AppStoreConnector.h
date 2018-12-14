//
//  AppStoreConnector.h
//  iPadCamera
//
//  Created by 聡史 伊藤 on 12/06/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "AppPurchasesDialog.h"

@interface AppStoreConnector : UIViewController 
<
SKProductsRequestDelegate, SKPaymentTransactionObserver, UIActionSheetDelegate,
AppPurchasesDialogDelegate
>
{
    
    // 購入が完了したか？
    BOOL _isCompleteRegist;
    
    // 復元が完了したか？
    BOOL _isCompletRestore;
    
}

// アプリ内課金の実行
-(void)registAppWithParentView:(UIView*)parentView;
@end