//
//  OverlayViewSettingPopup.m
//  iPadCamera
//
//  Created by MacBook on 11/07/13.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Common.h"

#import "OverlayViewSettingPopup.h"

#import "MainViewController.h"

#import "appCapacityManager.h"
#import "AccountManager.h"

///
/// 重ね合わせ画像設定ポップアップViewController
///
@implementation OverlayViewSettingPopup

@synthesize maxRecTime = _maxRecTime;
@synthesize maxDuration = _maxDuration;
@synthesize localCapacity = _localCapacity;
@synthesize viewAlpha = _viewAlpha;
@synthesize guideLineNums = _guideLineNums;
@synthesize isWithOverlaySave = _isWithOverlaySave;
@synthesize isWithGuideSave = _isWithGuideSave;
@synthesize camResolution;
@synthesize webCamRotate = _webCamRotate;
@synthesize webCamResolution = _webCamResolution;

@synthesize popoverController;
@synthesize delegate;

#define POPUPID_GUIDELINE_NUM   0x1000
#define POPUPID_CAM_ROTATE      0x2000
#define POPUPID_CAM_RESOLUTION  0x3000

#pragma mark private_methods

// 透過率[%]の表示
- (void)dispAlphaValue
{
	// 値をラベルに表示
	lblAlphaValue.text 
		= [NSString stringWithFormat:@"%d [％]", (int)(sliderAlpha.value)];
}

- (void)dispGuideLineAlphaValue
{
    // 値をラベルに表示
    lblGuideLineValue.text
    = [NSString stringWithFormat:@"%d [％]", (int)(sliderGuideLine.value)];
}

- (void)dispTimeValue
{
    lblTimeValue.text = [NSString stringWithFormat:@"%d[秒]",(int)_maxDuration];
}
- (void)dispLocalCapacityValue
{
    lblCapacityValue.text = [NSString stringWithFormat:@"%.1f[GB]",_localCapacity];
}
- (void)dispMaxTimeValue
{
    lblMaxTimeValue.text = [NSString stringWithFormat:@"%d[秒]", (int)_maxRecTime];
}
#pragma mark life_cycle

// 初期化
- (id) initWithSetParams:(CGFloat)alpha
           guideLineNums:(NSInteger)nums
	   isWithOverlaySave:(BOOL)isWith
		 isWithGuideSave:(BOOL)isWithGuide
           camResolution:(NSInteger)resolution
                 lblText:(NSString *)lblText
                    mode:(NSInteger)mode
	   popOverController:(UIPopoverController*)controller	
		callBackDelegate:(id)callBack
{
#ifdef CALULU_IPHONE
	self = [super initWithNibName:@"ip_OverlayViewSettingPopup" bundle:nil];
#else
	self = [super initWithNibName:@"OverlayViewSettingPopup" bundle:nil];
#endif
    if (self) {
        
		_viewAlpha = alpha;
		_guideLineNums = nums;
		_isWithOverlaySave = isWith;
		_isWithGuideSave = isWithGuide;
        _lblText = lblText;
        _mode = mode;
		popoverController = controller;
		delegate = callBack;
        camResolution = resolution;
    }
    return self;	
}

