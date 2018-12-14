//
//  SelectPopUp.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/07/25.
//
//

#import "SelectPopUp.h"

@interface SelectPopUp ()

@end

@implementation SelectPopUp

@synthesize myDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// ピッカーの初期化
// 都道府県設定
- (id) initWithSetting:(NSUInteger)popUpID
            lastSelect:(NSInteger)lastSelect
            pickerData:(NSArray *)pickerData
              callBack:(id)callBack
{
    if(self = [super initWithPopUpViewContoller:popUpID popOverController:nil callBack:callBack nibName:@"PrefecturePopUp"]) {
        
        // ポップアップサイズ
        self.contentSizeForViewInPopover = CGSizeMake(240.0f, 311.0f);

        pickerValueList = pickerData;
        [pickerValueList retain];
        
        // 都道府県リスト初期化
//        [self initSelectList];
        
        initRow = lastSelect;

        myDelegate = callBack;
    }
    return self;
}

/**
 * 都道府県リストの設定
 */
- (void)initSelectList
{
    // ピッカー初期設定
    pickerValueList =
    [NSArray arrayWithObjects:
     @"１本", @"２本", @"３本", @"４本", @"５本",
     @"１本", @"１本", @"１本", @"１本", @"１本",
     nil];
    
    [pickerValueList retain];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    prefecturePicker.delegate = self;
    prefecturePicker.dataSource = self;
    prefecturePicker.showsSelectionIndicator = YES;
    
    [prefecturePicker setBackgroundColor:[UIColor whiteColor]];
    [[prefecturePicker layer] setCornerRadius:6.0];
    [prefecturePicker setClipsToBounds:YES];
    [[prefecturePicker layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[prefecturePicker layer] setBorderWidth:1.0];
    
    [btnOK setBackgroundColor:[UIColor whiteColor]];
    [[btnOK layer] setCornerRadius:6.0];
    [btnOK setClipsToBounds:YES];
    [[btnOK layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnOK layer] setBorderWidth:1.0];
    
    [btnCancel setBackgroundColor:[UIColor whiteColor]];
    [[btnCancel layer] setCornerRadius:6.0];
    [btnCancel setClipsToBounds:YES];
    [[btnCancel layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnCancel layer] setBorderWidth:1.0];
    
//    initRow = 0;
//    for (NSString *pref in pickerValueList) {
//        if ([pref isEqualToString:initPfrefecture]) {
//            break;
//        }
//        initRow++;
//    }
//    if (initRow>=47) {
//        initRow = 0;
//    }
    
    [prefecturePicker selectRow:initRow inComponent:0 animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [prefecturePicker release];
    [btnOK release];
    [btnCancel release];
    [pickerValueList release];
    [super dealloc];
}
- (void)viewDidUnload {
    [prefecturePicker release];
    prefecturePicker = nil;
    [btnOK release];
    btnOK = nil;
    [btnCancel release];
    btnCancel = nil;
    [pickerValueList release];
    pickerValueList = nil;
    [super viewDidUnload];
}

#pragma mark
#pragma mark Action
/**
 * 都道府県設定(myDelegate呼び出し)
 */
- (IBAction)OnSetButton:(id)sender {
    if ([self.myDelegate respondsToSelector:@selector(OnSelectSet:selectNumber:)]) {
        [self.myDelegate OnSelectSet:_popUpID
                        selectNumber:[prefecturePicker selectedRowInComponent:0]];
    }
    
    [self closeByPopoverContoller];
}

/**
 * 設定キャンセル(myDelegate呼び出し)
 */
- (IBAction)OnCancelButton:(id)sender {
    if ([self.myDelegate respondsToSelector:@selector(OnSelectCancel:)]) {
        [self.myDelegate OnSelectCancel:_popUpID];
    }
    
    [self closeByPopoverContoller];
}

#pragma mark
#pragma mark Picker
/**
 * ピッカーに表示する列数の設定
 */
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

/**
 * ピッカーに表示する行数の設定
 */
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [pickerValueList count];
}

/**
 * ピッカーに表示する値の設定
 */
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [pickerValueList objectAtIndex:row];
}

@end
