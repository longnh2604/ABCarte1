//
//  Stamp.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/06/26.
//

/*
 座標
 NV: 通常座標
 SV: すっぽり正方形
 RV: 傾いたすっぽり正方形
 
 すっぽり正方形
 ー画像の中心を軸に回転させた時に出来る円がすっぽり収まる正方形
 ①傾いていないすっぽり正方形
 　→生成される傾いた画像はこの正方形として描画される
 ②傾いたすっぽり正方形
 　→この座標において、画像本体の矩形が表現される
 ＝＞すっぽり正方形はわかりにくい概念なので、外側からは意識させないように。
 
 diagonal->すっぽり正方形の直径 = 画像の矩形の対角線の長さ
 　originAtNV->すっぽり正方形の左上角
 
 通常座標
 center, originAtNV
 */

#import <UIKit/UIKit.h>
#import "ResizeDot.h"
#import "RotateDot.h"

#define STAMP_MODE   1

#if STAMP_MODE == 1
#define ROTATE_DISTANCE 0
#else
typedef enum {
    STAMP_VIEW,
    STAMP_MOVE,
    STAMP_RESIZE,
    STAMP_ROTATE,
} STAMP_DRAW_MODE;

#define RADIUS 5
#define LONG_RADIUS 30
#define ROTATE_RADIUS 10
#define ROTATE_DISTANCE 100
#define ROTATE_IMAGE @"rotate.png"
#endif
@interface Stamp : NSObject{
    UIImage *image;
    UIImage *cashRotateImage;
    CGFloat angle;
    CGSize size;
    CGPoint center;
}
@property(nonatomic, retain) UIImage *image;
@property(nonatomic, retain) UIImage *cashRotateImage;
@property(nonatomic) CGFloat angle;
@property(nonatomic) CGSize size;
@property(nonatomic) CGPoint center;

- (id)initWithImage: (UIImage *)img;
- (id)initWithStamp: (Stamp *)stamp;
- (void)drawInView: (UIView *)view;
- (void)drawInView:(UIView *)view context:(CGContextRef)context;
- (void)drawInViewWithBlackBackground:(UIView *)view;
- (void)updateImage;

- (CGPoint)NVtoRV:(CGPoint)pointNV;
- (CGPoint)RVtoSV: (CGPoint)pointRV;
- (CGPoint)RVtoNV: (CGPoint)pointNV;

- (CGAffineTransform)reverseAffine;

- (UIImage *)rotateImage;
- (UIImage *)rotateAndUpSideDownImage;
- (CGRect) rect;
- (CGRect) rectInNV;
- (CGPoint) centerInRV;
- (CGAffineTransform) affine;
- (CGPoint)originAtNV;
- (double)diagonal;

#if STAMP_MODE > 1
- (void)drawWithResizeDotsInView: (UIView *)view;
- (void)drawResizeDots: (CGContextRef)context;
- (void)drawResizeDot:(ResizeDot *)dot context:(CGContextRef)context;

- (BOOL)hasNearResizeDot:(CGPoint)point;
- (ResizeDot *)nearResizeDot:(CGPoint)point;
- (BOOL)nearRotateDot: (CGPoint)point;

- (double) diagonal;
- (CGRect) rect;
#endif

//計算用のメソッド
+ (CGFloat)distanceBetween: (CGPoint)p1 and: (CGPoint)p2;

+ (CGFloat)rectTop: (CGRect)rect;
+ (CGFloat)rectRight: (CGRect)rect;
+ (CGFloat)rectBottom: (CGRect)rect;
+ (CGFloat)rectLeft: (CGRect)rect;
+ (CGFloat)rect: (CGRect)rect xy:(int)xy smallBig:(int)smallBig;

+ (CGPoint)rectCenter: (CGRect)rect;
+ (CGRect)rectTop:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom left:(CGFloat)left;

//UIViewの矩形中の点が左から（上から）何ピクセルであるか
+ (CGPoint)offsetTap: (CGPoint)point fromCenter:(CGPoint)center;
//offsetから中心点を求める
+ (CGPoint)centerFromTap: (CGPoint)tap Offset:(CGPoint)offset;
@end