- (IBAction)OnSliderMaxTimeValueChange:(id)sender {
    _maxRecTime = (int)sliderMaxTime.value;
    [self dispMaxTimeValue];

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

    // 最大録画時間を設定
    sliderMaxTime.minimumValue = 1.0f;
    sliderMaxTime.maximumValue = 30.0f;
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    _maxRecTime = [df floatForKey:@"video_max_rectime"];
    // 未設定の場合、0.00になる
    if (_maxRecTime <= 0) {
        _maxRecTime = 10.0f;
        [df setFloat:_maxRecTime forKey:@"video_max_rectime"]; // 初期値は10秒
        [df synchronize];
    }
    [self dispMaxTimeValue];
    sliderMaxTime.value = _maxRecTime;
    
    // 自動停止時間を設定
	sliderTime.minimumValue = 1.0f;
	sliderTime.maximumValue = 30.0f;
    _maxDuration = [df floatForKey:@"video_max_duration"];
    // 最大録画時間以下にする
    if (_maxDuration > _maxRecTime) {
        _maxDuration = _maxRecTime;
    }
    // 未設定の場合、0.00になる
    if (_maxDuration <= 0) {
        _maxDuration = 10.0f;
        [df setFloat:_maxDuration forKey:@"video_max_duration"]; // 初期値は10秒
        [df synchronize];
    }
    [self dispTimeValue];
    sliderTime.value = _maxDuration;
    
    // カメラ画像回転角
    _webCamRotate = [df integerForKey:@"web_cam_rotate"];
    
    // カメラ解像度
    _webCamResolution = [df integerForKey:@"web_cam_resolution"];
    
    // ローカル保存容量を設定x
    APCValueEnable valEnable = [appCapacityManager setAutoAppUsingCapacity];
	sliderCapacity.minimumValue = 1.0f;
    sliderCapacity.maximumValue = (valEnable.isEnable)?
        [appCapacityManager getDeviceStorageFreeSpace] / 1024.0f : 1.0f;
    if (sliderCapacity.maximumValue < valEnable.settingValue) {
        sliderCapacity.value = sliderCapacity.maximumValue;
    } else {
        sliderCapacity.value = valEnable.settingValue;
    }
    [self OnSliderLocalCapacityValueChange];

	// 透過度をスライダーに反映
	sliderAlpha.minimumValue = 0.0f;
	sliderAlpha.maximumValue = 100.0f;
    sliderAlpha.value = _viewAlpha * 100.0f;
	// 透過率[%]の表示
	[self dispAlphaValue];
    
    sliderGuideLine.minimumValue = 0.0f;
    sliderGuideLine.maximumValue = 100.0f;
    sliderGuideLine.value = _viewAlpha * 100.0f;
    // 透過率[%]の表示
    [self dispGuideLineAlphaValue];
	
	// ガイド線の本数をpickerに設定
	/*[pkvwGuideLineNums selectRow:_guideLineNums 
					 inComponent:0 animated:NO];*/
	
	// 重ね合わせ画像／ガイド線も一緒に保存するか？スイッチの設定
	swWithOverlaySave.on = _isWithOverlaySave;
	swWithGuideSave.on = _isWithGuideSave;
	
#ifndef CALULU_IPHONE
	// ガイド線本数にPickerViewの高さ調整 : iPadのみ有効
    /*
	CGRect rect = pkvwGuideLineNums.frame;

	pkvwGuideLineNums.frame 
		= CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 92.0f);
    [pkvwGuideLineNums setBackgroundColor:[UIColor whiteColor]];
    [[pkvwGuideLineNums layer] setCornerRadius:6.0];
    [pkvwGuideLineNums setClipsToBounds:YES];
    [[pkvwGuideLineNums layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[pkvwGuideLineNums layer] setBorderWidth:1.0];
     */
    
    [segPicResolution setBackgroundColor:[UIColor whiteColor]];
    [[segPicResolution layer] setCornerRadius:5.0];
    [segPicResolution setClipsToBounds:YES];
    [[segPicResolution layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[segPicResolution layer] setBorderWidth:1.0];
#endif
    
    [btnGuideLineNums setBackgroundColor:[UIColor whiteColor]];
    [[btnGuideLineNums layer] setCornerRadius:6.0];
    [btnGuideLineNums setClipsToBounds:YES];
    [[btnGuideLineNums layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnGuideLineNums layer] setBorderWidth:1.0];
    
    lblTitle.text = _lblText;
    CGPoint op = CGPointMake(177, 64);
    if(_mode) { // 動画
        [sliderCapacity setFrame:CGRectMake(op.x, op.y, sliderCapacity.frame.size.width, sliderCapacity.frame.size.height)];
        lblCapacityTitle.frame = CGRectMake(op.x - 159, op.y -  6, lblCapacityTitle.frame.size.width, lblCapacityTitle.frame.size.height);
        lblCapacityValue.frame = CGRectMake(op.x - 109, op.y + 13, lblCapacityValue.frame.size.width, lblCapacityValue.frame.size.height);
        op.y += 48;
        [sliderMaxTime setFrame:CGRectMake(op.x, op.y, sliderMaxTime.frame.size.width, sliderMaxTime.frame.size.height)];
        lblMaxTimeTitle.frame = CGRectMake(op.x - 159, op.y -  6, lblMaxTimeTitle.frame.size.width, lblMaxTimeTitle.frame.size.height);
        lblMaxTimeValue.frame = CGRectMake(op.x - 109, op.y + 13, lblMaxTimeValue.frame.size.width, lblMaxTimeValue.frame.size.height);
        op.y += 48;
        [sliderTime setFrame:CGRectMake(op.x, op.y, sliderTime.frame.size.width, sliderTime.frame.size.height)];
        lblTimeTitle.frame = CGRectMake(op.x - 159, op.y -  6, lblTimeTitle.frame.size.width, lblTimeTitle.frame.size.height);
        lblTimeValue.frame = CGRectMake(op.x - 109, op.y + 13, lblTimeValue.frame.size.width, lblTimeValue.frame.size.height);
        op.y += 48;
        [sliderGuideLine setFrame:CGRectMake(op.x, op.y, sliderGuideLine.frame.size.width, sliderGuideLine.frame.size.height)];
        lblGuideLine.frame = CGRectMake(op.x - 159, op.y -  6, lblGuideLine.frame.size.width, lblGuideLine.frame.size.height);
        lblGuideLineValue.frame = CGRectMake(op.x - 109, op.y + 13, lblGuideLineValue.frame.size.width, lblGuideLineValue.frame.size.height);
    } else {    // 静止画
        [sliderCapacity setFrame:CGRectMake(op.x, op.y, sliderCapacity.frame.size.width, sliderCapacity.frame.size.height)];
        lblCapacityTitle.frame = CGRectMake(op.x - 159, op.y -  6, lblCapacityTitle.frame.size.width, lblCapacityTitle.frame.size.height);
        lblCapacityValue.frame = CGRectMake(op.x - 109, op.y + 13, lblCapacityValue.frame.size.width, lblCapacityValue.frame.size.height);
        op.y += 48;
        [sliderAlpha setFrame:CGRectMake(op.x, op.y, sliderAlpha.frame.size.width, sliderAlpha.frame.size.height)];
        lblAhphaTitle.frame = CGRectMake(op.x - 159, op.y -  6, lblAhphaTitle.frame.size.width, lblAhphaTitle.frame.size.height);
        lblAlphaValue.frame = CGRectMake(op.x - 109, op.y + 13, lblAlphaValue.frame.size.width, lblAlphaValue.frame.size.height);
        op.y += 48;
        [sliderGuideLine setFrame:CGRectMake(op.x, op.y, sliderGuideLine.frame.size.width, sliderGuideLine.frame.size.height)];
        lblGuideLine.frame = CGRectMake(op.x - 159, op.y -  6, lblGuideLine.frame.size.width, lblGuideLine.frame.size.height);
        lblGuideLineValue.frame = CGRectMake(op.x - 109, op.y + 13, lblGuideLineValue.frame.size.width, lblGuideLineValue.frame.size.height);
        op.y += 48;
        [segPicResolution setFrame:CGRectMake(op.x, op.y, 187, 29)];
        lblPicResolution.frame  = CGRectMake(op.x - 159, op.y + 3, lblPicResolution.frame.size.width, lblPicResolution.frame.size.height);
        lblPicResDocument.frame = CGRectMake(op.x -  86, op.y + 31, lblPicResDocument.frame.size.width, lblPicResDocument.frame.size.height);
        
        // 解像度を選択した時の説明文を変更するため
        [segPicResolution addTarget:self
                             action:@selector(changePicDocument:)
                   forControlEvents:UIControlEventValueChanged];
        segPicResolution.selectedSegmentIndex = camResolution;
        [self changePicDocument:segPicResolution];
    }

    op.y += 70;
    [btnGuideLineNums setFrame:CGRectMake(op.x, op.y, btnGuideLineNums.frame.size.width, btnGuideLineNums.frame.size.height)];
    [lblGuideLineNums setFrame:CGRectMake(op.x - 159, op.y + 3, lblGuideLineNums.frame.size.width, lblGuideLineNums.frame.size.height)];
    
    op.y += 48;
    [swWithGuideSave setFrame:CGRectMake(op.x, op.y, swWithGuideSave.frame.size.width, swWithGuideSave.frame.size.height)];
    [lblGuideSave setFrame:CGRectMake(op.x - 159, op.y + 3, lblGuideSave.frame.size.width, lblGuideSave.frame.size.height)];
    
    op.y += 48;
    [swWithOverlaySave setFrame:CGRectMake(op.x, op.y, swWithOverlaySave.frame.size.width, swWithOverlaySave.frame.size.height)];
    [lblOverlaySave setFrame:CGRectMake(op.x - 159, op.y + 3, lblOverlaySave.frame.size.width, lblOverlaySave.frame.size.height)];

    if ([AccountManager isWebCam2]) {
        // Webカメラ詳細設定用UI初期化
        op.y += 48;
//        CGFloat xoffset = scrollDetailView.frame.size.width;
        CGFloat xoffset = 0;
        lblCamRotate        = [self setDefaultLabel:@"WebCam画像回転"
                                          initFrame:CGRectMake(8 + xoffset, op.y + 18, 149, 21)];
        lblCamResolution    = [self setDefaultLabel:@"WebCam写真解像度"
                                          initFrame:CGRectMake(8 + xoffset, op.y + 64, 149, 21)];
        btnCamRotate        = [self setDefaultButton:@"回転"
                                           initFrame:CGRectMake(180 + xoffset, op.y + 14, 100, 30)];
        btnCamResolution    = [self setDefaultButton:@"解像度"
                                           initFrame:CGRectMake(180 + xoffset, op.y + 60, 100, 30)];
        segCamResolution    = [self setDefaultSegmentedControl:[NSArray arrayWithObjects:@"Low", @"Mid", @"High",nil]
                                                     initFrame:CGRectMake(180 + xoffset, op.y + 60, 187, 29)];
        
        [self.view addSubview:lblCamRotate];
        [self.view addSubview:lblCamResolution];
        [self.view addSubview:btnCamRotate];
        [self.view addSubview:btnCamResolution];
        [self.view addSubview:segCamResolution];
        
        [btnCamRotate addTarget:self
                         action:@selector(OnCamRotate:)
               forControlEvents:UIControlEventTouchUpInside];
        
        [btnCamResolution addTarget:self
                             action:@selector(OnCamResolution:)
                   forControlEvents:UIControlEventTouchUpInside];
        
        [segCamResolution addTarget:self
                             action:@selector(changeWebcamResolution:)
                   forControlEvents:UIControlEventValueChanged];
        segCamResolution.selectedSegmentIndex = _webCamResolution;
        [self changeWebcamResolution:segCamResolution];
    }
    
    rotateArray     = [NSArray arrayWithObjects:
                       @"０度", @"９０度", @"１８０度", @"２７０度", nil];
    resolutionArray = [NSArray arrayWithObjects:
                       @"2M", @"5M", @"18M", nil];
    [rotateArray retain];
    [resolutionArray retain];
    
    isiPad2 = ([UIScreen mainScreen].scale > 1.0f)? NO : YES;
    
    [self setPattern:_mode];
}

// nibでの標準ラベルと同等の初期化
- (UILabel *)setDefaultLabel:(NSString *)title initFrame:(CGRect)rect
{
    UILabel *label;
    
    label = [[UILabel alloc] initWithFrame:rect];
    [label setText:title];
    label.textAlignment = NSTextAlignmentRight;
    label.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    
    return label;
}

// nibでの標準ボタンと同等の初期化
- (UIButton *)setDefaultButton:(NSString *)title initFrame:(CGRect)rect
{
    UIButton *button;
    
    button = [[UIButton alloc] initWithFrame:rect];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:20]];

    [button setBackgroundColor:[UIColor whiteColor]];
    [[button layer] setCornerRadius:6.0];
    [button setClipsToBounds:YES];
    [[button layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[button layer] setBorderWidth:1.0];

    return button;
}

