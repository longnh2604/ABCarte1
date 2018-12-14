//
//  PasswordInputPopup.m
//  iPadCamera
//
//  Created by MacBook on 11/07/14.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PasswordInputPopup.h"


@implementation PasswordInputPopup


#pragma mark life_cycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// titleの角を丸める
	[Common cornerRadius4Control:lblTitle];
    
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

- (void)viewDidAppear:(BOOL)animated
{
	// キーボードの表示
	[txtPassword becomeFirstResponder];
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
/*
- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	
}
*/

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
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
	btnOK.enabled = ([txtPassword.text length] > 0);
}

// 編集終了
- (IBAction) onTextDidEnd:(id)sender
{
	
}

// リターンキー
- (IBAction) onTextDidEndOnExit:(id)sender
{
	// キーボードを閉じる
	[ ((UITextField*)sender) resignFirstResponder];
	
	// OKボタンの押下と同様とする
	if ( btnOK.enabled)
	{
		[self OnSetButton:btnOK];
	}
}

#pragma mark button_events

// パスワードの変更ボタン
- (IBAction) onPasswordChanged:(id)sender
{
	// パスワード文字を空にしてOKボタンの押下と同様とする
	txtPassword.text = @"";
	[self OnSetButton:btnOK];
}

#pragma mark override

// delegate objectの設定:設定ボタンのclick時にコールされるs
- (id) setDelegateObject
{
	// パスワード入力された文字を返す
	return (txtPassword.text);
}	

#pragma mark public_methods


- (void)viewDidUnload {
[btnCancel release];
btnCancel = nil;
[super viewDidUnload];
}
@end
