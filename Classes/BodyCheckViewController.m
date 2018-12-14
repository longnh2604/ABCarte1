//
//  BodyCheckViewController.m
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "BodyCheckViewController.h"
#import "NumberInputPopUp.h"
#import "GoodsPopup.h"
#import "SizeSelectPopup.h"
#import "defines.h"

#import "Common.h"
#import "UtilScreenCaptureSupport.h"

#import "courseItemCommonViewController.h"
#import "courseOptionItemViewController.h"

#define GRANT_VER 5

@interface BodyCheckViewController ()
{
    NSInteger   _activeCourse;          // 現在アクティブなコース
    course1ItemViewController       *course1ItemVC;
    course2ItemViewController       *course2ItemVC;
    course3ItemViewController       *course3ItemVC;
    course4ItemViewController       *course4ItemVC;
    course5ItemViewController       *course5ItemVC;
    courseOptionItemViewController  *courseOptionItemVC;
    
}
@end

@implementation BodyCheckViewController

//@synthesize histID;
@synthesize _selectedUserID;
@synthesize selectedUserName = _selectedUserName;

#ifdef FOR_GRANT
#pragma mark -
#pragma mark Init
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// 選択されたユーザ
- (void)setSelectedUser:(NSInteger)userID
{
    // ユーザIDをここで保存
    self._selectedUserID = userID;
}

// おすすめ商品の個数を１個で初期化
- (void)setRecommendsProdWithNum:(NSInteger)num
{
    NSString *sNum = [NSString stringWithFormat:@"%d", num];
    [nipperBisuchieNumButton setTitle:sNum forState:UIControlStateNormal];
    [HighWaistGirdleNumButton setTitle:sNum forState:UIControlStateNormal];
    [TBackBodySuitNumButton setTitle:sNum forState:UIControlStateNormal];
    [TBackShortsNumButton setTitle:sNum forState:UIControlStateNormal];
    [CoolbizTrenckerNumButton setTitle:sNum forState:UIControlStateNormal];
    
    [self OnPopUpViewSet:POPUP_INTEGER_INPUT setObject:nil];
}

// 理想サイズのlabelのクリア
-(void) _clearIdealLabels
{
    lblIdealHeight.text = @"";
    lblIdealWeight.text = @"";
    lblIdealTopBreast.text = @"";
    lblIdealUnderBreast.text = @"";
    lblIdealWaist.text = @"";
    lblIdealHip.text = @"";
    lblIdealThigh.text = @"";
    lblIdealHipHeight.text = @"";
    lblIdealWaistHeight.text = @"";
    lblIdealTopBreastHeight.text = @"";
}

// 現在・着衣サイズのtextクリア
-(void) _clearNowSetSizeClear
{
    CGFloat num = 0.0f;
    NSString *newValue = [NSString stringWithFormat:@"%3.1f cm",num];
    
    NSArray *btns
    = [NSArray arrayWithObjects:btnHeight, btnWeight, btnTopBreast, btnUnderBreast, btnWaist,
       btnHip, btnThigh, btnHipHeight, btnWaistHeight, btnTopBreastHeight,
       btnSetHeight, btnSetWeight, btnSetTopBreast, btnSetUnderBreast, btnSetWaist,
       btnSetHip, btnSetThigh, btnSetHipHeight, btnSetWaistHeight, btnSetTopBreastHeight, nil];
    
    for (UIButton *btn in btns) {
        [btn setTitle:newValue forState:UIControlStateNormal];
        [btn setTitle:newValue forState:UIControlStateHighlighted];
        [btn setTitle:newValue forState:UIControlStateDisabled];
    }
}

#pragma mark -
#pragma mark OverWrite

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    picker = nil;
    grantPrdctVer = GRANT_VER;
    inputFlag = NO;
    // 名前欄とレーダーチャートの角を丸める
    CALayer *layers[] = {[vwNameContiner layer],  [radarChartView layer]};
    for (NSInteger i = 0; i < 2; i++)
    {
        [layers[i] setMasksToBounds:YES];
        [layers[i] setCornerRadius:12.0f];	// Do any additional setup after loading the view.
    }
    
    // 理想サイズのlabelのクリア
    [self _clearIdealLabels];
    
    nowSize = [[sizeInfo alloc]init];
    setSize = [[sizeInfo alloc]init];
    idealSize = [[sizeInfo alloc]init];
    radarChartView.nowSize = nowSize;
    radarChartView.setSize = setSize;
    radarChartView.idealSize = idealSize;
    radarChartView.nowSizeShow = YES;
    radarChartView.setSizeShow = YES;
    radarChartView.idealSizeShow = YES;
    baseView.contentSize = CGSizeMake(baseView.frame.size.width, 1004);
    baseView.contentOffset = CGPointMake(0, 20);
    
    goodsItems = [[NSMutableArray alloc]init];    //デモ用商品作成
    [self setDemoData];
    
    txtCustomerName.text = self.selectedUserName;
    // おすすめ商品コンテナの角を丸める
    [Common cornerRadius4Control:goodsListHiddenTagetView];
    
    // おすすめ商品の個数を１個で初期化
    [self setRecommendsProdWithNum:1];
    
    // タイトルの角を丸める
    [Common cornerRadius4Control:vwTitle];
    
    // ブランドのviewControllerを追加
    _activeCourse = 1;
    course1ItemVC = [[course1ItemViewController alloc] initWithNotifyDelegate:self];
    
    prdctScrollView = [[UIScrollView alloc]
                       initWithFrame:CGRectMake(0, 0, vwCourseItemContiner.frame.size.width,vwCourseItemContiner.frame.size.height )];
    
    [vwCourseItemContiner addSubview:prdctScrollView];

    // スワイプのセットアップ
    UISwipeGestureRecognizer *swipeGestue = [[UISwipeGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(OnSwipeLeftView:)];
    swipeGestue.direction = UISwipeGestureRecognizerDirectionRight;
    swipeGestue.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:swipeGestue];
    //[swipeGestue release];
    
    // 画像保存時のflashViewの作成(インスタンスの作成のみ)
    flashView = [[UIView alloc] initWithFrame:self.view.frame];
    flashView.hidden =YES;
    [self.view addSubview:flashView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotateDeviceChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
    
    itemSel = [[UILabel alloc] init];
    itemSel.frame = CGRectMake(ITEMSEL_VIEW_POS_X, ITEMSEL_VIEW_POS_Y, ITEMSEL_VIEW_SIZE_W, ITEMSEL_VIEW_SIZE_H);
    [itemSel setText:@"現在　　　0点　選択中"];
    [itemSel setFont:[UIFont systemFontOfSize:20.0]] ;
    [itemSel setTextAlignment:NSTextAlignmentRight];
    [goodsListBaseView addSubview:itemSel];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSInteger compGrantPrdctVer = 0;
    compGrantPrdctVer = [defaults integerForKey:@"grantPrdctVer"];
    
    //内部バージョンが更新されていれば、商品を更新
    if(compGrantPrdctVer >= grantPrdctVer){
        gfManager = [[grantFmdbManager alloc]init];
        [gfManager initDataBase];
        [self grantDataSetup];
        [self prdctViewSet:selectedBrandIdx];
        [self totalViewSet];
        [self setNowDate];
    }else{
        
        /*下地*/
        loadingViewGround = [[UIView alloc] initWithFrame:[[self view] bounds]];
        [self.view addSubview:loadingViewGround];
        /*土台*/
        loadingView = [[UIView alloc] initWithFrame:CGRectMake(([[self view] bounds].size.width/2)-(200/2),([[self view] bounds].size.height/1.3)-(110/2),200,110)];  //適当なサイズと位置指定
        [loadingView setBackgroundColor:[UIColor blackColor]];  //背景色
        loadingView.layer.cornerRadius = 10;  //Viewの角を丸くする
        loadingView.clipsToBounds = YES;
        [loadingView setAlpha:0.5];  //透明
        [loadingViewGround addSubview:loadingView];  //表示
        
        /*ラベル*/
        msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(-23, 26, 250,90)];  //適当なサイズと位置指定
        msgLabel.text = @"データセットアップ中...";    //表示テキストの指定
        msgLabel.font = [UIFont fontWithName:@"Arial Rounded MT Bold" size:18.0f];  //フォント指定
        [msgLabel setTextAlignment:NSTextAlignmentCenter];
        msgLabel.backgroundColor = [UIColor clearColor];  //背景色
        msgLabel.textColor = [UIColor whiteColor];  //テキストカラー
        [loadingView addSubview:msgLabel];
        
        indicator = [[UIActivityIndicatorView alloc] init];
        indicator.frame = CGRectMake((200/2)-(50/2), (110/2)-50, 50, 50);
        //indicator.center = self.view.center;
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [loadingView addSubview:indicator];
        [indicator startAnimating];
    }
}
//データのセットアップ
-(void)grantDataSetup{

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger compGrantPrdctVer = 0;
    compGrantPrdctVer = [defaults integerForKey:@"grantPrdctVer"];
    //内部バージョンが更新されていれば、商品を更新
    if(compGrantPrdctVer < grantPrdctVer){
        //サイズのセット
        [gfManager setSizeData];
        //カラーのセット
        [gfManager setColorData];
        [defaults setInteger:grantPrdctVer forKey:@"grantPrdctVer"];
    }
    //ブランドのセット
    brandList = [gfManager getBrandData];
    [gfManager insertBrandMst:brandList];
    [self brandSet];
}

