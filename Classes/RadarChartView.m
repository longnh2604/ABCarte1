//
//  RadarChartView.m
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "RadarChartView.h"

#import "Common.h"

@implementation RadarChartView

@synthesize nowSize;
@synthesize setSize;
@synthesize idealSize;
@synthesize nowSizeShow;
@synthesize setSizeShow;
@synthesize idealSizeShow;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void) DrawRadarBack:(CGContextRef)context{
    
    // 線のサイズの指定
    CGContextSetLineWidth(context, 1.0f);
    
    CGRect selfRect = [self frame];
    CGFloat centerX = selfRect.size.width / 2;
    CGFloat centerY = selfRect.size.height / 2;
    CGFloat graphLength = centerY * GRAPH_LENGTH;
    CGFloat titleLenght = centerY * (GRAPH_LENGTH + 0.05f);
    CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
    UIColor *textColor = [UIColor blackColor]; 
    [textColor set];
    int i = 0;
    int drawAng;
    while(i < 10){
        drawAng = 18 + i * 36;

        CGContextMoveToPoint(context, centerX, centerY);  // 始点
        CGFloat tagetX = centerX + (graphLength * cos(SITA(drawAng)));
        CGFloat tagetY = centerY + (graphLength * sin(SITA(drawAng)));
        CGContextAddLineToPoint(context, tagetX,tagetY);  // 終点
        NSString *tagetName = [[NSString alloc]init];
        switch (i) {
            case HEIGHT_CHART:
                tagetName = @"身長";
                break;
            case WEIGHT_CHART:
                tagetName = @"体重";
                break;
            case TOPBREAST_CHART:
                tagetName = @"トップバスト";
                break;
            case UNDERBREAST_CHART:
                tagetName = @"アンダーバスト";
                break;
            case WAIST_CHART:
                tagetName = @"ウエスト";
                break;
            case HIP_CHART:
                tagetName = @"ヒップ周り";
                break;
            case THIGH_CHART:
                tagetName = @"太もも";
                break;
            case HIPHEIGHT_CHART:
                tagetName = @"ヒップ高";
                break;
            case WAISTHEIGHT_CHART:
                tagetName = @"ウエスト高";
                break;
            case TOPBREASTHEIGHT_CHART:
                tagetName = @"トップバスト高";
                break;
            default:
                tagetName = @"";
        }
        stringFont = [UIFont systemFontOfSize:8];
        tagetX = centerX + (titleLenght * cos(SITA(drawAng)));
        tagetY = centerY + (titleLenght * sin(SITA(drawAng)));
        [tagetName drawAtPoint:CGPointMake((tagetX - [tagetName length] * (stringFont.pointSize / 2)),
                                           (tagetY - (stringFont.pointSize / 2))) withFont:stringFont];
        CGContextStrokePath(context);  

        i++;
    }
}

