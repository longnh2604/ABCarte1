//
//  course1ItemViewController.m
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import "courseItemCommonViewController.h"
#import "SomeCourseItemCommon.h"

@interface course1ItemViewController ()

@end

@implementation course1ItemViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    btnSortGurdle.border = YES;
    
    // オプション：パンストは選択不可　スパッツは選択可
    _isOptionPanstEnable = NO;
    _isOptionSpatsEnable = YES;
}

#pragma mark- override_mehtods

// nib nameの指定
- (NSString*) _setNibName
{   return (@"course1ItemViewController"); }

/** priceItemの設定：初期化時にコールされる
 *  ・ORとなるitemも含め、全てをリストに登録する
 *  ・表示する列毎に、ORがあってもなくてもgroupIDを設定する
 */
- (void) _priceItemSet
{
    // ニッパービスチェ:group1
    niperBistchCourseItem *item1 = [[niperBistchCourseItem alloc]initCourseItem];
    item1.groupID = 1;
    [self.priceItems addObject:item1];
    [item1 release];
    
    // ハイウエストショートガードル or ハイウエストガードル：group2
    highWestShortGirdleCourseItem *item21 = [[highWestShortGirdleCourseItem alloc]initCourseItem];
    item21.groupID = 2;
    [self.priceItems addObject:item21];
    [item21 release];
    highWestGirdleCourseItem *item22 = [[highWestGirdleCourseItem alloc]initCourseItem];
    item22.groupID = 2;
    item22.isValid = NO;
    [self.priceItems addObject:item22];
    [item22 release];
    
    
    // パンスト：gropu3
    pantyhoseCourseItem *item3 = [[pantyhoseCourseItem alloc]initCourseItem];
    item3.groupID = 3;
    [self.priceItems addObject:item3];
    [item3 release];
    
}

/** 価格ラベル（priceLabels）の設定：ViewDidLoadにてコールされる
 *  ・priceItemのリストに合わせてlabelを設定する
 *   （リスト数と同じに設定する：OR=groupIDが同一のものは同じLabelとなる）
 */
- (void) _priceLabelSet
{
    [self.priceLabels addObjectsFromArray:
        [NSArray arrayWithObjects:lblGrp1Price, lblGrp2Price, lblGrp2Price, lblGrp3Price, nil]];
}

/**
 * Orアイテム変更時のimageとlabel変更
 *  Orアイテム選択ボタンのtagはitemListの通し番号となる
 *  例）course1の場合
 *      orBtn1.tag = 1    orBtn2.tag = 2
 *       ->item2         ->item3
 *
 */
- (void) _changeOrItemImageWitthBtnTag:(NSInteger)btnTag corseItem:(SomeCourseItemCommon*)item
{
    UIImage* img = nil;
    NSString *name = nil;
    
    switch (btnTag) {
        case 1:
        case 2:
            img = [UIImage imageNamed:item.getImageName];
            name = item.getItemName;
            break;
        default:
            break;
    }
    
    if (img) {
        imgGrp2Image.image = img;
        lblGrp2Name.text = name;
    }
}

// ORアイテムボタンの選択の初期化
- (void) _initOrItemBtnSelect
{
    btnSortGurdle.border = YES;
    btnGurdle.border = NO;
}

// 初期化するORアイテムのindex一覧を取得
- (void) _getInitOrItemIndexListWithBuffer:(NSMutableArray*)buffer
{
    [buffer addObject: [NSNumber numberWithInteger:1]];
}

@end

@implementation course2ItemViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    btnRegulerGurdle.border = YES;
}

#pragma mark- override_mehtods

// nib nameの指定
- (NSString*) _setNibName
{   return (@"course2ItemViewController"); }

/** priceItemの設定：初期化時にコールされる
 *  ・ORとなるitemも含め、全てをリストに登録する
 *  ・表示する列毎に、ORがあってもなくてもgroupIDを設定する
 */
