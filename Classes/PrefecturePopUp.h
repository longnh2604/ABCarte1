//
//  PrefecturePopUp.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/07/25.
//
//

#import "PopUpViewContollerBase.h"

@protocol PrefecturePopUpDelegate;

@interface PrefecturePopUp : PopUpViewContollerBase
<
UIPickerViewDelegate,   UIPickerViewDataSource
>
{
    
    IBOutlet UIPickerView   *prefecturePicker;  // 都道府県設定ピッカー
    IBOutlet UIButton       *btnOK;             // 設定ボタン
    IBOutlet UIButton       *btnCancel;         // 取消ボタン
    
    NSArray                 *pickerValueList;   // 都道府県リスト
    NSString                *initPfrefecture;   // 初期都道府県
    NSInteger               initRow;            // 初期選択都道府県
}

@property (nonatomic, assign) id<PrefecturePopUpDelegate>   myDelegate;

// 都道府県の設定
- (IBAction)OnSetButton:(id)sender;

// 設定のキャンセル
- (IBAction)OnCancelButton:(id)sender;

- (id) initWithSetting:(NSUInteger)popUpID
        lastPrefecture:(NSString *)lastPref
              callBack:(id)callBack;

@end

#pragma mark
#pragma mark Delegate

@protocol PrefecturePopUpDelegate <NSObject>

- (void)OnPrefectureSet:(NSString *)prefecture;

- (void)OnPrefectureCancel;

@end
