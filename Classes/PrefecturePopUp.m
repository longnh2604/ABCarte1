//
//  PrefecturePopUp.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/07/25.
//
//

#import "PrefecturePopUp.h"

@interface PrefecturePopUp ()

@end

@implementation PrefecturePopUp

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
        lastPrefecture:(NSString *)lastPref
              callBack:(id)callBack
{
    if(self = [super initWithPopUpViewContoller:popUpID popOverController:nil callBack:callBack nibName:@"PrefecturePopUp"]) {
        
        // ポップアップサイズ
        self.contentSizeForViewInPopover = CGSizeMake(240.0f, 311.0f);
        
        // 都道府県リスト初期化
        [self initPrefectureList];
        
        initPfrefecture = [lastPref copy];
        
        myDelegate = callBack;
    }
    return self;
}

/**
 * 都道府県リストの設定
 */
- (void)initPrefectureList
{
    // ピッカー初期設定
    pickerValueList =
    [NSArray arrayWithObjects:
     @"北海道", @"青森県", @"岩手県", @"宮城県", @"秋田県",
     @"山形県", @"福島県", @"茨城県", @"栃木県", @"群馬県",
     @"埼玉県", @"千葉県", @"東京都", @"神奈川県", @"新潟県",
     @"富山県", @"石川県", @"福井県", @"山梨県", @"長野県",
     @"岐阜県", @"静岡県", @"愛知県", @"三重県", @"滋賀県",
     @"京都府", @"大阪府", @"兵庫県", @"奈良県", @"和歌山県",
     @"鳥取県", @"島根県", @"岡山県", @"広島県", @"山口県",
     @"徳島県", @"香川県", @"愛媛県", @"高知県", @"福岡県",
     @"佐賀県", @"長崎県", @"熊本県", @"大分県", @"宮崎県",
     @"鹿児島県", @"沖縄県", nil];
    
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
    
    initRow = 0;
    for (NSString *pref in pickerValueList) {
        if ([pref isEqualToString:initPfrefecture]) {
            break;
        }
        initRow++;
    }
    if (initRow>=47) {
        initRow = 0;
    }
    
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
    if ([self.myDelegate respondsToSelector:@selector(OnPrefectureSet:)]) {
        [self.myDelegate OnPrefectureSet:[pickerValueList objectAtIndex:[prefecturePicker selectedRowInComponent:0]]];
    }
    
    [self closeByPopoverContoller];
}

/**
 * 設定キャンセル(myDelegate呼び出し)
 */
- (IBAction)OnCancelButton:(id)sender {
    if ([self.myDelegate respondsToSelector:@selector(OnPrefectureCancel)]) {
        [self.myDelegate OnPrefectureCancel];
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
