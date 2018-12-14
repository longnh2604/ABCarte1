//
//  AgePickerPopUp.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/03/25.
//
//

#import "AgePickerPopUp.h"

#import "Common.h"

@interface AgePickerPopUp ()

@end

@implementation AgePickerPopUp

@synthesize myDelegate;
@synthesize age;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// ピッカーの初期化
// 年齢取得
- (id) initWithAgeSetting:(NSInteger)init_age
                  popUpID:(NSUInteger)popUpID
                 callBack:(id)callBack
{
    if(self = [super initWithPopUpViewContoller:popUpID popOverController:nil callBack:callBack nibName:@"AgePickerPopUp"]) {
        
        // ポップアップサイズ
        self.contentSizeForViewInPopover = CGSizeMake(240.0f, 330.0f);

        // ピッカー初期設定
        pickerValueAgeList = [[NSMutableArray alloc] init];
        
        [pickerValueAgeList addObject:@""];
        [pickerValueAgeList addObject:@"10代"];
        [pickerValueAgeList addObject:@"20代"];
        [pickerValueAgeList addObject:@"30代"];
        [pickerValueAgeList addObject:@"40代"];
        [pickerValueAgeList addObject:@"50代"];
        [pickerValueAgeList addObject:@"60代"];
        [pickerValueAgeList addObject:@"その他"];
        
        // 年代の保存
        realAge = (init_age / 10);
        myDelegate = callBack;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    apSetAge.delegate = self;
    apSetAge.dataSource = self;
    apSetAge.showsSelectionIndicator = YES;
    
    // デフォルトの年代設定
    [apSetAge selectRow:realAge inComponent:0 animated:YES];
    
    // 角を丸める
    [Common cornerRadius4Control:lblTitle];

    [apSetAge setBackgroundColor:[UIColor whiteColor]];
    [[apSetAge layer] setCornerRadius:6.0];
    [apSetAge setClipsToBounds:YES];
    [[apSetAge layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[apSetAge layer] setBorderWidth:1.0];

    [btnSet setBackgroundColor:[UIColor whiteColor]];
    [[btnSet layer] setCornerRadius:6.0];
    [btnSet setClipsToBounds:YES];
    [[btnSet layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnSet layer] setBorderWidth:1.0];
    
    [btnCancel setBackgroundColor:[UIColor whiteColor]];
    [[btnCancel layer] setCornerRadius:6.0];
    [btnCancel setClipsToBounds:YES];
    [[btnCancel layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnCancel layer] setBorderWidth:1.0];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [btnCancel release];
    [btnSet release];
    [lblTitle release];
    [super dealloc];
}
- (void)viewDidUnload {
    [btnCancel release];
    btnCancel = nil;
    [btnSet release];
    btnSet = nil;
    [lblTitle release];
    lblTitle = nil;
    [super viewDidUnload];
}

// 年齢確定
- (IBAction)OnSetButton:(id)sender {
    if([self.myDelegate respondsToSelector:@selector(OnAgeSetOK)])
        [self.myDelegate OnAgeSetOK];

    [self closeByPopoverContoller];
}

// 年齢設定キャンセル
- (IBAction)OnCancelButton:(id)sender {
    if([self.myDelegate respondsToSelector:@selector(OnAgeSetCancel)])
        [self.myDelegate OnAgeSetCancel];
    
    [self closeByPopoverContoller];
}

#pragma mark - UIPopoverControllerDelegate
-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    //    _popoverController = nil;
    
    [self OnCancelButton:nil];
}

#pragma mark
#pragma mark Picker
/**
 * ピッカーに表示する列数を返す
 */
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    return 1;
}

/**
 * ピッカーに表示する行数を返す
 */
- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    return 8;
}

/**
 * ピッカーに表示する値を返す
 */
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    return [pickerValueAgeList objectAtIndex:row];
}
/**
 * ピッカーの値をリアルタイムに反映する
 */
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    age = [apSetAge selectedRowInComponent:0];
    
    if([self.myDelegate respondsToSelector:@selector(OnCheckAge:)])
        [self.myDelegate OnCheckAge:age];
}

@end