// nibでの標準セグメントコントローラと同等の初期化
- (UISegmentedControl *)setDefaultSegmentedControl:(NSArray *)items initFrame:(CGRect)rect
{
    UISegmentedControl *seg;
    
    seg = [[UISegmentedControl alloc] initWithItems:items];
    seg.frame = rect;
    
    [seg setBackgroundColor:[UIColor whiteColor]];
    [[seg layer] setCornerRadius:5.0];
    [seg setClipsToBounds:YES];
    [[seg layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[seg layer] setBorderWidth:1.0];

    return seg;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// ガイド線の本数をpickerに設定
//	[pkvwGuideLineNums selectRow:_guideLineNums 
//					 inComponent:0 animated:NO];
    [btnGuideLineNums   setTitle:[NSString stringWithFormat:@"%ld 本", (long)_guideLineNums]
                        forState:UIControlStateNormal];
    [btnCamRotate       setTitle:[rotateArray objectAtIndex:_webCamRotate]
                        forState:UIControlStateNormal];
    [btnCamResolution   setTitle:[resolutionArray objectAtIndex:_webCamResolution]
                        forState:UIControlStateNormal];
    segCamResolution.selectedSegmentIndex = _webCamResolution;
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

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated]; 
	
	if ( (self.delegate) &&
		([self.delegate respondsToSelector:@selector(OverlayViewOnClose:)]))
	{
		// クライアントクラスに終了通知
		[self.delegate OverlayViewOnClose:self];
	}
}

