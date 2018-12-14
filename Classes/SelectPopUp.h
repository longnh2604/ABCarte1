//
//  PrefecturePopUp.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/07/25.
//
//

#import "PopUpViewContollerBase.h"

@protocol SelectPopUpDelegate;

@interface SelectPopUp : PopUpViewContollerBase
<
UIPickerViewDelegate,   UIPickerViewDataSource
>
{
    
    IBOutlet UIPickerView   *prefecturePicker;  // 都道府県設定ピッカー
    IBOutlet UIButton       *btnOK;             // 設定ボタン
    IBOutlet UIButton       *btnCancel;         // 取消ボタン
    
    NSArray                 *pickerValueList;   // 都道府県リスト
    NSInteger               initSelect;         // 初期選択
    NSInteger               initRow;            // 初期選択都道府県
    NSArray                 *pickerArray;
}

@property (nonatomic, assign) id<SelectPopUpDelegate>   myDelegate;

// 都道府県の設定
- (IBAction)OnSetButton:(id)sender;

// 設定のキャンセル
- (IBAction)OnCancelButton:(id)sender;

- (id) initWithSetting:(NSUInteger)popUpID
            lastSelect:(NSInteger)lastSelect
            pickerData:(NSArray *)pickerData
              callBack:(id)callBack;

@end

#pragma mark
#pragma mark Delegate

@protocol SelectPopUpDelegate <NSObject>

- (void)OnSelectSet:(NSUInteger)popUpID selectNumber:(NSInteger)selectNum;

- (void)OnSelectCancel:(NSUInteger)popUpID;

@end
