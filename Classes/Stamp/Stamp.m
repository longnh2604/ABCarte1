//
//  Stamp.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/06/26.
//

#import "Stamp.h"
@interface Stamp(Private)
//- (double) diagonal;
//- (CGPoint)originAtNV;
@end

@implementation Stamp
@synthesize image, size, angle, center,cashRotateImage;
- (id)initWithImage:(UIImage *)img{
    if (self = [super init]) {
        self.image = img;
        //self.rect = CGRectMake(0.0f, 0.0f, img.size.width, img.size.height);
        self.size = img.size;
        center = CGPointZero;
        angle = 0.0f;
        self.cashRotateImage = self.rotateImage;
    }
    return self;
}
- (id)initWithStamp:(Stamp *)stamp{
    if (self = [super init]) {
        self.image = stamp.image;
        self.size = stamp.size;
        center = stamp.center;
        angle = stamp.angle;
        //self.cashRotateImage = self.rotateImage;
    }
    return self;
}
- (UIImage *)rotateImage{
    double diagonal = [self diagonal];
    CGSize circleS = CGSizeMake(diagonal, diagonal);
    UIGraphicsBeginImageContext(circleS);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform affine = [self affine];
    CGRect rect = [self rect];
    CGContextConcatCTM(context, affine);
    [image drawInRect:rect];
    UIImage *_rotateImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return _rotateImage;
}
- (UIImage *)rotateAndUpSideDownImage{
    double diagonal = [self diagonal];
    CGSize circleS = CGSizeMake(diagonal, diagonal);
    UIGraphicsBeginImageContext(circleS);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform affine = [self UpSideDownaffine];
    CGRect rect = [self rect];
    CGContextConcatCTM(context, affine);
    CGContextTranslateCTM(context, 0, diagonal);
    CGContextScaleCTM(context, 1, -1); //さらにひっくり返す
    [image drawInRect:rect];
    UIImage *_rotateImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return _rotateImage;
}

- (UIImage *)rotateImage: (CGContextRef)context{
    double diagonal = [self diagonal];
    CGSize circleS = CGSizeMake(diagonal, diagonal);
    UIGraphicsBeginImageContext(circleS);
    //CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform affine = [self affine];
    CGRect rect = [self rect];
    CGContextConcatCTM(context, affine);
    [image drawInRect:rect];
    UIImage *_rotateImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return _rotateImage;
}
- (void)updateImage{
    //self.cashRotateImage = self.rotateImage;
#if STAMP_MODE == 1
//    self.cashRotateImage = self.rotateAndUpSideDownImage;
    self.cashRotateImage = self.rotateImageWithRectangle;
#else
    self.cashRotateImage = self.rotateImageWithResizeDots;
#endif
}
- (void)drawInView:(UIView *)view{
    //[self.cashRotateImage drawAtPoint:[self originAtNV]];
    [self.rotateImage drawAtPoint:[self originAtNV]];
}
- (void)drawInView:(UIView *)view context:(CGContextRef)context{
    //[self.cashRotateImage drawAtPoint:[self originAtNV]];
    [[self rotateImage:context] drawAtPoint:[self originAtNV]];
}
- (void)drawInViewWithBlackBackground:(UIView *)view{
    //[self.cashRotateImage drawAtPoint:[self originAtNV]];
    [self.rotateImage drawAtPoint:[self originAtNV]];
}
//centerとsizeから導きだせるプロパティ的なもの
- (double)diagonal{
    return sqrt( pow( size.width, 2) + pow(size.height, 2)) + 2 * ROTATE_DISTANCE;
    //return sqrt( pow( size.width, 2) + pow(size.height, 2));
}
- (CGRect)rect{
    double diagonal = [self diagonal];
    return CGRectMake((diagonal - size.width) * 0.5,
                      (diagonal - size.height) * 0.5,
                      size.width,
                      size.height);
}
//座標変換系
- (CGAffineTransform)affine{
    CGAffineTransform aff = CGAffineTransformIdentity;
    double diagonal = [self diagonal];
    aff = CGAffineTransformTranslate(aff, diagonal * 0.5, diagonal * 0.5);
    aff = CGAffineTransformRotate(aff, angle);
    aff = CGAffineTransformTranslate(aff, diagonal * -0.5, diagonal * -0.5);
    return aff;
}
- (CGAffineTransform)UpSideDownaffine{
    CGAffineTransform aff = CGAffineTransformIdentity;
    double diagonal = [self diagonal];
    aff = CGAffineTransformTranslate(aff, diagonal * 0.5, diagonal * 0.5);
    aff = CGAffineTransformRotate(aff, -1 * angle);
    aff = CGAffineTransformTranslate(aff, diagonal * -0.5, diagonal * -0.5);
    //aff = CGAffineTransformTranslate(aff, 0, diagonal);
    //aff = CGAffineTransformTranslate(aff, 1, -1); //さらにひっくり返す
    return aff;
}
- (CGAffineTransform)reverseAffine{
    CGAffineTransform aff = CGAffineTransformIdentity;
    double diagonal = [self diagonal];
    aff = CGAffineTransformTranslate(aff, diagonal * 0.5, diagonal * 0.5);
    aff = CGAffineTransformRotate(aff, -1 *  angle);
    aff = CGAffineTransformTranslate(aff, diagonal * -0.5, diagonal * -0.5);
    return aff;
}
- (CGPoint)originAtNV{
    double diagonal = self.diagonal;
    return CGPointMake(self.center.x - diagonal / 2, self.center.y - diagonal / 2);
}
- (CGPoint)NVtoSV:(CGPoint)pointNV{
    CGPoint origin = [self originAtNV];
    return CGPointMake(pointNV.x - origin.x, pointNV.y - origin.y);
}
- (CGPoint)NVtoRV:(CGPoint)pointNV{
    CGPoint pointSV = [self NVtoSV:pointNV];
    CGAffineTransform affine = [self reverseAffine];
    return CGPointApplyAffineTransform(pointSV, affine);
}
- (CGPoint)RVtoSV: (CGPoint)point{
    CGAffineTransform affine = [self affine];
    return CGPointApplyAffineTransform(point, affine);
}
- (CGPoint)RVtoNV:(CGPoint)pointRV{
    CGPoint pointSV = [self RVtoSV:pointRV];
    CGPoint origin = [self originAtNV];
    return CGPointMake(pointSV.x + origin.x, pointSV.y + origin.y);
}
- (CGPoint)centerInRV{
    CGRect rect = [self rect];
    return CGPointMake(rect.origin.y + rect.size.height * 0.5f, rect.origin.y + rect.size.height * 0.5f);
}