//初期ブランドのセット
-(void)brandSet{
    if([brandList count] > 0){
        selectedBrandIdx = 0;
        brandM *brand = [brandList objectAtIndex:selectedBrandIdx];
        [btnBrand setTitle:brand.brand_name forState:UIControlStateNormal];
    }
}

//商品を表示
-(void)prdctViewSet:(NSInteger)brandIdx{
    CGFloat posX = PRDCT_VIEW_POS_X;
    CGFloat posY = PRDCT_VIEW_POS_Y;
    CGFloat viewSizeW = PRDCT_VIEW_SIZE_W;
    CGFloat viewSizeH = PRDCT_VIEW_SIZE_H;
    brandM *brand = [brandList objectAtIndex:brandIdx];
    prdctList = brand.prdct;
    int cnt = 1;
    CGFloat width = prdctScrollView.bounds.size.width;
    CGFloat height = prdctScrollView.bounds.size.height;
    //選択中ブランドの商品を表示
    for(productM *prom in prdctList){
        if((cnt >= 2 && cnt <= 4) || (cnt >= 6 && cnt <= 8)){
            posX = posX + PRDCT_VIEW_POS_ADDX;
        }else if(cnt ==5){
            posX = PRDCT_VIEW_POS_X;
            posY = posY + PRDCT_VIEW_POS_ADDY;
        }else if(cnt >= 9){
            if(cnt % 2 == 0){
                posY = posY + PRDCT_VIEW_POS_ADDY;
            } else {
                posY = PRDCT_VIEW_POS_Y;
                posX = posX + PRDCT_VIEW_POS_ADDX;
                width = width + PRDCT_VIEW_POS_ADDX;
            }
        }
        [self prdctBaseviewSet:prom:posX:posY:viewSizeW:viewSizeH];
        cnt = cnt + 1;
    }    
    prdctScrollView.contentSize = CGSizeMake(width, height);
}
//小計、税、合計を表示
-(void)totalViewSet{
    [self labelView:@"小計":SYOKEI_VIEW_POS_X:SYOKEI_VIEW_POS_Y:SYOKEI_VIEW_SIZE_W:SYOKEI_VIEW_SIZE_H];
    syokei = [self labelView2:@"　￥　0 -":syokei:SYOKEI_VIEW_POS_X+SYOKEI_VIEW_SIZE_W+SYOKEI_VIEW_POS_X_ADD:SYOKEI_VIEW_POS_Y:SYOKEI_VIEW_VALUE_SIZE_W:SYOKEI_VIEW_SIZE_H];
    [self labelView:@"税":ZEI_VIEW_POS_X:SYOKEI_VIEW_POS_Y:ZEI_VIEW_SIZE_W:ZEI_VIEW_SIZE_H];
    zei = [self labelView2:@"　￥　0 -":zei:ZEI_VIEW_POS_X+ZEI_VIEW_SIZE_W+SYOKEI_VIEW_POS_X_ADD:SYOKEI_VIEW_POS_Y:SYOKEI_VIEW_VALUE_SIZE_W:SYOKEI_VIEW_SIZE_H];
    [self labelView:@"合計":GOKEI_VIEW_POS_X:SYOKEI_VIEW_POS_Y:GOKEI_VIEW_SIZE_W:GOKEI_VIEW_SIZE_H];
    gokei = [self labelView2:@"　￥　0 -":gokei:GOKEI_VIEW_POS_X+GOKEI_VIEW_SIZE_W+SYOKEI_VIEW_POS_X_ADD:SYOKEI_VIEW_POS_Y:SYOKEI_VIEW_VALUE_SIZE_W:SYOKEI_VIEW_SIZE_H];
    
}
//タイトル表示
-(void)labelView : (NSString*)title : (CGFloat)posX : (CGFloat)posY : (CGFloat)sizeW : (CGFloat)sizeY{
    UILabel *lbl = [[UILabel alloc] init];
    lbl.frame = CGRectMake(posX, posY, sizeW, sizeY);
    [lbl setText:title];
    [lbl setFont:[UIFont systemFontOfSize:16.0]];
    [lbl setTextAlignment:NSTextAlignmentCenter];
    [vwCourseItemContiner addSubview:lbl];
}
//内容表示
-(UILabel*)labelView2 : (NSString*)title : (UILabel*)label : (CGFloat)posX : (CGFloat)posY : (CGFloat)sizeW : (CGFloat)sizeY{
    label = [[UILabel alloc] init];
    label.frame = CGRectMake(posX, posY, sizeW, sizeY);
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    [label setText:title];
    [label setFont:[UIFont systemFontOfSize:16.0]] ;
    [label setTextAlignment:NSTextAlignmentRight];
    [vwCourseItemContiner addSubview:label];
    
    return label;
}
//選択中の表示を更新
-(NSInteger)syokeiCal{
    
    NSInteger val = 0;
    NSInteger selVal = 0;
    for(brandM *brand in brandList){
        NSMutableArray *wkPrdctList = brand.prdct;
        for(productM *wkPrdct in wkPrdctList){
            val = val + (wkPrdct.num * wkPrdct.selPrice);
            if(wkPrdct.num > 0){
                selVal = selVal + wkPrdct.num;
            }
        }
    }
    
    [itemSel setText:[NSString stringWithFormat:@"現在　　　%d点　選択中",(int)selVal]];
    
    return val;
}
//小計、税、合計を更新
-(void)totalReload{
    
    NSInteger val = [self syokeiCal];
    NSInteger syohizei = (val*8)/100;
    NSInteger zeikomi = val + syohizei;
    
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    [syokei setText:[NSString stringWithFormat:@"　￥　%@ -",[nf stringFromNumber:[NSNumber numberWithInt:(int)val]]]];
    [zei setText:[NSString stringWithFormat:@"　￥　%@ -",[nf stringFromNumber:[NSNumber numberWithInt:(int)syohizei]]]];
    [gokei setText:[NSString stringWithFormat:@"　￥　%@ -",[nf stringFromNumber:[NSNumber numberWithInt:(int)zeikomi]]]];
}

//商品viewを表示
-(void)prdctBaseviewSet : (productM*)prom : (CGFloat)posX : (CGFloat)posY : (CGFloat)sizeW : (CGFloat)sizeY{
    UIView* prdctView = [[UIView alloc] initWithFrame:CGRectMake(posX, posY, sizeW, sizeY)];
    prdctView.tag = prom.idx;
    [prdctScrollView addSubview:prdctView];
    
    [self PrdctImageSet:prdctView:prom.file_name :(prdctView.frame.size.width-PRDCT_IMG_SIZE_W)/20:(prdctView.frame.size.height-PRDCT_IMG_SIZE_H)/30:PRDCT_IMG_SIZE_W:PRDCT_IMG_SIZE_H];
    
    [self PrdctTitleSet:prdctView:prom.product_name :(prdctView.frame.size.width-PRDCT_TITLE_SIZE_W)/2:((prdctView.frame.size.height-PRDCT_IMG_SIZE_H)/6)+PRDCT_IMG_SIZE_H:PRDCT_TITLE_SIZE_W:PRDCT_TITLE_SIZE_H];
    
    [self SizeSet:prdctView:prom.selSize:((prdctView.frame.size.width-PRDCT_IMG_SIZE_W)/20)+PRDCT_IMG_SIZE_W:PRDCT_SIZE_SIZE_H/2:PRDCT_SIZE_SIZE_W:PRDCT_SIZE_SIZE_H];
    
    [self ColorSet:prdctView:prom.selColor:((prdctView.frame.size.width-PRDCT_IMG_SIZE_W)/20)+PRDCT_IMG_SIZE_W:PRDCT_SIZE_SIZE_H*3:PRDCT_SIZE_SIZE_W:PRDCT_SIZE_SIZE_H];
    
    [self NumSet:prdctView:[NSString stringWithFormat:@"%d",(int)prom.num]:(prdctView.frame.size.width-(PRDCT_NUM_SIZE_W/1.03)):((prdctView.frame.size.height-PRDCT_IMG_SIZE_H)/5)+PRDCT_IMG_SIZE_H+PRDCT_TITLE_SIZE_H:PRDCT_NUM_SIZE_W:PRDCT_NUM_SIZE_H];
    
    [self PriceSet:prdctView:[NSString stringWithFormat:@"%d",(int)prom.selPrice]:(prdctView.frame.size.width-PRDCT_NUM_SIZE_W):((prdctView.frame.size.height-PRDCT_IMG_SIZE_H)/4)+PRDCT_IMG_SIZE_H+PRDCT_TITLE_SIZE_H+PRDCT_NUM_SIZE_H:PRDCT_NUM_SIZE_W:PRDCT_PRICE_SIZE_H];
}

