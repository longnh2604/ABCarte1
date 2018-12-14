//
//  AppPurchasesDialog.h
//  iPadCamera
//
//  Created by 西島和彦 on 2015/02/26.
//
//

#import "PopUpViewContollerBase.h"

@protocol  AppPurchasesDialogDelegate;

@interface AppPurchasesDialog : PopUpViewContollerBase
{
    IBOutlet UIButton   *btnNewPurchases;       // 新規購入ボタン
    IBOutlet UIButton   *btnRestorePurchases;   // 購入復元ボタン
    IBOutlet UILabel    *lblTitle;              // タイトル
    IBOutlet UILabel    *lblSummary;            // 要約
    IBOutlet UILabel    *lblContent;            // 内容
}
@property (nonatomic, assign) id <AppPurchasesDialogDelegate> appdelegate;

- (IBAction)OnNewPurchases:(id)sender;      // 新規購入
- (IBAction)OnRestorePurchases:(id)sender;  // 購入復元

@end

/**
 * 課金確認ポップアップ用Delegate
 */
@protocol AppPurchasesDialogDelegate <NSObject>

- (void)procNewPurchases;       // 新規購入

- (void)procRestorePurchases;   // 購入復元

@end