- (void) _priceItemSet
{
    // Tバックボディスーツ:group1
    tBackBodySuitCourseItem *item1
        = [[tBackBodySuitCourseItem alloc]initCourseItem];
    item1.groupID = 1;
    [self.priceItems addObject:item1];
    [item1 release];
    
    // ガードル or パンスト or スパッツ：group2
    regulerGirdleCourseItem *item21 = [[regulerGirdleCourseItem alloc]initCourseItem];
    item21.groupID = 2;
    [self.priceItems addObject:item21];
    [item21 release];
    
    pantyhoseCourseItem *item22 = [[pantyhoseCourseItem alloc]initCourseItem];
    item22.groupID = 2;
    item22.isValid = NO;
    [self.priceItems addObject:item22];
    [item22 release];
    
    spatsCourseItem *item23 = [[spatsCourseItem alloc]initCourseItem];
    item23.groupID = 2;
    item23.isValid = NO;
    [self.priceItems addObject:item23];
    [item23 release];
    
}

/** 価格ラベル（priceLabels）の設定：ViewDidLoadにてコールされる
 *  ・priceItemのリストに合わせてlabelを設定する
 *   （リスト数と同じに設定する：OR=groupIDが同一のものは同じLabelとなる）
 */
- (void) _priceLabelSet
{
    [self.priceLabels addObjectsFromArray:
     [NSArray arrayWithObjects:lblGrp1Price, lblGrp2Price, lblGrp2Price, lblGrp2Price, nil]];
}

/**
 * Orアイテム変更時のimageとlabel変更
 *  Orアイテム選択ボタンのtagはitemListの通し番号となる
 *  例）course1の場合
 *      orBtn1.tag = 1    orBtn2.tag = 2
 *       ->item2         ->item3
 *
 */
- (void) _changeOrItemImageWitthBtnTag:(NSInteger)btnTag corseItem:(SomeCourseItemCommon*)item
{
    UIImage* img = nil;
    NSString *name = nil;
    
    switch (btnTag) {
        case 1:
        case 2:
        case 3:
            img = [UIImage imageNamed:item.getImageName];
            name = item.getItemName;
            break;
        default:
            break;
    }
    
    if (img) {
        imgGrp2Image.image = img;
        lblGrp2Name.text = name;
    }
    
    // オプションのパンストとスパッツの有効を設定
    _isOptionPanstEnable = (btnTag != 2);
    _isOptionSpatsEnable = (btnTag != 3);
}

// ORアイテムボタンの選択の初期化
- (void) _initOrItemBtnSelect
{
    btnRegulerGurdle.border = YES;
    btnPanst.border = NO;
    btnSpats.border = NO;
}

// 初期化するORアイテムのindex一覧を取得
- (void) _getInitOrItemIndexListWithBuffer:(NSMutableArray*)buffer
{
    [buffer addObject: [NSNumber numberWithInteger:1]];
}

// オプションの選択有効設定
- (void) _optionSelectEnbaleSet
{
    // オプション：初期時は、パンストは選択可　スパッツは選択可
    _isOptionPanstEnable = YES;
    _isOptionSpatsEnable = YES;
}

@end

@implementation course3ItemViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    btnGrp11.border = YES;
    btnGrp21.border = YES;
    btnGrp31.border = YES;
}

#pragma mark- override_mehtods

// nib nameの指定
- (NSString*) _setNibName
{   return (@"course3ItemViewController"); }

/** priceItemの設定：初期化時にコールされる
 *  ・ORとなるitemも含め、全てをリストに登録する
 *  ・表示する列毎に、ORがあってもなくてもgroupIDを設定する
 */
- (void) _priceItemSet
{
    // 3/4カップブラジャー or フルカップブラジャー:group1
    trQuatCupBrassiereCourseItem *item11 = [[trQuatCupBrassiereCourseItem alloc]initCourseItem];
    item11.groupID = 1;
    [self.priceItems addObject:item11];
    [item11 release];
    fullCupBrassiereCourseItem *item12 = [[fullCupBrassiereCourseItem alloc]initCourseItem];
    item12.groupID = 1;
    item12.isValid = NO;
    [self.priceItems addObject:item12];
    [item12 release];
    
    // 袖付ボディースーツ or ララドール：group2
    sleevesBodySuiteCourseItem *item21 = [[sleevesBodySuiteCourseItem alloc]initCourseItem];
    item21.groupID = 2;
    [self.priceItems addObject:item21];
    [item21 release];
    lalaDoleCourseItem *item22 = [[lalaDoleCourseItem alloc]initCourseItem];
    item22.groupID = 2;
    item22.isValid = NO;
    [self.priceItems addObject:item22];
    [item22 release];
    
    // レギュラーガードル or パンスト or スパッツ：gropu3
    regulerGirdleCourseItem *item31 = [[regulerGirdleCourseItem alloc]initCourseItem];
    item31.groupID = 3;
    [self.priceItems addObject:item31];
    [item31 release];
    pantyhoseCourseItem *item32 = [[pantyhoseCourseItem alloc]initCourseItem];
    item32.groupID = 3;
    item32.isValid = NO;
    [self.priceItems addObject:item32];
    [item32 release];
    spatsCourseItem *item33 = [[spatsCourseItem alloc]initCourseItem];
    item33.groupID = 3;
    item33.isValid = NO;
    [self.priceItems addObject:item33];
    [item33 release];
    
}