//商品イメージを表示
-(void)PrdctImageSet : (UIView*)uv : (NSString*)file_name : (CGFloat)posX : (CGFloat)posY : (CGFloat)sizeW : (CGFloat)sizeY{
    UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(posX, posY, sizeW, sizeY)];
    //[imgView setImage:[UIImage imageNamed:file_name]];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *imagePath = [bundle pathForResource:file_name ofType:@"png"];
    [imgView setImage:[[UIImage alloc] initWithContentsOfFile:imagePath]];
    imgView.tag = 0;
    [uv addSubview:imgView];
}

//商品タイトルを表示
-(void)PrdctTitleSet : (UIView*)uv : (NSString*)title : (CGFloat)posX : (CGFloat)posY : (CGFloat)sizeW : (CGFloat)sizeY{
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(posX, posY, sizeW, sizeY);
    [label setText:title];
    label.adjustsFontSizeToFitWidth = YES;
    [label setTextAlignment:NSTextAlignmentCenter];
    label.tag = 0;
    [uv addSubview:label];
}

//サイズを表示
-(void)SizeSet : (UIView*)uv : (NSString*)title : (CGFloat)posX : (CGFloat)posY : (CGFloat)sizeW : (CGFloat)sizeY{
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(posX, posY, sizeW, sizeY);
    [label setText:@"サイズ"];
    [label setFont:[UIFont systemFontOfSize:14.0]];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.tag = 0;
    [uv addSubview:label];
    
    UIButton *sizeBtn = [[UIButton alloc] initWithFrame:CGRectMake(posX,(posY+sizeY)*1.2,sizeW,sizeY)];
    [sizeBtn setTitle:title forState:UIControlStateNormal];
    [sizeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    UILabel*innerLabel= sizeBtn.titleLabel;
    [innerLabel setFont:[UIFont systemFontOfSize:12.0]];
    innerLabel.lineBreakMode=NSLineBreakByClipping;
    [sizeBtn addTarget:self action:@selector(onPrdctSizeChange:)
      forControlEvents:UIControlEventTouchDown];
    [sizeBtn setBackgroundImage:[UIImage  imageNamed:@"prdctBtn.png" ] forState:UIControlStateNormal];
    sizeBtn.tag = 2;
    [uv addSubview:sizeBtn];
}

//カラーを表示
-(void)ColorSet : (UIView*)uv : (NSString*)title : (CGFloat)posX : (CGFloat)posY : (CGFloat)sizeW : (CGFloat)sizeY{
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(posX, posY, sizeW, sizeY);
    [label setText:@"カラー"];
    [label setFont:[UIFont systemFontOfSize:14.0]];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.tag = 0;
    [uv addSubview:label];
    
    UIButton *colorBtn = [[UIButton alloc] initWithFrame:CGRectMake(posX,posY+sizeY,sizeW,sizeY)];
    [colorBtn setTitle:title forState:UIControlStateNormal];
    [colorBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    UILabel*innerLabel= colorBtn.titleLabel;
    [innerLabel setFont:[UIFont systemFontOfSize:12.0]];
    innerLabel.lineBreakMode=NSLineBreakByClipping;
    [colorBtn addTarget:self action:@selector(onPrdctColorChange:)
       forControlEvents:UIControlEventTouchDown];
    [colorBtn setBackgroundImage:[UIImage  imageNamed:@"prdctBtn.png" ] forState:UIControlStateNormal];
    colorBtn.tag = 3;
    [uv addSubview:colorBtn];
}

//個数を表示
-(void)NumSet : (UIView*)uv : (NSString*)title : (CGFloat)posX : (CGFloat)posY : (CGFloat)sizeW : (CGFloat)sizeY{
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(posX, posY, sizeW, sizeY);
    [label setText:@"個数"];
    [label setFont:[UIFont systemFontOfSize:14.0]];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.tag = 0;
    
    UIButton *numBtn = [[UIButton alloc] initWithFrame:CGRectMake(posX,posY,sizeW,sizeY)];
    [numBtn setTitle:[NSString stringWithFormat:@"数量：　%@",title] forState:UIControlStateNormal];
    [numBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    UILabel*innerLabel= numBtn.titleLabel;
    [innerLabel setFont:[UIFont systemFontOfSize:14.0]];
    [innerLabel setTextAlignment:NSTextAlignmentRight];
    [numBtn addTarget:self action:@selector(onPrdctNumChange:)
     forControlEvents:UIControlEventTouchDown];
    [numBtn setBackgroundImage:[UIImage  imageNamed:@"prdctBtn.png" ] forState:UIControlStateNormal];
    numBtn.tag = 4;
    [uv addSubview:numBtn];
}

//単価を表示
-(void)PriceSet : (UIView*)uv : (NSString*)title : (CGFloat)posX : (CGFloat)posY : (CGFloat)sizeW : (CGFloat)sizeY{
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(posX, posY, sizeW, sizeY);
    [label setText:@"単価"];
    [label setFont:[UIFont systemFontOfSize:14.0]];
    [label setTextAlignment:NSTextAlignmentCenter];
    label.tag = 0;
    
    UILabel *priceLabel = [[UILabel alloc] init];
    priceLabel.frame = CGRectMake(posX, posY, sizeW, sizeY);
    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    [priceLabel setText:[NSString stringWithFormat:@"￥　%@", [nf stringFromNumber:[NSNumber numberWithInt:[title intValue]]]]];
    [priceLabel setTextAlignment:NSTextAlignmentRight];
    [priceLabel setFont:[UIFont boldSystemFontOfSize:14.0]];
    priceLabel.textColor = [UIColor colorWithRed: 0.698 green: 0.000 blue: 0.031 alpha: 1.0];
    priceLabel.tag = 5;
    [uv addSubview:priceLabel];
}

//サイズ変更
-(void)changePrdctSize:(NSInteger)num{
    
    for (UIView *view in [prdctScrollView subviews]) {
        if(view.tag == selectedPrdctIdx){
            for (UIView *view2 in [view subviews]) {
                if(view2.tag == 2){
                    productM *prdct = [prdctList objectAtIndex:selectedPrdctIdx];
                    UIButton *btn = (UIButton*)view2;
                    sizeM *size = [prdct.size objectAtIndex:num];
                    prdct.selSize = size.size_name;
                    prdct.selSizeVal = num;
                    [prdctList replaceObjectAtIndex:selectedPrdctIdx withObject:prdct];
                    [btn setTitle:size.size_name forState:UIControlStateNormal];
                }else if(view2.tag == 5){
                    UILabel *label = (UILabel*)view2;
                    productM *prdct = [prdctList objectAtIndex:selectedPrdctIdx];
                    sizeM *size = [prdct.size objectAtIndex:num];
                    prdct.selPrice = size.price;
                    [prdctList replaceObjectAtIndex:selectedPrdctIdx withObject:prdct];
                    NSNumberFormatter* nf = [[NSNumberFormatter alloc] init];
                    [nf setNumberStyle:NSNumberFormatterDecimalStyle];
                    [label setText:[NSString stringWithFormat:@"￥　%@", [nf stringFromNumber:[NSNumber numberWithInt:(int)size.price]]]];
                }
            }
        }
    }
}

//カラー変更
-(void)changePrdctColor:(NSInteger)num{
    
    for (UIView *view in [prdctScrollView subviews]) {
        if(view.tag == selectedPrdctIdx){
            for (UIView *view2 in [view subviews]) {
                if(view2.tag == 3){
                    UIButton *btn = (UIButton*)view2;
                    productM *prdct = [prdctList objectAtIndex:selectedPrdctIdx];
                    colorM *color = [prdct.color objectAtIndex:num];
                    prdct.selColor = color.color_name;
                    prdct.selColorVal = num;
                    [prdctList replaceObjectAtIndex:selectedPrdctIdx withObject:prdct];
                    [btn setTitle:color.color_name forState:UIControlStateNormal];
                }
            }
        }
    }
}

//数量変更
-(void)changePrdctNum:(NSInteger)num{
    
    for (UIView *view in [prdctScrollView subviews]) {
        if(view.tag == selectedPrdctIdx){
            for (UIView *view2 in [view subviews]) {
                if(view2.tag == 4){
                    productM *prdct = [prdctList objectAtIndex:selectedPrdctIdx];
                    prdct.num = num;
                    [prdctList replaceObjectAtIndex:selectedPrdctIdx withObject:prdct];
                    UIButton *btn = (UIButton*)view2;
                    [btn setTitle:[NSString stringWithFormat:@"数量：　%d",(int)num] forState:UIControlStateNormal];
                }
            }
        }
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //DBの準備
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSInteger compGrantPrdctVer = 0;
    compGrantPrdctVer = [defaults integerForKey:@"grantPrdctVer"];
    //内部バージョンが更新されていれば、商品を更新
    if(compGrantPrdctVer < grantPrdctVer){
        gfManager = [[grantFmdbManager alloc]init];
        [gfManager initDataBase];
        [self grantDataSetup];
        [self prdctViewSet:selectedBrandIdx];
        [self totalViewSet];
        [self setNowDate];
        
        [loadingViewGround removeFromSuperview];
        [loadingView removeFromSuperview];
        [indicator stopAnimating];
        [indicator removeFromSuperview];
    }
    
    [radarChartView setNeedsDisplay];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [UIView setAnimationsEnabled:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    NSInteger sumPriceNum = 0;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
    [formatter setPositiveFormat:@"###,###,##0"];
    switch (popUpID)
    {
        case (NSUInteger)POPUP_NUMBER_INPUT:
            inputFlag = YES;
            [self setButtonState:object];
            break;
        case (NSUInteger)POPUP_GOODS_SELECT:
            if([(GoodsItem *)object goodsID] == 1){
                HighWaistGirdle.colorName.text = [(GoodsItem *)object colorName].text;
            }
            break;
        case (NSUInteger)POPUP_INTEGER_INPUT:
            sumPriceNum += [nipperBisuchieNumButton.currentTitle intValue] * NipperBisuchiePrice.tag;
            sumPriceNum += [HighWaistGirdleNumButton.currentTitle intValue] * HighWaistGirdlePrice.tag;
            sumPriceNum += [TBackBodySuitNumButton.currentTitle intValue] * TBackBodySuitPrice.tag;
            sumPriceNum += [TBackShortsNumButton.currentTitle intValue] * TBackShortsPrice.tag;
            sumPriceNum += [CoolbizTrenckerNumButton.currentTitle intValue] * CoolbizTrenckerPrice.tag;
            sumPrice.text = [formatter stringFromNumber:[NSNumber numberWithInt:sumPriceNum]];
            break;
    }
}

- (void)dealloc
{
    if (flashView)
    {
        [flashView removeFromSuperview];
        //[flashView release];
        flashView = nil;
    }
    
    /*
    if (numberInput)
        //[numberInput release];
    if (goodsItems)
        //[goodsItems release];
    //[super dealloc];
     */
}

#pragma mark -
#pragma mark OnAction

// 数値入力
- (IBAction) OnBtnEditNumber:(id)sender
{
    CGFloat selectNum;
    UIButton *selectBtn = (UIButton*)sender;
    
    switch (selectBtn.tag) {
        case BTN_HEIGHT:
            selectNum = nowSize.Height;
            break;
        case BTN_WEIGHT:
            selectNum = nowSize.Weight;
            break;
        case BTN_TOPBREAST:
            selectNum = nowSize.TopBreast;
            break;
        case BTN_UNDERBREAST:
            selectNum = nowSize.UnderBreast;
            break;
        case BTN_WAIST:
            selectNum = nowSize.Waist;
            break;
        case BTN_HIP:
            selectNum = nowSize.Hip;
            break;
        case BTN_THIGH:
            selectNum = nowSize.Thigh;
            break;
        case BTN_HIPHEIGHT:
            selectNum = nowSize.HipHeight;
            break;
        case BTN_WAISTHEIGHT:
            selectNum = nowSize.WaistHeight;
            break;
        case BTN_TOPBREASTHEIGHT:
            selectNum = nowSize.TopBreastHeight;
            break;
            
        case BTN_SET_HEIGHT:
            selectNum = setSize.Height;
            break;
        case BTN_SET_WEIGHT:
            selectNum = setSize.Weight;
            break;
        case BTN_SET_TOPBREAST:
            selectNum = setSize.TopBreast;
            break;
        case BTN_SET_UNDERBREAST:
            selectNum = setSize.UnderBreast;
            break;
        case BTN_SET_WAIST:
            selectNum = setSize.Waist;
            break;
        case BTN_SET_HIP:
            selectNum = setSize.Hip;
            break;
        case BTN_SET_THIGH:
            selectNum = setSize.Thigh;
            break;
        case BTN_SET_HIPHEIGHT:
            selectNum = setSize.HipHeight;
            break;
        case BTN_SET_WAISTHEIGHT:
            selectNum = setSize.WaistHeight;
            break;
        case BTN_SET_TOPBREASTHEIGHT:
            selectNum = setSize.TopBreastHeight;
            break;
    }
    
    
    if (numberInput)
    {
        //[numberInput release];
        numberInput = nil;
    }
    
    // 数値選択ポップアップのViewControllerのインスタンス生成 : POPUP_NUMBER_INPUT
    NumberInputPopUp *numInp
    = [[NumberInputPopUp alloc] initWithButton:(UIButton*)sender selectNum:selectNum popUpID:POPUP_NUMBER_INPUT callBack:self ];
    // ポップアップViewの表示
    numberInput =
    [[UIPopoverController alloc] initWithContentViewController:numInp];
    numInp.popoverController = numberInput;
    
    [numberInput presentPopoverFromRect:selectBtn.bounds
                                 inView:selectBtn
               permittedArrowDirections:UIPopoverArrowDirectionAny
                               animated:YES];
    //[numInp release];
    numInp = nil;
    
}

- (void)setButtonState:(UIButton *)selectButton{

    UIButton *tagetBtn;
    NSString *newValue = [[NSString alloc]initWithString:@"cm"];
    CGFloat num = [selectButton.currentTitle floatValue];
    //ターゲット設定・最大・最低値処理
    switch (selectButton.tag) {
        case BTN_HEIGHT:
            tagetBtn = btnHeight;
            nowSize.Height = num;
            break;
        case BTN_WEIGHT:
            tagetBtn = btnWeight;
            nowSize.Weight = num;
            newValue = @"kg";
            break;
        case BTN_TOPBREAST:
            tagetBtn = btnTopBreast;
            nowSize.TopBreast = num;
            break;
        case BTN_UNDERBREAST:
            tagetBtn = btnUnderBreast;
            nowSize.UnderBreast = num;
            break;
        case BTN_WAIST:
            tagetBtn = btnWaist;
            nowSize.Waist = num;
            break;
        case BTN_HIP:
            tagetBtn = btnHip;
            nowSize.Hip = num;
            break;
        case BTN_THIGH:
            tagetBtn = btnThigh;
            nowSize.Thigh = num;
            break;
        case BTN_HIPHEIGHT:
            tagetBtn = btnHipHeight;
            nowSize.HipHeight = num;
            break;
        case BTN_WAISTHEIGHT:
            tagetBtn = btnWaistHeight;
            nowSize.WaistHeight = num;
            break;
        case BTN_TOPBREASTHEIGHT:
            tagetBtn = btnTopBreastHeight;
            nowSize.TopBreastHeight = num;
            break;
            
        case BTN_SET_HEIGHT:
            tagetBtn = btnSetHeight;
            setSize.Height = num;
            break;
        case BTN_SET_WEIGHT:
            tagetBtn = btnSetWeight;
            setSize.Weight = num;
            newValue = @"kg";
            break;
        case BTN_SET_TOPBREAST:
            tagetBtn = btnSetTopBreast;
            setSize.TopBreast = num;
            break;
        case BTN_SET_UNDERBREAST:
            tagetBtn = btnSetUnderBreast;
            setSize.UnderBreast = num;
            break;
        case BTN_SET_WAIST:
            tagetBtn = btnSetWaist;
            setSize.Waist = num;
            break;
        case BTN_SET_HIP:
            tagetBtn = btnSetHip;
            setSize.Hip = num;
            break;
        case BTN_SET_THIGH:
            tagetBtn = btnSetThigh;
            setSize.Thigh = num;
            break;
        case BTN_SET_HIPHEIGHT:
            tagetBtn = btnSetHipHeight;
            setSize.HipHeight = num;
            break;
        case BTN_SET_WAISTHEIGHT:
            tagetBtn = btnSetWaistHeight;
            setSize.WaistHeight = num;
            break;
        case BTN_SET_TOPBREASTHEIGHT:
            tagetBtn = btnSetTopBreastHeight;
            setSize.TopBreastHeight = num;
            break;
        default:
            return;
            break;
    }
    
    
    newValue = [NSString stringWithFormat:@"%3.1f %@",[selectButton.currentTitle floatValue],newValue];
    [tagetBtn setTitle:newValue forState:UIControlStateNormal];
    [tagetBtn setTitle:newValue forState:UIControlStateHighlighted];
    [tagetBtn setTitle:newValue forState:UIControlStateDisabled];
    
    //現在身長が変更された場合は理想サイズの変更処理へ入る
    if(tagetBtn.tag == BTN_HEIGHT){
        [self setIdeal:nowSize.Height];
    }
    radarChartView.nowSize = nowSize;
    radarChartView.setSize = setSize;
    radarChartView.idealSize = idealSize;
    // [radarChartView setNeedsDisplay];
    
    // アニメーション
    radarChartView.alpha = 0.9f;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         radarChartView.alpha = 0.25f;
                     }
                     completion:^(BOOL finished) {
                         radarChartView.alpha = 1.0f;
                         [radarChartView setNeedsDisplay];
                     }];
}

- (void)setIdeal:(CGFloat)newHeight{
    idealSize.Height = newHeight;
    lblIdealHeight.text = [NSString stringWithFormat:@"%3.1f",idealSize.Height];
    
    idealSize.Weight = (newHeight - 100) * 0.9f;
    lblIdealWeight.text = [NSString stringWithFormat:@"%3.1f",idealSize.Weight];
    
    idealSize.TopBreast = newHeight * 0.53f;
    lblIdealTopBreast.text = [NSString stringWithFormat:@"%3.1f",idealSize.TopBreast];
    
    idealSize.UnderBreast = newHeight * 0.43f;
    lblIdealUnderBreast.text = [NSString stringWithFormat:@"%3.1f",idealSize.UnderBreast];
    
    idealSize.Waist = newHeight * 0.37f;
    lblIdealWaist.text = [NSString stringWithFormat:@"%3.1f",idealSize.Waist];
    
    idealSize.Hip = newHeight * 0.55f;
    lblIdealHip.text = [NSString stringWithFormat:@"%3.1f",idealSize.Hip];
    
    idealSize.Thigh = newHeight * 0.31f;
    lblIdealThigh.text = [NSString stringWithFormat:@"%3.1f",idealSize.Thigh];
    
    idealSize.HipHeight = newHeight * 0.52f;
    lblIdealHipHeight.text = [NSString stringWithFormat:@"%3.1f",idealSize.HipHeight];
    
    idealSize.WaistHeight = newHeight * 0.60f;
    lblIdealWaistHeight.text = [NSString stringWithFormat:@"%3.1f",idealSize.WaistHeight];
    
    idealSize.TopBreastHeight = newHeight * 0.72f;
    lblIdealTopBreastHeight.text = [NSString stringWithFormat:@"%3.1f",idealSize.TopBreastHeight];
}

-(IBAction)OnTitleBtn:(id)sender{
    UIButton *selectBtn = (UIButton*)sender;
    switch (selectBtn.tag) {
        case NOWSIZE_BUTTON:
            if (radarChartView.nowSizeShow) {
                radarChartView.nowSizeShow = NO;
                [selectBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
                [selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
                [selectBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
            }else {
                radarChartView.nowSizeShow = YES;
                [selectBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
                [selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
                [selectBtn setTitleColor:[UIColor greenColor] forState:UIControlStateDisabled];
            }
            break;
        case SETSIZE_BUTTON:
            if (radarChartView.setSizeShow) {
                radarChartView.setSizeShow = NO;
                [selectBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
                [selectBtn setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
                [selectBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
            }else {
                radarChartView.setSizeShow = YES;
                [selectBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                [selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
                [selectBtn setTitleColor:[UIColor redColor] forState:UIControlStateDisabled];
            }
            break;
        case IDEALSIZE_BUTTON:
            if (radarChartView.idealSizeShow) {
                radarChartView.idealSizeShow = NO;
                [selectBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
                [selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
                [selectBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
            }else {
                radarChartView.idealSizeShow = YES;
                [selectBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
                [selectBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
                [selectBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateDisabled];
            }
            break;
        default:
            break;
    }
    [radarChartView setNeedsDisplay];
}

-(IBAction)onHardCopy:(id)sender
{
    inputFlag = NO;
    btnHardCopy.enabled = NO;
    
    // 画面をフラッシュする
    [Common flashViewWindowWithParentView:self.view flashView:flashView];
    
    // シャッター音を鳴らす
    [self performSelector:@selector(shutterSoundDelay)
               withObject:nil afterDelay:0.5f];
    
    UIImage* image = nil;
    
    image = [UtilScreenCaptureSupport getScreenCaptureWithDevState:self.interfaceOrientation];
    
    [self saveImageFile:image];
}

- (bool)saveImageFile:(UIImage*)image
{
    // 履歴IDをデータベースよりユーザIDと当日で取得する:当日の履歴がない場合は作成する
    HISTID_INT histID;
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    if ( (histID = [usrDbMng getHistIDWithDateUserID:_userID
                                            workDate:[NSDate date]
                                      isMakeNoRecord:YES] ) < 0)
    {
        NSLog(@"getHistIDWithDateUserID error on PicturePaintViewController!");
        //[usrDbMng release];
        return NO;
    }
    
    // Imageファイル管理を選択ユーザIDで作成する
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc] initWithUserID:_userID];
    
    // Imageの保存：実サイズ版と縮小版の保存
    //		fileName：パスなしの実サイズ版のファイル名
    NSString *fileName = [imgFileMng saveImage:image];
    
    if (! fileName)
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"写真保存エラー"
                                  message:@"写真の保存に失敗しました\n(誠に恐れ入りますが\n再度操作をお願いいたします)"
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil
                                  ];
        [alertView show];
        //[alertView release];
        //[usrDbMng release];
        //[ imgFileMng release];
        
        return (NO);
    }
    
    //NSLog(@"PictureCompViewController - Save image file. userID:%d fileName => %@ histID = %d", _userID, fileName,histID);
    
    // データベース内の写真urlはDocumentフォルダ以下で設定 -> TODO:変更必要
    NSString *docPictUrl =
    [NSString stringWithFormat:@"Documents/User%08d/%@", _userID, fileName];
    
    // 保存したファイル名（パスなしの実サイズ版）でデータベースの履歴用のユーザ写真を追加
    bool stat = [usrDbMng insertHistUserPicture:histID
                                     pictureURL:docPictUrl];	// docPictUrl -> fileName
    
    // 保存したファイル名（パスなしの実サイズ版でデータベースの履歴テーブルの代表画像の更新:既設の場合は何もしない
    stat |= [usrDbMng updateHistHeadPicture:histID pictureURL:docPictUrl	// docPictUrl -> fileName
                            isEnforceUpdate:NO];
    
    //[usrDbMng release];
    //[imgFileMng release];
    
    // 遷移元のVCに対して更新処理を行う
    [self refresh2OwnerTransitionVC];
    
    return (stat);
}

-(void) _raderChartRedraw
{
    radarChartView.nowSize = nowSize;
    radarChartView.setSize = setSize;
    radarChartView.idealSize = idealSize;
    // [radarChartView setNeedsDisplay];
    
    // アニメーション
    radarChartView.alpha = 0.9f;
    [UIView animateWithDuration:0.5f
                     animations:^{
                         radarChartView.alpha = 0.25f;
                     }
                     completion:^(BOOL finished) {
                         radarChartView.alpha = 1.0f;
                         [radarChartView setNeedsDisplay];
                     }];
}

// 全データのクリア：初期状態に戻す
-(IBAction)onAllClear:(id)sender
{

    [Common showYesNoDialogWithTitle:@"ボディチェックシート" message:@"全てのデータをクリアしますか？"
                         isYesNoType:YES callbackParam:nil
                        hCloseDialog:^(id sender, id param, BOOL isYesClick)
     {
         if (! isYesClick)
         {   return; }
         
         inputFlag = NO;
         // お名前、アドバイザー、紹介者のクリア
         txtAdviser.text = @"";
         txtIntroduces.text = INTRODUSE_NAME_INVALID;
         
         // チャート用の現在・理想・着衣サイズをクリア
         [nowSize allDataClaer];
         [setSize allDataClaer];
         [idealSize allDataClaer];
         [self _raderChartRedraw];
         
         // 理想サイズのlabelのクリア
         [self _clearIdealLabels];
         // 現在・着衣サイズのtextクリア
         [self _clearNowSetSizeClear];
         //商品の各種データをクリア
         NSInteger cnt = 1;
         gfManager = [[grantFmdbManager alloc]init];
         [gfManager initDataBase];
         for(int i = 0;i < [brandList count];i++){
             brandM *brand = [brandList objectAtIndex:i];
             brand.prdct = [gfManager getPrdctData:brand.brand_id:cnt];
             [brandList replaceObjectAtIndex:i withObject:brand];
             cnt = cnt + [brand.prdct count];
         }
         //ブランド、商品、合計を再表示
         [self brandSet];
         
         [self releasePrdctView];
         
         [self prdctViewSet:selectedBrandIdx];
         [self totalReload];
     }];
}

#pragma mark courseItem_control_event
//ブランド選択
-(IBAction)onBrandSelected:(id)sender{
    [self gtPickerView:1:selectedBrandIdx];
}
//サイズ変更
-(void)onPrdctSizeChange:(id)sender{
    selectedPrdctIdx = [sender superview].tag;
    productM *prdct = [prdctList objectAtIndex:selectedPrdctIdx];
    [self gtPickerView:2:prdct.selSizeVal];
}
//カラー変更
-(void)onPrdctColorChange:(id)sender{
    selectedPrdctIdx = [sender superview].tag;
    productM *prdct = [prdctList objectAtIndex:selectedPrdctIdx];
    [self gtPickerView:3:prdct.selColorVal];
}
//個数変更
-(void)onPrdctNumChange:(id)sender{
    selectedPrdctIdx = [sender superview].tag;
    productM *prdct = [prdctList objectAtIndex:selectedPrdctIdx];
    [self gtPickerView:4:prdct.num];
}
//ドラム表示
-(void)gtPickerView : (NSInteger)tag : (NSInteger)select{
    //背景を表示
    overlayView = [[UIView alloc] init];
    overlayView.frame = self.view.bounds;
    overlayView.backgroundColor = [UIColor blackColor];
    overlayView.alpha = 0.5;
    overlayView.userInteractionEnabled = YES;
    [self.view addSubview:overlayView];
    //ベースを表示
    frameView = [[UIView alloc] init];
    frameView.frame = CGRectMake((self.view.bounds.size.width/2)-(FRAME_VIEW_SIZE_W/2),(self.view.bounds.size.height/2)-(FRAME_VIEW_SIZE_H/2),FRAME_VIEW_SIZE_W,FRAME_VIEW_SIZE_H);
    frameView.backgroundColor = [UIColor lightGrayColor];
    frameView.layer.cornerRadius = 5;
    frameView.clipsToBounds = true;
    [self.view addSubview:frameView];
    //ドラムを表示
    picker = [[UIPickerView alloc]init];
    picker.delegate = self;
    picker.dataSource = self;
    picker.showsSelectionIndicator = YES;
    picker.tag = tag;
    picker.layer.cornerRadius = 5;
    picker.clipsToBounds = true;
    [[picker layer] setBorderColor:[[UIColor blueColor] CGColor]];
    [[picker layer] setBorderWidth:0.5];
    picker.frame = CGRectMake((frameView.frame.size.width/2)-(PICKER_VIEW_SIZE_W/2),(frameView.frame.size.height/2)-(PICKER_VIEW_SIZE_H/1.8),PICKER_VIEW_SIZE_W,PICKER_VIEW_SIZE_H);
    picker.backgroundColor = [UIColor whiteColor];
    
    [picker selectRow:select inComponent:0 animated:NO];
    //設定ボタンを表示
    UIButton *SetteiBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    SetteiBtn.frame = CGRectMake(SETTEIBTN_POS_X,SETTEIBTN_POS_Y,SETTEIBTN_SIZE_W,SETTEIBTN_SIZE_H);
    [SetteiBtn setTitle:@"設定" forState:UIControlStateNormal];
    SetteiBtn.backgroundColor = [UIColor whiteColor];
    SetteiBtn.layer.cornerRadius = 5;
    SetteiBtn.clipsToBounds = true;
    [[SetteiBtn layer] setBorderColor:[[UIColor blueColor] CGColor]];
    [[SetteiBtn layer] setBorderWidth:0.5];
    UILabel*innerLabel= SetteiBtn.titleLabel;
    [innerLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
    [SetteiBtn addTarget:self action:@selector(settingPickerView)
     forControlEvents:UIControlEventTouchDown];
    [frameView addSubview:SetteiBtn];
    //取消ボタンを表示
    UIButton *CancelBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    CancelBtn.frame = CGRectMake(CANCELBTN_POS_X,CANCELBTN_POS_Y,SETTEIBTN_SIZE_W,SETTEIBTN_SIZE_H);
    [CancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    CancelBtn.backgroundColor = [UIColor whiteColor];
    CancelBtn.layer.cornerRadius = 5;
    CancelBtn.clipsToBounds = true;
    [[CancelBtn layer] setBorderColor:[[UIColor blueColor] CGColor]];
    [[CancelBtn layer] setBorderWidth:0.5];
    UILabel*innerLabel2= CancelBtn.titleLabel;
    [innerLabel2 setFont:[UIFont boldSystemFontOfSize:15.0]];
    [CancelBtn addTarget:self action:@selector(cancel)
        forControlEvents:UIControlEventTouchDown];
    [frameView addSubview:CancelBtn];

    [frameView addSubview:picker];
     
}

//表示する列数を返す
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

//表示する行数を返す
- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    int cnt;
    productM *prdct;
    switch (pickerView.tag) {
        case 1:
            cnt = (int)[brandList count];
            break;
        case 2:
            prdct = [prdctList objectAtIndex:selectedPrdctIdx];
            cnt = (int)[prdct.size count];
            break;
        case 3:
            prdct = [prdctList objectAtIndex:selectedPrdctIdx];
            cnt = (int)[prdct.color count];
            break;
        case 4:
            cnt = 11;
            break;
    }
    return cnt;
}

/**
 * ピッカーに表示する値を返す
 */
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title;
    brandM *brand;
    productM *prdct;
    sizeM *size;
    colorM *color;
    
    switch (pickerView.tag) {
        case 1:
            brand = [brandList objectAtIndex:row];
            title = brand.brand_name;
            break;
        case 2:
            prdct = [prdctList objectAtIndex:selectedPrdctIdx];
            size = [prdct.size objectAtIndex:row];
            title = size.size_name;
            break;
        case 3:
            prdct = [prdctList objectAtIndex:selectedPrdctIdx];
            color = [prdct.color objectAtIndex:row];
            title = color.color_name;
            break;
        case 4:
            title = [NSString stringWithFormat:@"%d",(int)row];
            break;
    }
    
    return title;
}
//設定ボタンをタップ
- (void)settingPickerView{

    // 1列目の選択された行数を取得
    NSInteger sel = [picker selectedRowInComponent:0];
    brandM *brand;
    switch(picker.tag){
        case 1:
            [self releasePrdctView];
            selectedBrandIdx = sel;
            brand = [brandList objectAtIndex:selectedBrandIdx];
            [btnBrand setTitle:brand.brand_name forState:UIControlStateNormal];
            [self prdctViewSet:selectedBrandIdx];
            break;
        case 2:
            inputFlag = YES;
            [self changePrdctSize:sel];
            [self totalReload];
            break;

        case 3:
            inputFlag = YES;
            [self changePrdctColor:sel];
            break;
        case 4:
            inputFlag = YES;
            [self changePrdctNum:sel];
            [self totalReload];
            break;
    }

    [picker removeFromSuperview];
    [frameView removeFromSuperview];
    picker = nil;
    [overlayView removeFromSuperview];
}
//取消ボタンをタップ
- (void)cancel{
    [picker removeFromSuperview];
    [frameView removeFromSuperview];
    picker = nil;
    [overlayView removeFromSuperview];
}
/**
 * ピッカーの選択行が決まったとき
 */
- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    /*
    // 1列目の選択された行数を取得
    NSInteger sel = [pickerView selectedRowInComponent:0];
    
    switch (pickerView.tag) {
        case 1:
            for (UIView *view in [prdctScrollView subviews]) {
                NSString* className = NSStringFromClass([view class]);
                if([className compare:@"UIImageView"] == NSOrderedSame){
                    UIImageView*imgView = (UIImageView*)view;
                    if(imgView != nil){
                        //UIImageView解放
                        imgView.image = nil;
                        imgView.layer.sublayers = nil;
                        imgView = nil;
                    }
                }
                [view removeFromSuperview];
            }
            selectedBrandIdx = sel;
            brandM *brand = [brandList objectAtIndex:selectedBrandIdx];
            [btnBrand setTitle:brand.brand_name forState:UIControlStateNormal];
            [self prdctViewSet:selectedBrandIdx];
            break;
        case 2:
            [self changePrdctSize:sel];
            [self totalReload];
            break;
        case 3:
            [self changePrdctColor:sel];
            break;
        case 4:
            [self changePrdctNum:sel];
            [self totalReload];
            break;
        case 5:
            break;
    }
    
    [pickerView removeFromSuperview];
    picker = nil;
    [overlayView removeFromSuperview];
     */
}

/*
 // コースの変更
 -(IBAction)onCourseChange:(id)sender
 {
 NSInteger course = ((UIButton*)sender).tag;
 
 // 表示されているVCを非表示にする
 courseItemBaseViewController *oldItemVC = [self _getActiveCourseItemVC];
 oldItemVC.view.hidden = YES;
 
 // ここでアクティブなVCの番号を更新
 _activeCourse = course;
 
 // こから表示するVC
 courseItemBaseViewController *itemVC = [self _getActiveCourseItemVC];
 
 NSInteger sum = 0;
 
 #ifndef OPTION_ITEM_NO_SELECT
 
 [courseOptionItemVC setPanstVisible:itemVC.isOptionPanstEnable];
 sum = [courseOptionItemVC setSpatsVisible:itemVC.isOptionSpatsEnable];
 
 #else
 sum = [courseOptionItemVC calcItemSumPrice];
 #endif
 
 // これから表示するVCを表示する
 itemVC.view.hidden = NO;
 
 //これから表示するVCの合計値を求める
 sum += [itemVC calcItemSumPrice];
 
 // 各コースとオプションの合計値を表示
 [self _showCourseSumPrice:sum];
 
 // ボタンの色を変える
 UIImage *img = [UIImage imageNamed:@"button_Blank_Blue_148.png"];
 //[btnCourse1 setBackgroundImage:img forState:UIControlStateNormal];
 [btnCourse2 setBackgroundImage:img forState:UIControlStateNormal];
 [btnCourse3 setBackgroundImage:img forState:UIControlStateNormal];
 [btnCourse4 setBackgroundImage:img forState:UIControlStateNormal];
 [btnCourse5 setBackgroundImage:img forState:UIControlStateNormal];
 
 [(UIButton*)sender setBackgroundImage:[UIImage imageNamed:@"button_Blank_Red.png"]
 forState:UIControlStateNormal];
 }
 */

// サイズの変更
- (IBAction)onSizeChange:(id)sender
{
    CourseItemPrice price = ((UIButton*)sender).tag;
    
    // 各コースにサイズ変更を通知
    [course1ItemVC notifyChangeSizeWithCourceItemPrice:price];
    [course2ItemVC notifyChangeSizeWithCourceItemPrice:price];
    [course3ItemVC notifyChangeSizeWithCourceItemPrice:price];
    [course4ItemVC notifyChangeSizeWithCourceItemPrice:price];
    [course5ItemVC notifyChangeSizeWithCourceItemPrice:price];
    NSInteger sum = [courseOptionItemVC notifyChangeSizeWithCourceItemPrice:price];
    
    courseItemBaseViewController *itemVC = [self _getActiveCourseItemVC];
    sum += [itemVC calcItemSumPrice];
    
    // 各コースとオプションの合計値を表示
    [self _showCourseSumPrice:sum];
    
    // ボタンの色を変える
    UIImage *img = [UIImage imageNamed:@"button_Blank_Blue_148.png"];
    [btnNormalSize setBackgroundImage:img forState:UIControlStateNormal];
    [btnLargeSize setBackgroundImage:img forState:UIControlStateNormal];
    [btnSpeceialSize setBackgroundImage:img forState:UIControlStateNormal];
    
    [(UIButton*)sender setBackgroundImage:[UIImage imageNamed:@"button_Blank_Red.png"]
                                 forState:UIControlStateNormal];
}

#pragma mark UITextFieldDelegate

// 編集する直前にコールされる
-(BOOL)textFieldShouldBeginEditing: (UITextField*)textField
{
    if (textField != txtIntroduces)
    {   return (YES); }
    
    if ([txtIntroduces.text isEqualToString:INTRODUSE_NAME_INVALID]) {
        txtIntroduces.text = nil;
    }
    return (YES);
}

// 編集が終了した直後にコールされる
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    inputFlag = YES;
    if (textField != txtIntroduces)
    {   return; }
    
    if ((! txtIntroduces.text ) || ([txtIntroduces.text length] <= 0)) {
        txtIntroduces.text = INTRODUSE_NAME_INVALID;
    }
}

// リターンキーが押された時にコールされる
-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    inputFlag = YES;
    // キーボードを閉じる
    [textField resignFirstResponder];
    
    return (YES);
}

#pragma mark courseItemDelegate
/**
 * 合計額の変更通知
 *  @param      sender          : 通知したクラス
 *  @param      changeSumPrice  : このインスタンスのItemの変更後の合計額
 */
- (void) courseItemViewController:(id)sender notifySumPriceChange:(NSInteger)price
{
    NSInteger course = ((UIViewController*)sender).view.tag;
    courseItemBaseViewController *itemVC = nil;
    
    if (course <= 0) {
        // オプションからの通知
        itemVC = [self _getActiveCourseItemVC];
        price += [itemVC calcItemSumPrice];
    }
    else {
        // 各コースからの通知
        #ifndef OPTION_ITEM_NO_SELECT
        // オプションのパンストとスパッツの有効を設定
        itemVC = (courseItemBaseViewController*)sender;
        [courseOptionItemVC setPanstVisible:itemVC.isOptionPanstEnable];
        price += [courseOptionItemVC setSpatsVisible:itemVC.isOptionSpatsEnable];
#else
        price += [courseOptionItemVC calcItemSumPrice];
#endif
    }
    
    // 各コースとオプションの合計値を表示
    [self _showCourseSumPrice:price];
    
}

#pragma mark -
#pragma mark demo

-(void)setDemoData{
    NipperBisuchie = [[GoodsItem alloc]init];
    NipperBisuchie.goodsName = nipperBisuchieName;
    NipperBisuchie.selectBtn = nipperBisuchieButton;
    NipperBisuchie.goodsID = 1;
    NipperBisuchie.selectImageView = nipperBisuchieImage;
    NipperBisuchie.colorName = nipperBisuchieColor;
    [NipperBisuchie setColorItem:@"コーラルシャンパン" colorImage:@"fantasy_cora-champagne.png"];
    [NipperBisuchie setColorItem:@"ベビーピンク" colorImage:@"fantasy_baby-pink.png"];
    [NipperBisuchie setColorItem:@"ブルージューン" colorImage:@"fantasy_blue-jean.png"];
    [NipperBisuchie setColorItem:@"ラブ" colorImage:@"fantasy_love.png"];
    [NipperBisuchie setColorItem:@"ミスティブラック" colorImage:@"fantasy_misty-black.png"];
    [NipperBisuchie setColorItem:@"オリーブ" colorImage:@"fantasy_olive.png"];
    NipperBisuchie.selectColorNum = 0;
    NipperBisuchie.sizeType=S1;
    NipperBisuchie.sizeBtn = NipperBisuchieSizeBtn;
    [goodsItems addObject:NipperBisuchie];
    
    HighWaistGirdle = [[GoodsItem alloc]init];
    HighWaistGirdle.goodsName = HighWaistGirdleName;
    HighWaistGirdle.goodsID = 2;
    HighWaistGirdle.colorName = HighWaistGirdleColor;
    HighWaistGirdle.sizeType=S2;
    HighWaistGirdle.sizeBtn = HighWaistGirdleSizeBtn;
    
    [goodsItems addObject:HighWaistGirdle];
    
    TBackBodySuit = [[GoodsItem alloc]init];
    TBackBodySuit.goodsName = TBackBodySuitName;
    TBackBodySuit.selectBtn = TBackBodySuitButton;
    TBackBodySuit.goodsID = 3;
    TBackBodySuit.selectImageView = TBackBodySuitImage;
    TBackBodySuit.colorName = TBackBodySuitColor;
    [TBackBodySuit setColorItem:@"エンジェル" colorImage:@"fairy_angel.png"];
    [TBackBodySuit setColorItem:@"ブルームーン" colorImage:@"fairy_blue-moon.png"];
    [TBackBodySuit setColorItem:@"キューティミント" colorImage:@"fairy_cuite-mint.png"];
    TBackBodySuit.selectColorNum = 2;
    TBackBodySuit.sizeType=SII;
    TBackBodySuit.sizeBtn = TBackBodySuitSizeBtn;
    [goodsItems addObject:TBackBodySuit];
    
    TBackShorts = [[GoodsItem alloc]init];
    TBackShorts.goodsName = TBackShortsName;
    TBackShorts.selectBtn = TBackShortsButton;
    TBackShorts.goodsID = 4;
    TBackShorts.selectImageView = TBackShortsImage;
    TBackShorts.colorName = TBackShortsColor;
    [TBackShorts setColorItem:@"エンジェル" colorImage:@"fairy_T-back-shorts_angel.png"];
    [TBackShorts setColorItem:@"ベビーピンク" colorImage:@"fairy_T-back-shorts_baby-pink.png"];
    [TBackShorts setColorItem:@"ブルージーン" colorImage:@"fairy_T-back-shorts_blue-jean.png"];
    [TBackShorts setColorItem:@"コーラルシャンパン" colorImage:@"fairy_T-back-shorts_cora-champagne.png"];
    [TBackShorts setColorItem:@"オリーブ" colorImage:@"fairy_T-back-shorts_olive.png"];
    TBackShorts.selectColorNum = 2;
    TBackShorts.sizeType=S3;
    TBackShorts.sizeBtn = TBackShortsSizeBtn;
    [goodsItems addObject:TBackShorts];
    
    CoolbizTrencker = [[GoodsItem alloc]init];
    CoolbizTrencker.goodsName = CoolbizTrenckerName;
    CoolbizTrencker.selectBtn = CoolbizTrenckerButton;
    CoolbizTrencker.goodsID = 5;
    CoolbizTrencker.selectImageView = CoolbizTrenckerImage;
    CoolbizTrencker.colorName = CoolbizTrenckerColor;
    [CoolbizTrencker setColorItem:@"ブラック" colorImage:@"drainage_coolbiz-trencker.png"];
    CoolbizTrencker.selectColorNum = 0;
    CoolbizTrencker.sizeType=S3;
    CoolbizTrencker.sizeBtn = CoolbizTrenckerSizeBtn;
    [goodsItems addObject:CoolbizTrencker];
};

-(IBAction)OnSelectItem:(id)sender{
    //デモなのでIDが固定
    UIButton *selectBtn = (UIButton*)sender;
    if (goodsSelector)
    {
        NSLog(@"goodsSelector release");
        //[goodsSelector release];
        goodsSelector = nil;
    }
    
    // 商品選択ポップアップのViewControllerのインスタンス生成 : POPUP_GOODS_SELECT
    GoodsPopup *goodsSel
    = [[GoodsPopup alloc] initWithGoodsItem:[goodsItems objectAtIndex:selectBtn.tag] popUpID:POPUP_GOODS_SELECT callBack:self];    // ポップアップViewの表示
    goodsSelector =
    [[UIPopoverController alloc] initWithContentViewController:goodsSel];
    goodsSel.popoverController = goodsSelector;
    
    [goodsSelector presentPopoverFromRect:selectBtn.bounds
                                   inView:selectBtn
                 permittedArrowDirections:UIPopoverArrowDirectionAny
                                 animated:YES];
    //[goodsSel release];
    goodsSel = nil;
}

// 1整数入力
- (IBAction) OnBtnEditSalesNumber:(id)sender
{
    UIButton *selectBtn = (UIButton*)sender;
    if (numberInput)
    {
        NSLog(@"numberInput release");
        //[numberInput release];
        numberInput = nil;
    }
    
    // 数値選択ポップアップのViewControllerのインスタンス生成 : POPUP_NUMBER_INPUT
    NumberInputPopUp *numInp
    = [[NumberInputPopUp alloc] initWithIntButton:(UIButton*)sender selectNum:[selectBtn.currentTitle intValue] popUpID:POPUP_INTEGER_INPUT callBack:self ];
    // ポップアップViewの表示
    numberInput =
    [[UIPopoverController alloc] initWithContentViewController:numInp];
    numInp.popoverController = numberInput;
    
    [numberInput presentPopoverFromRect:selectBtn.bounds
                                 inView:selectBtn
               permittedArrowDirections:UIPopoverArrowDirectionAny
                               animated:YES];
    //[numInp release];
    numInp = nil;
}

-(IBAction)OnSizePickerShow:(id)sender{
    UIButton *selectBtn = (UIButton*)sender;
    GoodsItem *selectItem = [goodsItems objectAtIndex:selectBtn.tag];
    if (numberInput)
    {
        NSLog(@"sizeSelector release");
        //[sizeSelector release];
        sizeSelector = nil;
    }
    // 数値選択ポップアップのViewControllerのインスタンス生成 : POPUP_SIZE_SELECT
    SizeSelectPopup *sizeSel = [[SizeSelectPopup alloc] initWithGoodsItems:selectItem popUpID:POPUP_SIZE_SELECT callBack:self];
    
    // ポップアップViewの表示
    sizeSelector =
    [[UIPopoverController alloc] initWithContentViewController:sizeSel];
    sizeSel.popoverController = sizeSelector;
    
    [sizeSelector presentPopoverFromRect:selectBtn.bounds
                                  inView:selectBtn
                permittedArrowDirections:UIPopoverArrowDirectionAny
                                animated:YES];
    //[sizeSel release];
    sizeSel = nil;
}

#pragma mark - private_methods

// 各コースとオプションの合計値を表示
-(void) _showCourseSumPrice:(NSInteger)sum
{
    NSNumberFormatter *format = [[NSNumberFormatter alloc] init];
    [format setPositiveFormat:@"###,###,##0"];
    sumPrice.text =[NSString stringWithFormat:@"%@ %@",
                    [format currencySymbol],
                    [format stringFromNumber:[NSNumber numberWithInt:(int)sum]]];
    //[format release];
}

- (courseItemBaseViewController*) _getActiveCourseItemVC
{
    courseItemBaseViewController *itemVC = nil;
    
    switch (_activeCourse) {
        case 1:
            itemVC = course1ItemVC;
            break;
        case 2:
            itemVC = course2ItemVC;
            break;
        case 3:
            itemVC = course3ItemVC;
            break;
        case 4:
            itemVC = course4ItemVC;
            break;
        case 5:
            itemVC = course5ItemVC;
            break;
        default:
            break;
    }
    
    return (itemVC);
    
}

#pragma mark - public_methods

// 現在日付の設定
-(void) setNowDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY年MM月dd日 （EEE）"];
    txtNowDate.text  = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:[NSDate date]]];
    
    //[dateFormatter release];
}

// 左方向のスワイプイベント
- (void)OnSwipeLeftView:(id)sender
{
    if(inputFlag){
        [self showAlert];
    }else{
        // 現時点で最上位のViewController(=self)を削除する
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        [mainVC closePopupWindow:self];
        ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).bodyCheckView = nil;
    }
}

// シャッター音を鳴らす
- (void) shutterSoundDelay
{
    [Common playSoundWithResouceName:@"shutterSound" ofType:@"mp3"];
    
    btnHardCopy.enabled = YES;
}

// 遷移元のVCに対して更新処理を行う
- (void) refresh2OwnerTransitionVC
{
    // MainViewControllerの取得
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    
    /*
     // 他の画面に保存済み画像を表示する
     // 画面遷移の経路によって、通知先画面を変更する
     if (self.IsNavigationCall)
     {
     // 写真一覧（サムネイル）画面へ通知
     
     // NavigationControllerよりthumbNailクラスのVCを取得
     UIViewController *vc
     = [ mainVC getVC4NaviCtrlWithClass:[ThumbnailViewController class]];
     if (vc)
     {
     // サムネイルの更新(画像一覧のTAG変更含む)
     [(ThumbnailViewController*)vc refreshThumbNail:true];
     }
     
     // ViewContllerのリストより履歴一覧クラスのVCを取得
     vc = [ mainVC getVC4ViewControllersWithClass:[HistListViewController class] ];
     if (vc)
     {
     // Viewの日付による更新
     [ (HistListViewController*)vc refrshViewWithDate:[NSDate date]];
     }
     
     }
     else
     {*/
    // 履歴詳細VC(2つ前のVC)を取得して、サムネイルを更新
    UIViewController *vc = [mainVC getViewControllerFromCurrentView:self pageTo:-2];
    if ((vc)
        && ([vc isKindOfClass:[HistDetailViewController class]]) )
    {
        // 当日の場合のみ、サムネイルと選択セルを更新する
        if ( ((HistDetailViewController*)vc).isWorkDateToday)
        { [(HistDetailViewController*)vc thumbnailSelectedCellRefresh]; }
        
        // ユーザ情報Viewの更新
        [(HistDetailViewController*)vc refreshUserInfoView];
    }
    
    // 履歴一覧VC（３つ前のVC）を取得して、一覧を更新
    vc = [mainVC getViewControllerFromCurrentView:self pageTo:-3];
    if ((vc)
        && ([vc isKindOfClass:[HistListViewController class]]) )
    {
        // Viewの日付による更新
        [ (HistListViewController*)vc refrshViewWithDate:[NSDate date]];
    }
    //}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    NSString* className = NSStringFromClass([touch.view class]);
    if([className compare:@"UIPickerView"] == NSOrderedSame){
    }else{
        if(picker != nil){
            [picker removeFromSuperview];
            [frameView removeFromSuperview];
            picker = nil;
            [overlayView removeFromSuperview];
        }
    }
}

- (void)showAlert
{

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ボディチェックシート"
                                                                       message:@"画面の内容を破棄します\nよろしいですか？\n（「は　い」を選ぶと画面の内容は\n破棄されます）"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"は　い"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    // 現時点で最上位のViewController(=self)を削除する
                                                    MainViewController *mainVC
                                                    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
                                                    [mainVC closePopupWindow:self];
                                                    ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).bodyCheckView = nil;
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"いいえ"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {

                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
}

// ユーザー情報の設定
- (void)setUser:(USERID_INT)userID;
{
    _userID = userID;
}

- (void)setUserName:(NSString*)userName
{
    txtCustomerName.text = userName;
}

//リソースの解放
- (void)releasePrdctView{
    
    for (UIView *view in [prdctScrollView subviews]) {
        for (UIView *view2 in [view subviews]) {
            NSString* className = NSStringFromClass([view2 class]);
            if([className compare:@"UIImageView"] == NSOrderedSame){
                UIImageView *imgView = (UIImageView*)view2;
                if(imgView != nil){
                    imgView.image = nil;
                    imgView.layer.sublayers = nil;
                }
            }else if([className compare:@"UIButton"] == NSOrderedSame){
                UIButton*btn = (UIButton*)view2;
                [btn setBackgroundImage:nil forState:UIControlStateNormal];
            }
            [view2 removeFromSuperview];
        }
        [view removeFromSuperview];
    }
}

- (void)didRotateDeviceChangeNotification:(NSNotification*)notification {
    [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
}

#endif
@end
