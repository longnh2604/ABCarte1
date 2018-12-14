//
//  TouchManager.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/07/12.
//
//

#import <Foundation/Foundation.h>
#import "Stamp.h"

#define MAX_TOUCHES                     2               //トラッキングするタッチの数

@interface TouchManager : NSObject{
    CGPoint offset;
    CGPoint center;
    CGFloat width_magn;
    CGFloat height_magn;
    CGFloat preAngle;
    CGFloat angle;
    CGSize  preSize;
    CGSize  size;
    CFMutableDictionaryRef touches_; //1または2を記録
}
//１または2個目のタッチなら辞書に登録して、開始位置も記録、移動後位置も初期化
- (void)registerBeganTouches:(NSSet *)touches event:(UIEvent *)event stamp:(Stamp *)stamp atView:(UIView *)view;
//タッチが移動した時に移動後位置を変更
- (void)moveTouches:(NSSet *)touches event:(UIEvent *)event stamp:(Stamp *)stamp atView:(UIView *)view;
//タッチが終了した時に辞書から削除し、フラグもOFFに
- (void)endTouches:(NSSet *)touches event:(UIEvent *)event stamp:(Stamp *)stamp atView:(UIView *) view;
#if 1 // 不具合対応 kikuta - start - 2014/01/30
//タッチがスタンプ内にあるかの判定
- (BOOL) isStampInRect:(NSSet*)touches event:(UIEvent*)event stamp:(Stamp*)stamp atView:(UIView*)view;
#endif // 不具合対応 kikuta - end - 2014/01/30


- (NSUInteger)touchNumber:(UIEvent *)event;

//いくつタッチしているかを返す
//- (NSUInteger)status;
//異動後の中心を返す。
- (CGPoint)center;

- (CGSize)size;
//
- (CGFloat)angle;
@end
