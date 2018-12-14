//
//  courseOptionItemViewController.m
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import "courseOptionItemViewController.h"

@interface courseOptionItemViewController ()

@end

@implementation courseOptionItemViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark- override_mehtods

// nib nameの指定
- (NSString*) _setNibName
{   return (@"courseOptionItemViewController"); }

/** priceItemの設定：初期化時にコールされる
 *  ・ORとなるitemも含め、全てをリストに登録する
 *  ・表示する列毎に、ORがあってもなくてもgroupIDを設定する
 */
- (void) _priceItemSet
{
    // パンスト：gropu1
    multiPriceCourseItem *item1
        = [[multiPriceCourseItem alloc]initWithNormalPrice:10290 largerPrice:10290 specialPrice:10290];
    item1.groupID = 1;
    item1.itemNum = 0;
    [self.priceItems addObject:item1];
    [item1 release];
    
    // スパッツ：gropu2
    multiPriceCourseItem *item2
        = [[multiPriceCourseItem alloc]initWithNormalPrice:39900 largerPrice:60900 specialPrice:60900];
    item2.groupID = 2;
    item2.itemNum = 0;
    [self.priceItems addObject:item2];
    [item2 release];
    
    // ハイソックス：gropu3
    multiPriceCourseItem *item3
        = [[multiPriceCourseItem alloc]initWithNormalPrice:10290 largerPrice:10290 specialPrice:10290];
    item3.groupID = 3;
    item3.itemNum = 0;
    [self.priceItems addObject:item3];
    [item3 release];
    
    // Tバックショーツ：gropu4
    multiPriceCourseItem *item4
        = [[multiPriceCourseItem alloc]initWithNormalPrice:7140 largerPrice:11550 specialPrice:11550];
    item4.groupID = 4;
    item4.itemNum = 0;
    [self.priceItems addObject:item4];
    [item4 release];
    
    // レーシーショーツ：gropu5
    multiPriceCourseItem *item5
        = [[multiPriceCourseItem alloc]initWithNormalPrice:10290 largerPrice:15700 specialPrice:15700];
    item5.groupID = 5;
    item5.itemNum = 0;
    [self.priceItems addObject:item5];
    [item5 release];
    
}

/** 価格ラベル（priceLabels）の設定：ViewDidLoadにてコールされる
 *  ・priceItemのリストに合わせてlabelを設定する
 *   （リスト数と同じに設定する：OR=groupIDが同一のものは同じLabelとなる）
 */
- (void) _priceLabelSet
{
    [self.priceLabels addObjectsFromArray:
     [NSArray arrayWithObjects:lblGrp1Price, lblGrp2Price, lblGrp3Price, lblGrp4Price, lblGrp5Price, nil]];
}

// viewのframe設定
- (CGRect) _viewFrameSet
{   return COURSE_OPTION_ITEM_VIEW_FRAME; }

// リセット個数の取得
- (NSInteger) _setResetItemNum
{   return 0; }

#pragma mark private_mathods

- (NSInteger) _setItemVisible:(BOOL)isShow itemIndex:(NSInteger)idx
{
    UIImageView *img = nil;
    UIButton *btn = nil;
    UILabel *lbl = nil;
    UILabel *lblName = nil;
    
    multiPriceCourseItem *item = nil;
    
    switch (idx) {
        case 0:
            img = imgPanst;
            btn = btnPanst;
            lbl = lblPanst;
            lblName = lblPanstName;
            item = [self.priceItems objectAtIndex:idx];
            break;
        case 1:
            img = imgSpats;
            btn = btnSpats;
            lbl = lblSpats;
            lblName = lblSpatsName;
            item = [self.priceItems objectAtIndex:idx];
        default:
            break;
    }
    
    if (img)
    {   
        img.hidden = ! isShow;
        btn.hidden = ! isShow;
        lbl.hidden = ! isShow;
        lblName.hidden = ! isShow;
        
        item.isValid = isShow;
    }
    
    return ([self calcItemSumPrice]);
}

#pragma mark public_methods

// パンストの表示設定
-(NSInteger) setPanstVisible:(BOOL)isShow;
{
    return ([self _setItemVisible:isShow itemIndex:0]);
}

// スパッツの表示設定
-(NSInteger) setSpatsVisible:(BOOL)isShow
{
    return ([self _setItemVisible:isShow itemIndex:1]);
}

@end
