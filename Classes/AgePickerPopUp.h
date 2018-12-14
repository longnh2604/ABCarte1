//
//  AgePickerPopUp.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/03/25.
//
//

#import "PopUpViewContollerBase.h"

@protocol AgePickerPopUpDelegate;

@interface AgePickerPopUp : PopUpViewContollerBase <UIPickerViewDelegate, UIPickerViewDataSource>
{
    IBOutlet UIPickerView   *apSetAge;              // 年齢設定用ピッカー
    
    NSMutableArray          *pickerValueAgeList;    // 年代設定用
    NSInteger               realAge;                // 年齢
    IBOutlet UILabel        *lblTitle;              // タイトルラベル
    IBOutlet UIButton       *btnSet;                // 設定ボタン
    IBOutlet UIButton       *btnCancel;             // キャンセルボタン
}

@property (nonatomic, assign) id<AgePickerPopUpDelegate>    myDelegate;
@property NSInteger age;

- (IBAction)OnSetButton:(id)sender;                 // 年齢設定
- (IBAction)OnCancelButton:(id)sender;              // 設定キャンセル

- (id) initWithAgeSetting:(NSInteger)init_age       // ポップアップ初期化呼び出し
                  popUpID:(NSUInteger)popUpID
                 callBack:(id)callBack;
@end

@protocol AgePickerPopUpDelegate <NSObject>

// ポップアップ側の設定値を取得
- (void)OnCheckAge:(NSInteger)age;
// キャンセルの場合、設定前の状態に戻す
- (void)OnAgeSetCancel;
// 年齢確定
- (void)OnAgeSetOK;

@end
