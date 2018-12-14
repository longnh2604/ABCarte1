//
//  RadarChartView.h
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <math.h>
#import "sizeInfo.h"

#define SITA(c)                 ((M_PI * (c)) / 180.0)
#define GRAPH_LENGTH            0.83f


// フリックボタンのタグID定義
typedef enum {
    HIPHEIGHT_CHART             = 0,         //ヒップ高
    THIGH_CHART                 = 1,        //太もも
    WEIGHT_CHART                = 2,        //体重
    HIP_CHART                   = 3,        //ヒップ周り
    WAIST_CHART                 = 4,        //ウエスト    
	UNDERBREAST_CHART           = 5,        //アンダーバスト
	TOPBREAST_CHART             = 6,        //トップバスト
	HEIGHT_CHART                = 7,        //身長
    TOPBREASTHEIGHT_CHART       = 8,        //トップバスト高
    WAISTHEIGHT_CHART           = 9,        //ウエスト高
} BODY_CHECK_RADARCHART_TAGET_ID;

typedef enum {
    NOWSIZE_CHART               = 0,        //現在値
    IDEALSIZE_CHART             = 1,        //理想値
    SETSIZE_CHART               = 2,        //着衣値
} BODY_CHECK_RADARCHART_TAGET_GROUP;

@interface RadarChartView : UIView{

    UIFont *stringFont;
    sizeInfo* nowSize;
    sizeInfo* setSize;
    sizeInfo* idealSize;
}
@property(nonatomic,retain)     sizeInfo*   nowSize;
@property(nonatomic,retain)     sizeInfo*   setSize;
@property(nonatomic,retain)     sizeInfo*   idealSize;
@property(nonatomic)            BOOL        nowSizeShow;
@property(nonatomic)            BOOL        setSizeShow;
@property(nonatomic)            BOOL        idealSizeShow;

@end
