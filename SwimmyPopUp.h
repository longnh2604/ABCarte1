//
//  SwimmyPopUp.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/03/19.
//
//

#import "PopUpViewContollerBase.h"
#import "userDbManager.h"
#import "userFmdbManager.h"
#import "fcUserWorkItem.h"
#import "mstUser.h"

#import "selectSwimmyPicture.h"
#import "AgePickerPopUp.h"
#import "def64bit_common.h"

@interface SwimmyPopUp : PopUpViewContollerBase
<
selectSwimmyPictureDelegate,
AgePickerPopUpDelegate,
UITextFieldDelegate
>
{
    USERID_INT              selectUserID;           // ユーザーID
    NSMutableArray          *selectImageArray;      // 添付画像配列
    NSError                 *mailError;             // メール送信エラー
    UIAlertView             *indicatorAlert;        // 送信中アラート
    BOOL                    aliveThreadFlag;        // メール送信処理中のフラグ
    BOOL                    dissmissPopupFlag;      // メール送信中に画面の向きを変えたらたてるフラグ
    
    IBOutlet UIButton       *btnSetAge;             // 年齢設定ボタン

	UIPopoverController		*popoverCntlSetAge;		// 年齢設定用ポップアップコントローラ
    NSString                *preAge;                // ポップアップ呼び出し前に保持している年齢
    BOOL                    isNavigationCall;       // 呼び出し元の種類
    id                      tempView;               // 呼び出し元のview
    UIPopoverController     *popoverCntlSelSwimmy;  // 施術前後画像選択ポップアップ
    BOOL                    isBefore;               // 施術前後写真のどちらを選択中か
    NSInteger               beforeNum;              // 施術前写真の施術回数
    NSInteger               afterNum;               // 施術後写真の施術回数
    BOOL                    lockFlag;
    
    IBOutlet UILabel        *lblTitle;              // タイトルラベル
    IBOutlet UILabel        *imageLabel3;
    IBOutlet UIButton       *btnCancel;             // キャンセルボタン
    IBOutlet UILabel        *lblBeforeView;         // 施術前ポップアップ表示起点
    IBOutlet UILabel        *lblAfterView;          // 施術後ポップアップ表示起点
    
    selectSwimmyPicture     *vcSelSwimmy;           // Swimmy送信写真選択ポップアップ
    AgePickerPopUp          *vcSetAge;              // Swimmy送信年齢選択ポップアップ
}

@property(nonatomic)        USERID_INT selectUserID;

- (IBAction)OnCancelBtn:(id)sender;     // 送信取り消し
- (IBAction)doMailsend:(id)sender;      // メール送信
- (IBAction)OnSetAge:(id)sender;        // 年齢設定
- (IBAction)OnBefore:(id)sender;        // 施術前画像選択ボタン
- (IBAction)OnAfter:(id)sender;         // 施術後画像選択ボタン

- (void) OnSetComparePicture:(BOOL)before;

@property BOOL beforeSelect;
@property (retain, nonatomic) IBOutlet UIButton *MailSend;
@property (retain, nonatomic) IBOutlet UIScrollView *myScrollView;  // 添付Before画像View
@property (retain, nonatomic) IBOutlet UIScrollView *myScrollView2; // 添付After画像View
@property (retain, nonatomic) IBOutlet UITextView *emailText;       // メール本文
@property (retain, nonatomic) IBOutlet UILabel *imageLabel1;        // 添付画像
@property (retain, nonatomic) IBOutlet UILabel *imageLabel2;        // 添付画像枚数
@property (retain, nonatomic) IBOutlet UILabel *sexLabel;                   // 性別
@property (retain, nonatomic) IBOutlet UISegmentedControl *sexSegmentCtrl;
@property (retain, nonatomic) IBOutlet UILabel *treatmentLabel;     // 施行回数
@property (retain, nonatomic) IBOutlet UITextField *treatmentField;
@property (retain, nonatomic) IBOutlet UILabel *treatmentCntLabel;
@property (retain, nonatomic) IBOutlet UISwitch *treatmentNo1;      // 美健
@property (retain, nonatomic) IBOutlet UISwitch *treatmentNo2;      // 美骨
@property (retain, nonatomic) IBOutlet UISwitch *treatmentNo3;      // 美脚
@property (retain, nonatomic) IBOutlet UISwitch *treatmentNo4;      // その他
@property (retain, nonatomic) IBOutlet UITextField *beforeTreatField;   // 施術前画像、施術回数
@property (retain, nonatomic) IBOutlet UITextField *afterTreatField;    // 施術後画像、施術回数


- (id) initWithSwimmySetting:(NSMutableArray *)pictImageItems
                selectUserID:(USERID_INT)userID                  // アカウントID
                     popUpID:(NSUInteger)popUpID
                isNavigation:(BOOL)isNavigation                 // 呼び出し元の種別
                   superView:(id)superView                      // 呼び出し元のview
                    callBack:(id)callBack;                      // delegate用

// Swimmy画像設定
- (void)OnSelectComparePictureSet:(NSMutableArray *)view;

@end
