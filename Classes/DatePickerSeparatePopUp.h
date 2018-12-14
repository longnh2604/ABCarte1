//
//  DatePickerSeparatePopUp.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/12/03.
//
//

#import "PopUpViewContollerBase.h"

@interface DatePickerSeparatePopUp : PopUpViewContollerBase
<
UIPickerViewDataSource,
UIPickerViewDelegate
>
{
    IBOutlet UIPickerView   *pickerSeparateDate;    // 日付設定ピッカー
    IBOutlet UIButton       *btnOK;                 // 設定ボタン
    IBOutlet UIButton       *btnCancel;             // 取消ボタン
    IBOutlet UIButton       *btnToday;              // 本日日付設定
    IBOutlet UIButton       *btnDateReset;          // 日付リセット

    // 設定データ
    NSInteger               currentYear;            // 年
    NSInteger               currentMonth;           // 月
    NSInteger               currentDay;             // 日
    
    NSDateComponents        *selectedDay;           // 設定された日付
}

@end
