//
//  DatePickerPopUp.m
//  iPadCamera
//
//  Created by MacBook on 10/12/01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "DatePickerPopUp.h"

@implementation DatePickerPopUp

@synthesize lblTitle;
@synthesize dpSetDate;
@synthesize isJapanese;

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

/**
 * 表示日時を指定して初期化する(言語環境含む)
 */
- (id)initWithDatePopUpViewContoller:(NSUInteger)popUpID
                   popOverController:(UIPopoverController *)controller
                            callBack:(id)callBackDelegate
                            initDate:(NSDate *)initDate
                          selectLang:(BOOL)lang
{
    self = [super initWithPopUpViewContoller:popUpID
                           popOverController:controller
                                    callBack:callBackDelegate];
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (self) {
        currentDate = initDate;
        if (iOSVersion>=7.0) {
            [self setPreferredContentSize:CGSizeMake(332.0f, 364.0f)];
        } else {
            self.contentSizeForViewInPopover = CGSizeMake(332.0f, 364.0f);
        }
        isJapanese = lang;
    }
    return self;
}

/**
 * 表示日時を指定して初期化する
 */
- (id)initWithDatePopUpViewContoller:(NSUInteger)popUpID
                   popOverController:(UIPopoverController *)controller
                            callBack:(id)callBackDelegate
                            initDate:(NSDate *)initDate
{
    self = [super initWithPopUpViewContoller:popUpID
                           popOverController:controller
                                    callBack:callBackDelegate];
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (self) {
        currentDate = initDate;
        if (iOSVersion>=7.0) {
            [self setPreferredContentSize:CGSizeMake(332.0f, 364.0f)];
        } else {
            
            self.contentSizeForViewInPopover = CGSizeMake(332.0f, 364.0f);
        }
        isJapanese = YES;
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion>=7.0) {
        NSArray *partsArr = @[dpSetDate, btnSet, btnCancel];
        for (id parts in partsArr) {
            [parts setBackgroundColor:[UIColor whiteColor]];
            [[parts layer] setCornerRadius:6.0];
            [parts setClipsToBounds:YES];
            [[parts layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
            [[parts layer] setBorderWidth:1.0];
        }
    }
	
	// titleラベルの角を丸くする
	CALayer *layer = [self.lblTitle layer];
	[layer setMasksToBounds:YES];
	[layer setCornerRadius:12.0f];
    
    // 2015/09/28 TMS iOS9対応
    // 現在日付を設定
    if (currentDate == nil) {
        currentDate = [NSDate date];
    }
    
    [dpSetDate setDate:currentDate];
    
    [self dispLabelBirthday:dpSetDate.date];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!isJapanese) {
        [btnSet setTitle:@"Entry" forState:UIControlStateNormal];
        [btnCancel setTitle:@"Cancel" forState:UIControlStateNormal];
    }
    

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
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [btnSet release];
    btnSet = nil;
    [btnCancel release];
    btnCancel = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [btnSet release];
    [btnCancel release];
    [super dealloc];
}

#pragma mark private methods

// 生年月日pickerのイベント
- (IBAction) OnBirthDayValueChanged:(id)sender
{
	[self dispLabelBirthday:dpSetDate.date];
}

// 生年月日の和暦表示
- (void) dispLabelBirthday:(NSDate*)date
{
	// 時刻書式指定子を設定
    NSDateFormatter* form = [[NSDateFormatter alloc] init];
    [form setDateStyle:NSDateFormatterFullStyle];
    [form setTimeStyle:NSDateFormatterNoStyle];
    
    // ロケールを設定
    NSLocale* loc = [[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"];
    [form setLocale:loc];
    
    // カレンダーを指定
    NSCalendar* cal;
    
    // 和暦を出力するように書式指定:曜日まで出す
    if (isJapanese) {
        cal = [[NSCalendar alloc] initWithCalendarIdentifier: NSJapaneseCalendar];
        [form setCalendar: cal];
        [form setDateFormat:@"GGyy年MM月dd日 EEEE"];
        dpSetDate.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ja"];
    } else {
        cal = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
        [form setCalendar: cal];
        [form setDateFormat:@"　MM/dd/yyyy"];
        dpSetDate.calendar = cal;
        dpSetDate.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
    }
    
	lblBirthday.text = [form stringFromDate:date];
	// NSLog (@"%@", lblBirthday.text);
	
	// 生年月日が設定されたことを示す
	lblBirthday.tag = 1;
	
    [form release];
    [cal release];
    [loc release];
	
}


#pragma mark PopUpViewContollerBase

// delegate objectの設定:設定ボタンおよびあ行など行ボタンのclick時にコールされるs
- (id) setDelegateObject
{
	// 選択された日付を返す
	NSDate *date = dpSetDate.date;
	return(date);
}


@end
