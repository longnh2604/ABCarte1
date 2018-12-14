//
//  NumberInputPopUp.m
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "NumberInputPopUp.h"
#import "Common.h"

@implementation NumberInputPopUp

@synthesize editNumber;
@synthesize editEntry;
@synthesize strUnit;

#pragma mark PopUpViewContollerBase_override

/** delegate objectの設定:設定ボタンのclick時にコールされる
 * @param       なし
 * @return      UIButton* 変更情報を内包したUIButton
 */

- (id) setDelegateObject
{
    if (IntMode) {
        editNumber = [NSString stringWithFormat:@"%d",[editNumber intValue]];

    }else {
        if ([editNumber floatValue] > maxNum) {
            editNumber = [NSString stringWithFormat:@"%3.1f",maxNum];
            lblNumber.text = editNumber;
        }
        if ([editNumber floatValue] < minNum) {
            editNumber = [NSString stringWithFormat:@"%3.1f",minNum];
            lblNumber.text = editNumber;
        }
    }
    [editButton setTitle:editNumber forState:UIControlStateNormal];
    [editButton setTitle:editNumber forState:UIControlStateHighlighted];
    [editButton setTitle:editNumber forState:UIControlStateDisabled];


    return editButton ;
}

- (id)initWithButton:(UIButton *)selectButton
           selectNum:(CGFloat)selectNum
             popUpID:(NSUInteger)popUpID
            callBack:(id)callBackDelegate{
    
    if (self = [super initWithPopUpViewContoller:popUpID
                           popOverController:nil
                                    callBack:callBackDelegate
                                     nibName:@"numberInputPopup"])
    {
        self.contentSizeForViewInPopover = CGSizeMake(277.0f, 331.0f);
        [self setButtonStates:selectButton selectNum:selectNum];

        IntMode = NO;
    }
    return (self);
}

