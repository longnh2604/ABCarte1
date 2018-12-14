//
//  iPad2CameraSettingPopup.m
//  iPadCamera
//
//  Created by MacBook on 11/05/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Common.h"

#import "iPad2CameraSettingPopup.h"

///
/// iPad内蔵カメラの設定用popupコントローラ
///
@implementation iPad2CameraSettingPopup

@synthesize isHandVib;
@synthesize delayTime;
@synthesize captureSpeed;

#pragma mark local_methods

#pragma mark life_cycle

// 初期化
- (id) initWithSetParams:(NSUInteger)popUpID 
	   popOverController:(UIPopoverController*)controller 
				callBack:(id)callBackDelegate
			   isHandVid:(BOOL)handVid 
			   delayTime:(NSInteger)time 
			captureSpeed:(IPAD2_CAM_SET_CAPTURE_SPEED)speed
{
#ifndef CALULU_IPHONE
	if (self = [super initWithPopUpViewContoller:popUpID
							   popOverController:controller
										callBack:callBackDelegate] )
#else
   	if (self = [super initWithPopUpViewContoller:popUpID
                               popOverController:controller
                                        callBack:callBackDelegate 
                                         nibName:@"ip_iPad2CameraSettingPopup"])
#endif
	{
		self.isHandVib = handVid;
		self.delayTime = time;
		self.captureSpeed = speed;
		
		// self.contentSizeForViewInPopover = CGSizeMake(384.0f, 250.0f);
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
	
	// Titleの角を丸くする
	[Common cornerRadius4Control:lblTitle];
	
	// プロパティの値をコントロールに設定する
	[swIsHandVib setOn:self.isHandVib animated:NO];
	txtDelayTime.text = [NSString stringWithFormat:@"%ld", (long)self.delayTime];
	NSInteger idx;
	switch (self.captureSpeed) {
		case IPAD2_CAM_CAPTURE_LOW:
			idx = 0;
			break;
		case IPAD2_CAM_CAPTURE_MIDDLE:
			idx = 1;
			break;
		case IPAD2_CAM_CAPTURE_HIGH:
			idx = 2;
			break;
		default:
			idx = 1;
			break;
	}
	segCapSpeed.selectedSegmentIndex = idx;
    
    [btnOk setBackgroundColor:[UIColor whiteColor]];
    [[btnOk layer] setCornerRadius:6.0];
    [btnOk setClipsToBounds:YES];
    [[btnOk layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnOk layer] setBorderWidth:1.0];

    [btnCancel setBackgroundColor:[UIColor whiteColor]];
    [[btnCancel layer] setCornerRadius:6.0];
    [btnCancel setClipsToBounds:YES];
    [[btnCancel layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnCancel layer] setBorderWidth:1.0];
    
#ifdef CALULU_IPHONE
    // キーボードを隠す(for iPhone)
	UITapGestureRecognizer *tapGesture 
        = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(OnHideKeyBord)];
	tapGesture.numberOfTouchesRequired = 2;		// 指２本
	[self.view addGestureRecognizer:tapGesture];
	[tapGesture release];
#endif
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [btnCancel release];
    btnCancel = nil;
    [btnOk release];
    btnOk = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [btnCancel release];
    [btnOk release];
    [super dealloc];
}

#pragma mark control_events

// 手ぶれ補正の有効／無効
- (IBAction)onIshancVid:(id)sender
{
	txtDelayTime.enabled = swIsHandVib.on;
}

// 手ぶれ補正速度TextFieldのEnterキーイベント
- (IBAction)onTextDidEnd:(id)sender
{
	// キーボードを隠す
	[txtDelayTime resignFirstResponder];
}

#ifdef CALULU_IPHONE
- (void) OnHideKeyBord
{
    [txtDelayTime resignFirstResponder];
}
#endif

#pragma mark override

// delegate objectの設定:設定ボタンのclick時にコールされるs
- (id) setDelegateObject
{
	// コントロールの値をプロパティの設定する
	self.isHandVib = swIsHandVib.on;
	self.delayTime = [txtDelayTime.text intValue];
	switch (segCapSpeed.selectedSegmentIndex) {
		case 0:
			self.captureSpeed = IPAD2_CAM_CAPTURE_LOW;
			break;
		case 1:
			self.captureSpeed = IPAD2_CAM_CAPTURE_MIDDLE;
			break;
		case 2:
			self.captureSpeed = IPAD2_CAM_CAPTURE_HIGH;
			break;
		default:
			break;
	}
	
	// 本インスタンスを返す
	return (self);
}

@end
