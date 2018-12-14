//
//  CustomerPopup.h
//  iPadCamera
//
//  Created by Long on 2018/03/16.
//

#import <UIKit/UIKit.h>

@interface CustomerPopup : UIViewController<UIScrollViewDelegate,UITextFieldDelegate>

@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *heightView;
@property (retain, nonatomic) IBOutlet UILabel *lblTitle;

@property (retain, nonatomic) IBOutlet UITextField *tfFirstName;
@property (retain, nonatomic) IBOutlet UITextField *tfLastName;
@property (retain, nonatomic) IBOutlet UITextField *tfBirthday;
@property (retain, nonatomic) IBOutlet UITextField *tfGenre;
@property (retain, nonatomic) IBOutlet UITextField *tfBloodType;
@property (retain, nonatomic) IBOutlet UITextField *tfCustomerNo;
@property (retain, nonatomic) IBOutlet UITextField *tfPersonInCharge;
@property (retain, nonatomic) IBOutlet UITextField *tfAddress;
@property (retain, nonatomic) IBOutlet UITextField *tfMobile;
@property (retain, nonatomic) IBOutlet UITextField *tfPhone;
@property (retain, nonatomic) IBOutlet UITextField *tfHobby;
@property (retain, nonatomic) IBOutlet UITextField *tfMail;
@property (retain, nonatomic) IBOutlet UITextView *tvMemo;
@property (retain, nonatomic) IBOutlet UIButton *btnConfirm;

- (IBAction)onConfirm:(UIButton *)sender;
@end
