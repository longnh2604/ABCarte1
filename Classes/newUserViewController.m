//
//  newUserViewController.m
//  iPadCamera
//
//  Created by MacBook on 10/10/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "newUserViewController.h"
#import "mstUser.h"

@implementation newUserViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Titleの角を丸くする
	CALayer *layer = [lblTitle layer];
	[layer setMasksToBounds:YES];
	[layer setCornerRadius:12.0f];
	
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

// 各TextFieldのEnterキーイベント
- (IBAction)onTextDidEnd:(id)sender
{
	UITextField *textField = (UITextField*)sender;
	
	switch (textField.tag) {
		case 0:
			if ([textField.text length] > 0) {
				//if ([txtSecondName resignFirstResponder]) 
				{
					// OKならフォーカスをあてる
					[txtSecondName becomeFirstResponder];
				}
			}
			break;
		case 1:
			//if ([txtFirstNameCana resignFirstResponder]) 
			{
				// OKならフォーカスをあてる
				[txtFirstNameCana becomeFirstResponder];
			}
			break;
		case 2:
			if ([textField.text length] > 0) {
				//if ([txtSecondNameCana resignFirstResponder]) 
				{
					// OKならフォーカスをあてる
					[txtSecondNameCana becomeFirstResponder];
				}
				
				// ひらがなのかなの入力で登録ボタンを有効にする
				btnRegist.enabled = YES;
			}
			break;
		case 3:
			// キーボードを隠す
			[textField resignFirstResponder];
			break;

		default:
			break;
	}
}

#pragma mark - override_methods

// delegate objectの設定:設定ボタンのclick時にsetDelegateObjectの前にコールされる
// NOを返すとイベントを中止する
//    remark : このメソッドにて設定値の検証を行い、ダイアログを表示する
//             デフォルトはYESを返す
- (BOOL) preProcessValidate
{
    BOOL stat = YES;
    
    if ( ([txtFirstName.text length] <= 0) ||
        ([txtFirstNameCana.text length] <= 0) )
	{
		// 姓の入力は必須とする
		[self alertViewSwow:@"姓は必ず入力してください"];
		stat = NO;
	}
    return (stat);
}

// delegate objectの設定:設定ボタンのclick時にコールされるs
- (id) setDelegateObject
{
#ifdef VER130_LATER
	if ( ([txtFirstName.text length] <= 0) ||
		 ([txtFirstNameCana.text length] <= 0) )
	{
		// 姓の入力は必須とする
		[self alertViewSwow:@"姓は必ず入力してください"];
		return (nil);
	}
#endif
	
	mstUser *user = [[mstUser alloc] initWithNewUser:
					  txtFirstName.text 
						secondName:txtSecondName.text 
						firstNameCana:txtFirstNameCana.text 
						secondNameCana:txtSecondNameCana.text
						registNumber:@"-1"
						sex:(segSex.selectedSegmentIndex != 0)? Lady : Men];
	[user autorelease];
	
	return (user);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
