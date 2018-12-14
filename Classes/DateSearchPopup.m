//
//  DateSearchPopup.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/12/02.
//
//

#import "DateSearchPopup.h"
#import "DatePickerPopUp.h"
#import "DatePickerSeparatePopUp.h"

#define START_SEARCH_DAY_POPUP  120001
#define END_SEARCH_DAY_POPUP    120002

enum SearchDateIndex
{
    DAY_TREATMENT = 1,
    LATEST_TREATMENT,
    FIRST_TREATMENT,
    INTERVAL_TREATMENT,
};

@interface DateSearchPopup ()

@end

@implementation DateSearchPopup

@synthesize ds_delegate;

- (id)initWithPopUpViewContoller:(NSUInteger)popUpID
               popOverController:(UIPopoverController *)controller
                        callBack:(id)callBackDelegate
{
    self = [super initWithPopUpViewContoller:popUpID
                           popOverController:controller
                                    callBack:callBackDelegate];
    if (self) {
        ds_delegate = callBackDelegate;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    NSArray *array = @[@"来店日", @"最新来店日", @"初回来店日", @"来店間隔"];
    arrayDocs = [@[@"来店日による検索を行います\n検索範囲の指定または日付を指定します",
                   @"最新来店日による検索を行います",
                   @"初回来店日による検索を行います",
                   @"指定日数以上の来店間隔がある顧客の検索を行います"] mutableCopy];
    arrayButtons    = [[NSMutableArray alloc] init];
    
    // 検索条件選択ボタンの初期化
    NSInteger i=DAY_TREATMENT;
    for (NSString *str in array) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(((i-1)*115)+20,50,100,35)];
        if (i==DAY_TREATMENT)
        {   // 初期検索条件は「施術日」検索とする
            btn.selected = YES;
            selectedSearchKind = DAY_TREATMENT;
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor blueColor]];
            [lblSearchDoc setText:[arrayDocs objectAtIndex:i-1]];
        }
        else
        {
            btn.selected = NO;
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [btn setBackgroundColor:[UIColor whiteColor]];
        }
        [btn setTitle:str forState:UIControlStateNormal];
        [[btn layer] setCornerRadius:6.0];
        [btn setClipsToBounds:YES];
        [[btn layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[btn layer] setBorderWidth:1.0];

        // IBで生成したボタンと同等の動作をさせる為の処理
        [btn addTarget:self action:@selector(onSetSearchKind:) forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(setBgColorForButton:) forControlEvents:UIControlEventTouchDown];
        [btn addTarget:self action:@selector(clearBgColorForButton:) forControlEvents:UIControlEventTouchDragExit];
        [btn addTarget:self action:@selector(setBgColorForButton:) forControlEvents:UIControlEventTouchDragInside];
        btn.tag = i++;
        [self.view addSubview:btn];
        [arrayButtons addObject:btn];
    }
    // 青枠表示に変えるパーツの処理
    NSArray *partsArr = @[btnOK, btnCancel];
    for (id parts in partsArr) {
        [parts setBackgroundColor:[UIColor whiteColor]];
        [[parts layer] setCornerRadius:6.0];
        [parts setClipsToBounds:YES];
        [[parts layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
        [[parts layer] setBorderWidth:1.0];
    }
    
    startDay = nil;
    endDay = nil;
    startDayComp = [[NSDateComponents alloc] init];
    startDayComp.year = 0;
    startDayComp.month = 0;
    startDayComp.day = 0;
    endDayComp = [[NSDateComponents alloc] init];
    endDayComp.year = 0;
    endDayComp.month = 0;
    endDayComp.day = 0;
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
    [btnStartDate release];
    [btnEndDate release];
    [btnOK release];
    [btnCancel release];
    [lblSearchDoc release];
    [lblTilde release];
    [txtInterval release];
    [lblIntervalDay release];
    [txtIntervalYear release];
    [lblIntervalYear release];
    [swSearchRange release];
    [super dealloc];
}
- (void)viewDidUnload {
    [btnStartDate release];
    btnStartDate = nil;
    [btnEndDate release];
    btnEndDate = nil;
    [btnOK release];
    btnOK = nil;
    [btnCancel release];
    btnCancel = nil;
    [lblSearchDoc release];
    lblSearchDoc = nil;
    [lblTilde release];
    lblTilde = nil;
    [txtInterval release];
    txtInterval = nil;
    [lblIntervalDay release];
    lblIntervalDay = nil;
    [txtIntervalYear release];
    txtIntervalYear = nil;
    [lblIntervalYear release];
    lblIntervalYear = nil;
    [swSearchRange release];
    swSearchRange = nil;
    [super viewDidUnload];
}

#pragma mark アクション処理部

// 検索開始範囲設定
- (IBAction)onSetStartDay:(id)sender {
    switch (selectedSearchKind) {
        case DAY_TREATMENT:
//            [self viewDatePickerPopUp:START_SEARCH_DAY_POPUP
//                          boundsPoint:sender
//                          CurrentDate:startDay];
//            break;
        case LATEST_TREATMENT:
        case FIRST_TREATMENT:
            [self viewDatePickerSeparetePopUp:START_SEARCH_DAY_POPUP
                                  boundsPoint:sender
                                  CurrentDate:startDay];
            break;
        case INTERVAL_TREATMENT:
            break;
        default:
            break;
    }
}

// 検索終了範囲設定
- (IBAction)onSetEndDay:(id)sender {
    switch (selectedSearchKind) {
        case DAY_TREATMENT:
//            [self viewDatePickerPopUp:END_SEARCH_DAY_POPUP
//                          boundsPoint:sender
//                          CurrentDate:endDay];
//            break;
        case LATEST_TREATMENT:
        case FIRST_TREATMENT:
            [self viewDatePickerSeparetePopUp:END_SEARCH_DAY_POPUP
                                  boundsPoint:sender
                                  CurrentDate:endDay];
            break;
        case INTERVAL_TREATMENT:
            break;
        default:
            break;
    }
}

// 日付設定ポップアップ呼び出し
- (void)viewDatePickerPopUp:(NSInteger)popUpID boundsPoint:(UIButton *)btn CurrentDate:(NSDate *)date
{
    DatePickerPopUp *vcDatePicker;
    // 日付の設定ポップアップのViewControllerのインスタンス生成
    if (date)
    {   // 再設定の場合
        vcDatePicker
        = [[DatePickerPopUp alloc]initWithDatePopUpViewContoller:popUpID
                                               popOverController:nil
                                                        callBack:self
                                                        initDate:date];
    }
    else
    {
        // 初回設定の場合
        vcDatePicker
        = [[DatePickerPopUp alloc]initWithPopUpViewContoller:popUpID
                                           popOverController:nil
                                                    callBack:self];
    }
    
    // ポップアップViewの表示
    UIPopoverController *popoverCntl = [[UIPopoverController alloc]
                                        initWithContentViewController:vcDatePicker];
    vcDatePicker.popoverController = popoverCntl;
    [popoverCntl presentPopoverFromRect:btn.bounds
                                 inView:btn
               permittedArrowDirections:UIPopoverArrowDirectionAny
                               animated:YES];
    [popoverCntl setPopoverContentSize:CGSizeMake(332.0f, 364.0f)];
    
    vcDatePicker.lblTitle.text = @"検索する来店日を設定してください";
    
    [popoverCntl release];
    [vcDatePicker release];
}

// 日付設定ポップアップ呼び出し
- (void)viewDatePickerSeparetePopUp:(NSInteger)popUpID
                        boundsPoint:(UIButton *)btn
                        CurrentDate:(NSDate *)date
{
    DatePickerSeparatePopUp *vcDatePicker;
    // 日付の設定ポップアップのViewControllerのインスタンス生成
//    if (date)
//    {   // 再設定の場合
//        vcDatePicker
//        = [[DatePickerSeparatePopUp alloc]initWithDatePopUpViewContoller:popUpID
//                                               popOverController:nil
//                                                        callBack:self
//                                                        initDate:date];
//    }
//    else
    {
        // 初回設定の場合
        vcDatePicker
        = [[DatePickerSeparatePopUp alloc]initWithPopUpViewContoller:popUpID
                                           popOverController:nil
                                                    callBack:self];
    }
    
    // ポップアップViewの表示
    UIPopoverController *popoverCntl = [[UIPopoverController alloc]
                                        initWithContentViewController:vcDatePicker];
    vcDatePicker.popoverController = popoverCntl;
    [popoverCntl presentPopoverFromRect:btn.bounds
                                 inView:btn
               permittedArrowDirections:UIPopoverArrowDirectionAny
                               animated:YES];
    [popoverCntl setPopoverContentSize:CGSizeMake(350.0f, 265.0f)];
    
//    vcDatePicker.lblTitle.text = @"検索する施術日を設定してください";
    
    [popoverCntl release];
    [vcDatePicker release];
}

/**
 検索種別ボタンの選択状態表示の変更
 */
- (void)onSetSearchKind:(UIButton *)button
{
    selectedSearchKind = button.tag;
    switch (button.tag) {
        case DAY_TREATMENT:
            // 施術日検索
            [self selectedButtonHighlight:selectedSearchKind];
            [self partsHidden:0];
            break;
        case LATEST_TREATMENT:
            // 最新施術日検索
            [self selectedButtonHighlight:selectedSearchKind];
            [self partsHidden:0];
            break;
        case FIRST_TREATMENT:
            // 初回登録検索
            [self selectedButtonHighlight:selectedSearchKind];
            [self partsHidden:0];
            break;
        case INTERVAL_TREATMENT:
            // 来店間隔検索
            [self selectedButtonHighlight:selectedSearchKind];
            [self partsHidden:1];
            break;
        default:
            selectedSearchKind = DAY_TREATMENT;
            [self selectedButtonHighlight:selectedSearchKind];
            [self partsHidden:0];
            break;
    }
}

// 検索種別決定時の処理
-(void)selectedButtonHighlight:(NSInteger)num
{
    UIButton *btn;
    for (int i=0; i<[arrayButtons count]; i++) {
        btn = [arrayButtons objectAtIndex:i];
        if ((i+1) == num) {
            btn.selected = YES;
            [self setBgColorForButton:btn];
            // 検索種別の説明文表示
            [lblSearchDoc setText:[arrayDocs objectAtIndex:i]];
        } else {
            btn.selected = NO;
            [self clearBgColorForButton:btn];
        }
    }
}

// ボタン押下・DragInside時の処理
-(void)setBgColorForButton:(UIButton*)sender
{
    [sender setBackgroundColor:[UIColor blueColor]];
    [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

// ボタンDragExit時の処理
-(void)clearBgColorForButton:(UIButton*)sender
{
    if (sender.selected) {  // 選択中のボタンの場合はなにもしない(全非選択状態になってしまうため)
        return;
    }
    [sender setBackgroundColor:[UIColor whiteColor]];
    [sender setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

// 検索ボタン
- (IBAction)onSearchStart:(id)sender {
    switch (selectedSearchKind) {
        case DAY_TREATMENT:         // 施術日検索
//            [self OnSetButton:sender];    // 旧delegate I/F
            if([ds_delegate respondsToSelector:@selector(OnNormalWorkSearch:)]) {
                [self checkSearchDayRange];
                NSArray *arrayObject = @[startDayComp, endDayComp];
                [ds_delegate OnNormalWorkSearch:arrayObject];
            }
            [self closeByPopoverContoller];
            break;
        case LATEST_TREATMENT:      // 最新施術日検索
            if([ds_delegate respondsToSelector:@selector(OnLatestWorkSearch:)]) {
                [self checkSearchDayRange];
                NSArray *arrayObject = @[startDayComp, endDayComp];
                [ds_delegate OnLatestWorkSearch:arrayObject];
            }
            [self closeByPopoverContoller];
            break;
        case FIRST_TREATMENT:       // 初回施術日検索
            if ([ds_delegate respondsToSelector:@selector(OnFirstWorkSearch:)]) {
                [self checkSearchDayRange];
                NSArray *arrayObject = @[startDayComp, endDayComp];
                [ds_delegate OnFirstWorkSearch:arrayObject];
            }
            [self closeByPopoverContoller];
            break;
        case INTERVAL_TREATMENT:    // 来店間隔検索
            if (txtInterval.text.length==0) txtInterval.text = @"0";
            if (txtIntervalYear.text.length==0) txtIntervalYear.text = @"0";
            if ([ds_delegate respondsToSelector:@selector(OnIntervalWorkSearch:)]) {
                NSArray *arryObject = @[txtIntervalYear.text, txtInterval.text];
                [ds_delegate OnIntervalWorkSearch:arryObject];
            }
            [self closeByPopoverContoller];
            break;
        default:
            [self closeByPopoverContoller];
            break;
    }
}

- (IBAction)onSearchCancel:(id)sender {
    [self OnCancelButton:sender];
}

/**
 年入力フィールドから間隔入力フィールドへの移動
 */
- (IBAction)onTextDidEnd:(id)sender
{
    UITextField *textField = (UITextField*)sender;
    
    switch (textField.tag) {
        case 1:
            // 間隔入力フィールドへのカーソル移動
            [txtInterval becomeFirstResponder];
            break;
        default:
            // キーボードを隠す
            [textField resignFirstResponder];
            break;
    }
}

- (IBAction)onSearchRangeChanged:(id)sender {
    [self partsHidden:0];
}

#pragma mark Local
/**
 検索条件による各パーツの表示・非表示設定
 */
- (void)partsHidden:(NSInteger)pattern
{
    switch (pattern) {
        case 0:
            // 日付検索時
            btnStartDate.hidden = NO;
            if (swSearchRange.selectedSegmentIndex==0)
            {   // 範囲検索時
                btnEndDate.hidden = NO;
                lblTilde.hidden = NO;
            }
            else
            {   // 単独日付検索時
                btnEndDate.hidden = YES;
                lblTilde.hidden = YES;
            }
            swSearchRange.hidden = NO;
            txtInterval.hidden = YES;
            lblIntervalDay.hidden = YES;
            txtIntervalYear.hidden = YES;
            lblIntervalYear.hidden = YES;
            break;
        case 1:
            // 来店間隔検索時
            btnStartDate.hidden = YES;
            btnEndDate.hidden = YES;
            lblTilde.hidden = YES;
            swSearchRange.hidden = YES;
            txtInterval.hidden = NO;
            lblIntervalDay.hidden = NO;
            txtIntervalYear.hidden = NO;
            lblIntervalYear.hidden = NO;
            break;
        default:
            btnStartDate.hidden = NO;
            btnEndDate.hidden = NO;
            lblTilde.hidden = NO;
            swSearchRange.hidden = NO;
            txtInterval.hidden = YES;
            lblIntervalDay.hidden = YES;
            txtIntervalYear.hidden = YES;
            lblIntervalYear.hidden = YES;
            break;
    }
}

// 範囲指定の片方が設定されていない場合の処理
- (void)checkSearchDayRange
{
    if (swSearchRange.selectedSegmentIndex==0) {
        // 範囲設定時
        if (startDayComp.year==0 && startDayComp.month==0 && startDayComp.day==0) {
            NSDate* date = [NSDate dateWithTimeIntervalSince1970:0];
            NSCalendar* calendar = [NSCalendar currentCalendar];
            startDayComp = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
                                       fromDate:date];
        }
        if (endDayComp.year==0 && endDayComp.month==0 && endDayComp.day==0) {
            NSDate* date = [NSDate date];
            NSCalendar* calendar = [NSCalendar currentCalendar];
            endDayComp = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit)
                                     fromDate:date];
        }
    }
}

#pragma mark PopUpViewBaseDelegate

// 日付選択ポップアップで決定された場合に呼ばれる
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    // 日付書式の設定
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:@"yyyy / MM / dd"];
    NSDateComponents *comp;

    if (popUpID == START_SEARCH_DAY_POPUP) {
        switch (selectedSearchKind) {
            case DAY_TREATMENT:
//                [btnStartDate setTitle:[formatter stringFromDate:(NSDate *)object] forState:UIControlStateNormal];
//                if (startDay) [startDay release];
//                startDay = [(NSDate *)object copy];
//                break;
            case LATEST_TREATMENT:
            case FIRST_TREATMENT:
                comp = (NSDateComponents *)object;
                [btnStartDate setTitle:[NSString stringWithFormat:@"%@ / %@ / %@",
                                        (comp.year>0)? [NSString stringWithFormat:@"%ld", (long)comp.year] : @"----",
                                        (comp.month>0)? [NSString stringWithFormat:@"%02ld", (long)comp.month] : @"--",
                                        (comp.day>0)? [NSString stringWithFormat:@"%02ld", (long)comp.day] : @"--"]
                              forState:UIControlStateNormal];
                if (startDayComp) [startDayComp release];
                startDayComp = [(NSDateComponents *)object copy];
                break;
            case INTERVAL_TREATMENT:
                break;
            default:
                break;
        }
    }
    else if (popUpID == END_SEARCH_DAY_POPUP) {
        switch (selectedSearchKind) {
            case DAY_TREATMENT:
//                [btnEndDate setTitle:[formatter stringFromDate:(NSDate *)object] forState:UIControlStateNormal];
//                if (endDay) [endDay release];
//                endDay = [(NSDate *)object copy];
//                break;
            case LATEST_TREATMENT:
            case FIRST_TREATMENT:
                comp = (NSDateComponents *)object;
                [btnEndDate setTitle:[NSString stringWithFormat:@"%@ / %@ / %@",
                                      (comp.year>0)? [NSString stringWithFormat:@"%ld", (long)comp.year] : @"----",
                                      (comp.month>0)? [NSString stringWithFormat:@"%02ld", (long)comp.month] : @"--",
                                      (comp.day>0)? [NSString stringWithFormat:@"%02ld", (long)comp.day] : @"--"]
                            forState:UIControlStateNormal];
                if (endDayComp) [endDayComp release];
                endDayComp = [(NSDateComponents *)object copy];
                break;
            case INTERVAL_TREATMENT:
                break;
            default:
                break;
        }
    }
}
- (void)OnPopupViewFinished:(NSUInteger)popUpID setObject:(id)object Sender:(id)sender
{
    
}

// delegate objectの設定:設定ボタンおよびあ行など行ボタンのclick時にコールされるs
- (id) setDelegateObject
{
    // 選択された日付を返す
    NSDate *date = startDay;
    return(date);
}

@end