- (void)viewDidUnload {
    [sliderTime release];
    sliderTime = nil;
    [sliderCapacity release];
    sliderCapacity = nil;
    [lblOverlaySave release];
    lblOverlaySave = nil;
    [lblAhphaTitle release];
    lblAhphaTitle = nil;
    [sliderMaxTime release];
    sliderMaxTime = nil;
    [lblMaxTimeValue release];
    lblMaxTimeValue = nil;
    [lblMaxTimeTitle release];
    lblMaxTimeTitle = nil;
    [lblTimeTitle release];
    lblTimeTitle = nil;
    [lblCapacityTitle release];
    lblCapacityTitle = nil;
    [segPicResolution release];
    segPicResolution = nil;
    [lblPicResolution release];
    lblPicResolution = nil;
    [lblPicResDocument release];
    lblPicResDocument = nil;
    [btnGuideLineNums release];
    btnGuideLineNums = nil;
    [btnCamResolution release];
    btnCamResolution = nil;
    [btnCamRotate release];
    btnCamRotate = nil;
    [rotateArray release];
    [resolutionArray release];
    [lblGuideLineNums release];
    lblGuideLineNums = nil;
    [lblGuideSave release];
    lblGuideSave = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [sliderTime release];
    [sliderCapacity release];
    [lblOverlaySave release];
    [lblAhphaTitle release];
    [sliderMaxTime release];
    [lblMaxTimeValue release];
    [lblMaxTimeTitle release];
    [lblTimeTitle release];
    [lblCapacityTitle release];
    [segPicResolution release];
    [lblPicResolution release];
    [lblPicResDocument release];
    [btnGuideLineNums release];
    [btnCamResolution release];
    [btnCamRotate release];
    [rotateArray release];
    [resolutionArray release];
    [lblGuideLineNums release];
    [lblGuideSave release];
    [lblGuideLine release];
    [lblGuideLineValue release];
    [sliderGuideLine release];
    [super dealloc];
}

