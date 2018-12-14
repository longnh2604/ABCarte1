//
//  LastWorkDateSearchPopup.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/24.
//
//

/*
 ** IMPORT
 */
#import "LastWorkDateSearchPopup.h"

@interface LastWorkDateSearchPopup ()
{
	// UIパーツ
	IBOutlet UIButton *btnSearch;
	IBOutlet UIButton *btnCancel;
	IBOutlet UIPickerView *pickerLastWorkDate;
	IBOutlet UINavigationBar *naviBar;

	// 設定データ
	id<LastWorkDateSearchPopupDelegate> _delegate;
	NSInteger currentYear;
	NSInteger currentMonth;
	NSInteger currentDay;
	BOOL isLeapYear;
	BOOL isLeapMonth;
}

- (IBAction) OnSearch:(id)sender;
- (IBAction) OnCancel:(id)sender;

@end

@implementation LastWorkDateSearchPopup

/*
 ** PROPERTY
 */
@synthesize popOverController;

#pragma mark iOS_Framework
/**
 initWithNibName
 */
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
		currentYear = currentMonth = currentDay = 0;
		isLeapYear = NO;
		isLeapMonth = NO;
    }
    return self;
}

/**
 viewDidLoad
 */
- (void) viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	[self getDateInfo];
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion) {
        [pickerLastWorkDate setBackgroundColor:[UIColor whiteColor]];
        [[pickerLastWorkDate layer] setCornerRadius:6.0];
        [pickerLastWorkDate setClipsToBounds:YES];
        [[pickerLastWorkDate layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[pickerLastWorkDate layer] setBorderWidth:1.0];
    }
}

/**
 viewDidUnload
 */
- (void) viewDidUnload
{
	[btnSearch release];
	btnSearch = nil;
	[btnCancel release];
	btnCancel = nil;
	[pickerLastWorkDate release];
	pickerLastWorkDate = nil;
	
	[super viewDidUnload];
}

/**
 viewDidAppear
 */
- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

/**
 didReceiveMemoryWarning
 */
- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 dealloc
 */
- (void) dealloc
{
	[btnSearch release];
	[btnCancel release];
	[pickerLastWorkDate release];
	[super dealloc];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark Instance_Method
/**
 初期化
 */
- (id) initWithDelegate:(id)delegate
{
	self = [self initWithNibName:@"LastWorkDateSearchPopup" bundle:nil];
	if ( self )
	{
		// デリゲート
		_delegate = delegate;
		// サイズ
		self.contentSizeForViewInPopover = CGSizeMake(650, 304);
	}
	return self;
}

/**
 選択されている期限を取得する
 */
- (void) getSelectedTerm:(NSDateComponents**)start End:(NSDateComponents**)end
{
	if ( *start != nil )
	{
		NSInteger year = [pickerLastWorkDate selectedRowInComponent:0];
		year = (year > 0) ? (currentYear + 1) - year : 0;
		[*start setYear:year];
		[*start setMonth:[pickerLastWorkDate selectedRowInComponent:1]];
		[*start setDay:[pickerLastWorkDate selectedRowInComponent:2]];
	}
	if ( end != nil )
	{
		NSInteger year = [pickerLastWorkDate selectedRowInComponent:4];
		year = (year > 0) ? (currentYear + 1) - year : 0;
		[*end setYear:year];
		[*end setMonth:[pickerLastWorkDate selectedRowInComponent:5]];
		[*end setDay:[pickerLastWorkDate selectedRowInComponent:6]];
	}
}

/**
 うるう年の判定
 */
+ (BOOL) isLeapYear:(NSInteger)year
{
	BOOL ret = NO;
	if ( (year % 4) == 0 )
	{
		if ( (year % 100) == 0 )
		{
			ret = ((year % 400) == 0) ? YES : NO;
		}
	}
	return ret;
}


#pragma mark PickerView_DataSource
/**
 列数を返す
 */
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)pickerView
{
	return 7;
}

/**
 行数を返す
 */
- (NSInteger) pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component
{
	NSInteger row = 0;
	if ( component == 0 || component == 4 )
		row = 101; // year
	else if ( component == 1 || component == 5 )
		row = 13; // month
	else if ( component == 2 || component == 6 )
		row = 32; // day
	else
		row = 1;  // 〜

	return row;
}

#pragma mark PickerView_Delegate
/**
 行のタイトルを返す
 */
- (NSString*) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	NSString* retString = nil;
	switch ( component )
	{
		// YEAR
		case 0:
		case 4:
			if ( row == 0 )
				retString = @"----";
			else
				retString = [NSString stringWithFormat:@"%ld年", (long)((currentYear - row) + 1)];
			break;

		// MONTH
		case 1:
		case 5:
			if ( row == 0 )
				retString = @"--";
			else
				retString = [NSString stringWithFormat:@"%ld月", (long)row];
			break;

		// DAY
		case 2:
		case 6:
			if ( row == 0 )
				retString = @"--";
			else
				retString = [NSString stringWithFormat:@"%ld日", (long)row];
			break;

		// 〜
		case 3:
			retString = @"〜";
			break;
			
		default:
			break;
	}
	return retString;
}


#pragma mark Local_Method
/**
 */
- (void) getDateInfo
{
	NSDate* date = [NSDate date];
	NSCalendar* calendar = [NSCalendar currentCalendar];
	NSDateComponents* dateComponents = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
												   fromDate:date];
	
	// 現在の西暦を取得
	currentYear = dateComponents.year;
	// 現在の月を取得
	currentMonth = dateComponents.month;
	// 現在の日を取得
	currentDay = dateComponents.day;
}


#pragma mark Event_Handler
/**
 検索ボタン
 */
- (IBAction) OnSearch:(id)sender
{
	[_delegate OnLastWorkDateSearch:self Cancel:NO];
}

/**
 取消ボタン
 */
- (IBAction) OnCancel:(id)sender
{
	[_delegate OnLastWorkDateSearch:self Cancel:YES];
}

/**
 本日ボタン
 */
- (IBAction) OnToday:(id)sender
{
	[pickerLastWorkDate selectRow:1 inComponent:0 animated:NO];
	[pickerLastWorkDate selectRow:currentMonth inComponent:1 animated:NO];
	[pickerLastWorkDate selectRow:currentDay inComponent:2 animated:NO];

	[pickerLastWorkDate selectRow:1 inComponent:4 animated:NO];
	[pickerLastWorkDate selectRow:currentMonth inComponent:5 animated:NO];
	[pickerLastWorkDate selectRow:currentDay inComponent:6 animated:NO];
}

/**
 開始日リセットボタン
 */
- (IBAction) OnStartReset:(id)sender
{
	[pickerLastWorkDate selectRow:0 inComponent:0 animated:NO];
	[pickerLastWorkDate selectRow:0 inComponent:1 animated:NO];
	[pickerLastWorkDate selectRow:0 inComponent:2 animated:NO];
}

/**
 終了日リセットボタン
 */
- (IBAction) OnEndReset:(id)sender
{
	[pickerLastWorkDate selectRow:0 inComponent:4 animated:NO];
	[pickerLastWorkDate selectRow:0 inComponent:5 animated:NO];
	[pickerLastWorkDate selectRow:0 inComponent:6 animated:NO];
}

@end
