//
//  DateAddDaysPopup.m
//  iPadCamera
//
//  Created by yoshida on 2014/08/04.
//
//

#import "DateAddDaysPopup.h"
#import "Common.h"

@interface DateAddDaysPopup ()

@end

@implementation DateAddDaysPopup

@synthesize lblTitle;
@synthesize picker;

- (id) initWithDateAddDaysPopUpViewContoller:(NSUInteger)popUpID
                                    callBack:(id)callBackDelegate
{
    self = [super initWithPopUpViewContoller:popUpID
                           popOverController:nil
                                    callBack:callBackDelegate
                                     nibName:@"DateAddDaysPopup"];
    
    if (self) {
        // Custom initialization
        _data = [[NSMutableArray array] retain];
        for( int i = 0; i < 10; i++ )
        {
            NSNumber *data = [NSNumber numberWithInt:i];
            [_data addObject:data];
        }
        _addDays = 0;
        _dataAddDaysDelegate = callBackDelegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion>=7.0) {
        NSArray *arr = @[_picker, _btnSet, _btnCancel];
        for (id parts in arr) {
            [parts setBackgroundColor:[UIColor whiteColor]];
            [[parts layer] setCornerRadius:6.0];
            [parts setClipsToBounds:YES];
            [[parts layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
            [[parts layer] setBorderWidth:1.0];
        }
    }
    
    [Common cornerRadius4Control:_lblTitle];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload
{
    [_btnSet release];
    _btnSet = nil;
    [_btnCancel release];
    _btnCancel = nil;
    [_data removeAllObjects];
    [_data release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [_btnSet release];
    [_btnCancel release];
    [_data release];
    [super dealloc];
}

#pragma mark picker data source
//  コンポーネントの数を返す
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}

//  コンポーネントの行数を返す
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 10;
}

//  コンポーネントに表示するテキストを返す
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    if( row >= [_data count] )  return nil;
    return [[_data objectAtIndex:row] stringValue];
}

//  コンポーネントの内容が変更された際に呼ばれる
- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    int data = [[_data objectAtIndex:row] intValue];
    switch (component) {
        case 0:;
            _addDays %= 100;
            _addDays += data * 100;
            break;
        case 1:;
            _addDays = (_addDays / 100) * 100 + (_addDays % 10);
            _addDays += data * 10;
            break;
        case 2:;
            _addDays = (_addDays / 10) * 10;
            _addDays += data;
            break;
        default:
            break;
    }
    _lblAddDays.text = [NSString stringWithFormat:@"%ld日後", (long)_addDays];
}

#pragma mark On Button Action
-(void) OnCancelButton:(id)sender
{
    [super OnCancelButton:sender];
    [_dataAddDaysDelegate onDateAddDaysChansel];
}

#pragma mark PopUpViewContollerBase

// delegate objectの設定:設定ボタンおよびあ行など行ボタンのclick時にコールされるs
- (id) setDelegateObject
{
    return [NSNumber numberWithInteger:_addDays];
}

/**
 * ポップアップが閉じたあと行われる処理
 */
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController;
{
    [_dataAddDaysDelegate onDateAddDaysChansel];
}


@end