#pragma mark control_events
// 自動停止時間の値変更イベント
- (IBAction)OnSliderTimeValueChange {
    _maxDuration = (int)sliderTime.value;
    if (_maxDuration > _maxRecTime) {
        _maxDuration = _maxRecTime;
    }
    [self dispTimeValue];
    sliderTime.value = _maxDuration;
}
- (IBAction)OnSliderLocalCapacityValueChange {
    _localCapacity = sliderCapacity.value;
    [self dispLocalCapacityValue];
}
// 透過率スライダーの値変更イベント
- (IBAction) OnSliderAlphaValueChange:(UISlider*)sender
{
	// クライアントクラスにガイド線本数の設定通知
	if ( (self.delegate) &&
		([self.delegate respondsToSelector:@selector(OverlayView:OnAlphaChange:)]))
	{
		// % -> 実数に変換
		CGFloat alpha = sliderAlpha.value / 100.0f;
		
		[self.delegate OverlayView:self OnAlphaChange:alpha];
	}
	
	// 透過率[%]の表示
	[self dispAlphaValue];
}

- (IBAction) OnSliderGuideLineValueChange:(UISlider*)sender {
    if ( (self.delegate) &&
        ([self.delegate respondsToSelector:@selector(OverlayView:OnGuideLineAlphaChange:)]))
    {
        // % -> 実数に変換
        CGFloat alpha = sliderGuideLine.value / 100.0f;
        
        [self.delegate OverlayView:self OnGuideLineAlphaChange:alpha];
    }
    
    // 透過率[%]の表示
    [self dispGuideLineAlphaValue];
}