/** 価格ラベル（priceLabels）の設定：ViewDidLoadにてコールされる
 *  ・priceItemのリストに合わせてlabelを設定する
 *   （リスト数と同じに設定する：OR=groupIDが同一のものは同じLabelとなる）
 */
- (void) _priceLabelSet
{
    [self.priceLabels addObjectsFromArray:
     [NSArray arrayWithObjects: lblGrp1Price, lblGrp1Price,
                                lblGrp2Price, lblGrp2Price,
                                lblGrp3Price, lblGrp3Price, lblGrp3Price, nil]];
}

/**
 * Orアイテム変更時のimageとlabel変更
 *  Orアイテム選択ボタンのtagはitemListの通し番号となる
 *  例）course1の場合
 *      orBtn1.tag = 1    orBtn2.tag = 2
 *       ->item2         ->item3
 *
 */
- (void) _changeOrItemImageWitthBtnTag:(NSInteger)btnTag corseItem:(SomeCourseItemCommon*)item
{
    if ((0 > btnTag) || (btnTag > 6) )
    {   return; }   // 対象外
    
    UIImageView *imgVw = nil;
    UILabel *lbl = nil;
    
    switch (btnTag) {
        case 0:
        case 1:
            imgVw = imgGrp1Image;
            lbl = lblGrp1Name;
            break;
        case 2:
        case 3:
            imgVw = imgGrp2Image;
            lbl = lblGrp2Name;
            break;
        case 4:
        case 5:
        case 6:
            imgVw = imgGrp3Image;
            lbl = lblGrp3Name;
            break;

        default:
            break;
    }
    
    if (imgVw) {
        imgVw.image = [UIImage imageNamed:item.getImageName];;
        lbl.text = item.getItemName;
    }
    
    // オプションのパンストとスパッツの有効を設定
    _isOptionPanstEnable = (btnTag != 5);
    _isOptionSpatsEnable = (btnTag != 6);
}

// ORアイテムボタンの選択の初期化
- (void) _initOrItemBtnSelect
{
    btnGrp11.border = YES;
    btnGrp12.border = NO;
    btnGrp21.border = YES;
    btnGrp22.border = NO;
    btnGrp31.border = YES;
    btnGrp32.border = NO;
    btnGrp33.border = NO;
}

// 初期化するORアイテムのindex一覧を取得
- (void) _getInitOrItemIndexListWithBuffer:(NSMutableArray*)buffer
{
    [buffer addObject: [NSNumber numberWithInteger:0]];
    [buffer addObject: [NSNumber numberWithInteger:2]];
    [buffer addObject: [NSNumber numberWithInteger:4]];
}

// オプションの選択有効設定
- (void) _optionSelectEnbaleSet
{
    // オプション：初期時は、パンストは選択可　スパッツは選択可
    _isOptionPanstEnable = YES;
    _isOptionSpatsEnable = YES;
}

@end

@implementation course4ItemViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    btnGrp11.border = YES;
    btnGrp31.border = YES;
}

#pragma mark- override_mehtods

// nib nameの指定
- (NSString*) _setNibName
{   return (@"course4ItemViewController"); }

/** priceItemの設定：初期化時にコールされる
 *  ・ORとなるitemも含め、全てをリストに登録する
 *  ・表示する列毎に、ORがあってもなくてもgroupIDを設定する
 */
