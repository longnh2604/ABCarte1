//
//  BirthdaySearchPopup.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/20.
//
//

/*
 ** IMPORT
 */
#import "BirthdaySearchPopup.h"

/*
 ** CLASS EXTENSION
 */
@interface BirthdaySearchPopup ()
{
	/*
	 UIパーツ
	 */
	IBOutlet UIButton *btnSearch;
	IBOutlet UIButton *btnCancel;
	IBOutlet UISegmentedControl *segBirthdaySearch;
	IBOutlet UIDatePicker *pickerBirthday;
	IBOutlet UIPickerView *pickerMonth;

	/*
	 データ
	 */
	id<BirthdaySearchPopupDelegate> _delegate;
	NSInteger currentYear;
	NSInteger currentMonth;
}

/**
 誕生月の設定
 */
- (void) setupPickerMonth;

@end


/*
 ** IMPLEMENTATION
 */
@implementation BirthdaySearchPopup

/*
 ** PROPERTY
 */
@synthesize popOverController;

#pragma mark iOS_Framework
/**
 initWithNibName
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
		currentYear = currentMonth = 0;
    }
    return self;
}

/**
 viewDidLoad
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	// セグメントの初期化
	[segBirthdaySearch setSelectedSegmentIndex:DEF_SEGMENT_INDEX];

	// Pickerの初期状態設定
	[pickerBirthday setHidden:NO];
	[pickerMonth setHidden:YES];

	// 誕生月の設定
	[self setupPickerMonth];

    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];

    if (iOSVersion>=7.0f) {
        NSArray *arr = @[pickerBirthday, pickerMonth, btnSearch, btnCancel];
        for (id parts in arr) {
            [parts setBackgroundColor:[UIColor whiteColor]];
            [[parts layer] setCornerRadius:6.0];
            [parts setClipsToBounds:YES];
            [[parts layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
            [[parts layer] setBorderWidth:1.0];
        }
    }

}

/**
 viewDidUnload
 */
- (void)viewDidUnload
{
	[btnCancel release];
	btnCancel = nil;
	[btnSearch release];
	btnSearch = nil;
	[segBirthdaySearch release];
	segBirthdaySearch = nil;
	[pickerBirthday release];
	pickerBirthday = nil;
	[pickerMonth release];
	pickerMonth = nil;
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
 viewWillDisappear
 */
- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

/**
 didReceiveMemoryWarning
 */
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 dealloc
 */
- (void)dealloc
{
	[btnCancel release];
	[btnSearch release];
	[segBirthdaySearch release];
	[pickerBirthday release];
	[pickerMonth release];
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


#pragma mark BirthdaySearch_LocalMethod
/**
 初期化
 */
- (id) initWithDelegate:(id) delegate
{
	self = [self initWithNibName:@"BirthdaySearchPopup" bundle:nil];
	if ( self )
	{
		// デリゲート
		_delegate = delegate;
		// サイズ
		self.contentSizeForViewInPopover = CGSizeMake(400, 305);
	}
	return self;
}

/**
 セグメントのインデックスを取得する
 */
- (NSInteger) getSegmentIndex
{
	return [segBirthdaySearch selectedSegmentIndex];
}

/**
 検索する誕生日を取得する
 */
- (NSDate*) getBirthDay
{
	// 誕生日で検索のみ
	if ( [segBirthdaySearch selectedSegmentIndex] != SEGMENT_BIRTHDAY )
		return nil;

	// 誕生日を取得する
	return [pickerBirthday date];
}

/**
 検索する誕生月を取得する
 */
- (NSDate*) getBirthMonth:(BOOL)startSearch
{
	// 誕生月で検索のみ
	if ( [segBirthdaySearch selectedSegmentIndex] != SEGMENT_MONTH )
		return nil;

	// 選択行の取得
	NSInteger row = [pickerMonth selectedRowInComponent:((startSearch == YES) ? 0 : 2)];
	if ( row == 0 ) return nil;

	NSString* strDateFormat = @"yyyy-MM-dd HH:mm:ss";
	NSDateFormatter* dateFomrat = [[[NSDateFormatter alloc] init] autorelease];
	[dateFomrat setLocale:[NSLocale systemLocale]];
	[dateFomrat setTimeZone:[NSTimeZone systemTimeZone]];
	[dateFomrat setDateFormat:strDateFormat];
	NSString* createTime = [NSString stringWithFormat:@"%ld-%02ld-01 01:01:01", (long)currentYear, (long)row];
	return [dateFomrat dateFromString:createTime];
}

/**
 検索する誕生年を取得する
 */
- (NSDate*) getBirthYear:(BOOL)startSearch
{
	// 誕生年で検索のみ
	if ( [segBirthdaySearch selectedSegmentIndex] != SEGMENT_YEAR )
		return nil;

	// 選択行の取得
	NSInteger row = [pickerMonth selectedRowInComponent:((startSearch == YES) ? 0 : 2)];
	if ( row == 0 ) return nil;

	NSString* strDateFormat = @"yyyy-MM-dd HH:mm:ss";
	NSDateFormatter* dateFomrat = [[[NSDateFormatter alloc] init] autorelease];
	[dateFomrat setLocale:[NSLocale systemLocale]];
	[dateFomrat setTimeZone:[NSTimeZone systemTimeZone]];
	[dateFomrat setDateFormat:strDateFormat];
	NSString* createTime = [NSString stringWithFormat:@"%ld-%02ld-01 01:01:01", (long)(currentYear - 100 + row), (long)currentMonth];
	return [dateFomrat dateFromString:createTime];
}


#pragma mark BirthdaySearch_LocalMethod
/**
 誕生月の設定
 */
- (void) setupPickerMonth
{
	NSDate* date = [NSDate date];
	NSCalendar* calendar = [NSCalendar currentCalendar];
	NSDateComponents* dateComponents = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit)
												   fromDate:date];

	// 現在の西暦を取得
	currentYear = dateComponents.year;
	// 現在の月を取得
	currentMonth = dateComponents.month;
}