- (id)initWithIntButton:(UIButton *)selectButton
           selectNum:(NSInteger)selectNum
             popUpID:(NSUInteger)popUpID
            callBack:(id)callBackDelegate{
    if (self = [super initWithPopUpViewContoller:popUpID
                               popOverController:nil
                                        callBack:callBackDelegate
                                         nibName:@"numberInputPopup"])
    {
        self.contentSizeForViewInPopover = CGSizeMake(277.0f, 331.0f);
        [self setButtonStatesInteger:selectButton selectNum:selectNum];
        IntMode = YES;
    }
    return (self);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    // titleの角を丸める
	[Common cornerRadius4Control:lblTitle];
    [lblTitle setText:[NSString stringWithFormat:@"%@の値を入力",self.editEntry]];

    lblNumber.userInteractionEnabled = NO;
    [lblNumber setText:[NSString stringWithFormat:@"%@",self.editNumber]];
    [lblUnit setText:strUnit];
    didInput = NO;
    if(IntMode){
        comma.hidden = YES;

    }else {
        comma.hidden = NO;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//入力されたボタンのステータス読み取り
-(void)setButtonStatesInteger:(UIButton *)selectBtn
             selectNum:(NSInteger)selectNum{
    editButton = selectBtn;
    self.editNumber = [NSString stringWithFormat:@"%d", selectNum];
    self.editEntry = @"個数";
    self.strUnit = @"個";
    maxNum = 10;
    minNum = 0;
    return;

}
-(void)setButtonStates:(UIButton *)selectBtn
             selectNum:(CGFloat)selectNum{
    editButton = selectBtn;
    self.editNumber = [NSString stringWithFormat:@"%3.1f", selectNum];
    self.strUnit = @"cm";
    //2016/4/12 TMS サイズ上下限対応
    switch (selectBtn.tag % 100) {
        case BTN_HEIGHT:
            self.editEntry = @"身長";
            maxNum = 250.0f;
            minNum = 100.0f;
            break;
        case BTN_WEIGHT:
            self.editEntry = @"体重";
            self.strUnit = @"kg";
            maxNum = 155.0f;
            minNum = 0.0f;
            break;
        case BTN_TOPBREAST:
            self.editEntry = @"トップバスト";
            maxNum = 165.0f;
            minNum = 53.0f;
            break;
        case BTN_UNDERBREAST:
            self.editEntry = @"アンダーバスト";
            maxNum = 140.0f;
            minNum = 43.0f;
            break;
        case BTN_WAIST:
            self.editEntry = @"ウエスト";
            maxNum = 156.0f;
            minNum = 37.0f;
            break;
        case BTN_HIP:
            self.editEntry = @"ヒップ周り";
            maxNum = 150.0f;
            minNum = 55.0f;
            break;
        case BTN_THIGH:
            self.editEntry = @"太もも";
            maxNum = 95.0f;
            minNum = 31.0f;
            break;
        case BTN_HIPHEIGHT:
            self.editEntry = @"ヒップ高";
            maxNum = 140.0f;
            minNum = 52.0f;
            break;
        case BTN_WAISTHEIGHT:
            self.editEntry = @"ウエスト高";
            maxNum = 160.0f;
            minNum = 60.0f;
            break;
        case BTN_TOPBREASTHEIGHT:
            self.editEntry = @"トップバスト高";
            maxNum = 190.0f;
            minNum = 72.0f;
            break;
    }
    if (selectBtn.tag >= 100) {
        self.editEntry = [NSString stringWithFormat:@"着衣時の%@",self.editEntry];
    }
}

-(IBAction)OnNumButton:(id)sender{
    if (!didInput) {
        //初めての入力の場合、現在値を空に
        self.editNumber = @"";
        didInput = YES;
    }
    //数値が0の場合は空白に
    if ([self.editNumber isEqualToString:@"0.0"] || [self.editNumber isEqualToString:@"0"]) {
        self.editNumber = @"";
    }
    
    if (IntMode) {
        UIButton *addNumBtn = (UIButton *)sender;
        self.editNumber = [self.editNumber stringByAppendingString:addNumBtn.currentTitle];
        //10以上の数字は計測対象外のため、10にあわせる
        if([self.editNumber floatValue] > 10){
            self.editNumber = @"10";
        }
    }else {
        //カンマなしは3文字、カンマありは5文字まで入力可能。ただしカンマの下は1桁まで
        if (([self.editNumber length] >= 5 ) ||
            ([self.editNumber length] >= 3 && (NSNotFound == [self.editNumber rangeOfString:@"."].location)) ||
            (![self.editNumber hasSuffix:@"."] && (NSNotFound != [self.editNumber rangeOfString:@"."].location)))
        {return;}
        UIButton *addNumBtn = (UIButton *)sender;
        self.editNumber = [self.editNumber stringByAppendingString:addNumBtn.currentTitle];
        //200以上の数字は計測対象外のため、200にあわせる
        if([self.editNumber floatValue] > 250){
            self.editNumber = @"250";
        }
    }
    lblNumber.text = [NSString stringWithFormat:@"%@",self.editNumber];
}

-(IBAction)OnCommaButton:(id)sender{
    //数字が0の場合カンマは打てない,初めての入力の場合、現在値を空に
    if ([self.editNumber isEqualToString:@"0.0"] || [self.editNumber isEqualToString:@"0"] || ([self.editNumber length] == 0 || !didInput)) {
        self.editNumber = @"";
        lblNumber.text = [NSString stringWithFormat:@"%@",self.editNumber];
        return;
    }
    //カンマは一つまで
    if (NSNotFound != [self.editNumber rangeOfString:@"."].location) {
        return;
    }
    self.editNumber = [self.editNumber stringByAppendingFormat:@"."];
    lblNumber.text = [NSString stringWithFormat:@"%@",self.editNumber];
}

-(IBAction)OnBackSpace:(id)sender{
    if (!didInput) {
        //初めての入力の場合、現在値を空に
        self.editNumber = @"";
        didInput = YES;
    }
    //一文字以上ある場合は末尾を、それ以外は空白にする
    if ([self.editNumber length] > 1 && ![self.editNumber isEqualToString:@"0.0"]) {
        self.editNumber = [self.editNumber substringToIndex:([self.editNumber length]) - 1];
        if([self.editNumber hasSuffix:@"."]){
            //削除により末尾がカンマになった場合、それも削除s
            self.editNumber = [self.editNumber substringToIndex:([self.editNumber length]) - 1];
        }
    }else {
        self.editNumber = @"";
    }
    lblNumber.text = [NSString stringWithFormat:@"%@",self.editNumber];
}

@end