// 重ね合わせ画像も一緒に保存する変更イベント
- (IBAction) OnWithOverlaySaveValueChange:(UISwitch*)sender
{
	_isWithOverlaySave = swWithOverlaySave.isOn;
}

// ガイド線も一緒に保存する変更イベント
- (IBAction) OnWithGuideSaveValueChange:(UISwitch*)sender
{
	_isWithGuideSave = swWithGuideSave.isOn;
}

- (IBAction)OnGuideLineNum:(id)sender {
    NSArray *initArray =
    [NSArray arrayWithObjects:
     @"０本", @"１本", @"２本", @"３本", @"４本",
     @"５本", @"６本", @"７本", @"８本", @"９本",
     @"１０本", @"１１本", @"１２本", @"１３本",
     nil];
    
    SelectPopUp *guideSel = [[SelectPopUp alloc] initWithSetting:POPUPID_GUIDELINE_NUM
                                                      lastSelect:_guideLineNums
                                                      pickerData:initArray
                                                        callBack:self];

    // ポップアップViewの表示
    UIPopoverController *popoverCnt = [[UIPopoverController alloc]
                                       initWithContentViewController:guideSel];
    guideSel.popoverController = popoverCnt;
    
    [popoverCnt presentPopoverFromRect:btnGuideLineNums.bounds
                                inView:btnGuideLineNums
              permittedArrowDirections:UIPopoverArrowDirectionAny
                              animated:NO];
    
    if ([guideSel respondsToSelector:@selector(setPreferredContentSize:)]) {
        [guideSel setPreferredContentSize:CGSizeMake(240.0f, 311.0f)];
    }
    
    [guideSel release];
    [popoverCnt release];
}

