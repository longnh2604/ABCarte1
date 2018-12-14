//
//  courseItemBaseViewController.m
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import "courseItemBaseViewController.h"

#import "NumberInputPopUp.h"
#import "UIPopoverControllerHelper.h"

#define POPUP_INTEGER_INPUT 1

@interface courseItemBaseViewController (override)

/** priceItemの設定：初期化時にコールされる
 *  ・ORとなるitemも含め、全てをリストに登録する
 *  ・表示する列毎に、ORがあってもなくてもgroupIDを設定する
 */
- (void) _priceItemSet;

// nib nameの指定
- (NSString*) _setNibName;

// viewのframe設定
- (CGRect) _viewFrameSet;

/** 価格ラベル（priceLabels）の設定：ViewDidLoadにてコールされる
 *  ・priceItemのリストに合わせてlabelを設定する
 *   （リスト数と同じに設定する：OR=groupIDが同一のものは同じLabelとなる）
 */
- (void) _priceLabelSet;

/**
 *  個数設定ボタンのtagはgroup毎に設定する
 *  例）course1の場合
 *      btn1.tag = 0    btn2.tag = 1        btn3.tag = 3
 *       ->item1         ->item2, item3      ->item4
 */

/**
 * Orアイテム変更時のimageとlabel変更
 *  Orアイテム選択ボタンのtagはitemListの通し番号となる
 *  例）course1の場合
 *      orBtn1.tag = 1    orBtn2.tag = 2
 *       ->item2         ->item3      
 * 
 */
- (void) _changeOrItemImageWitthBtnTag:(NSInteger)btnTag corseItem:(SomeCourseItemCommon*)item;

// リセット個数の取得
- (NSInteger) _setResetItemNum;

// ORアイテムボタンの選択の初期化
- (void) _initOrItemBtnSelect;

// 初期化するORアイテムのindex一覧を取得
- (void) _getInitOrItemIndexListWithBuffer:(NSMutableArray*)buffer;

// オプションの選択有効設定
- (void) _optionSelectEnbaleSet;

@end

@implementation courseItemBaseViewController

@synthesize isOptionPanstEnable = _isOptionPanstEnable;
@synthesize isOptionSpatsEnable = _isOptionSpatsEnable;

#pragma mark life_cycle
- (id)initWithNibName:(NSString *)nibNameOrNil notifyDelegate:(id<courseItemDelegate>)delegate
{
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    if (self) {
        self.delegate = delegate;
        self.priceItems = [[NSMutableArray alloc]init];
        
        // 派生クラスにてpriceItemを設定する
        [self _priceItemSet];
        
    }
    return self;
}

// 初期化
-(id) initWithNotifyDelegate:(id<courseItemDelegate>)delegate
{
    return ([self initWithNibName:[self _setNibName] notifyDelegate:delegate]);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // viewの位置と大きさの設定
    [self.view setFrame:[self _viewFrameSet]];
    
    self.priceLabels = [[NSMutableArray alloc]init];
    // 派生クラスにて価格ラベル（priceLabels）を設定する
    [self _priceLabelSet];
    
    // デフォルトでオプションのパンストとスパッツは選択可とする
    _isOptionPanstEnable = _isOptionSpatsEnable = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    [self.priceLabels removeAllObjects];
    [self.priceLabels release];
    
    [self.priceItems removeAllObjects];
    [self.priceItems release];
    
    [super dealloc];
}

#pragma mark- control_events
// 個数入力
- (IBAction) OnBtnEditNumber:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    
    // 数値選択ポップアップのViewControllerのインスタンス生成 : POPUP_NUMBER_INPUT
    NumberInputPopUp *numInp
        = [[NumberInputPopUp alloc] initWithIntButton:(UIButton*)sender
                                            selectNum:[btn.currentTitle intValue]
                                              popUpID:POPUP_INTEGER_INPUT callBack:self ];
    // ポップアップViewの表示
    [UIPopoverControllerHelper presentPopoverWithDispViewController:numInp
                                                             inView:btn];
    
    numInp.popoverController = [UIPopoverControllerHelper getInstance].popoverController;
    [numInp release];
    numInp = nil;
}