-(void) DrawSize:(CGContextRef)context
        sizeInfo:(sizeInfo*)sizeInfo
           taget:(NSInteger)taget
{

    // 線のサイズの指定
    CGContextSetLineWidth(context, 2.5f);
    
    CGRect selfRect = [self frame];
    CGFloat centerX = selfRect.size.width / 2;
    CGFloat centerY = selfRect.size.height / 2;
    CGFloat graphLength = centerY * GRAPH_LENGTH * 0.98f;
    CGFloat baseSpace = graphLength * 0.15f;    //最低値　中央で点にならないよう
    int i = 0;
    int drawAng;
    BOOL didStart = NO;
    CGPoint beforPoint = CGPointMake(centerX, centerY);
    CGPoint startPoint = CGPointMake(centerX, centerY);
    //UIColor *textColor = [UIColor blackColor]; 
    switch (taget) {
        case NOWSIZE_CHART:
            CGContextSetRGBStrokeColor(context, 0, 1, 0, 0.75f);
            //textColor = [UIColor greenColor];
            break;
        case SETSIZE_CHART:
            CGContextSetRGBStrokeColor(context, 1, 0, 0, 0.5f);
            //textColor = [UIColor redColor];
            break;
        case IDEALSIZE_CHART:
            CGContextSetRGBStrokeColor(context, 0, 1, 1, 0.5f);
            //textColor = [UIColor cyanColor];
            break;
    }
    while(i < 10){
        drawAng = 18 + i * 36;
        CGFloat sizeNum = 0;
        CGFloat sizeScale = 0;
        switch (i) {
            case HEIGHT_CHART:
                sizeNum = sizeInfo.Height;
                sizeScale = 1.00f;
                break;
            case WEIGHT_CHART:
                sizeNum = sizeInfo.Weight;
                sizeScale = 0.90f;
                break;
            case TOPBREAST_CHART:
                sizeNum = sizeInfo.TopBreast;
                sizeScale = 0.53f;
                break;
            case UNDERBREAST_CHART:
                sizeNum = sizeInfo.UnderBreast;
                sizeScale = 0.43f;
                break;
            case WAIST_CHART:
                sizeNum = sizeInfo.Waist;
                sizeScale = 0.37f;
                break;
            case HIP_CHART:
                sizeNum = sizeInfo.Hip;
                sizeScale = 0.55f;
                break;
            case THIGH_CHART:
                sizeNum = sizeInfo.Thigh;
                sizeScale = 0.31f;
                break;
            case HIPHEIGHT_CHART:
                sizeNum = sizeInfo.HipHeight;
                sizeScale = 0.52f;
                break;
            case WAISTHEIGHT_CHART:
                sizeNum = sizeInfo.WaistHeight;
                sizeScale = 0.60f;
                break;
            case TOPBREASTHEIGHT_CHART:
                sizeNum = sizeInfo.TopBreastHeight;
                sizeScale = 0.72f;
                break;
            default:
                sizeNum = 0;
        }
        CGFloat setNum = 0;
        CGFloat tagetX = centerX;
        CGFloat tagetY = centerY;
        if (sizeNum != 0) {
            //最低値の分を引く
            //値のMAX値からの割合を求める
            //2016/4/12 TMS サイズ上下限対応
            sizeNum = [[NSString stringWithFormat:@"%3.1f",sizeNum] floatValue];
            if (i == WEIGHT_CHART){
                setNum = sizeNum - (0 * sizeScale);
            }else{
                setNum = sizeNum - (100 * sizeScale);
            }
            if (setNum > 0) {
                setNum = setNum / (150 * sizeScale);
            }else {
                setNum = 0;

            }
            //グラフの長さに割合をかけてグラフの位置を求める。
            setNum = (setNum * (graphLength - baseSpace)) + baseSpace;
            tagetX = centerX + (setNum * cos(SITA(drawAng)));
            tagetY = centerY + (setNum * sin(SITA(drawAng)));
        }
        if (!didStart) {
            startPoint = CGPointMake(tagetX, tagetY);
            beforPoint = CGPointMake(tagetX, tagetY);
            
            didStart = YES;
        }else {
            CGContextMoveToPoint(context, beforPoint.x, beforPoint.y);
            CGContextAddLineToPoint(context, tagetX,tagetY);
            beforPoint = CGPointMake(tagetX, tagetY);

        }
        CGContextStrokePath(context);
        CGContextStrokeEllipseInRect(context, CGRectMake(tagetX - 2, tagetY -2, 4, 4));
        /*
        [textColor set];
        [[NSString stringWithFormat:@"%3.1f",sizeNum]
         drawAtPoint:CGPointMake(beforPoint.x,beforPoint.y) withFont:stringFont];
         */

        i++;
    }
    CGContextMoveToPoint(context, beforPoint.x, beforPoint.y);
    CGContextAddLineToPoint(context, startPoint.x,startPoint.y);
    CGContextStrokePath(context); 
}

#pragma mark -
#pragma mark OverWrite

#pragma mark -
#pragma mark drawRect
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    NSLog(@"DrawRect RadarChartView");
    CGContextRef context = UIGraphicsGetCurrentContext();// コンテキストを取得
    
    // self.alpha = 0.1f;
    
    [UIView animateWithDuration:2.5f
                     animations:^{
                         NSLog(@"Draw Graph");
                         [self DrawRadarBack:context];// レーダー表
                         if (nowSizeShow) {
                             NSLog(@"NowSize");
                             [self DrawSize:context sizeInfo:nowSize taget:NOWSIZE_CHART];
                         }
                         if (setSizeShow) {
                             NSLog(@"SetSize");
                             [self DrawSize:context sizeInfo:setSize taget:SETSIZE_CHART];
                         }
                         if (idealSizeShow) {
                             NSLog(@"IdealSize");
                             [self DrawSize:context sizeInfo:idealSize taget:IDEALSIZE_CHART];
                         }
                     }
                     completion:^(BOOL finished){
                         // self.alpha = 1.0f;
                         
                         // フラッシュする
                         // [Common flashViewWindowWithParentView:nil flashView:self];
                     }];
}


@end
