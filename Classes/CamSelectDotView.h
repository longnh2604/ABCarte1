//
//  CamSelectDotView.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/06/26.
//
//

#import <UIKit/UIKit.h>

@protocol CamSelectDotViewDelegate <NSObject>
- (void)CamSelectKind:(NSInteger)selNum;
@end

@interface CamSelectDotView : UIScrollView
<
UIScrollViewDelegate
>
{
    CGPoint     defaultPoint;
    NSInteger   _btnNum;
    UIView      *selBorder;
}

@property(nonatomic, assign) id<CamSelectDotViewDelegate> camselDelegate;

// 選択位置を示すポイント画像と、選択ボタン数とともに初期化を行う
- (id)initWithFrame:(CGRect)frame btnName:(NSString *)btnName btnNum:(NSInteger)btnNum;

// 選択位置の設定
- (void)setPos:(NSInteger)pos;

@end
