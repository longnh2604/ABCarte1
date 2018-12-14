//
//  DateAddDaysPopup.h
//  iPadCamera
//
//  Created by yoshida on 2014/08/04.
//
//

#import <UIKit/UIKit.h>
#import "PopUpViewContollerBase.h"

@protocol DataAddDaysPopupDelegate <PopUpViewContollerBaseDelegate>
-(void) onDateAddDaysChansel;
@end

@interface DateAddDaysPopup : PopUpViewContollerBase <UIPopoverControllerDelegate>
{
    
	IBOutlet UILabel		*_lblTitle;         //  タイトル
	IBOutlet UILabel		*_lblAddDays;		//  追加日数
	IBOutlet UIPickerView   *_picker;           //  日付設定用DatePicker
    IBOutlet UIButton       *_btnSet;           //  設定ボタン
    IBOutlet UIButton       *_btnCancel;        //  取り消しボタン
    
    NSMutableArray          *_data;             //  データソース
    NSInteger               _addDays;           //  追加日数
    
    id<DataAddDaysPopupDelegate> _dataAddDaysDelegate;
}

@property(assign) UILabel		*lblTitle;
@property(assign) UIPickerView	*picker;


- (id) initWithDateAddDaysPopUpViewContoller:(NSUInteger)popUpID
                                    callBack:(id)callBackDelegate;

//  picker data source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component;

-(void) OnCancelButton:(id)sender;
@end
