//
//  NameSearchPopup.h
//  iPadCamera
//
//  Created by TMS on 2016/08/10.
//
//

#import "PopUpViewContollerBase.h"

@protocol ResponsibleSearchPopupDelegate;


@interface ResponsibleSearchPopup : PopUpViewContollerBase
<
PopUpViewContollerBaseDelegate
>
{
    IBOutlet UITextField    *txtName;            // 担当者名
    IBOutlet UIButton       *btnOK;             // 検索
}
@property (nonatomic, assign) id <ResponsibleSearchPopupDelegate> rs_delegate;

- (IBAction)onSetStartDay:(id)sender;           // 検索開始範囲設定
- (IBAction)onSetEndDay:(id)sender;             // 検索終了範囲設定

- (IBAction)onSearchStart:(id)sender;           // 検索開始
- (IBAction)onSearchCancel:(id)sender;          // 検索キャンセル
- (IBAction)onTextDidEnd:(id)sender;            // テキストボックス入力終了
- (IBAction)onSearchRangeChanged:(id)sender;    // 検索範囲変更

@end

// 日付検索関連デリゲート
@protocol ResponsibleSearchPopupDelegate <NSObject>
@optional

/**
 顧客名検索
 */
- (void)OnResponsibleSearch:(id)sender;

@end