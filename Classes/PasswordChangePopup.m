//
//  PasswordChangePopup.m
//  iPadCamera
//
//  Created by MacBook on 11/07/14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PasswordChangePopup.h"

#import "Common.h"

@implementation PasswordChangePopup

#pragma mark life_cycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// titleの角を丸める
	[Common cornerRadius4Control:lblTitle];
	
	// キーボードの表示
	[txtOldPassword becomeFirstResponder];

    [btnOK setBackgroundColor:[UIColor whiteColor]];
    [[btnOK layer] setCornerRadius:6.0];
    [btnOK setClipsToBounds:YES];
    [[btnOK layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnOK layer] setBorderWidth:1.0];
    
    [btnCancel setBackgroundColor:[UIColor whiteColor]];
    [[btnCancel layer] setCornerRadius:6.0];
    [btnCancel setClipsToBounds:YES];
    [[btnCancel layer] setBorderColor:[[UIColor colorWithRed:0.863 green:0.078 blue:0.235 alpha:1.0] CGColor]];
    [[btnCancel layer] setBorderWidth:1.0];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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


#pragma mark text_field_events

// 編集開始
// - (IBOutlet) onTextEditBegin:(id)sender;

// 文字列変更 
- (IBAction) onChangeText:(id)sender
{
	// １文字でも入力されればOKボタンを有効にする
	btnOK.enabled 
		= ( ([txtOldPassword.text length] > 0) &&
		    ([txtNewPassword1.text length] > 0) &&
		   ([txtNewPassword2.text length] > 0) );
}

// 編集終了
- (IBAction) onTextDidEnd:(id)sender
{
	
}

// リターンキー
- (IBAction) onTextDidEndOnExit:(id)sender
{
	UITextField *textField = (UITextField*)sender;
	
	switch (textField.tag) {
		case 1:
			// 旧パスワード
			if ([textField.text length] > 0) {
				[txtNewPassword1 becomeFirstResponder];
			}
			break;
		case 2:
			// 新パスワード
			if ([textField.text length] > 0) {
				[txtNewPassword2 becomeFirstResponder];
			}
			break;
		case 3:
			//  新パスワード（確認用）
			
			// キーボードを閉じる
			[ ((UITextField*)sender) resignFirstResponder];
			
			// OKボタンの押下と同様とする
			if ( btnOK.enabled)
			{
				[self onOkButton:btnOK];
			}
			break;
			
		default:
			break;
	}
	
	}

#pragma mark button_events
// OKボタン
- (IBAction) onOkButton:(id)sender
{
	if (! [txtNewPassword1.text isEqualToString:txtNewPassword2.text])
	{
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:@"パスワードの変更"
								  message:@"確認用に入力した新パスワードと\n先の新パスワードが異なります"
								  delegate:nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil
								  ];
		[alertView show];
		[alertView release];
		
		[txtNewPassword1 becomeFirstResponder];
	}
	else 
	{
		[self OnSetButton:btnOK];
	}

}

#pragma mark override

// delegate objectの設定:設定ボタンのclick時にコールされる
- (id) setDelegateObject
{
	// 旧パスワードと新パスワードを配列にして返す
	return ([NSArray arrayWithObjects:
			 txtOldPassword.text, txtNewPassword1.text, nil]);
}	

#pragma mark public_methods

@end
