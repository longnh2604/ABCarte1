//
//  courseItemBaseViewController.h
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import <UIKit/UIKit.h>

#import "SomeCourseItemCommon.h"

#define COURSE_ITEM_VIEW_FRAME CGRectMake(14.0f, 6.0f, 700.0f, 188.0f)
#define COURSE_OPTION_ITEM_VIEW_FRAME CGRectMake(14.0f, 200.0f, 700.0f, 188.0f)

@protocol courseItemDelegate;

/*
 * 各コースのViewControllerのbaseクラス
 */
@interface courseItemBaseViewController : UIViewController
{
    
    IBOutlet UILabel        *lblGrp1Price;      // Group1の単価Label
    IBOutlet UILabel        *lblGrp2Price;      // Group2の単価Label
    IBOutlet UILabel        *lblGrp3Price;      // Group3の単価Label
    IBOutlet UILabel        *lblGrp4Price;      // Group5の単価Label
    IBOutlet UILabel        *lblGrp5Price;      // Group6の単価Label
    
    IBOutlet UIButton       *btnGrp1Num;        // Group1の個数ボタン
    IBOutlet UIButton       *btnGrp2Num;        // Group2の個数ボタン
    IBOutlet UIButton       *btnGrp3Num;        // Group3の個数ボタン
    IBOutlet UIButton       *btnGrp4Num;        // Group4の個数ボタン
    IBOutlet UIButton       *btnGrp5Num;        // Group5の個数ボタン
    
@protected
    BOOL _isOptionPanstEnable;
    BOOL _isOptionSpatsEnable;
}

@property (nonatomic, assign) id<courseItemDelegate> delegate;

@property(nonatomic, retain) NSMutableArray *priceItems;
@property(nonatomic, retain) NSMutableArray *priceLabels;

@property(nonatomic, readonly) BOOL isOptionPanstEnable;
@property(nonatomic, readonly) BOOL isOptionSpatsEnable;

// 初期化
-(id) initWithNibName:(NSString *)nibNameOrNil notifyDelegate:(id<courseItemDelegate>)delegate;

// 初期化
-(id) initWithNotifyDelegate:(id<courseItemDelegate>)delegate;

/**
 * サイズ変更の通知
 * @param   CourceItemPrice     : 変更となるサイズ
 * @return  このViewControllerが管理するitemの合計額
 */
-(NSInteger) notifyChangeSizeWithCourceItemPrice:(CourseItemPrice)itemPrice;

// このViewControllerが管理するitemの合計額
- (NSInteger) calcItemSumPrice;

// コースのitemのリセット
- (void) resetCourseItems;

@end

/**
 * 各コースの通知イベント定義
 */
@protocol courseItemDelegate <NSObject>

@optional

/**
 * 合計額の変更通知
 *  @param      sender          : 通知したクラス
 *  @param      changeSumPrice  : このインスタンスのItemの変更後の合計額
 */
- (void) courseItemViewController:(id)sender notifySumPriceChange:(NSInteger)price;

@end