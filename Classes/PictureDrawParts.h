//
//  PictureDrawParts.h
//  iPadCamera
//
//  Created by 聡史 伊藤 on 12/07/04.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum {
    PAINT_COLOR_CLEAR           = NSIntegerMax,
    
    PAINT_COLOR_RED             = 1,
    PAINT_COLOR_YERROW          = 2,
    PAINT_COLOR_BLUE            = 3,
    //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
    PAINT_COLOR_WHITE           = 4,
    PAINT_COLOR_BEIGE           = 5,
    PAINT_COLOR_BLACK           = 6,
    
}PAINT_PARTS_COLOR;

typedef enum {
    PAINT_DRAW_TYPE_INIT        = 0x0100,       // 初期値
    PAINT_DRAW_TYPE_LINE        = 0x0101,       // 直線
    PAINT_DRAW_TYPE_FREESTROKE  = 0x0102,       // スプライン（描画、削除）
    PAINT_DRAW_TYPE_STRINGS     = 0x0103,       // 文字
    PAINT_DRAW_TYPE_ELLIPSE     = 0x0104,       // 楕円
    PAINT_DRAW_TYPE_ALL_CLEAR   = 0x1000,       // 全消去
    PAINT_DRAW_TYPE_VOID,
}PAINT_DRAW_TYPE;

@interface PictureDrawParts : NSObject{
    NSInteger           paintColor;     //  ペンの色定数
    NSInteger           widthNo;        //  太さ定数
    
    UIColor*            penColor;		//	ペンの色
    CGFloat             penWidth;		//	ペンの幅
    
    NSMutableArray*     lines;          //  線分リスト
    
    NSString*           drawString;     //  文字挿入の際の値
    CGPoint             setPoint;       //  文字列描画の再のポイント
}
@property(nonatomic)        PAINT_DRAW_TYPE     paintDrawType;

@property(nonatomic)        NSInteger           paintColor;
@property(nonatomic)        NSInteger           widthNo;

@property(nonatomic,retain) UIColor*            penColor;
@property(nonatomic)        CGFloat             penWidth;
@property(nonatomic,retain) NSMutableArray*     lines;

@property(nonatomic,retain) NSString*           drawString;
@property(nonatomic)        CGPoint             setPoint;
@property(nonatomic)        CGSize              rectSize;               //文字範囲
@property(nonatomic)        BOOL                thisSelect;
@property(nonatomic)        BOOL                selectStartPoint;       //先頭を選択:YES 末尾を選択:NO
@property(nonatomic)        BOOL                selectLineRect;         //線分全体を選択
@property(nonatomic)        CGRect              rectSelectObject;
@property(nonatomic)        BOOL                moveWait;               //選択されたが移動がまだ。

// 線分の新規作成
- (id)initWithLine:(CGPoint)startPoint
          endPoint:(CGPoint)endPoint
             color:(NSInteger)color
             width:(NSInteger)width;
// 楕円の新規作成
- (id)initWithEllipse:(CGPoint)startPoint
             endPoint:(CGPoint)endPoint
                color:(NSInteger)color
                width:(NSInteger)width;

// 文字ラベルの新規作成
- (id)initWithString:(NSString*)labelName
           drawPoint:(CGPoint)setPos
               color:(NSInteger)color
               width:(NSInteger)size;
// 全消去の新規作成
- (id)initAllClearObject;
// 何もしないオブジェクト
- (id)initVoidObject;

- (void)drawObject:(CGContextRef)context contextSize:(CGSize)size;
- (void)drawNewObject:(CGContextRef)context;

//開始地点を指定して線分挿入
- (void)addLine:(CGPoint)startPont
       endPoint:(CGPoint)endPoint;

//前回入力情報を元に線分挿入
- (void)apendLine:(CGPoint)endPoint;

//自分をタッチしているかの判定（現在文字列専用）
-(BOOL)thisTouch:(CGPoint)point
            mode:(NSInteger)mode;

//移動
-(void)movePoint:(CGPoint)point;

@end

@interface PictureLine : NSObject{
    CGPoint startPoint;
    CGPoint endPoint;
}
@property (nonatomic)       CGPoint startPoint;
@property (nonatomic)       CGPoint endPoint;

- (id)initWithPoints:(CGPoint)newStartPont
            endPoint:(CGPoint)newEndPoint;

@end