// ORアイテム変更（ボタンイベント）
- (IBAction)OnBtnOrItemChange:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    //  btn.tag ：priceItemsの通し番号（1始まり）
    
    // 今回選択されたORアイテム
    SomeCourseItemCommon *item = [self.priceItems objectAtIndex:btn.tag];
    NSInteger grpID = item.groupID;
    
    // 派生クラスにてimageを変更する
    [self _changeOrItemImageWitthBtnTag:btn.tag  corseItem:item];
    
    [UIView animateWithDuration:0.75f animations:^{
        // 価格表示を更新
        [self _setPrice2Label:btn.tag];
        
    } completion:^(BOOL finished) {  }];

    // 一旦、関連するORアイテムを無効にする
    for (multiPriceCourseItem *item in self.priceItems){
        if (item.groupID != grpID) {
            continue;
        }
        item.isValid = NO;
    }

    // 今回選択されたORアイテムを有効にする
    item.isValid = YES;

    // 価格の変更をクライアントクラスに通知
    if (self.delegate) {
        // 合計額を求める
        NSInteger sum = [self calcItemSumPrice];
        [self.delegate courseItemViewController:self notifySumPriceChange:sum];
    }
}

#pragma mark PopUpViewContollerBaseDelegate

// 個数設定のpopup
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    UIButton *btn;
	switch (popUpID)
	{
        case POPUP_INTEGER_INPUT:
        // 数値入力
            btn = object;
            // 入力された個数
            NSInteger num = [btn.currentTitle intValue];
            // itemに個数を設定
            multiPriceCourseItem* item = [self.priceItems objectAtIndex:btn.tag];
            
            // 同じgroupIDのitemに個数を設定する
            for (multiPriceCourseItem *grpItem in self.priceItems){
                if (item.groupID != grpItem.groupID)
                {   continue; }
                
                grpItem.itemNum = num;
            }
            
            // 合計を算出
            NSInteger sum = [self calcItemSumPrice];
            // 合計額の変更をクライアントクラスに通知
            if (self.delegate) {
                [self.delegate courseItemViewController:self notifySumPriceChange:sum];
            }
            
            break;
    }
}

#pragma mark- private_methedos

// Groupの個数ボタンのリセット
- (void) _resetGrpNumBtn:(UIButton*) btn resetNum:(NSInteger)num
{
    if (! btn)
    {   return; }
    
    NSString *setNum = [NSString stringWithFormat:@"%d", num];
    
    [btn setTitle:setNum forState:UIControlStateNormal];
    [btn setTitle:setNum forState:UIControlStateHighlighted];
    [btn setTitle:setNum forState:UIControlStateDisabled];
}

#pragma mark- override_mehtods

/** priceItemの設定：初期化時にコールされる
 *  ・ORとなるitemも含め、全てをリストに登録する
 *  ・表示する列毎に、ORがあってもなくてもgroupIDを設定する
 */
- (void) _priceItemSet{    }

/** 価格ラベル（priceLabels）の設定：ViewDidLoadにてコールされる
 *  ・priceItemのリストに合わせてlabelを設定する
 *   （リスト数と同じに設定する：OR=groupIDが同一のものは同じLabelとなる）
 */
- (void) _priceLabelSet{    }

// viewのframe設定
- (CGRect) _viewFrameSet
{   return COURSE_ITEM_VIEW_FRAME; }

/**
 * Orアイテム変更時のimageとlabel変更
 *  Orアイテム選択ボタンのtagはitemListの通し番号となる
 *  例）course1の場合
 *      orBtn1.tag = 1    orBtn2.tag = 2
 *       ->item2         ->item3
 *
 */
- (void) _changeOrItemImageWitthBtnTag:(NSInteger)btnTag corseItem:(SomeCourseItemCommon*)item{     }