- (IBAction)OnCamRotate:(id)sender
{
    SelectPopUp *guideSel = [[SelectPopUp alloc] initWithSetting:POPUPID_CAM_ROTATE
                                                      lastSelect:_webCamRotate
                                                      pickerData:rotateArray
                                                        callBack:self];
    
    // ポップアップViewの表示
    UIPopoverController *popoverCnt = [[UIPopoverController alloc]
                                       initWithContentViewController:guideSel];
    guideSel.popoverController = popoverCnt;
    
    [popoverCnt presentPopoverFromRect:btnCamRotate.bounds
                                inView:btnCamRotate
              permittedArrowDirections:UIPopoverArrowDirectionAny
                              animated:NO];
    
    if ([guideSel respondsToSelector:@selector(setPreferredContentSize:)]) {
        [guideSel setPreferredContentSize:CGSizeMake(240.0f, 311.0f)];
    }
    
    [guideSel release];
    
    [popoverCnt release];
}

- (IBAction)OnCamResolution:(id)sender
{
    SelectPopUp *guideSel = [[SelectPopUp alloc] initWithSetting:POPUPID_CAM_RESOLUTION
                                                      lastSelect:_webCamResolution
                                                      pickerData:resolutionArray
                                                        callBack:self];
    
    // ポップアップViewの表示
    UIPopoverController *popoverCnt = [[UIPopoverController alloc]
                                       initWithContentViewController:guideSel];
    guideSel.popoverController = popoverCnt;
    
    [popoverCnt presentPopoverFromRect:btnCamResolution.bounds
                                inView:btnCamResolution
              permittedArrowDirections:UIPopoverArrowDirectionAny
                              animated:NO];
    
    if ([guideSel respondsToSelector:@selector(setPreferredContentSize:)]) {
        [guideSel setPreferredContentSize:CGSizeMake(240.0f, 311.0f)];
    }
    
    [guideSel release];
    
    [popoverCnt release];
}

// Webカメラ撮影解像度設定
- (void) changeWebcamResolution:(id)sender
{
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    
    if (isiPad2) {  // iPad2の場合、高解像度を選択出来ないようにする
        if (seg.selectedSegmentIndex!=0) {
            seg.selectedSegmentIndex = _webCamResolution;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"解像度について",
                                                                  @"About Resolution")
                                  message:NSLocalizedString(@"このiPadでは選択出来ません",
                                                            @"Can't select")
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
        } else {
            _webCamResolution = seg.selectedSegmentIndex;
        }
    } else {
        _webCamResolution = seg.selectedSegmentIndex;
    }
}

- (void)setPattern:(NSInteger)mode
{
    switch(mode) {
        case 0: // 静止画
            swWithOverlaySave.hidden = NO;
            lblOverlaySave.hidden = NO;
            
            sliderAlpha.hidden = NO;
            lblAhphaTitle.hidden = NO;
            lblAlphaValue.hidden = NO;
            
            lblMaxTimeTitle.hidden = YES;
            lblMaxTimeValue.hidden = YES;
            sliderMaxTime.hidden = YES;
            
            sliderTime.hidden = YES;
            lblTimeTitle.hidden = YES;
            lblTimeValue.hidden = YES;
            
            lblPicResolution.hidden = NO;
            segPicResolution.hidden = NO;
            lblPicResDocument.hidden = NO;

            if ([AccountManager isWebCam2]) {
                lblCamResolution.hidden = NO;
                btnCamResolution.hidden = YES;
                segCamResolution.hidden = NO;
                lblCamRotate.hidden = NO;
                btnCamRotate.hidden = NO;
            }

            break;
        case 1: // 動画
        default:
            swWithOverlaySave.hidden = YES;
            lblOverlaySave.hidden = YES;
            
            sliderAlpha.hidden = YES;
            lblAhphaTitle.hidden = YES;
            lblAlphaValue.hidden = YES;

            lblMaxTimeTitle.hidden = NO;
            lblMaxTimeValue.hidden = NO;
            sliderMaxTime.hidden = NO;

            sliderTime.hidden = NO;
            lblTimeTitle.hidden = NO;
            lblTimeValue.hidden = NO;

            lblPicResolution.hidden = YES;
            segPicResolution.hidden = YES;
            lblPicResDocument.hidden = YES;
            
            lblCamResolution.hidden = YES;
            btnCamResolution.hidden = YES;
            segCamResolution.hidden = YES;
            lblCamRotate.hidden = YES;
            btnCamRotate.hidden = YES;
            break;
    }
}

