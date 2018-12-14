//
//  SetUpSmtpPopUp.h
//  iPadCamera
//
//  Created by GIGASJAPAN on 13/06/17.
//
//

#import <UIKit/UIKit.h>
#import "PopUpViewContollerBase.h"
#import "userFmdbManager.h"
#import "mstUserMailItemBean.h"

@interface SetUpSmtpPopUp : PopUpViewContollerBase<UITextFieldDelegate>
{
    //データベースにデータがあるかどうかのフラグ
    BOOL noDataFlag;
}
@property (retain, nonatomic) IBOutlet UITextField *senderAddr;
@property (retain, nonatomic) IBOutlet UITextField *smtpServer;
@property (retain, nonatomic) IBOutlet UITextField *smtpUser;
@property (retain, nonatomic) IBOutlet UITextField *smtpPass;
@property (retain, nonatomic) IBOutlet UITextField *smtpPort;
@property (retain, nonatomic) IBOutlet UISegmentedControl *smtpAuthSegment;

- (IBAction)OnSaveButton:(id)sender;
- (id) initWithSmtpSetting:(NSUInteger)popUpID callBack:(id)callBack;
@end
