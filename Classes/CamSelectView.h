//
//  CamSelectView.h
//  iPadCamera
//
//  Created by 西島和彦 on 2014/06/12.
//
//

#import <UIKit/UIKit.h>

@protocol CamSelectKindDelegate <NSObject>
- (void)CamSelectKind:(NSInteger)selNum;
@end

@interface CamSelectView : UIScrollView
<
UIScrollViewDelegate
>
{
    CGPoint         touchPoint;     // タッチした座標
    NSInteger       btnNum;         // 表示ボタン数
    NSInteger       btnSel;         // 選択中のボタン番号
    BOOL            _isScrolling;   // アニメーションによるスクロール中を示すフラグ
    CGFloat         slide;          // スライドボタンの移動量
    NSMutableArray  *labels;        // ラベル配列
    NSInteger       kind;           // ボタン or ラベル
}
// カメラ選択に変更が有った時に呼ばれるデリゲート
@property(nonatomic, assign)    id<CamSelectKindDelegate>   camselDelegate;
@property(nonatomic)            BOOL                        btnEnable;      // スライドボタンの操作許可

// 選択カメラ一覧と、初期選択カメラを設定
- (id)initWithFrame:(CGRect)frame btnObj:(NSArray *)btnOjb initSel:(NSInteger)initSel;

// ラベル表示で初期化する場合
- (id)initWithFrame:(CGRect)frame labelObj:(NSArray *)labelOjb initSel:(NSInteger)initSel;


// カメラアイコンの表示位置を設定する
- (void)setPos:(NSInteger)pos;

// 選択されたラベルの色を変える
- (void)setLabelColor:(NSInteger)selected;

@end
