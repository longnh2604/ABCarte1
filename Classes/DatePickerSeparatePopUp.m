//
//  DatePickerSeparatePopUp.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/12/03.
//
//

#import "DatePickerSeparatePopUp.h"

@interface DatePickerSeparatePopUp ()

@end

@implementation DatePickerSeparatePopUp

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [self getDateInfo];
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion) {
        NSArray *arr = @[pickerSeparateDate, btnOK, btnCancel, btnToday, btnDateReset];
        for (id parts in arr) {
            [parts setBackgroundColor:[UIColor whiteColor]];
            [[parts layer] setCornerRadius:6.0];
            [parts setClipsToBounds:YES];
            [[parts layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
            [[parts layer] setBorderWidth:1.0];
        }
    }
    pickerSeparateDate.delegate = self;
    
    selectedDay = [[NSDateComponents alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc {
    [pickerSeparateDate release];
    [btnOK release];
    [btnCancel release];
    [btnToday release];
    [btnDateReset release];
    [selectedDay release];
    [super dealloc];
}
- (void)viewDidUnload {
    [pickerSeparateDate release];
    pickerSeparateDate = nil;
    [btnOK release];
    btnOK = nil;
    [btnCancel release];
    btnCancel = nil;
    [btnToday release];
    btnToday = nil;
    [btnDateReset release];
    btnDateReset = nil;
    [selectedDay release];
    selectedDay = nil;
    [super viewDidUnload];
}

#pragma mark PickerView_DataSource
/**
 列数を返す
 */
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView*)pickerView
{
    return 3;
}

/**
 行数を返す
 */
- (NSInteger) pickerView:(UIPickerView*)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSInteger row = 0;
    if ( component == 0 )
        row = 101; // year
    else if ( component == 1 )
        row = 13; // month
    else if ( component == 2 )
        row = 32; // day
    
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
            if ( row == 0 )
                retString = @"----";
            else
                retString = [NSString stringWithFormat:@"%ld年", (long)((currentYear - row) + 1)];
            break;
            
            // MONTH
        case 1:
            if ( row == 0 )
                retString = @"--";
            else
                retString = [NSString stringWithFormat:@"%ld月", (long)row];
            break;
            
            // DAY
        case 2:
            if ( row == 0 )
                retString = @"--";
            else
                retString = [NSString stringWithFormat:@"%ld日", (long)row];
            break;
            
        default:
            break;
    }
    return retString;
}

#pragma mark PopUpViewContollerBase

// delegate objectの設定:設定ボタンおよびあ行など行ボタンのclick時にコールされるs
- (id) setDelegateObject
{
    // 選択された日付を返す
    return(selectedDay);
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
 本日ボタン
 */
- (IBAction)OnToday:(id)sender {
    [pickerSeparateDate selectRow:1 inComponent:0 animated:NO];
    [pickerSeparateDate selectRow:currentMonth inComponent:1 animated:NO];
    [pickerSeparateDate selectRow:currentDay inComponent:2 animated:NO];
}

/**
 日付リセットボタン
 */
- (IBAction)OnDateReset:(id)sender {
    [pickerSeparateDate selectRow:0 inComponent:0 animated:NO];
    [pickerSeparateDate selectRow:0 inComponent:1 animated:NO];
    [pickerSeparateDate selectRow:0 inComponent:2 animated:NO];
}

/**
 日付設定ボタン
 */
- (IBAction)OnDateSet:(id)sender {
    NSInteger year = [pickerSeparateDate selectedRowInComponent:0];
    year = (year > 0) ? (currentYear + 1) - year : 0;
    [selectedDay setYear:year];
    [selectedDay setMonth:[pickerSeparateDate selectedRowInComponent:1]];
    [selectedDay setDay:[pickerSeparateDate selectedRowInComponent:2]];

    [self OnSetButton:sender];
}


@end
