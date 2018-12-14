//
//  BloodGroupPopUp.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/07/17.
//
//

#import "BloodGroupPopUp.h"

@interface BloodGroupPopUp ()

@end

@implementation BloodGroupPopUp

@synthesize myDelegate,btnSet,btnCancel,segBloodType;

#pragma mark life_cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

/**
 * 初期化(血液型と共に)
 */
- (id)initWithBloodTypePopUpViewContoller:(NSUInteger)popUpID
                        popOverController:(UIPopoverController *)controller
                                 callBack:(id)callBackDelegate
                                bloodType:(NSInteger)bloodType
{
    if(self = [super initWithPopUpViewContoller:popUpID
                              popOverController:nil
                                       callBack:callBackDelegate
                                        nibName:@"BloodGroupPopUp"]) {
        myDelegate = callBackDelegate;
        _bloodType = bloodType;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion>=7.0f) {
        [segBloodType setBackgroundColor:[UIColor whiteColor]];
        [[segBloodType layer] setCornerRadius:5.0];
        [segBloodType setClipsToBounds:YES];
        [[segBloodType layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        //        [[segBloodType layer] setBorderWidth:1.0];
        
        [btnSet setBackgroundColor:[UIColor whiteColor]];
        [[btnSet layer] setCornerRadius:6.0];
        [btnSet setClipsToBounds:YES];
        [[btnSet layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[btnSet layer] setBorderWidth:1.0];

        [btnCancel setBackgroundColor:[UIColor whiteColor]];
        [[btnCancel layer] setCornerRadius:6.0];
        [btnCancel setClipsToBounds:YES];
        [[btnCancel layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[btnCancel layer] setBorderWidth:1.0];
    }
    
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    NSString *language = [df stringForKey:@"CUSTOMER_COUNTRY"];
    if ([language isEqualToString:@"en"]) {
        [btnSet setTitle:@"Confirm" forState:UIControlStateNormal];
        [btnCancel setTitle:@"Cancel" forState:UIControlStateNormal];
        [segBloodType setTitle:@"Unknown" forSegmentAtIndex:4];
    }
    if ([language isEqualToString:@"ja"]) {
        [btnSet setTitle:@"設　定" forState:UIControlStateNormal];
        [btnCancel setTitle:@"取　消" forState:UIControlStateNormal];
        [segBloodType setTitle:@"不明" forSegmentAtIndex:4];
    }

    segBloodType.selectedSegmentIndex = _bloodType;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [segBloodType release];
    [btnSet release];
    [btnCancel release];
    [super dealloc];
}
- (void)viewDidUnload {
    [segBloodType release];
    segBloodType = nil;
    [btnSet release];
    btnSet = nil;
    [btnCancel release];
    btnCancel = nil;
    [super viewDidUnload];
}

#pragma mark ButtonAction

// 取消ボタン
- (IBAction)OnCancel:(id)sender {
    [self closeByPopoverContoller];
}

// 設定ボタン
- (IBAction)OnSet:(id)sender {
    if ([self.myDelegate respondsToSelector:@selector(OnBloodSetOK:)]) {
        [self.myDelegate OnBloodSetOK:segBloodType.selectedSegmentIndex];
    }
    
    [self closeByPopoverContoller];
}

@end