/**
 * 写真保存解像度を切り替えた時に説明文を変更する
 */
- (void) changePicDocument:(id)sender
{
    UISegmentedControl *seg = (UISegmentedControl *)sender;
    if (isiPad2) {  // iPad2の場合、低解像度以外を選択出来ないようにする
        if (seg.selectedSegmentIndex!=0) {
            seg.selectedSegmentIndex = camResolution;
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"解像度について",
                                                                  @"About Resolution")
                                  message:NSLocalizedString(@"このiPadでは選択出来ません",
                                                            @"Can't select")
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
        } else {
            camResolution = seg.selectedSegmentIndex;
        }
    } else {
        camResolution = seg.selectedSegmentIndex;
    }

    switch (camResolution) {
        case 0:
            [lblPicResDocument setText:@"低解像度で画像を保存します"];
            break;
        case 1:
            [lblPicResDocument setText:@"中解像度で画像を保存します"];
            break;
        case 2:
            [lblPicResDocument setText:@"高解像度で画像を保存します"];
            break;
        default:
            [lblPicResDocument setText:@""];
            break;
    }
}
/*
#pragma mark UIPickerViewDataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	// 列数は１
	return (1);
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	if (component != 0)
	{	return 0; }				// １列目以外はない
	
	return (1 + GUIDE_LINE_NUMS_MAX);		// 1 (なし) + ガイド線最大本数
}

#pragma mark UIPickerViewDelegate

// 表示する内容を返す
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if (component != 0)
	{	return 0; }				// １列目以外はない

	// 行インデックスに本を付与
	return ((row != 0)? [NSString stringWithFormat:@" %d [本]", row]:@"な  し");
}

// 行インデックスの選択
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	// クライアントクラスにガイド線本数の設定通知
	if ( (self.delegate) &&
		 ([self.delegate respondsToSelector:@selector(OverlayView:OnGuideLineNumsChange:)]))
	{
		[self.delegate OverlayView:self OnGuideLineNumsChange:row];
	}
}
*/
#pragma mark SelectGuideNum delegate

- (void)OnSelectSet:(NSUInteger)popUpID selectNumber:(NSInteger)selectNum
{
    switch (popUpID) {
        case POPUPID_GUIDELINE_NUM:
            [self doDelegateGuidLine:selectNum];
            break;
        case POPUPID_CAM_ROTATE:
            [self doDelegateCamRotate:selectNum];
            break;
        case POPUPID_CAM_RESOLUTION:
            [self doDelegateCamResolution:selectNum];
            break;
        default:
            break;
    }
}

/**
 * SelectPopUpDelegate
 */
- (void)OnSelectCancel:(NSUInteger)popUpID
{
    // 何もしない
}

- (void)doDelegateGuidLine:(NSInteger)selectNum
{
    _guideLineNums = selectNum;
    
    // クライアントクラスにガイド線本数の設定通知
    if ( (self.delegate) &&
        ([self.delegate respondsToSelector:@selector(OverlayView:OnGuideLineNumsChange:)]))
    {
        [self.delegate OverlayView:self OnGuideLineNumsChange:selectNum];
    }
    
    [btnGuideLineNums setTitle:[NSString stringWithFormat:@"%ld 本", (long)selectNum]
                      forState:UIControlStateNormal];
}

- (void)doDelegateCamRotate:(NSInteger)selectNum
{
    _webCamRotate = selectNum;
    
    [btnCamRotate setTitle:[rotateArray objectAtIndex:selectNum]
                  forState:UIControlStateNormal];
}

- (void)doDelegateCamResolution:(NSInteger)selectNum
{
    _webCamResolution = selectNum;
    
    [btnCamResolution setTitle:[resolutionArray objectAtIndex:selectNum]
                      forState:UIControlStateNormal];
}

#pragma mark private_methods

@end
