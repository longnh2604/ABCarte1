//
//  CourseItem.m
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import "CourseItem.h"

/**
 * コースのitemを表すクラス
 */
@implementation CourseItem

#pragma mrk life_cycle

- (void) _initializeWithItemNum:(NSInteger)num itemPrice:(NSInteger)price
{
    self.itemNum = num;
    self.itemPrice = price;
    self.groupID = COURSE_ITEM_GROUP_INVALID;
    self.isValid = YES;     // デフォルトで有効にする
}

// 初期化
- (id) initWithItemNum:(NSInteger)num itemPrice:(NSInteger)price
{
    if ((self = [super init])) {
        [self _initializeWithItemNum:num itemPrice:price];
    }
    
    return (self);
}

#pragma mark- public_methods
// 合計を求める
- (NSInteger) getSumPrice
{
    return (self.itemPrice * self.itemNum);
}

@end

/**
 * 複数単価を持つコースのitemを表すクラス
 */
@implementation multiPriceCourseItem

// 初期化
- (id) initWithNormalPrice:(NSInteger)nPrice largerPrice:(NSInteger)lPrice specialPrice:(NSInteger)sPrice
{
    if ((self = [super initWithItemNum:1 itemPrice:nPrice]))
    {
        self.normalItemPrice =nPrice;
        self.largeItemPrice = lPrice;
        self.specialItemPrice = sPrice;
    }
    
    return (self);
}

#pragma mark- public_methods
// itemPriceの設定
- (void) setCourseItem:(CourseItemPrice)price
{
    switch (price) {
        case CourseItemNormalPrice:
            self.itemPrice = self.normalItemPrice;
            break;
        case CourseItemLargePrice:
            self.itemPrice = self.largeItemPrice;
            break;
        case CourseItemSpecialPrice:
            self.itemPrice = self.specialItemPrice;
        default:
            break;
    }
}

@end
