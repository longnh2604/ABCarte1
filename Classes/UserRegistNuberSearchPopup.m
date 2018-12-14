//
//  UserRegistNuberSearchPopup.m
//  iPadCamera
//
//  Created by MacBook on 11/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "defines.h"
#import "Common.h"

#import "UserRegistNuberSearchPopup.h"

///
/// お客様番号による検索用ポップアップ
///
@implementation UserRegistNuberSearchPopup

#pragma mark local_methods

#pragma mark life_cycle

// お客様番号による検索用PopUpの作成
//		LastRegistNumber:前回検索で使用した番号（REGIST_NUMBER_INVALIDで無効）
- (id) initWithLastRegNumPopUpViewContoller:(NSUInteger)popUpID 
						  popOverController:(UIPopoverController*)controller callBack:(id)callBackDelegate
						   LastRegistNumber:(NSInteger)lastNum
{
#ifdef CALULU_IPHONE
	if (self = [super initWithPopUpViewContoller:popUpID
							   popOverController:controller
										callBack:callBackDelegate nibName:@"ip_UserRegistNuberSearchPopup"] )
#else
    if (self = [super initWithPopUpViewContoller:popUpID
                               popOverController:controller
                                        callBack:callBackDelegate] )
#endif
	{
		_lastRegistNumber = lastNum;
		
		self.contentSizeForViewInPopover = CGSizeMake(332.0f, 240.0f);
	}
	
	return (self);
}

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// 前回、入力値をTextFieldに設定
	txtUserRegistNumber.text = 
		(_lastRegistNumber != REGIST_NUMBER_INVALID)? 
			([NSString stringWithFormat:@"%ld", (long)_lastRegistNumber] ): @"";
	
	// タイトルの角を丸める
	[Common cornerRadius4Control:lblDialogTitle];
	
	// お客様番号の入力をコントロールする
	txtUserRegistNumber.delegate = self;
	
	// お客様番号TextFieldにフォーカスする（キーボード表示）
	[txtUserRegistNumber becomeFirstResponder];
    
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

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [btnCancel release];
    btnCancel = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [btnCancel release];
    [super dealloc];
}

#pragma mark control_events

// TextFieldのText変更ベント
- (IBAction)onTextChanged:(id)sender
{
	UITextField *textField = (UITextField*)sender;
	
	BOOL stat= ([textField.text length] > 0);
	
	if (btnSet.enabled != stat)
	{	btnSet.enabled = stat; }
}

// TextFieldのEnterキーイベント
- (IBAction)onTextDidEnd:(id)sender
{
	UITextField *textField = (UITextField*)sender;
	
	// キーボードを隠す
	[textField resignFirstResponder];
	
}

#pragma mark public_methods

- (BOOL)textField:(UITextField *)textField 
			shouldChangeCharactersInRange:(NSRange)range 
						replacementString:(NSString *)string
{
	// お客様番号専用:念のため
	if (textField != txtUserRegistNumber)
	{	return (NO); }
	
	// 数値入力TextFieldの入力文字種別と文字数を制限する
	BOOL stat = ([Common checkNumericInputTextLengh:textField inRange:range 
								  replacementString:string
										  maxLength:REGIST_NUMBER_LENGTH]);
	
	return (stat);
}

#pragma mark PopUpViewContollerBase_override

// delegate objectの設定:設定ボタンのclick時にコールされるs
- (id) setDelegateObject
{
	// 入力されたTextを返す
	return (txtUserRegistNumber.text);
}	
@end
