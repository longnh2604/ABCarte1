//
//  PictureDrawParts.m
//  iPadCamera
//
//  Created by 聡史 伊藤 on 12/07/04.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PictureDrawParts.h"
#import "GlyphTable.m"
@implementation PictureDrawParts

@synthesize paintDrawType;
@synthesize paintColor;
@synthesize widthNo;
@synthesize penColor;
@synthesize penWidth;
@synthesize lines;
@synthesize drawString;
@synthesize setPoint;
@synthesize rectSize;
@synthesize thisSelect;
@synthesize selectStartPoint;
@synthesize selectLineRect;
@synthesize rectSelectObject;
@synthesize moveWait;

// 線分の新規作成
- (id)initWithLine:(CGPoint)startPoint
           endPoint:(CGPoint)endPoint
              color:(NSInteger)color
              width:(NSInteger)width{
    self = [super init];
    if (self) {
        self.paintColor = color;
        self.penWidth    = width;
        lines = [[NSMutableArray alloc]init];
        [self addLine:startPoint endPoint:endPoint];
        self.paintDrawType = PAINT_DRAW_TYPE_LINE;
        self.moveWait = NO;
        self.thisSelect = NO;
        self.selectLineRect = NO;
    }
    return self;
}
// 楕円の新規作成
- (id)initWithEllipse:(CGPoint)startPoint
          endPoint:(CGPoint)endPoint
             color:(NSInteger)color
             width:(NSInteger)width{
    self = [super init];
    if (self) {
        self.paintColor = color;
        self.penWidth    = width;
        //lines = [[NSMutableArray alloc]init];
        //[self addLine:startPoint endPoint:endPoint];
        self.paintDrawType = PAINT_DRAW_TYPE_ELLIPSE;
        self.setPoint = startPoint;
        self.rectSize = CGSizeMake(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
        //self.moveWait = NO;
        //self.thisSelect = NO;
        //self.selectLineRect = NO;
    }
    return self;
}
// 文字ラベルの新規作成
- (id)initWithString:(NSString*)labelName
           drawPoint:(CGPoint)setPos
               color:(NSInteger)color
               width:(NSInteger)size{
    self = [super init];
    if (self) {
        self.setPoint   = setPos;
        self.drawString = [[NSString alloc]initWithString:labelName];
        self.paintColor = color;
        self.penWidth   = size;
        self.paintDrawType = PAINT_DRAW_TYPE_STRINGS;
    }

    return self;
}

// 全消去の新規作成
- (id)initAllClearObject
{
    if ((self = [super init]) )
    {
        self.paintColor = PAINT_COLOR_CLEAR;
        self.paintDrawType = PAINT_DRAW_TYPE_ALL_CLEAR;
    }
    return (self);
}
// 何もしない
- (id)initVoidObject
{
    if ((self = [super init]) )
    {
        self.paintDrawType = PAINT_DRAW_TYPE_VOID;
    }
    return (self);
}
- (void)dealloc{
    if (self.paintDrawType == PAINT_DRAW_TYPE_STRINGS){ 
        [self.drawString release];
    }
    if (self.paintDrawType == PAINT_DRAW_TYPE_LINE ||self.paintDrawType ==  PAINT_DRAW_TYPE_FREESTROKE) {
        [self.lines release];
    }
    [super dealloc];
}

// 描画色の設定
- (void) setDrawColor :(CGContextRef)context
{
	CGFloat r, g, b, a;
    CGContextSetBlendMode(context, kCGBlendModeNormal);

	switch (self.paintColor) {
		case PAINT_COLOR_RED:
            // 赤色
			r = 0.8f;		// 0.502 -> 128 : 濃い赤
			g = 0.0f;	
			b = 0.0f;
			a = 1.0f;
			break;
		case PAINT_COLOR_YERROW:
            // 黄色
			r = 1.0f;
			g = 1.0f;		// 0.502 -> 128 : 濃い緑	
			b = 0.0f;
			a = 1.0f;
			break;
		case PAINT_COLOR_BLUE:
            // 青色
			r = 0.0f;
			g = 0.0f;
			b = 0.502f;		// 0.502 -> 128 : 濃い青	
			a = 1.0f;
			break;
        //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
        case PAINT_COLOR_WHITE:
            // 白色
            r = 1.0f;
            g = 1.0f;
            b = 1.0f;
            a = 1.0f;
            break;
        case PAINT_COLOR_BEIGE:
            // 肌色
            r = 1.0f;
            g = 0.89f;
            b = 0.77f;
            a = 1.0f;
            break;
        case PAINT_COLOR_BLACK:
            // 黒色
            r = 0.0f;
            g = 0.0f;
            b = 0.0f;
            a = 1.0f;
            break;

		case PAINT_COLOR_CLEAR:
            // 消しゴム:　背景色
			r = 1.0f;
			g = 1.0f;
			b = 1.0f;
			a = 0.0f;
            CGContextSetBlendMode(context, kCGBlendModeCopy);			// CGBlendModeCopy:消しゴム
			break; 
		default:
			r = 1.0f;
			g = 1.0f;
			b = 1.0f;
			a = 0.0f;
			break;
	}
	[self.penColor initWithRed:r green:g blue:b alpha:a];

    CGContextSetRGBFillColor(context,r,g,b,a);
    CGContextSetRGBStrokeColor(context,r,g,b,a);
}

// 描画幅の設定
- (void) setDrawWidth:(CGContextRef)context
{
    if (self.paintDrawType == PAINT_DRAW_TYPE_LINE || self.paintDrawType == PAINT_DRAW_TYPE_FREESTROKE) {   
        CGContextSetLineWidth(context,self.penWidth);
    }
	CGContextSetLineWidth(context,self.penWidth);

}

- (void)drawObject:(CGContextRef)context contextSize:(CGSize)size
{
    
    //描画色を決める
    [self setDrawColor:context];
    
    // 全消去の場合は、ここでcontextをクリアする
    if (self.paintDrawType == PAINT_DRAW_TYPE_ALL_CLEAR)
    {
        // Canvasを白の透明で塗りつぶす
        CGContextSetBlendMode(context, kCGBlendModeCopy);			// CGBlendModeCopy:消しゴム
        CGContextFillRect(context, 
                          CGRectMake(0, 0, size.width, size.height));
        // BlendModeを戻す
        CGContextSetBlendMode(context, kCGBlendModeDarken);
        
        return;
    }
    
    if (self.paintDrawType == PAINT_DRAW_TYPE_LINE 
        ||self.paintDrawType == PAINT_DRAW_TYPE_FREESTROKE) {
        // 線の太さを指定
        [self setDrawWidth:context];
        
        for(PictureLine* line in self.lines){
            CGContextMoveToPoint(context, line.startPoint.x , line.startPoint.y);  // 始点
            CGContextAddLineToPoint(context, line.endPoint.x   , line.endPoint.y)  ;  // 終点
            CGContextStrokePath(context); 
        }
        if(self.thisSelect == YES || self.moveWait){
            if (paintDrawType == PAINT_DRAW_TYPE_LINE) {
                if (selectLineRect || self.moveWait) {
                    //白枠で囲む
                    CGContextSetRGBStrokeColor(context, 1, 1, 1, 0.75f);
                    CGContextSetLineWidth(context, 1);
                    PictureLine* line = [lines objectAtIndex:0];
                    CGFloat rectStartPointX = (line.startPoint.x < line.endPoint.x)?line.startPoint.x:line.endPoint.x;
                    CGFloat rectStartPointY = (line.startPoint.y < line.endPoint.y)?line.startPoint.y:line.endPoint.y;
                    CGFloat rectWidth = fabs(line.startPoint.x - line.endPoint.x);
                    CGFloat rectHeight = fabs(line.startPoint.y - line.endPoint.y);
                    CGRect rectLine= CGRectMake(rectStartPointX - penWidth, rectStartPointY - penWidth
                                                , rectWidth + (penWidth * 2), rectHeight + (penWidth * 2));
                    if (moveWait) {
                        CGContextStrokeEllipseInRect(context,CGRectMake(line.startPoint.x - 10,
                                                                        line.startPoint.y - 10,
                                                                        20,
                                                                        20));
                        CGContextStrokeEllipseInRect(context,CGRectMake(line.endPoint.x - 10,
                                                                        line.endPoint.y - 10,
                                                                        20,
                                                                        20));
                    }
                    CGContextStrokeRect(context,rectLine);
                }else{
                    PictureLine* rectPointObject = [lines objectAtIndex:0];
                    CGPoint rectPoint;
                    if (self.selectStartPoint) {
                        rectPoint = rectPointObject.startPoint;
                    }else {
                        rectPoint = rectPointObject.endPoint;
                    }
                    //白枠で囲む
                    CGContextSetRGBStrokeColor(context, 1, 1, 1, 0.75f);
                    CGContextSetLineWidth(context, 1);
                    CGContextStrokeEllipseInRect(context,CGRectMake(rectPoint.x - 10,
                                                                    rectPoint.y - 10,
                                                                    20,
                                                                    20));
                }
            }else if(paintDrawType == PAINT_DRAW_TYPE_FREESTROKE){
                CGRect rectLine = [self getMaxRect];
                CGContextSetRGBStrokeColor(context, 1, 1, 1, 0.75f);
                CGContextSetLineWidth(context, 1);
                CGContextStrokeRect(context,rectLine);
            }
        }
    } else if (self.paintDrawType == PAINT_DRAW_TYPE_ELLIPSE) {
        CGContextSaveGState(context);
        // 線の太さを指定
        [self setDrawWidth:context];
        CGContextStrokeEllipseInRect(context, CGRectMake(self.setPoint.x,
                                                         self.setPoint.y,
                                                         self.rectSize.width,
                                                         self.rectSize.height));
        CGContextRestoreGState(context);
    }else{
        self.rectSize = [self.drawString sizeWithFont:[UIFont fontWithName:@"HiraKakuProN-W3" size:self.penWidth]];
        CGPoint drawPoint = CGPointMake(self.setPoint.x - (self.rectSize.width / 2)
                                        , self.setPoint.y);
        CGAffineTransform affine = CGAffineTransformMake(1.0, 0.0, 0.0, 
                                                         -1.0, 0.0, 0.0); 
        CGContextSetTextMatrix(context, affine); 
        CGFontRef HiraKakuProN = CGFontCreateWithFontName((CFStringRef)@"HiraKakuProN-W3");
        CGContextSetFont(context, HiraKakuProN);
        CGContextSetFontSize(context, self.penWidth);
        fontTable* fnttbl = readFontTableFromCGFont(HiraKakuProN);
        NSInteger originalLen = [self.drawString length];
        CGGlyph _glyphs[[self.drawString length]];
        unichar _chars[[self.drawString length]];
        int i;
        for(i = 0; i < [self.drawString length]; i++) {
            _chars[i] = [self.drawString characterAtIndex:i];
        }
        
        size_t griphLen = 0;
        mapCharactersToGlyphsInFont(fnttbl, _chars, originalLen, _glyphs, &griphLen);
        CGContextShowGlyphsAtPoint(context, drawPoint.x, drawPoint.y, _glyphs, griphLen);
        CGContextGetTextPosition(context);
        
        if(self.thisSelect == YES){
            //白枠で囲む
            CGContextSetRGBStrokeColor(context, 1, 1, 1, 0.75f);
            CGContextSetLineWidth(context, 1);
            CGContextStrokeRect(context, CGRectMake((self.setPoint.x - self.rectSize.width / 2),
                                                    self.setPoint.y - self.rectSize.height,
                                                    self.rectSize.width,
                                                    self.rectSize.height));
        }
    }
}

// 新規で線を描画
- (void)addLine:(CGPoint)startPont
       endPoint:(CGPoint)endPoint{
    PictureLine* line = [[PictureLine alloc]initWithPoints:startPont endPoint:endPoint];
    [self.lines addObject:line];
    [line release];
}

//前回の線の終点から線を描画
- (void)apendLine:(CGPoint)endPoint{
    PictureLine* lastLine = [lines lastObject];
    CGPoint startPont = lastLine.endPoint;
    PictureLine* line = [[PictureLine alloc]initWithPoints:startPont endPoint:endPoint];
    [self.lines addObject:line];
    [line release];
    self.paintDrawType = PAINT_DRAW_TYPE_FREESTROKE;
}

// 最後の線分のみ描画
- (void)drawNewObject:(CGContextRef)context
{  
    // 線の太さを指定
    [self setDrawWidth:context];
    
    //描画色を決める
    [self setDrawColor:context];
    
    if (self.paintDrawType == PAINT_DRAW_TYPE_FREESTROKE) {
        PictureLine* line = [lines lastObject]; 
        CGContextMoveToPoint(context, line.startPoint.x , line.startPoint.y);  // 始点
        CGContextAddLineToPoint(context, line.endPoint.x   , line.endPoint.y)  ;  // 終点
        CGContextStrokePath(context);
    }
}


-(BOOL)thisTouch:(CGPoint)point
            mode:(NSInteger)mode;
{
    BOOL result = NO;
    PictureLine* line;
    if (paintDrawType == PAINT_DRAW_TYPE_LINE) {
        line = [lines objectAtIndex:0];
    }
    // 文字列の枠内を求める
    if (mode == PAINT_DRAW_TYPE_STRINGS && self.paintDrawType == PAINT_DRAW_TYPE_STRINGS) {
        if(CGRectContainsPoint(CGRectMake(self.setPoint.x - self.rectSize.width / 2
                                          ,self.setPoint.y - self.rectSize.height
                                          ,self.rectSize.width,self.rectSize.height), point)){
            result = YES;
            NSLog(@"innner");
        }
        
    // 直線のタッチ判定
    }else if (mode == PAINT_DRAW_TYPE_LINE && self.paintDrawType == PAINT_DRAW_TYPE_LINE) {
        // 始点の判定
        selectLineRect = NO;
        selectStartPoint = NO;
        if(CGRectContainsPoint(CGRectMake(line.startPoint.x - 16,line.startPoint.y - 16,32,32), point)){
                result = YES;
                selectStartPoint = YES;
                NSLog(@"innner");
        }
        // 終点の判定
        if(CGRectContainsPoint(CGRectMake(line.endPoint.x - 16,line.endPoint.y - 16,32,32), point)){
            result = YES;
            selectStartPoint = NO;
            NSLog(@"innner");
        }
        // 点ではなく線がタップされた場合
        if (result == NO) {
            result = [self touchOnLine:line point:point];
        }
    }else if(mode == PAINT_DRAW_TYPE_LINE && self.paintDrawType == PAINT_DRAW_TYPE_FREESTROKE) {
        for (PictureLine* line in lines){
            if ([self touchOnLine:line point:point]){
                result = YES;
                NSLog(@"innner");
                break;
            }
        }
    }
    NSLog(@"touch");
    self.thisSelect = result;
    return  result;
}

// フリーストローク線の最大範囲を求める
- (CGRect)getMaxRect{
    CGRect maxRect;
    CGFloat xtop = INT_MAX;
    CGFloat xunder = 0;
    CGFloat ytop = INT_MAX;
    CGFloat yunder = 0;
    for (PictureLine* line in lines) {
        if(xtop > line.startPoint.x){
            xtop = line.startPoint.x;
        }
        if(xunder < line.startPoint.x){
            xunder = line.startPoint.x;
        }
        if(ytop > line.startPoint.y){
            ytop = line.startPoint.y;
        }
        if(yunder < line.startPoint.y){
            yunder = line.startPoint.y;
        }
        
        if(xtop > line.endPoint.x){
            xtop = line.endPoint.x;
        }
        if(xunder < line.endPoint.x){
            xunder = line.endPoint.x;
        }
        if(ytop > line.endPoint.y){
            ytop = line.endPoint.y;
        }
        if(yunder < line.endPoint.y){
            yunder = line.endPoint.y;
        }
    }
    maxRect = CGRectMake(xtop - (penWidth),
                         ytop - (penWidth),
                         xunder - xtop + (penWidth * 2),
                         yunder - ytop + (penWidth * 2));
    return maxRect;
}

- (BOOL)touchOnLine:(PictureLine*)line point:(CGPoint)point{
    BOOL result = NO;
    
    CGFloat rectStartPointX = (line.startPoint.x < line.endPoint.x)?line.startPoint.x:line.endPoint.x;
    CGFloat rectStartPointY = (line.startPoint.y < line.endPoint.y)?line.startPoint.y:line.endPoint.y;
    CGFloat rectWidth = fabs(line.startPoint.x - line.endPoint.x);
    CGFloat rectHeight = fabs(line.startPoint.y - line.endPoint.y);
    rectSelectObject= CGRectMake(rectStartPointX - penWidth, rectStartPointY - penWidth
                                 , rectWidth + (penWidth * 2), rectHeight + (penWidth * 2));
    if (CGRectContainsPoint(rectSelectObject, point)) {
        NSInteger lineDirection; //  ／ = NO ＼= YES
        if ((line.startPoint.x < line.endPoint.x && line.startPoint.y < line.endPoint.y) || 
            (line.endPoint.x < line.startPoint.x && line.endPoint.y < line.startPoint.y)) {
            lineDirection = 1;
            NSLog(@"＼");
        }else {
            lineDirection = -1;
            NSLog(@"／");
        }
        NSInteger j;
        CGFloat i = 0;
        CGFloat mathX = rectWidth;
        if (mathX < 1) {
            mathX = 1;
        }
        while (i < mathX) {
            if(lineDirection > 0){
                j = i * (rectHeight / mathX);
            }else {
                j = rectHeight + (i * (rectHeight / mathX) * lineDirection);
            }
            if (CGRectContainsPoint(CGRectMake(rectStartPointX + i - 16
                                               ,rectStartPointY + j - 16, 32, 32), point))
            {
                selectLineRect = YES;
                result = YES;
                moveWait = YES;
                break;
            }
            i = i + 0.1f;
        }
        
    }
    return result;
}

-(void)movePoint:(CGPoint)point{
    // 文字の移動
    if (paintDrawType == PAINT_DRAW_TYPE_STRINGS) {
        self.setPoint = CGPointMake(self.setPoint.x + point.x, self.setPoint.y + point.y);
    }else if (paintDrawType == PAINT_DRAW_TYPE_LINE) {
        // 線分頂点の移動
        moveWait = NO;
        PictureLine *newLine = [PictureLine alloc];

        PictureLine* rectPointObject = [lines objectAtIndex:0];
        CGPoint targetPoint;
        CGPoint lineStart;
        if (!selectLineRect){
            if (self.selectStartPoint) {
                targetPoint = rectPointObject.startPoint;
                lineStart = rectPointObject.endPoint;
            }else {
                lineStart = rectPointObject.startPoint;
                targetPoint = rectPointObject.endPoint;
            }
            targetPoint = CGPointMake(targetPoint.x + point.x, targetPoint.y + point.y);
            if (self.selectStartPoint) {
                newLine = [newLine initWithPoints:targetPoint endPoint:lineStart];
            }else {
                newLine = [newLine initWithPoints:lineStart endPoint:targetPoint];
            }
        }else {
            newLine = [newLine initWithPoints:CGPointMake(rectPointObject.startPoint.x + point.x,
                                                          rectPointObject.startPoint.y + point.y)
                                     endPoint:CGPointMake(rectPointObject.endPoint.x + point.x,
                                                          rectPointObject.endPoint.y + point.y)];
        }

        [lines removeAllObjects];
        [lines addObject:newLine];
        [newLine release];
    }else if(paintDrawType == PAINT_DRAW_TYPE_FREESTROKE){
        moveWait = NO;
        NSMutableArray* newLines = [NSMutableArray array];
        for (PictureLine* oldLine in lines) {
            PictureLine* newLine = [[PictureLine alloc] initWithPoints:CGPointMake(oldLine.startPoint.x + point.x,
                                                          oldLine.startPoint.y + point.y)
                                     endPoint:CGPointMake(oldLine.endPoint.x + point.x,
                                                          oldLine.endPoint.y + point.y)];
            [newLines addObject:newLine];
            [newLine release];
        }
        [lines removeAllObjects];
        [lines addObjectsFromArray:newLines];
    }
}
@end

#pragma mark -
#pragma mark localClass

@implementation PictureLine
@synthesize startPoint;
@synthesize endPoint;

- (id)initWithPoints:(CGPoint)newStartPont
             endPoint:(CGPoint)newEndPoint{
    self = [super init];
    if (self) {
        self.startPoint = newStartPont;
        self.endPoint = newEndPoint;
    }
    return self;
}

@end