#pragma mark PickerView_DataSource
/**
 列数を返す
 */
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)pickerView
{
	// 誕生日の時は返さない
	if ( [segBirthdaySearch selectedSegmentIndex] == SEGMENT_BIRTHDAY )
		return 0;

	// 誕生月、誕生年は３固定
	return 3;
}

/**
 行数を返す
 */
- (NSInteger) pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component
{
	NSInteger segmentIndex = [segBirthdaySearch selectedSegmentIndex];
	if ( segmentIndex == SEGMENT_BIRTHDAY )
	{
		// 誕生日の時は返さない
		return 0;
	}
	else if ( segmentIndex == SEGMENT_MONTH )
	{
		// 誕生月
		if ( component == 1 )
			return 1;
		return 13; // 12+1
	}
	else
	{
		// 誕生年
		if ( component == 1 )
			return 1;
		return 101; // 100+1
	}
}

#pragma mark PickerView_Delegate
/**
 行のタイトルを返す
 */
- (NSString *)pickerView:(UIPickerView*)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	switch( [segBirthdaySearch selectedSegmentIndex] )
	{
	case SEGMENT_MONTH:
		{
			if ( component == 0 || component == 2 )
			{
				if ( row == 0 )
				{
					// インデックス０だけ別
					return @"なし";
				}
				else
				{
					// 月の文字列を返す
					return [NSString stringWithFormat:@"%ld月", (long)row];
				}
			}
			else
			{
				return @"〜";
			}
		}
		break;

	case SEGMENT_YEAR:
		{
			if ( component == 0 || component == 2 )
			{
				if ( row == 0 )
				{
					// インデックス０だけ別
					return @"なし";
				}
				else
				{
					// 年の文字列を返す
					return [NSString stringWithFormat:@"%ld年", (long)(currentYear - 100 + row) ];
				}
			}
			else
			{
				return @"〜";
			}
		}
		return @"なし";

	default:
		return @"なし";
	}
}

#pragma mark BirthdaySearch_EventHandler
/**
 検索方法のセグメントが押された
 */
- (IBAction) OnBirthdaySegment:(id)sender
{
	NSInteger segmentIndex = [segBirthdaySearch selectedSegmentIndex];
	if ( segmentIndex == SEGMENT_BIRTHDAY )
	{
		// 誕生日で検索
		[pickerBirthday setHidden:NO];
		[pickerMonth setHidden:YES];
	}
	else
	{
		// 誕生月で検索
		[pickerBirthday setHidden:YES];
		[pickerMonth setHidden:NO];
		// セグメントで表示内容が違うのでリロードする
		[pickerMonth reloadAllComponents];
		// メインスレッドに通知
		dispatch_async(dispatch_get_main_queue(), ^{
			// reloadAllComponentsはメインキューで実行されているようす
			// 一応reloadAllComponentsの実行終了後に選択をする
			if ( segmentIndex == SEGMENT_MONTH )
			{
				// 現在月を選択する
				[pickerMonth selectRow:currentMonth inComponent:0 animated:NO];
				[pickerMonth selectRow:currentMonth inComponent:2 animated:NO];
			}
			else
			{
				// 現在年（行の最後）を選択する
				NSInteger rows0 = [pickerMonth numberOfRowsInComponent:0] - 1;
				NSInteger rows2 = [pickerMonth numberOfRowsInComponent:2] - 1;
				[pickerMonth selectRow:rows0 inComponent:0 animated:NO];
				[pickerMonth selectRow:rows2 inComponent:2 animated:NO];
			}
		});
	}
}

/**
 検索ボタンが押された
 */
- (IBAction) OnSearch:(id)sender
{
	[_delegate OnSearch:self Cancel:NO];
}

/**
 キャンセルボタンが押された
 */
- (IBAction) OnCancel:(id)sender
{
	[_delegate OnSearch:self Cancel:YES];
}


@end
