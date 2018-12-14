//
//  AppPurchasesDialog.m
//  iPadCamera
//
//  Created by 西島和彦 on 2015/02/26.
//
//

#import "AppPurchasesDialog.h"

@interface AppPurchasesDialog ()

@end

@implementation AppPurchasesDialog

@synthesize appdelegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 青枠表示に変えるパーツの処理
    NSArray *partsArr = @[btnNewPurchases, btnRestorePurchases];
    for (id parts in partsArr) {
        [parts setBackgroundColor:[UIColor whiteColor]];
        [[parts layer] setCornerRadius:6.0];
        [parts setClipsToBounds:YES];
        [[parts layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[parts layer] setBorderWidth:1.0];
    }
    
    //選択可能な言語設定の配列を取得
    NSArray *langs = [NSLocale preferredLanguages];
    //取得した配列から先頭の文字列を取得（先頭が現在の設定言語）
    NSString *currentLanguage = [langs objectAtIndex:0];
	NSLog(@"端末言語設定： %@",currentLanguage);
	// 2015/10/27 TMS iOS9対応
    if ([currentLanguage isEqualToString:@"ja-JP"] || [currentLanguage isEqualToString:@"ja"]) {
        lblTitle.text = @"[ ABCarteのアカウント購入 ]";
        lblSummary.text = @"アカウントを購入いただくと、次のようなことが可能になります。";
        lblContent.text = @"・新規ユーザ作成の制限解除\n・写真撮影枚数の制限解除";
        [btnNewPurchases setTitle:@"新規にアカウントを購入" forState:UIControlStateNormal];
        [btnRestorePurchases setTitle:@"購入済みアカウントを復元" forState:UIControlStateNormal];
    } else {
        lblTitle.text = @"[ Purchase of ABCarte account ]";
        lblSummary.text = @"Limit will be canceled when you purchased.";
        lblContent.text = @"* Make new customer list\n* Unlimited photography";
        [btnNewPurchases     setTitle:@"Buy account"     forState:UIControlStateNormal];
        [btnRestorePurchases setTitle:@"Restore account" forState:UIControlStateNormal];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [btnNewPurchases release];
    [btnRestorePurchases release];
    [lblTitle release];
    [lblSummary release];
    [lblContent release];
    [super dealloc];
}
- (void)viewDidUnload {
    [btnNewPurchases release];
    btnNewPurchases = nil;
    [btnRestorePurchases release];
    btnRestorePurchases = nil;
    [lblTitle release];
    lblTitle = nil;
    [lblSummary release];
    lblSummary = nil;
    [lblContent release];
    lblContent = nil;
    [super viewDidUnload];
}

/**
 * 新規購入ボタン押下処理
 */
- (IBAction)OnNewPurchases:(id)sender {
    btnNewPurchases.enabled = NO;
    if ([appdelegate respondsToSelector:@selector(procNewPurchases)]) {
        [appdelegate procNewPurchases];
    }
    
    double delayInSeconds = 1.5f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self closeByPopoverContoller];
    });
}

/**
 * 購入復元ボタン押下処理
 */
- (IBAction)OnRestorePurchases:(id)sender {
    btnRestorePurchases.enabled = NO;
    if ([appdelegate respondsToSelector:@selector(procRestorePurchases)]) {
        [appdelegate procRestorePurchases];
    }

    double delayInSeconds = 1.5f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self closeByPopoverContoller];
    });
}

@end
