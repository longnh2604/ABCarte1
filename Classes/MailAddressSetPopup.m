//
//  MailAddressSetPopup.m
//  iPadCamera
//
//  Created by MacBook on 11/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MailAddressSetPopup.h"

///
/// メールアドレス設定PopupViewControllerクラス
///
@implementation MailAddressSetPopup

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

// 初期化 :
- (id) initPopUpViewWithPopupID:(NSUInteger)popUpID
					mailAddress:(NSString*)address
			  popOverController:(UIPopoverController*)controller 
					   callBack:(id)callBackDelegate
{
#ifdef CALULU_IPHONE
    if ( (self = [super initWithPopUpViewContoller:popUpID 
                                 popOverController:controller 
                                          callBack:callBackDelegate nibName:@"ip_MailAddressSetPopup"]) )
#else
   	if ( (self = [super initWithPopUpViewContoller:popUpID 
                                 popOverController:controller 
                                          callBack:callBackDelegate]) )
#endif
	{
		_mailAddress 
			= (address)? [address mutableCopy] : [[NSString alloc]initWithString:@""];
	}
	
	return (self);
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	[super viewDidLoad];
 
	// titleの角を丸める
	[Common cornerRadius4Control:lblTitle];
	
	txtMailAddress.text = _mailAddress;
}
 
- (void)viewDidAppear:(BOOL)animated
{
	// キーボードの表示
	[txtMailAddress becomeFirstResponder];
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    
	[_mailAddress release];
	
	[super dealloc];
}

#pragma mark text_field_events

// 編集開始
// - (IBOutlet) onTextEditBegin:(id)sender;

// 文字列変更 
- (IBAction) onChangeText:(id)sender
{
	// ３文字以上入力されていて、@がふくまれていればOKボタンを有効にする
	BOOL isOK = NO;
	if([txtMailAddress.text length] > 3)
	{
		NSRange range = [txtMailAddress.text rangeOfString:@"@"];
		if (range.location != NSNotFound)
		{	isOK = YES; }
	}
	
	btnOK.enabled = isOK;
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


#pragma mark override

// delegate objectの設定:設定ボタンのclick時にコールされるs
- (id) setDelegateObject
{
	// パスワード入力された文字を返す
	return (txtMailAddress.text);
}	

#pragma mark public_methods


@end
