//
//  GoodsPopup.m
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "GoodsPopup.h"
#import "Common.h"

@interface GoodsPopup ()

@end

@implementation GoodsPopup

@synthesize goodsName;
@synthesize nowSelectIdx;
@synthesize editGoodsItem;

- (id)initWithGoodsItem:(GoodsItem *)sendGoodsItem
                   popUpID:(NSUInteger)popUpID
                  callBack:(id)callBackDelegate;
{
    if (self = [super initWithPopUpViewContoller:popUpID
                               popOverController:nil
                                        callBack:callBackDelegate
                                         nibName:@"goodsPopup"])
    if (self && [sendGoodsItem.ColorList count] > 0) {

        self.contentSizeForViewInPopover = CGSizeMake(400, 350);
        self.editGoodsItem = sendGoodsItem;
        NSLog(@"%d" ,sendGoodsItem.selectColorNum);

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Common cornerRadius4Control:lblTitle];
    lblTitle.text = editGoodsItem.goodsName.text;
    self.nowSelectIdx = self.editGoodsItem.selectColorNum;
    GoodsColorItem *nowColor = [self.editGoodsItem.ColorList objectAtIndex:nowSelectIdx];
    lblNowColor.text = nowColor.ColorName;
    [imageListView setDelegate:self];
    [self setPageng];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)setPageng{
    NSInteger page = 0;
    for (GoodsColorItem * item in editGoodsItem.ColorList){
        imageListView.contentSize = CGSizeMake(360 * (page + 1), 220);
        UIImage *imageFile = item.GoodsImage;
        CGSize imageSize = imageFile.size;
        CGFloat Scale = 1;
        if (imageSize.height > 220 || imageSize.width > 360) {
            if (220 / imageSize.height > 360 / imageSize.width) {
                Scale = (360 / imageSize.width);
            }else{
                Scale = (220 / imageSize.height);
            }
        }
        UIImageView *tempView = [[UIImageView alloc]initWithImage:item.GoodsImage];
        tempView.frame = CGRectMake((360 - (imageSize.width * Scale)) / 2,
                                    (220 - (imageSize.height * Scale)) / 2,
                                    imageSize.width * Scale,
                                    imageSize.height * Scale);
        
        UIImageView *pageView = [[UIImageView alloc]init];
        [pageView addSubview:tempView];
        pageView.frame = CGRectMake(360 * page, 0, 360, 220);
        [imageListView addSubview:pageView];
        page++;
    }
    [imageListView setContentOffset:CGPointMake(360 * self.nowSelectIdx, 0)];
    NSLog(@"%d",self.nowSelectIdx);
}

#pragma mark -
#pragma mark Delegate

- (id) setDelegateObject
{
    editGoodsItem.colorName.text = lblNowColor.text;
    editGoodsItem.selectColorNum = nowSelectIdx;
    GoodsColorItem* color =[editGoodsItem.ColorList objectAtIndex:nowSelectIdx];
    [editGoodsItem.selectImageView setImage:color.GoodsImage];

    return editGoodsItem;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    float nowPageX  = imageListView.contentOffset.x;
    //ページが半分を超えた所で表示中の色名変更
    int page = (nowPageX + 180) / 360;
    if (page < [editGoodsItem.ColorList count]) {
        nowSelectIdx = page;
        GoodsColorItem *color = [editGoodsItem.ColorList objectAtIndex:nowSelectIdx];
        lblNowColor.text = color.ColorName;
    }

}
@end