- (CGRect) rectInNV{
    double diagonal = self.diagonal;
    return CGRectMake(center.x - diagonal * 0.5f,
                      center.y - diagonal * 0.5f,
                      diagonal,
                      diagonal);
}
#if STAMP_MODE==1
- (UIImage *)rotateImageWithRectangle{
    double diagonal = [self diagonal];
    CGSize circleS = CGSizeMake(diagonal, diagonal);
    UIGraphicsBeginImageContext(circleS);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //CGAffineTransform affine = [self affine];
    
    CGAffineTransform affine = [self UpSideDownaffine];
    CGRect rect = [self rect];
    CGContextConcatCTM(context, affine);
    CGContextTranslateCTM(context, 0, diagonal);
    CGContextScaleCTM(context, 1, -1); //さらにひっくり返す
    
    [image drawInRect:rect];
    //    [self drawResizeDots:context];
    //    [self drawRotateDot:context];
    [self drawBreakRect:rect];
    
    UIImage *_rotateImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return _rotateImage;
}
- (void)drawBreakRect: (CGRect)rect{
    UIBezierPath *path = [UIBezierPath bezierPath];
    //色
    [[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0] set ];
    //幅
    [path setLineWidth:2.0f];
    
    //点線のパターンをセット
    CGFloat dashPattern[2] = { 15.0f, 5.0f };
    [path setLineDash:dashPattern  count:2 phase:0];
    
    //描画位置設定
    [path moveToPoint:CGPointMake(rect.origin.x - 2, rect.origin.y - 2)];
    [path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width + 3, rect.origin.y - 2)];
    [path addLineToPoint:CGPointMake(rect.origin.x + rect.size.width + 3, rect.origin.y + rect.size.height + 3)];
    [path addLineToPoint:CGPointMake(rect.origin.x - 2, rect.origin.y + rect.size.height + 3)];
    [path addLineToPoint:CGPointMake(rect.origin.x - 2, rect.origin.y - 2)];
    
    //描画
    [path stroke];
}
#else //if STAMP_MODE > 1
#pragma mark -with 9 buttons
- (UIImage *)rotateImageWithResizeDots{
    double diagonal = [self diagonal];
    CGSize circleS = CGSizeMake(diagonal, diagonal);
    UIGraphicsBeginImageContext(circleS);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //CGAffineTransform affine = [self affine];
    
    CGAffineTransform affine = [self UpSideDownaffine];
    CGRect rect = [self rect];
    CGContextConcatCTM(context, affine);
    CGContextTranslateCTM(context, 0, diagonal);
    CGContextScaleCTM(context, 1, -1); //さらにひっくり返す
    
    [image drawInRect:rect];
    [self drawResizeDots:context];
    [self drawRotateDot:context];
    UIImage *_rotateImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return _rotateImage;
}
- (void)drawResizeDots: (CGContextRef)context{
    NSMutableArray * dots = [self getResizeDots];
    for (ResizeDot *dot in dots) {
        [self drawResizeDot:dot context:context];
    }
}
- (void)drawWithResizeDotsInView:(UIView *)view{
    UIImage *rotateImage = [self rotateImageWithResizeDots];
    [rotateImage drawAtPoint: self.originAtNV];
}

