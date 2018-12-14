//
//  DateSearchPopup.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/12/02.
//
//

#import "PopUpViewContollerBase.h"

@protocol DateSearchPopupDelegate;


@interface DateSearchPopup : PopUpViewContollerBase
<
PopUpViewContollerBaseDelegate
>
{
    
    IBOutlet UIButton       *btnStartDate;      // 検索開始日付
    IBOutlet UIButton       *btnEndDate;        // 検索終了日付
    IBOutlet UIButton       *btnOK;             // 検索
    IBOutlet UIButton       *btnCancel;         // 取消
    IBOutlet UILabel        *lblSearchDoc;      // 検索内容の説明
    IBOutlet UILabel        *lblTilde;          // にょろ
    IBOutlet UITextField    *txtInterval;       // 来店間隔日数入力フィールド
    IBOutlet UILabel        *lblIntervalDay;    // 来店間隔ラベル
    IBOutlet UITextField    *txtIntervalYear;   // 来店間隔検索範囲
    IBOutlet UILabel        *lblIntervalYear;   // 来店間隔検索範囲ラベル
    IBOutlet UISegmentedControl *swSearchRange; // 検索範囲設定スイッチ

    NSInteger               selectedSearchKind; // 現在選択中の検索種別
    NSMutableArray          *arrayButtons;      // ボタン配列
    NSMutableArray          *arrayDocs;         // 検索説明文配列
    
    NSDate                  *startDay;          // 検索開始日
    NSDate                  *endDay;            // 検索終了日
    NSDateComponents        *startDayComp;      // 検索開始日
    NSDateComponents        *endDayComp;        // 検索終了日
}
@property (nonatomic, assign) id <DateSearchPopupDelegate> ds_delegate;

- (IBAction)onSetStartDay:(id)sender;           // 検索開始範囲設定
- (IBAction)onSetEndDay:(id)sender;             // 検索終了範囲設定

- (IBAction)onSearchStart:(id)sender;           // 検索開始
- (IBAction)onSearchCancel:(id)sender;          // 検索キャンセル
- (IBAction)onTextDidEnd:(id)sender;            // テキストボックス入力終了
- (IBAction)onSearchRangeChanged:(id)sender;    // 検索範囲変更

@end

// 日付検索関連デリゲート
@protocol DateSearchPopupDelegate <NSObject>
@optional

/**
 施術日検索
 */
- (void)OnNormalWorkSearch:(id)sender;

/**
 最新施術日検索
 */
- (void)OnLatestWorkSearch:(id)sender;

/**
 初回登録日検索
 */
- (void)OnFirstWorkSearch:(id)sender;

/**
 来店間隔検索
  */
- (void)OnIntervalWorkSearch:(id)sender;

@end