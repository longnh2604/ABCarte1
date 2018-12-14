//
//  GoodsPopup.h
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "PopUpViewContollerBase.h"
#import "GoodsItem.h"
#import "GoodsColorItem.h"

@interface GoodsPopup : PopUpViewContollerBase<UIScrollViewDelegate>
{
    NSString * goodsColorName;//選択中色名    
    NSMutableArray * GoodsItemList;//カラーリスト
    
    NSInteger nowSelectIdx;
    
    IBOutlet UIButton * btnSubmit;//決定キー
    IBOutlet UILabel * lblTitle;//タイトルバー
    IBOutlet UILabel * lblNowColor;//選択中色
    IBOutlet UIScrollView * imageListView;//イメージリストビュー
    
    GoodsItem * editGoodsItem;//操作中の商品
}
@property(nonatomic,retain) NSString *goodsName;
@property(nonatomic)        NSInteger nowSelectIdx;
@property(nonatomic,retain) GoodsItem *editGoodsItem;

- (id)initWithGoodsItem:(GoodsItem *)sendGoodsItem
                   popUpID:(NSUInteger)popUpID
                  callBack:(id)callBackDelegate;
@end
