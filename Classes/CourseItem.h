//
//  CourseItem.h
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import <Foundation/Foundation.h>

#define COURSE_ITEM_GROUP_INVALID NSIntegerMin

/**
 * コースのitemを表すクラス
 */
@interface CourseItem : NSObject

@property(nonatomic, assign) NSInteger itemNum;     // 個数
@property(nonatomic, assign) NSInteger itemPrice;   // 単価
@property(nonatomic, assign) NSInteger groupID;     // このitemが属するグループ
@property(nonatomic, assign) BOOL isValid;          // このitemが有効であるか(ORアイテム対応)

// 初期化
- (id) initWithItemNum:(NSInteger)num itemPrice:(NSInteger)price;

// 合計を求める
- (NSInteger) getSumPrice;

@end

typedef NS_ENUM(NSInteger, CourseItemPrice)
{   CourseItemNormalPrice, CourseItemLargePrice, CourseItemSpecialPrice};

/**
 * 複数単価を持つコースのitemを表すクラス
 */
@interface multiPriceCourseItem : CourseItem

@property(nonatomic, assign) NSInteger normalItemPrice;  // 通常サイズ単価
@property(nonatomic, assign) NSInteger largeItemPrice;   // ラージサイズ単価
@property(nonatomic, assign) NSInteger specialItemPrice; // 特注単価

// 初期化
- (id) initWithNormalPrice:(NSInteger)nPrice largerPrice:(NSInteger)lPrice specialPrice:(NSInteger)sPrice;

// itemPriceの設定
- (void) setCourseItem:(CourseItemPrice)price;

@end