- (NSMutableArray *)getResizeDots{
    NSMutableArray *dots = [NSMutableArray array];
    CGRect rect = [self rect];
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            BOOL flag = true;
            if ((x == 0 && y == 0) || //真ん中
                (x == 0 && rect.size.width < 30) || //幅狭い
                (y == 0 && rect.size.height < 30)) { //高さ低い
                flag = false;
            }
            if (flag) {
                ResizeDot *dot = [[ResizeDot alloc] init];
                dot.x = x;
                dot.y = y;
                dot.radius = RADIUS;
                dot.longRadius = LONG_RADIUS;
                CGPoint rectCenter = CGPointMake(rect.origin.x + rect.size.width / 2,
                                                 rect.origin.y + rect.size.height / 2);
                dot.point = CGPointMake(rectCenter.x + x * rect.size.width / 2,
                                        rectCenter.y + y * rect.size.height / 2);
                [dots addObject:dot];
            }
        }
    }
    return dots;
}
- (void)drawRotateDot:(CGContextRef)context{
    RotateDot *dot = [self getRotateDot];
    [self drawRotateDot:dot context:context];
}
- (RotateDot *)getRotateDot{
    CGRect rect = [self rect];
    CGPoint centerInRV = [self centerInRV];
    RotateDot *dot = [[RotateDot alloc] init];
    dot.point = CGPointMake(centerInRV.x, rect.origin.y - 60);
    dot.radius = RADIUS;
    return dot;
}
- (void)drawRotateDot:(RotateDot *)dot context:(CGContextRef)context{
    UIImage *rotateImg = [UIImage imageNamed:ROTATE_IMAGE];
    [rotateImg drawInRect:dot.rect];
}
- (BOOL)nearRotateDot: (CGPoint)point{
    RotateDot* dot = [self getRotateDot];
    return ([Stamp distanceBetween:dot.point and:point] < LONG_RADIUS);
}
- (BOOL)hasNearResizeDot:(CGPoint)point{
    NSMutableArray *dots = [self getResizeDots];
    for (ResizeDot *dot in dots) {
        if ([Stamp distanceBetween:dot.point and:point] < dot.longRadius) {
            return true;
        }
    }
    return false;
}
- (ResizeDot *)nearResizeDot:(CGPoint)point{
    NSMutableArray *dots = [self getResizeDots];
    ResizeDot *nearDot;
    CGFloat min = LONG_RADIUS;
    for (ResizeDot *dot in dots) {
        if ([Stamp distanceBetween:dot.point and:point] < min) {
            min = [Stamp distanceBetween:dot.point and:point];
            nearDot = dot;
        }
    }
    if (min < LONG_RADIUS) {
        return nearDot;
    }
    return NULL;
}
- (void)drawResizeDot:(ResizeDot *)dot context:(CGContextRef)context{
    CGRect currentBounds = [self ninePoint:dot];
    CGFloat diameter=MIN(currentBounds.size.height, currentBounds.size.width);
    CGFloat borderWidth=1;
    CGMutablePathRef circle=CGPathCreateMutable();
    CGPathAddArc(circle, NULL, CGRectGetMidX(currentBounds), CGRectGetMidY(currentBounds), (diameter/2.0)-borderWidth, M_PI, -M_PI, NO);
    
    CGColorRef color1 = [UIColor colorWithRed:0.2f green:0.2f blue:0.2f alpha:1.0f].CGColor;
    CGColorRef color2 = [UIColor colorWithRed:0.9f green:0.9f blue:0.9f alpha:1.0f].CGColor;
    CGGradientRef gradient;
    CGFloat locations[2] = { 0.0, 1.0 };
    NSArray *colors = [NSArray arrayWithObjects:( id)(color1), color2, nil];
    
    gradient = CGGradientCreateWithColors(NULL,( CFArrayRef)(colors), locations);
    
    CGFloat startX = CGRectGetMidX(currentBounds);
    CGFloat endX = startX;
    CGFloat startY = CGRectGetMidY(currentBounds);
    CGFloat endY = startY;
    startX = CGRectGetMinX(currentBounds);
    endX = CGRectGetMaxX(currentBounds);
    startY = CGRectGetMinY(currentBounds);
    endY = CGRectGetMaxY(currentBounds);
    /*
     if (dot.x < 0) {
     startX = CGRectGetMinX(currentBounds);
     endX = CGRectGetMaxX(currentBounds);
     } else if (dot.x > 0){
     startX = CGRectGetMaxX(currentBounds);
     endX = CGRectGetMinX(currentBounds);
     }
     if (dot.y < 0) {
     startY = CGRectGetMinY(currentBounds);
     endY = CGRectGetMaxY(currentBounds);
     } else if (dot.y > 0){
     startY = CGRectGetMaxY(currentBounds);
     endY = CGRectGetMinY(currentBounds);
     }
     */
    CGPoint topCenter = CGPointMake(startX, startY);
    CGPoint midCenter = CGPointMake(endX, endY);
    //fill the circle with gradient
    CGContextAddPath(context, circle);
    CGContextSaveGState(context);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, topCenter, midCenter, 0);
    CGContextRestoreGState(context);
    CGGradientRelease(gradient);
    CFRelease(circle);
}
//長方形に均等に９つの点を置くイメージ x=>(-1,0,1) y=>(-1,0,1)
- (CGRect)ninePoint: (ResizeDot *)dot{
    return CGRectMake(dot.point.x - dot.radius, dot.point.y - dot.radius, 2 * dot.radius, 2 * dot.radius);
}
#endif
#pragma mark -caliculate