- (void) _priceItemSet
{
    // 3/4カップブラジャー or フルカップブラジャー:group1
    trQuatCupBrassiereCourseItem *item11 = [[trQuatCupBrassiereCourseItem alloc]initCourseItem];
    item11.groupID = 1;
    [self.priceItems addObject:item11];
    [item11 release];
    fullCupBrassiereCourseItem *item12 = [[fullCupBrassiereCourseItem alloc]initCourseItem];
    item12.groupID = 1;
    item12.isValid = NO;
    [self.priceItems addObject:item12];
    [item12 release];
    
    // ウエストニッパー：group2
    waistNipperCourseItem *item21 = [[waistNipperCourseItem alloc]initCourseItem];
    item21.groupID = 2;
    [self.priceItems addObject:item21];
    [item21 release];
    
    // レギュラーガードル or パンスト or スパッツ：gropu3
    regulerGirdleCourseItem *item31 = [[regulerGirdleCourseItem alloc]initCourseItem];
    item31.groupID = 3;
    [self.priceItems addObject:item31];
    [item31 release];
    pantyhoseCourseItem *item32 = [[pantyhoseCourseItem alloc]initCourseItem];
    item32.groupID = 3;
    item32.isValid = NO;
    [self.priceItems addObject:item32];
    [item32 release];
    spatsCourseItem *item33 = [[spatsCourseItem alloc]initCourseItem];
    item33.groupID = 3;
    item33.isValid = NO;
    [self.priceItems addObject:item33];
    [item33 release];
    
}

/** 価格ラベル（priceLabels）の設定：ViewDidLoadにてコールされる
 *  ・priceItemのリストに合わせてlabelを設定する
 *   （リスト数と同じに設定する：OR=groupIDが同一のものは同じLabelとなる）
 */
- (void) _priceLabelSet
{
    [self.priceLabels addObjectsFromArray:
     [NSArray arrayWithObjects:
      lblGrp1Price, lblGrp1Price,
      lblGrp2Price,
      lblGrp3Price, lblGrp3Price, lblGrp3Price, nil]];
}

/**
 * Orアイテム変更時のimageとlabel変更
 *  Orアイテム選択ボタンのtagはitemListの通し番号となる
 *  例）course1の場合
 *      orBtn1.tag = 1    orBtn2.tag = 2
 *       ->item2         ->item3
 *
 */
- (void) _changeOrItemImageWitthBtnTag:(NSInteger)btnTag corseItem:(SomeCourseItemCommon*)item
{
    if ((0 > btnTag) || (btnTag > 5) )
    {   return; }   // 対象外
    
    UIImageView *imgVw = nil;
    UILabel *lbl = nil;
    
    switch (btnTag) {
        case 0:
        case 1:
            imgVw = imgGrp1Image;
            lbl = lblGrp1Name;
            break;
        case 3:
        case 4:
        case 5:
            imgVw = imgGrp3Image;
            lbl = lblGrp3Name;
            break;
            
        default:
            break;
    }
    
    if (imgVw) {
        imgVw.image = [UIImage imageNamed:item.getImageName];;
        lbl.text = item.getItemName;
    }
    
    // オプションのパンストとスパッツの有効を設定
    _isOptionPanstEnable = (btnTag != 4);
    _isOptionSpatsEnable = (btnTag != 5);
}

// ORアイテムボタンの選択の初期化
- (void) _initOrItemBtnSelect
{
    btnGrp11.border = YES;
    btnGrp12.border = NO;
    btnGrp31.border = YES;
    btnGrp32.border = NO;
    btnGrp33.border = NO;
}

// 初期化するORアイテムのindex一覧を取得
- (void) _getInitOrItemIndexListWithBuffer:(NSMutableArray*)buffer
{
    [buffer addObject: [NSNumber numberWithInteger:0]];
    [buffer addObject: [NSNumber numberWithInteger:3]];
}

// オプションの選択有効設定
- (void) _optionSelectEnbaleSet
{
    // オプション：初期時は、パンストは選択可　スパッツは選択可
    _isOptionPanstEnable = YES;
    _isOptionSpatsEnable = YES;
}

@end

@implementation course5ItemViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    btnGrp11.border = YES;
    btnGrp21.border = YES;
    
    // オプション：初期時は、パンストは選択可　スパッツは選択不可
    _isOptionPanstEnable = YES;
    _isOptionSpatsEnable = NO;
}

#pragma mark- override_mehtods

// nib nameの指定
- (NSString*) _setNibName
{   return (@"course5ItemViewController"); }

/** priceItemの設定：初期化時にコールされる
 *  ・ORとなるitemも含め、全てをリストに登録する
 *  ・表示する列毎に、ORがあってもなくてもgroupIDを設定する
 */