// 価格ラベルの設定
- (void) _setPrice2Label:(NSInteger)idx
{
    multiPriceCourseItem *item = [self.priceItems objectAtIndex:idx];
    UILabel *lbl = [self.priceLabels objectAtIndex:idx];
    NSNumberFormatter *format = [[NSNumberFormatter alloc] init];
    [format setPositiveFormat:@"###,###,##0"];
    lbl.text = [NSString stringWithFormat:@"%@%@",
                [format currencySymbol],
                [format stringFromNumber:[NSNumber numberWithInt:item.itemPrice]]];
    [format release];
}

// リセット個数の取得 : デフォルトは１個
- (NSInteger) _setResetItemNum
{   return 1; }

// ORアイテムボタンの選択の初期化
- (void) _initOrItemBtnSelect
{   }

// 初期化するORアイテムのindex一覧を取得
- (void) _getInitOrItemIndexListWithBuffer:(NSMutableArray*)buffer
{   }

// オプションの選択有効設定
- (void) _optionSelectEnbaleSet
{   }

#pragma mark- public_methods

/**
 * サイズ変更の通知
 * @param   CourceItemPrice     : 変更となるサイズ
 * @return  このViewControllerが管理するitemの合計額
 */
-(NSInteger) notifyChangeSizeWithCourceItemPrice:(CourseItemPrice)itemPrice
{
    NSInteger idx = 0;
    for (multiPriceCourseItem* item in self.priceItems) {
        
        // itemに変更を通知
        [item setCourseItem :itemPrice];
        
        // 無効であるものは価格表示を更新しない
        if (! item.isValid)
        {   continue; }
        
        // 価格表示を更新
        [self _setPrice2Label:idx];
        
        idx++;
    }
    
    // 合計を求める
    return ([self calcItemSumPrice]);
}

// このViewControllerが管理するitemの合計額
- (NSInteger) calcItemSumPrice
{
    NSInteger sum = 0;
    
    for (multiPriceCourseItem* item in self.priceItems) {
        // 無効時はskip
        if (! item.isValid) {
            continue;
        }
        
        sum += [item getSumPrice];
    }
    
    return (sum);
}

// コースのitemのリセット
- (void) resetCourseItems
{
    // コースitemをリセットする個数を取得
    NSInteger resetNum = [self _setResetItemNum];
    // コースitemの個数をリセット
    for (multiPriceCourseItem *item in self.priceItems) {
        item.itemNum = resetNum;
    }
    
    // Groupの個数ボタンのリセット
    [self _resetGrpNumBtn:btnGrp1Num resetNum:resetNum];
    [self _resetGrpNumBtn:btnGrp2Num resetNum:resetNum];
    [self _resetGrpNumBtn:btnGrp3Num resetNum:resetNum];
    [self _resetGrpNumBtn:btnGrp4Num resetNum:resetNum];
    [self _resetGrpNumBtn:btnGrp5Num resetNum:resetNum];
    
    // ORアイテムボタンの選択の初期化
    [self _initOrItemBtnSelect];
    
    // 初期化するORアイテムのindex一覧を取得
    NSMutableArray *initOrItemIdxs = [NSMutableArray array];
    [self  _getInitOrItemIndexListWithBuffer:initOrItemIdxs];
    
    for (NSNumber *numIdx in initOrItemIdxs) {
        NSInteger idx = [numIdx integerValue];
        
        // 設定するORアイテム
        SomeCourseItemCommon *item = [self.priceItems objectAtIndex:idx];
        NSInteger grpID = item.groupID;
        
        // 派生クラスにてimageを変更する
        [self _changeOrItemImageWitthBtnTag:idx  corseItem:item];
        
        // 価格表示を更新
        [self _setPrice2Label:idx];
        
        // 一旦、関連するORアイテムを無効にする
        for (multiPriceCourseItem *item in self.priceItems){
            if (item.groupID != grpID) {
                continue;
            }
            item.isValid = NO;
        }
        
        // 今回選択されたORアイテムを有効にする
        item.isValid = YES;
    }
    
    [initOrItemIdxs removeAllObjects];
    
    // オプションの選択有効設定
    [self _optionSelectEnbaleSet];
}

@end
