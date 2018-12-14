    //
//  PopUpViewContollerBase.m
//  iPadCamera
//
//  Created by MacBook on 10/10/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PopUpViewContollerBase.h"

#import "MainViewController.h"

@implementation PopUpViewContollerBase

@synthesize popoverController;
@synthesize delegate;

- (id) initWithPopUpID:(NSUInteger)popUpID
{
	if (self == [super init])
	{
		_popUpID = popUpID;
	}
	
	return (self);
}

- (id) initWithPopUpViewContoller:(NSUInteger)popUpID 
				popOverController:(UIPopoverController*)controller callBack:(id)callBackDelegate
                          nibName:(NSString*)nibName
{
	if (self = [super initWithNibName:nibName bundle:nil])
	{
		_popUpID = popUpID;
		popoverController = controller;
		delegate = callBackDelegate;
	}
	
	return (self);
}

- (id) initWithPopUpViewContoller:(NSUInteger)popUpID 
				popOverController:(UIPopoverController*)controller callBack:(id)callBackDelegate
{
	if (self = [super init])
	{
		_popUpID = popUpID;
		popoverController = controller;
		delegate = callBackDelegate;
	}
	
	return (self);
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

#pragma mark - override_methods

// delegate objectの設定:設定ボタンのclick時にsetDelegateObjectの前にコールされる
// NOを返すとイベントを中止する
//    remark : このメソッドにて設定値の検証を行い、ダイアログを表示する
//             デフォルトはYESを返す
- (BOOL) preProcessValidate
{
    return (YES);
}

// delegate objectの設定
- (id) setDelegateObject
{
	return (nil);
}

// 設定ボタンクリック
- (IBAction) OnSetButton:(id)sender
{
    if (! [self preProcessValidate])
    {
        return;
    }
    
    // viewControllerを閉じる  2012/09/21
    [self closeByPopoverContoller];
    
	if (delegate != nil) 
	{
		// callback Objectの設定 : nilでイベント中断
		if ( (_delegateObject = [self setDelegateObject]) == nil)
		{	return; }
		
		// クライアントクラスへcallback
		[delegate OnPopUpViewSet:_popUpID setObject:_delegateObject];

		// クライアントクラスへCallback
		if ( [delegate respondsToSelector:@selector(OnPopupViewFinished:setObject:Sender:)] == YES )
		{
			[delegate OnPopupViewFinished:_popUpID setObject:_delegateObject Sender:self];
		}
	}
	
	// [self closeByPopoverContoller];
}

// キャンセルボタンクリック
- (IBAction) OnCancelButton:(id)sender
{
	[self closeByPopoverContoller];
}

// このViewContlloerを閉じる
- (void) closeByPopoverContoller
{
#ifndef CALULU_IPHONE
	if (popoverController)
	{
		[popoverController dismissPopoverAnimated:YES];
	}
#else
    // 下表示modalDialogを閉じる
    [MainViewController closeBottomModalDialog];
#endif
}

// alertの表示
- (void)alertViewSwow:(NSString*)message
{
	UIAlertView *alertView 
		= [[UIAlertView alloc] initWithTitle:
				@"設定内容が正しくありません"
				message:message
				delegate:nil
				cancelButtonTitle:@"OK"
				otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

// Override to allow orientations other than the default portrait orientation.
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//    // Return YES for supported orientations
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
//}

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

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    return NO;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    
}


@end
