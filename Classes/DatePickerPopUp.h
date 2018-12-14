//
//  DatePickerPopUp.h
//  iPadCamera
//
//  Created by MacBook on 10/12/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PopUpViewContollerBase.h"

@interface DatePickerPopUp : PopUpViewContollerBase 
{

	IBOutlet UILabel		*lblTitle;			// タイトル
	IBOutlet UIDatePicker	*dpSetDate;			// 日付設定用DatePicker
    IBOutlet UIButton       *btnSet;            // 設定ボタン
    IBOutlet UIButton       *btnCancel;         // 取り消しボタン
	
	IBOutlet UILabel		*lblBirthday;		// 生年月日（和暦表示）
    
    NSDate                  *currentDate;       // 開始日
}

@property(assign) UILabel		*lblTitle;
@property(assign) UIDatePicker	*dpSetDate;
@property(assign) BOOL          isJapanese;

// 表示日時を指定する場合
- (id)initWithDatePopUpViewContoller:(NSUInteger)popUpID
                   popOverController:(UIPopoverController *)controller
                            callBack:(id)callBackDelegate
                            initDate:(NSDate *)initDate;

/**
 * 表示日時を指定して初期化する(言語環境含む)
 */
- (id)initWithDatePopUpViewContoller:(NSUInteger)popUpID
                   popOverController:(UIPopoverController *)controller
                            callBack:(id)callBackDelegate
                            initDate:(NSDate *)initDate
                          selectLang:(BOOL)lang;

// 生年月日pickerのイベント
- (IBAction) OnBirthDayValueChanged:(id)sender;

// 生年月日の和暦表示
- (void) dispLabelBirthday:(NSDate*)date;

@end