- (void) _priceItemSet
{
    // パンプ半袖 or パンプ７分袖 or パンプ十分袖:group1
    punpShortSleevesCourseItem *item11 = [[punpShortSleevesCourseItem alloc]initCourseItem];
    item11.groupID = 1;
    [self.priceItems addObject:item11];
    [item11 release];
    punpSevenSleevesCourseItem *item12 = [[punpSevenSleevesCourseItem alloc]initCourseItem];
    item12.groupID = 1;
    item12.isValid = NO;
    [self.priceItems addObject:item12];
    [item12 release];
    punpTenSleevesCourseItem *item13 = [[punpTenSleevesCourseItem alloc]initCourseItem];
    item13.groupID = 1;
    item13.isValid = NO;
    [self.priceItems addObject:item13];
    [item13 release];
    
    // スパッツ or レディースガードル（七分丈） or レディースガードル（五分丈）： or レディースガードル（十分丈）gropu3
    spatsCourseItem *item21 = [[spatsCourseItem alloc]initCourseItem];
    item21.groupID = 2;
    [self.priceItems addObject:item21];
    [item21 release];
    ladiesGirdleSevenSleevesCourseItem *item22 = [[ladiesGirdleSevenSleevesCourseItem alloc]initCourseItem];
    item22.groupID = 2;
    item22.isValid = NO;
    [self.priceItems addObject:item22];
    [item22 release];
    ladiesGirdleFiveSleevesCourseItem *item23 = [[ladiesGirdleFiveSleevesCourseItem alloc]initCourseItem];
    item23.groupID = 2;
    item23.isValid = NO;
    [self.priceItems addObject:item23];
    [item23 release];
    ladiesGirdleTenSleevesCourseItem *item24 = [[ladiesGirdleTenSleevesCourseItem alloc]initCourseItem];
    item24.groupID = 2;
    item24.isValid = NO;
    [self.priceItems addObject:item24];
    [item24 release];
    
}

/** 価格ラベル（priceLabels）の設定：ViewDidLoadにてコールされる
 *  ・priceItemのリストに合わせてlabelを設定する
 *   （リスト数と同じに設定する：OR=groupIDが同一のものは同じLabelとなる）
 */
- (void) _priceLabelSet
{
    [self.priceLabels addObjectsFromArray:
     [NSArray arrayWithObjects:
      lblGrp1Price, lblGrp1Price,lblGrp1Price,
      lblGrp2Price, lblGrp2Price, lblGrp2Price, lblGrp2Price, nil]];
}

/**
 * Orアイテム変更時のimageとlabel変更
 *  Orアイテム選択ボタンのtagはitemListの通し番号となる
 *  例）course1の場合
 *      orBtn1.tag = 1    orBtn2.tag = 2
 *       ->item2         ->item3
 *
 */
- (void) _changeOrItemImageWitthBtnTag:(NSInteger)btnTag corseItem:(SomeCourseItemCommon*)item
{
    if ((0 > btnTag) || (btnTag > 6) )
    {   return; }   // 対象外
    
    UIImageView *imgVw = nil;
    UILabel *lbl = nil;
    
    switch (btnTag) {
        case 0:
        case 1:
        case 2:
            imgVw = imgGrp1Image;
            lbl = lblGrp1Name;
            break;
        case 3:
        case 4:
        case 5:
        case 6:
            imgVw = imgGrp2Image;
            lbl = lblGrp2Name;
            break;
            
        default:
            break;
    }
    
    if (imgVw) {
        imgVw.image = [UIImage imageNamed:item.getImageName];;
        lbl.text = item.getItemName;
    }
    
    // オプションのスパッツの有効を設定
    _isOptionSpatsEnable = (btnTag != 3);
}

// ORアイテムボタンの選択の初期化
- (void) _initOrItemBtnSelect
{
    btnGrp11.border = YES;
    btnGrp12.border = NO;
    btnGrp13.border = NO;
    btnGrp21.border = YES;
    btnGrp22.border = NO;
    btnGrp23.border = NO;
    btnGrp24.border = NO;
}

// 初期化するORアイテムのindex一覧を取得
- (void) _getInitOrItemIndexListWithBuffer:(NSMutableArray*)buffer
{
    [buffer addObject: [NSNumber numberWithInteger:0]];
    [buffer addObject: [NSNumber numberWithInteger:3]];
}

// オプションの選択有効設定
- (void) _optionSelectEnbaleSet
{
    // オプション：初期時は、パンストは選択可　スパッツは選択不可
    _isOptionPanstEnable = YES;
    _isOptionSpatsEnable = NO;
}

@end