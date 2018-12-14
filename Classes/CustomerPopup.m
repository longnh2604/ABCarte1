//
//  CustomerPopup.m
//  iPadCamera
//
//  Created by Long on 2018/03/16.
//

#import "CustomerPopup.h"

@interface CustomerPopup ()

@end

@implementation CustomerPopup

- (instancetype)init
{
    self = [super initWithNibName:@"CustomerPopup" bundle:nil];
    if (self != nil)
    {
        // Further initialization if needed
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupUI];
}

#pragma mark - Config

-(void) setupUI
{
    //scrollview
    _scrollView.delegate = self;
    self.heightView.constant = 650;
    
    _tvMemo.layer.cornerRadius = 5;
    _tvMemo.clipsToBounds = true;
    _tvMemo.layer.borderWidth = 1.0;
    _tvMemo.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    
    _btnConfirm.layer.cornerRadius = 10;
    _btnConfirm.clipsToBounds = true;
    
    _lblTitle.layer.cornerRadius = 10;
    _lblTitle.clipsToBounds = true;
}

- (void)dealloc {
    [_scrollView release];
    [_heightView release];
    [_tfFirstName release];
    [_tfLastName release];
    [_tfBirthday release];
    [_tfGenre release];
    [_tfBloodType release];
    [_tfCustomerNo release];
    [_tfPersonInCharge release];
    [_tfAddress release];
    [_tfMobile release];
    [_tfPhone release];
    [_tfHobby release];
    [_tfMail release];
    [_btnConfirm release];
    [_lblTitle release];
    [super dealloc];
}
- (IBAction)onConfirm:(UIButton *)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
