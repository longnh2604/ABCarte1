//
//  BloodGroupPopUp.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/07/17.
//
//

#import "PopUpViewContollerBase.h"

NS_ENUM(NSInteger, BloodTypeIndex)
{
    BLOODTYPE_A = 0,
    BLOODTYPE_B,
    BLOODTYPE_O,
    BLOODTYPE_AB,
    BLOODTYPE_UNKNOWN,
};

@protocol BloodGroupPopUpDelegate;

@interface BloodGroupPopUp : PopUpViewContollerBase
{
//    IBOutlet UISegmentedControl     *segBloodType;  // 血液型選択ボタン
//    IBOutlet UIButton               *btnSet;        // 設定ボタン
//    IBOutlet UIButton               *btnCancel;     // 取消ボタン
    
    NSInteger                       _bloodType;     // 血液型
}
@property (retain, nonatomic) IBOutlet UISegmentedControl *segBloodType;
@property (retain, nonatomic) IBOutlet UIButton *btnCancel;
@property (retain, nonatomic) IBOutlet UIButton *btnSet;
@property (nonatomic, assign) id<BloodGroupPopUpDelegate>   myDelegate;

- (IBAction)OnCancel:(id)sender;    // 取消ボタン
- (IBAction)OnSet:(id)sender;       // 設定ボタン

/**
 * 初期化(血液型と共に)
 */
- (id)initWithBloodTypePopUpViewContoller:(NSUInteger)popUpID
                        popOverController:(UIPopoverController *)controller
                                 callBack:(id)callBackDelegate
                                bloodType:(NSInteger)bloodType;

@end

@protocol BloodGroupPopUpDelegate <NSObject>

// 血液型設定
- (void)OnBloodSetOK:(NSInteger)bloodType;

@end