//距離
+ (CGFloat)distanceBetween: (CGPoint)p1 and: (CGPoint)p2{
    return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
}

//CGRectの端
+ (CGFloat)rectTop: (CGRect)rect{
    return rect.origin.y;
}
+ (CGFloat)rectRight: (CGRect)rect{
    return rect.origin.x + rect.size.width;
}
+ (CGFloat)rectBottom: (CGRect)rect{
    return rect.origin.y + rect.size.height;
}
+ (CGFloat)rectLeft: (CGRect)rect{
    return rect.origin.x;
}
+(CGFloat)rect: (CGRect)rect xy:(int)xy smallBig:(int)smallBig{
    if (xy < 0) {
        return (smallBig < 0) ? [Stamp rectLeft:rect] : [Stamp rectRight:rect];
    } else {
        return (smallBig < 0) ? [Stamp rectTop:rect] : [Stamp rectBottom:rect];
    }
}
+ (CGPoint)rectCenter: (CGRect)rect{
    return CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height / 2);
}
//右左上下で
+ (CGRect)rectTop:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom left:(CGFloat)left{
    if (left > right){
        CGFloat tmp = left;
        left = right;
        right = tmp;
    }
    if (top > bottom) {
        CGFloat tmp = top;
        top = bottom;
        bottom = tmp;
    }
    return CGRectMake(left, top, right - left, bottom - top);
}

//UIViewの矩形中の点が左から（上から）何ピクセルであるか
+ (CGPoint)offsetTap: (CGPoint)point fromCenter:(CGPoint)center{
    return CGPointMake(center.x - point.x, center.y - point.y);
}
//offsetから中心点を求める
+ (CGPoint)centerFromTap: (CGPoint)tap Offset:(CGPoint)offset{
    return CGPointMake(tap.x + offset.x, tap.y + offset.y);
}

@end