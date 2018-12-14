//
//  PicturePaintManagerView.m
//  iPadCamera
//
//  Created by MacBook on 11/03/04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PicturePaintManagerView.h"

#import "PicturePaintPalletView.h"

#import "PicturePaintViewController.h" //DELC SASAGE

#import "PictureDrawParts.h"

#import "Common.h"
#import <CoreImage/CoreImage.h>

///
/// 写真描画の管理クラス
///
@implementation PicturePaintManagerView

@synthesize scrollViewParent;
@synthesize vwSaparete;
@synthesize vwGrayOut1;
@synthesize vwGrayOut2;
@synthesize vwPallet;
@synthesize pictObjects;
@synthesize lastDrawAction;
@synthesize IsDirty;
@synthesize vwStampE;
@synthesize imgvwStamp;
@synthesize prevClearPictObj;
@synthesize brightness;
@synthesize ppvController;


#pragma mark local_methods

// Canvas（オフスクリーン）の作成
CGContextRef createCanvasContext(int width, int height)
{
	//	RGBの描画領域作成。
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(
												 NULL,		//	初期化用データ。NULLなら初期化はシステムに任せる
												 width,		//	画像横ピクセル数
												 height,		//	　　縦
												 8,			//	RGB各要素は8ビット
												 0,			//	横１ラインの画像を定義するのに必要なバイト数。0はシステムに任せる。
												 colorSpace, //	RGB色空間。
												 kCGImageAlphaPremultipliedLast);	//	RGBの後ろにアルファ値。
	//	RGBはアルファ値が適用済み。
	//	この時点で色情報は不要なので解放。
    CGColorSpaceRelease(colorSpace);
	return context;	
}

// 区分線の状態変更
- (void) changeSaparate2Draw:(BOOL)isDraw
{
	vwSaparete.hidden = isDraw;
	vwGrayOut1.hidden = isDraw;
	vwGrayOut2.hidden = isDraw;
	
	// 変更時にはviewの透明度を0にする
	vwGrayOut1.alpha = vwGrayOut2.alpha = 0.0f;
}

// 描画色の設定
- (void) setDrawColor :(NSInteger)colorNo
{
	CGFloat r, g, b, a;
	
	switch (colorNo) {
		case 1:
		// 赤色
			r = 0.8f;		// 0.502 -> 128 : 濃い赤
			g = 0.0f;	
			b = 0.0f;
			a = 1.0f;
			break;
		case 2:
		// 黄色
			r = 1.0f;
			g = 1.0f;		// 0.502 -> 128 : 濃い緑	
			b = 0.0f;
			a = 1.0f;
			break;
		case 3:
		// 青色
			r = 0.0f;
			g = 0.0f;
			b = 0.502f;		// 0.502 -> 128 : 濃い青	
			a = 1.0f;
			break;
        //2016/1/5 TMS ストア・デモ版統合対応 カルテ画像への描き込みの色を追加
        case 4:
            // 白色
            r = 1.0f;
            g = 1.0f;
            b = 1.0f;		// 0.502 -> 128 : 濃い青
            a = 1.0f;
            break;
        case 5:
            // 肌色
            r = 1.0f;
            g = 0.89f;
            b = 0.77f;		// 0.502 -> 128 : 濃い青
            a = 1.0f;
            break;
        case 6:
            // 黒色
            r = 0.0f;
            g = 0.0f;
            b = 0.0f;
            a = 1.0f;
            break;
		case ERASE_COLOR_NO:
		// 消しゴム:　背景色
			r = 1.0f;
			g = 1.0f;
			b = 1.0f;
			a = 0.0f;
			break; 
		default:
			r = 1.0f;
			g = 1.0f;
			b = 1.0f;
			a = 0.0f;
			break;
	}
	
	CGContextSetRGBFillColor(canvasContext,r,g,b,a);
    CGContextSetRGBStrokeColor(canvasContext,r,g,b,a);
}

// 描画幅の設定
- (void) setDrawWidth:(int)widthNo
{
	CGFloat lineWidth;
	switch (widthNo) 
	{
        //2016/1/5 TMS ストア・デモ版統合対応 線の太さを追加
        case 1:
            lineWidth = 1.0f;
            break;
        case 2:
            lineWidth = 4.0f;
            break;
        case 3:
            lineWidth = 6.0f;
            break;
        case 4:
            lineWidth = 10.0f;
            break;
        default:
            lineWidth = 1.0f;
            break;
	}
	
	CGContextSetLineWidth(canvasContext,lineWidth);
    
    // 描画太さをここで保存
    _lineWidth = lineWidth;
}

// 区分線の描画
- (void) drawSparateLine:(CGPoint)startPos endPosition:(CGPoint)endPos
{
	// X/Y方向差分
	CGFloat difX = fabsf(startPos.x - endPos.x);
	CGFloat difY = fabsf(startPos.y - endPos.y);
	
	// XかY方向のいずれの差分が大きいかで横か縦かを決める
	_isSparatePortraite = (difX < difY);
	if (_isSparatePortraite)
	{
	// Y方向が大きい
		// 区分線Viewを縦方向で位置設定
		[vwSaparete setFrame:
			CGRectMake((endPos.x - (SPARATE_LINE_WIDTH / 2.0f)), 0.0f,
					SPARATE_LINE_WIDTH, VIEW_HEIGHT)];
		
		// グレーアウトView1の位置設定
		[vwGrayOut1 setFrame:
			CGRectMake(0.0f, 0.0f, endPos.x, VIEW_HEIGHT)];
		// グレーアウトView2の位置設定
		[vwGrayOut2 setFrame:
			CGRectMake(endPos.x, 0.0f, (VIEW_WIDTH - endPos.x), VIEW_HEIGHT)];
		
	}
	else 
	{
	// X方向が大きい：
		// 区分線Viewを横方向で位置設定
		[vwSaparete setFrame:
			CGRectMake(0.0f, (endPos.y - (SPARATE_LINE_WIDTH / 2.0f)),
					VIEW_WIDTH, SPARATE_LINE_WIDTH)];
		
		// グレーアウトView1の位置設定
		[vwGrayOut1 setFrame:
			CGRectMake(0.0f, 0.0f, VIEW_WIDTH, endPos.y)];
		// グレーアウトView2の位置設定
		[vwGrayOut2 setFrame:
			CGRectMake(0.0f, endPos.y, VIEW_WIDTH, (VIEW_HEIGHT - endPos.y) )];
	}
}

// touch位置に応じてグレーアウトViewを設定
- (void)grayOutViewByTouchPos:(CGPoint)touchPos
{
	// _sparatePosには、区分線描画の２回目touchEndが保存されている
	
	// touch位置は１か２か？
	NSInteger touchNum;
	
	if (_isSparatePortraite)
	{
	// 区分線は縦
		touchNum = ( _sparatePos.x <= touchPos.x)? 2 : 1;
	}
	else 
	{
	// 区分線は横
		touchNum = ( _sparatePos.y <= touchPos.y)? 2 : 1;
	}
	
	// 指定したグレーアウトViewの選択設定を反転
	UIView *grayVw = (touchNum == 1)? vwGrayOut1 : vwGrayOut2;
	grayVw.alpha = (grayVw.alpha >= 0.01f)? 0.0f : GRAY_OUT_VIEW_SHOW_APLHA; 
	
}

// 再描画する範囲を求める（正規化つき）
- (CGRect) redrawRectWithStartPos:(CGPoint)startPos endPositopn:(CGPoint)endPos
{
    // 開始座標の算出
    CGFloat sX = (startPos.x <= endPos.x)? startPos.x :endPos.x;
    CGFloat sY = (startPos.y <= endPos.y)? startPos.y :endPos.y;
    
    // 開始座標を線幅分引く：負数で０に正規化する
    CGFloat x = (sX - _lineWidth);
    if (x < 0) x = 0.0f;
    CGFloat y = (sY - _lineWidth);
    if (y < 0) y = 0.0f;
    
    float width = fabsf(x - endPos.x);
    float height = fabsf(y - endPos.y);
    
    /*NSLog(@"redraw rect start %f/%f width %f/%f",
          x, y, width, height);*/
    
    return (CGRectMake(x, y, width*10.0f, height*10.0f));
}

// 直線描画
- (void)drawLine:(CGPoint)startPos endPosition:(CGPoint)endPos isWrite:(BOOL)isWrite
{
	if ((_touchMode != MODE_SPLINE) && (_touchMode != MODE_ERASE) && (_touchMode != MODE_LINE) && (_touchMode != MODE_CIRCLE))
	{
		// undoバッファの更新
		CGImageRelease(lastImage);
		lastImage = CGBitmapContextCreateImage(canvasContext);
	}
    if (_drawMode == MODE_LINE) {
        //[self drawObjects];
        CGContextSetLineWidth(canvasContext,_lineWidth);
        CGContextMoveToPoint(canvasContext, startPos.x, startPos.y);
        CGContextAddLineToPoint(canvasContext, endPos.x, endPos.y);
        //	ラインの端の処理を、丸になるよう指示する。
        CGContextSetLineCap(canvasContext, kCGLineCapRound);
        
        //2012 7/4 元の描画処理をコメントアウト
        // 描画（直線、スプライン）では水彩画のように、暗めの色が明るめの色に打ち勝つ設定
        // 消しゴムではCGBlendModeCopyで完全に置き換える。
        CGContextSetBlendMode(canvasContext,
                              (isWrite)? kCGBlendModeDarken : kCGBlendModeCopy);
        
        // 描画色の設定
        [self setDrawColor:(isWrite)? _drawColorNo : ERASE_COLOR_NO];
        
        CGContextStrokePath(canvasContext);
    } else if (_drawMode == MODE_CIRCLE) {
        CGContextSetLineWidth(canvasContext,_lineWidth);
        
        //2012 7/4 元の描画処理をコメントアウト
        // 描画（直線、スプライン）では水彩画のように、暗めの色が明るめの色に打ち勝つ設定
        // 消しゴムではCGBlendModeCopyで完全に置き換える。
        CGContextSetBlendMode(canvasContext,
                              (isWrite)? kCGBlendModeDarken : kCGBlendModeCopy);
        
        // 描画色の設定
        [self setDrawColor:(isWrite)? _drawColorNo : ERASE_COLOR_NO];
        
        CGContextStrokeEllipseInRect(canvasContext, CGRectMake(startPos.x, startPos.y,
                                                               endPos.x - startPos.x, endPos.y - startPos.y));
	} else {
        //2012 7/4 伊藤 前回の線分の終点から新しい線分を延ばす
        PictureDrawParts* pict = [pictObjects lastObject];
        [pict apendLine:endPos];
        [pict drawNewObject:canvasContext];
        //	ラインの端の処理を、丸になるよう指示する。
        CGContextSetLineCap(canvasContext, kCGLineCapRound);
    }
	// drawRect(再描画指示)
    if ((_touchMode != MODE_SPLINE) && (_touchMode != MODE_ERASE) )
    {
        // スプライン系はnew_iPad(iPad3)では描画が追いつかない
        [self setNeedsDisplay]; 
    } else {
        // スプライン系はnew_iPad(iPad3)では再描画で全範囲だと描画が追いつかないので
        // 再描画する範囲を求める（正規化つき）
#ifndef SPLINE_BAD_DRAW_FROM_VER121
        CGRect rect = [self redrawRectWithStartPos:startPos endPositopn:endPos];
        [self setNeedsDisplayInRect:rect];
#else   
        if(drawAllDispFlg > 10){
            //高速で描画すると指定範囲再描画に穴があくので
            [self setNeedsDisplay];
            drawAllDispFlg = 0;
        }
        else {
            CGRect rect = [self redrawRectWithStartPos:startPos endPositopn:endPos];
            [self setNeedsDisplayInRect:rect];
            drawAllDispFlg++;
        }

#endif
    }
    
}
//選択中のスタンプを設定 //DELC SASAGE
- (void)setSelectedStamp:(Stamp *)_stamp{
#if STAMP_MODE==1
    if (!_determinStamp) {
        [self drawStamp:NO];
    }
    _determinStamp = YES;
#else 
#if STAMP_MODE > 1
    if (!_determinStamp) {
        [self drawStampWithDots:NO];
    }
    _determinStamp = YES;
    /*
    CGImageRelease(lastImageForStamp);
    lastImageForStamp = CGBitmapContextCreateImage(canvasContext);
     */
#endif
#endif
    _drawMode = MODE_SELECT_STAMP;
    _touchMode = MODE_SELECT_STAMP;
    stamp = _stamp;
}
//スタンプを画面上に配置 //DELC SASAGE
- (void)setStamp:(Stamp *)_stamp center:(CGPoint)center{
//    [pictObjects removeAllObjects];
    _determinStamp = NO;
    hasStamp = YES;
    //スタンプを置く前の状態を記録
    CGImageRelease(lastImage);
    lastImage = CGBitmapContextCreateImage(canvasContext);
    //undo用
    CGImageRelease(lastImageForStamp);
    lastImageForStamp = CGBitmapContextCreateImage(canvasContext);
    [self setNeedsDisplay];
    
    _drawMode = MODE_STAMP;
    stamp = _stamp;
    stamp.center = center;
    stamp.size = CGSizeMake(_stamp.size.width/4, _stamp.size.height/4);
    [stamp updateImage];
#if STAMP_MODE == 1
    [self drawStamp:YES];
    //[self drawStamp:NO];  //0320
#else
    [self drawStampWithDots:YES];
#endif
//    PicturePaintViewController *ppvc = [self viewController];
//    [ppvc setStampsUnselected];
    [vwPallet setStampsUnselected];
    self.IsDirty = YES;
    [self setLastModifiedPaintManager];
}
//- (PicturePaintViewController*)viewController
//{
//    for (UIView* next = [self superview]; next; next = next.superview)
//    {
//        UIResponder* nextResponder = [next nextResponder];
//        
//        if ([nextResponder isKindOfClass:[PicturePaintViewController class]])
//        {
//            return (PicturePaintViewController*)nextResponder;
//        }
//    }
//    
//    return nil;
//}
// 元に戻す
- (void) undoPaint
{
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
    /*
	CGContextDrawImage(canvasContext, self.bounds, lastImage);
	CGImageRelease(lastImage);
     */
    CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
    CGContextDrawImage(canvasContext, self.bounds, lastImage);
#ifdef DEBUG
    NSLog(@"[type : %d]", self.lastDrawAction.paintDrawType);
#endif
    if (self.lastDrawAction.paintDrawType != PAINT_DRAW_TYPE_VOID) {
        if(setUndo){
            if (self.lastDrawAction)
            {
                [pictObjects addObject:self.lastDrawAction];
            }
            setUndo = NO;
        }else {
            if([pictObjects count] > 0){
                // 直線描画前に戻す
                self.lastDrawAction = [pictObjects lastObject];
                [pictObjects removeLastObject];
                setUndo = YES;
                if (preHasStamp) {
                    [self drawObjects:YES];
                }
            }
#if 1 // 不具合対応 kikuta - start - 2014/01/30 -
           else
            {
                if (self.prevClearPictObj) { // prevClearPictObjが存在するときのみ
                    [pictObjects addObject:self.prevClearPictObj];
                    self.lastDrawAction = [pictObjects lastObject];
                    self.prevClearPictObj = nil;
                }
                else if(!hasStamp) // 線オブジェクトがないときはスタンプが有るものとする(暫定)
                    hasStamp = YES;
            }
#endif // 不具合対応 kikuta - end - 2014/01/30 -
        }
        [self drawObjects:NO];
    } else{
        [self drawObjects:YES];
    }
    [self setNeedsDisplay];
    
    if (self.lastDrawAction)
    {
        // undo（またはredo）の対象が全消去であれば編集フラグをクリアする
        self.IsDirty
        = (self.lastDrawAction.paintDrawType != PALLET_ALL_CLEAR);
    } else {
        // 初期に戻った場合も編集フラグはクリア
        if([pictObjects count] <= 0){
            self.IsDirty = NO;
        }
    }
}

// 全消去
- (void) _allClear
{
    // 全消去できるかを確認する
    PictureDrawParts* lastOprObj = nil;
    if ([pictObjects count] > 0) 
    {
        lastOprObj = [pictObjects objectAtIndex:([pictObjects count] - 1)];
    }
    if ( ((! lastOprObj) ||
         ((lastOprObj) && (lastOprObj.paintDrawType == PAINT_DRAW_TYPE_ALL_CLEAR)))
        && !hasStamp )
    {
        [Common showDialogWithTitle:@"" 
                            message:@"描画していないので\n全消去はできません。"];
        return;
    }
    
    //スタンプを置く前の状態を記録
    CGImageRelease(lastImage);
    lastImage = CGBitmapContextCreateImage(canvasContext);
//    CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
//    CGContextDrawImage(canvasContext, self.bounds, lastImage);
    
    [self allClearCanvas];
    /* * DELC SASAGE この記述はいらない？
    PictureDrawParts* pictObj = [[PictureDrawParts alloc]initAllClearObject];
    [pictObjects addObject:pictObj];
    [pictObj release];
    * */

#if 1 // 不具合対応 kikuta - start - 2014/01/30 -
    // クリア前の状態を保存しておく
    [self setPrevClearPictObj:lastOprObj];
#endif // 不具合対応 kikuta - end - 2014/01/30 -
    
    [pictObjects removeAllObjects]; //DELC SASAGE
    setUndo = NO;       // undoにする（objectリストより取り出す）
    _determinStamp = YES;
    _drawMode = MODE_VOID;
    preHasStamp = hasStamp;
    hasStamp = NO;

    // 編集フラグをここでクリア
    self.IsDirty = NO;
}
// Viewに２つのPicturePaintManagerViewがあるとき
// 全消去はできないとき、NOを返す
- (BOOL) allClear
{
    // 全消去できるかを確認する
    PictureDrawParts* lastOprObj = nil;
    if ([pictObjects count] > 0)
    {
        lastOprObj = [pictObjects objectAtIndex:([pictObjects count] - 1)];
    }
    if ( ((! lastOprObj) ||
          ((lastOprObj) && (lastOprObj.paintDrawType == PAINT_DRAW_TYPE_ALL_CLEAR)))
        && !hasStamp )
    {
        //[Common showDialogWithTitle:@""
        //                    message:@"描画していないので\n全消去はできません。"];
        return NO;
    }
    
    //スタンプを置く前の状態を記録
    CGImageRelease(lastImage);
    lastImage = CGBitmapContextCreateImage(canvasContext);
    
    [self allClearCanvas];
    [pictObjects removeAllObjects]; //DELC SASAGE
    setUndo = NO;       // undoにする（objectリストより取り出す）
    _determinStamp = YES;
    _drawMode = MODE_VOID;
    
    // 編集フラグをここでクリア
    self.IsDirty = NO;
    return YES;
}
#pragma mark UIAlertViewDelegate

#ifdef PICTURE_ALL_CLEAR_ALERT
// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
/*
	// 合成画像保存確認の場合
	if (alertView == modifyCheckAlert)
	{
        NSLog(@"alert no");
	} else {
        NSLog(@"alert yes");
    }
*/
    // 押されたボタンを保存
    _modifyCheckAlertWait = buttonIndex;

	// alertの表示を消す
	[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
}
#endif

#pragma mark life_cycle

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}

// InterfaceBuilderからの初期化
- (void)awakeFromNib
{
    [self initAfterFrameSet];
}
- (void)initAfterFrameSet {
    // 初期状態は非表示
	// self.hidden = YES;
    CGImageRelease(lastImage);
    CGImageRelease(lastImageForLine);
    CGImageRelease(lastImageForCircle);
    CGImageRelease(lastImageForStamp);
	CGContextRelease(canvasContext);
	// Canvas（オフスクリーン）の作成
	canvasContext = createCanvasContext(self.bounds.size.width, self.bounds.size.height);
	// Canvasを白の透明で塗りつぶす
	CGContextSetRGBFillColor(canvasContext, 1.0f, 1.0f, 1.0f, 0.0f);
	CGContextFillRect(canvasContext,
					  CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
	// undo用imageの初期化
	lastImage = CGBitmapContextCreateImage(canvasContext);
	lastImageForLine = CGBitmapContextCreateImage(canvasContext);
	lastImageForCircle = CGBitmapContextCreateImage(canvasContext);
    lastImageForStamp = CGBitmapContextCreateImage(canvasContext); //DELC SASAGE
	
	// 複数タッチのサポート
	self.multipleTouchEnabled = YES;
    
	// 管理モードを指が放された状態から始める
	_touchMode = MODE_RELEASED;
	// 描画モードを機能しないで始める
	_drawMode = MODE_VOID;
	
	_isLineFirstTouch = NO;
	
	// 線色と線幅の初期化
	// [self setDrawColor:1];
	_drawColorNo = 1;
	[self setDrawWidth:1];
    
    //2012 7/4 線分リスト初期化
    pictObjects = [[NSMutableArray alloc]init];
    self.lastDrawAction = [[PictureDrawParts alloc]init];
    //スタンプの確定状態の初期化
    _determinStamp = YES;
    _twiceStampTouch = NO;
    hasStamp = NO;
    //タッチ処理の初期化
    preStamp = [[Stamp alloc] init];
#if STAMP_MODE == 1
    touchM = [[TouchManager alloc] init];
#else
    stampMode = STAMP_MOVE;
    resize = CGPointZero;
    offset = CGPointZero;
#endif
    self.IsDrawenable = YES;
}
// 上下比較の際、キャンパスをリサイズする
- (void)resizeFrame : (BOOL)isUpdown{
    CGImageRelease(lastImage);
    CGImageRelease(lastImageForLine);
    CGImageRelease(lastImageForCircle);
    CGImageRelease(lastImageForStamp);
    CGContextRelease(canvasContext);
    
    if (isUpdown){
        [self setFrame:CGRectMake(0, 0, 728.0f, 696.0f)];
        [vwStampE setFrame:CGRectMake(vwStampE.frame.origin.x, vwStampE.frame.origin.y, vwStampE.frame.size.width, 696.0f)];
    }else{
        [self setFrame:CGRectMake(0, 0, 728.0f, 546.0f)];
        [vwStampE setFrame:CGRectMake(vwStampE.frame.origin.x, vwStampE.frame.origin.y, vwStampE.frame.size.width, 546.0f)];
    }
    // Canvas（オフスクリーン）の作成
    canvasContext = createCanvasContext(self.bounds.size.width, self.bounds.size.height);
    // Canvasを白の透明で塗りつぶす
    CGContextSetRGBFillColor(canvasContext, 1.0f, 1.0f, 1.0f, 0.0f);
    CGContextFillRect(canvasContext,
                      CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
    // undo用imageの初期化
    lastImage = CGBitmapContextCreateImage(canvasContext);
    lastImageForLine = CGBitmapContextCreateImage(canvasContext);
    lastImageForCircle = CGBitmapContextCreateImage(canvasContext);
    lastImageForStamp = CGBitmapContextCreateImage(canvasContext); //DELC SASAGE
    
    [self setDrawWidth:1];
    
}

- (void) initLocal {

    // 移動中のスタンプを表示する為のビューを追加した
    vwStampEdit = [[UIImageView alloc] init];

    vwStampE.alpha = 1.0f;
    vwStampE.userInteractionEnabled = NO;
    vwStampE.clipsToBounds = YES;
    vwStampE.opaque = NO;
    vwStampE.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    
    stampMoveFirst = YES;

    [self.vwStampE addSubview:vwStampEdit];
    
    self.brightness = 0;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code.
	
	CGContextRef context = UIGraphicsGetCurrentContext() ;
	CGImageRef imgRef = CGBitmapContextCreateImage(canvasContext);
	CGRect r = self.bounds;
	CGContextDrawImage(context, CGRectMake(0, 0, r.size.width, r.size.height), imgRef);
	CGImageRelease(imgRef);
    
    //CIImage *ciimage = [[CIImage alloc] ini]
    
//    NSLog(@"drawRect start    %f/%f width %f/%f",
//          rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}
// 輝度の調整
// http://dev.eyewhale.com/archives/367
+(CGImageRef)adjustImage:(CGImageRef)imageRef brightness:(float)brightness
{
    brightness = MAX(brightness, -1.0);
    brightness = MIN(brightness, 1.0);
    
    // UIImageをCIImageに変換
    
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:imageRef];
    
    // フィルタの作成
    CIFilter *ciFilter = [CIFilter filterWithName:@"CIColorControls"
                                    keysAndValues:kCIInputImageKey, ciImage,
                          @"inputBrightness", [NSNumber numberWithFloat:brightness]
                          ,nil];
    // 結果画像の取り出し
    CIImage* filterdImage = [ciFilter outputImage];
    
    
    // CIImageからUIImageに変換
    CIContext *ciContext = [CIContext contextWithOptions:nil];
    CGImageRef imgRef = [ciContext createCGImage:filterdImage fromRect:[filterdImage extent]];
    
    [ciImage release];

    return imgRef;
}
- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif

	CGImageRelease(lastImage);
	CGImageRelease(lastImageForLine);
	CGImageRelease(lastImageForCircle);
    CGImageRelease(lastImageForStamp); //DELC SASAGE

	CGContextRelease(canvasContext);	//	解放

    [scrollViewParent release];			// 親スクロールビュー
    [vwSaparete release];				// 区分線
    [vwGrayOut1 release];				// グレイアウトView-1
    [vwGrayOut2 release];				// グレイアウトView-2
    [vwStampE release];
    [vwStampEdit removeFromSuperview];
    [vwStampEdit release];               // エディット中スタンプ
    [imgvwStamp release];
    [pickTouch release];		//	touchesBeganで保存する起点座標を持つUITouchインスタンス。
    [penColor release];		//	ペンの色
    [stamp release];                               //現在編集状態のスタンプ
    stamp = nil;
    [movestamp release];                           //現在編集状態のスタンプ
    [preStamp release];                            //スタンプの拡大縮小などをする前の状態
    [prevClearPictObj release];         // クリアする前のオブジェクト
    [touchM release];                       //タッチを管理する
    touchM = nil;

    //2012 7/4 伊藤
    [pictObjects removeAllObjects];
    [pictObjects release];

    [lastDrawAction release];
    
    vwPallet.delegate = nil;
    [vwPallet release];

    [super dealloc];
}

#pragma mark touch_events

// タッチ開始
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
	// 描画不可なら何もしない
    if (!self.IsDrawenable) {
        [Common showDialogWithTitle:@"描画できません" message:@"再生位置が描画範囲外に設定されています。再生位置を調整して下さい。"];
        return;
    }
	// 指が放されていなければ何もしない //スタンプはマルチタッチを認識する必要 DELC SASAGE
	if (_touchMode != MODE_RELEASED && _touchMode != MODE_STAMP && _touchMode != MODE_SELECT_STAMP)
	{	return; }
	
	_touchMode = MODE_WAITING_JUDGE;
	pickTouch = [touches anyObject];
	pickPos = [pickTouch locationInView:pickTouch.window];	//	自分のviewはスケーリングされるので、判定用には使えない。
	
	//if ( !((_drawMode == MODE_SPARATE_DRAW) || (_drawMode == MODE_LINE) 
	//										|| (_drawMode == MODE_SPARATE) ) )
	if ( !((_drawMode == MODE_SPARATE_DRAW) || (_drawMode == MODE_SPARATE)) )
	{
		// 区分線描画以外は線、描画用に起点座標を保存
		// 区分線（グレイアウト）の場合は、区分線描画の２回目touchEndが保存されている
		lineStartPos = [pickTouch locationInView:self];
	}
	
	// ライン描画時は描画開始時点のコンテキスト内容を保存しておく
	if (_drawMode == MODE_LINE)
	{
        //2012 7/4 伊藤 背景画像は常に初期の物を使用するためコメントアウト
		CGImageRelease(lastImageForLine);
		lastImageForLine = CGBitmapContextCreateImage(canvasContext);
		CGImageRelease(lastImage);
		lastImage = CGBitmapContextCreateImage(canvasContext);
		
        [self drawObjects:NO];
		_touchMoveCount4Line = 0;
	}
    // 円描画時は描画開始時点のコンテキスト内容を保存しておく
	if (_drawMode == MODE_CIRCLE)
	{
		CGImageRelease(lastImageForCircle);
		lastImageForCircle = CGBitmapContextCreateImage(canvasContext);
		CGImageRelease(lastImage);
		lastImage = CGBitmapContextCreateImage(canvasContext);
		
        [self drawObjects:NO];
		_touchMoveCount4Line = 0;
	}
    if (_drawMode == MODE_CHARA) {
        /*

        //ポップアップを開く
        if (PopupCharacterInsert)
        {
            [PopupCharacterInsert release];
            PopupCharacterInsert = nil;
        }
        // 文字編集のViewControllerのインスタンス生成
        CharacterInsertPopup *vcCharaInsert 
        = [[CharacterInsertPopup alloc]initCharacterInsertWithPictList:pictObjects
                                                                 color:(NSInteger)_drawColorNo
                                                         canvasContext:canvasContext
                                                            targetView:self
                                                              position:[pickTouch locationInView:self]
                                                               popUpID:0
                                                              callBack:self];        
        // ポップアップViewの表示
        PopupCharacterInsert = 
        [[UIPopoverController alloc] initWithContentViewController:vcCharaInsert];
        vcCharaInsert.popoverController = PopupCharacterInsert;
        [PopupCharacterInsert presentPopoverFromRect:CGRectMake(pickPos.x, pickPos.y, 0, 0)
                                             inView:self
                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                           animated:YES];
        
        //2012 6/25 伊藤 画面外をタップしてもポップアップが閉じないようにする処理
        NSMutableArray *viewCof = [[NSMutableArray alloc]init];
        [viewCof addObject:self];
        
        PopupCharacterInsert.passthroughViews = viewCof;
        [viewCof release];
        
        [vcCharaInsert release];
        */

    }
    if(_drawMode == MODE_SPLINE ){
        [self addLine:lineStartPos endPos:lineStartPos isWrite:YES];
        drawAllDispFlg = 0;
    }else if(_drawMode == MODE_ERASE){
        [self addLine:lineStartPos endPos:lineStartPos isWrite:NO];
    }
    //DELC SASAGE
    if (_drawMode == MODE_SELECT_STAMP) {
        [self beganStampSelect:touches event:event];
    } else if (_drawMode == MODE_STAMP){
        [self beganStamp:touches event:event];
    } else{
        //MODE_STAMPではない状態でタッチされた時に、確定する
        _determinStamp = YES;
    }
	NSUInteger c = [[event allTouches] count];			//	現在追跡中のタッチイベントの数が、触れている指の数。
	if (c >= 2 && _drawMode != MODE_STAMP) {			//	ここで判定しないとピンチが取りこぼされるときがある。//DELC SASAGE
		_touchMode = MODE_VOID;
	}
	if (_touchMode != MODE_VOID) {
		[scrollViewParent setCanCancelContentTouches:NO];		//	UIScrollViewに取られないようにする。
	}
	
    // self.clipsToBounds = YES;
}

- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    
}
// ドラッグ中：
// 最初のタッチ位置からある程度（DRAG_THRESHOLD）動かない限り、ドラッグを開始しない。
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event 
{
	// NSLog(@"touchesMoved");
	
	UITouch *touch = nil;
	if (pickTouch) {
		touch = [touches member:pickTouch];
	}
	if (touch == nil) {										//	対象の指は動いていない。
		return;
	}
	
	if (_touchMode == MODE_WAITING_JUDGE) {						//	判定待ち
		// printf("mode == mode_WaitingJudge\n");
		CGPoint pos = [touch locationInView:touch.window];	//	自分のviewはスケーリングされるので、判定用には使えない。
		if ((fabs(pickPos.x - pos.x) > 2) || (fabs(pickPos.y - pos.y) > 2)) {
			//	判定する。
            if (_drawMode == MODE_STAMP) {
                CGImageRelease(lastImageForStamp);
                lastImageForStamp = CGBitmapContextCreateImage(canvasContext);
            }
			NSUInteger c = [[event allTouches] count];				//	現在追跡中のタッチイベントの数が、触れている指の数。
			if (c == 1|| _drawMode == MODE_STAMP){ //スタンプのときはUIScrollViewを使わせない。
				_touchMode = _drawMode;
			}
			else {
				_touchMode = MODE_VOID;
				[scrollViewParent setCanCancelContentTouches:YES];	//	UIScrollViewにまかせる。
			}
#ifdef DEBUG
			NSLog(@"_touchMode=%d", _touchMode);
#endif
		}
		if ((_touchMode == MODE_SPLINE) || (_touchMode == MODE_ERASE) || (_touchMode == MODE_LINE) )
		{
			CGImageRelease(lastImageForLine);
			lastImageForLine = CGBitmapContextCreateImage(canvasContext);
            CGImageRelease(lastImage);
            lastImage = CGBitmapContextCreateImage(canvasContext);
		}
        // 一応
		if (_touchMode == MODE_CIRCLE )
		{
			CGImageRelease(lastImageForCircle);
			lastImageForCircle = CGBitmapContextCreateImage(canvasContext);
            CGImageRelease(lastImage);
            lastImage = CGBitmapContextCreateImage(canvasContext);
		}
	}
	
	if ((_touchMode == MODE_SPLINE) || (_touchMode == MODE_ERASE)) {
		
		// 終端座標
		CGPoint lineEndPos = [touch locationInView:self];
		
		/*NSLog (@"touchesMoved: start_x:%f/start_y:%f  end_x:%f /end_y:%f",
			   lineStartPos.x, lineStartPos.y, lineEndPos.x, lineEndPos.y);*/
		
		// スプライン（連続直線）、消しゴムで描画
		[self drawLine:lineStartPos endPosition:lineEndPos isWrite:(_touchMode == MODE_SPLINE)];
		
		// 開始座標（位置）を置き換え
		lineStartPos = lineEndPos;
		
		// 編集フラグをここで設定
		self.IsDirty = YES;
        [self setLastModifiedPaintManager];
	}
	else if(_touchMode == MODE_LINE)
	{
		// if ( (++_touchMoveCount4Line) % 1 == 0)
		{
			// NSLog(@"touchMoveCount4Line start.");
				
			// 直線描画前に戻す
			CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
			CGContextDrawImage(canvasContext, self.bounds, lastImageForLine);
			CGContextDrawImage(canvasContext, self.bounds, lastImage);
			// 直線描画
			CGPoint lineEndPos = [touch locationInView:self];
			[self drawLine:lineStartPos endPosition:lineEndPos isWrite:YES];
			
			// NSLog(@"touchMoveCount4Line done.");
			
			// 編集フラグをここで設定
			self.IsDirty = YES;
            [self setLastModifiedPaintManager];
		}
	} else if (_touchMode == MODE_CIRCLE) {
        // 円描画前に戻す
        CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
        CGContextDrawImage(canvasContext, self.bounds, lastImageForCircle);
        CGContextDrawImage(canvasContext, self.bounds, lastImage);
        // 直線描画
        CGPoint lineEndPos = [touch locationInView:self];
        [self drawLine:lineStartPos endPosition:lineEndPos isWrite:YES];
        
        // 編集フラグをここで設定
        self.IsDirty = YES;
        [self setLastModifiedPaintManager];
    } else if (_touchMode == MODE_STAMP) {
        // 直線描画前に戻す
        [self moveStamp:touches event:event];
        self.IsDirty = YES;
        [self setLastModifiedPaintManager];
    }
}
// DELC SASAGE
// パレットに自分が最後に編集されたviewであることを伝える。UNDOのため
- (void)setLastModifiedPaintManager {
    if ([self.vwPallet isKindOfClass:[DoublePicturePaintPalletView class]]){
        [((DoublePicturePaintPalletView *)self.vwPallet) setLastModifiedPaintManager:self];
    }
}
// DrawModeによるタッチ終了時の処理 //withEventを追加 DELC SASAGE
- (void)touchEndByDrawMode:(NSSet*)touches withEvent:(UIEvent *)event
{
	UITouch *touch = nil;
	if (pickTouch) {
		touch = [touches member:pickTouch];
	}
	if (touch == nil && _drawMode != MODE_STAMP) {										//	対象の指は動いていない。
		return;
	}
	
	CGPoint endPos;
	
	switch (_drawMode)
	{
		case MODE_SPARATE_DRAW:
		// case MODE_LINE:
		// 区分線描画またはライン描画線
			if (! _isLineFirstTouch)
			{
				// 初回タッチの場合は、区分線描画またはライン描画以外は線、描画用に保存。
				lineStartPos = [touch locationInView:self];
			}
			else
			{
				// 2回目の処理
				endPos = [touch locationInView:self];
				switch (_drawMode) {
					case MODE_SPARATE_DRAW:
						// 区分線描画
						[self drawSparateLine:lineStartPos endPosition:endPos];
						// 状態変更 -> 区分線ViewとグレーアウトViewを表示 
						[self changeSaparate2Draw:NO];
						// パレットに通知
						[vwPallet notifySeparateGrayOut];
						// モードを区分線（グレーアウト）に移行
						_drawMode = MODE_SPARATE;
						// 区分線の座標をここで保存
						_sparatePos = endPos;
						break;
					/*
					case MODE_LINE:
						// 直線描画
						[self drawLine:lineStartPos endPosition:endPos isWrite:YES];
						break;
					*/
					default:
						break;
				}
			}
			
			// 初回タッチフラグを反転
			_isLineFirstTouch = ! _isLineFirstTouch;
			
			break;
			
		case MODE_SPARATE:
		// 区分線（グレーアウト）モード
			endPos = [touch locationInView:self];
			// touch位置に応じてグレーアウトViewを設定
			[self grayOutViewByTouchPos:endPos];
			break;
		
		case MODE_LINE:
		// ライン描画線	
			
			// 再度描画する
			// endPos = [touch locationInView:self];
			// [self drawLine:lineStartPos endPosition:endPos isWrite:YES];
			
			// undoバッファの更新
			// CGImageRelease(lastImage);
			// lastImage = CGBitmapContextCreateImage(canvasContext);
            
            //2012 6/4 伊藤 ペイントのベクタ化 入力した線分を保存し、全体を再読み込み
            endPos = [touch locationInView:self];
            [self addLine:lineStartPos endPos:endPos isWrite:YES];
            // 直線描画前に戻す
			CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
			CGContextDrawImage(canvasContext, self.bounds, lastImage);
            [self drawObjects:NO];
            [self setNeedsDisplay];

            preHasStamp = NO;
			break;
		case MODE_CIRCLE:
            // 円描画線
            endPos = [touch locationInView:self];
            [self addEllipse:lineStartPos endPos:endPos isWrite:YES];
            // 直線描画前に戻す
			CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
			CGContextDrawImage(canvasContext, self.bounds, lastImage);
            [self drawObjects:NO];
            [self setNeedsDisplay];
            
            preHasStamp = NO;
			break;
        case MODE_SPLINE:
        case MODE_ERASE:
            // スプライン系は途中で点線になる場合があるので、ここで全範囲で再描画 
            [self setNeedsDisplay];
            preHasStamp = NO;
            break;
        case MODE_STAMP:
            [self endStamp:touches event:event];
            break;
        default:
            break;
	}
}

//線分の保存
- (void)addLine:(CGPoint)startPos
         endPos:(CGPoint)endPos
        isWrite:(BOOL)isWrite{
    PictureDrawParts* pictObj = [[PictureDrawParts alloc]initWithLine:startPos endPoint:endPos color:(isWrite)? _drawColorNo : ERASE_COLOR_NO width:_lineWidth];
    [pictObjects addObject:pictObj];
    
    [pictObj release];	
    
    setUndo = NO;       // undoにする（objectリストより取り出す）
}
//楕円の保存
- (void)addEllipse:(CGPoint)startPos
         endPos:(CGPoint)endPos
        isWrite:(BOOL)isWrite{
    PictureDrawParts* pictObj = [[PictureDrawParts alloc]initWithEllipse:startPos endPoint:endPos color:(isWrite)? _drawColorNo : ERASE_COLOR_NO width:_lineWidth];
    [pictObjects addObject:pictObj];
    
    [pictObj release];
    
    setUndo = NO;       // undoにする（objectリストより取り出す）
}
//スタンプ選択モードの時にタッチ開始したときの処理
- (void)beganStampSelect:(NSSet *)touches event:(UIEvent *)event{
    _drawMode = MODE_STAMP;
    _twiceStampTouch = NO; //jump:twice_yes
    UITouch *touch = (UITouch *)[touches anyObject];
    CGPoint center = [touch locationInView:self];
    [self setStamp:stamp center:center];
    preStamp = NULL;
}
//スタンプ・モードの時にタッチ開始したときの処理
- (void)beganStamp:(NSSet *)touches event:(UIEvent *)event{
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
    _determinStamp = NO;
    _twiceStampTouch = YES;
    CGImageRelease(lastImageForStamp);
    lastImageForStamp = CGBitmapContextCreateImage(canvasContext);
    //[touchM registerBeganTouches:touches event:event stamp:stamp atView:self];
#if STAMP_MODE == 1
#if 1 // 不具合対応 kikuta - start - 2014/01/30
    // スタンプの矩形外を押された場合は、preStampに以前の状態を保存しないようにする。
    if ( [touchM isStampInRect:touches event:event stamp:stamp atView:self])
        preStamp = [[Stamp alloc] initWithStamp:stamp];
#else
    preStamp = [[Stamp alloc] initWithStamp:stamp];
#endif // 不具合対応 kikuta - end - 2014/01/30
    
    [touchM moveTouches:touches event:event stamp:stamp atView:self];
    NSUInteger touchNum = [touchM touchNumber:event];
    stampMoveFirst = YES;
    if(touchNum==0) {
        [self drawStamp:NO];
    }
#else
    UITouch *touch = [touches anyObject];
    CGPoint pointInV = [touch locationInView:self];
    CGPoint pointInS = [stamp NVtoRV:pointInV];
    
    if (stampMode != STAMP_VIEW && [stamp hasNearResizeDot:pointInS]){
        stampMode = STAMP_RESIZE;
        ResizeDot *dot = [stamp nearResizeDot:pointInS];
        resize = CGPointMake(dot.x, dot.y);
        preStamp = [[Stamp alloc] initWithStamp:stamp];
        offset = CGPointMake(stamp.rect.origin.x - pointInS.x, stamp.rect.origin.y - pointInS.y);
        [self drawStampWithDots:YES];
    }else if (stampMode != STAMP_VIEW && [stamp nearRotateDot:pointInS]){
        stampMode = STAMP_ROTATE;
        preStamp = [[Stamp alloc] initWithStamp:stamp];
        offset = CGPointMake(stamp.rect.origin.x - pointInS.x, stamp.rect.origin.y - pointInS.y);
        [self drawStampWithDots:YES];
    } else if (CGRectContainsPoint(stamp.rect, pointInS)) {
        stampMode = STAMP_MOVE;
        preStamp = [[Stamp alloc] initWithStamp:stamp];
        offset = CGPointMake(stamp.center.x - pointInV.x, stamp.center.y - pointInV.y);
        [self drawStampWithDots:YES];
    } else{
        stampMode = STAMP_VIEW;
        NSLog(@"back to default");
        [self drawStampWithDots:NO];
    }
#endif
}
- (void)moveStamp:(NSSet *)touches event:(UIEvent *)event{
//    NSLog(@"%s",__func__);
#if STAMP_MODE == 1
    [touchM moveTouches:touches event:event stamp:stamp atView:self];
    NSUInteger touchNum = [touchM touchNumber:event];
    
    if (touchNum == 1) {
//        NSLog(@"touchNum==1");
        movestamp = [[Stamp alloc] initWithStamp:stamp]; // 移動中の直前スタンプ
        stamp.center = touchM.center;
        vwStampEdit.center = touchM.center;
//        imgvwStamp.center = touchM.center;
    } else if (touchNum == 2){
//        NSLog(@"touchNum==2");
        stamp.center = touchM.center;
        stamp.size = touchM.size;
        stamp.angle = touchM.angle;
        [stamp updateImage];
    }
    [self drawStamp:YES];
#else
    UITouch *touch = [touches anyObject];
    CGPoint pointInV = [touch locationInView:self];
    if (stampMode == STAMP_MOVE) {
        stamp.center = [Stamp centerFromTap:pointInV Offset:offset];
        [self drawStampWithDots:YES];
    } else if (stampMode == STAMP_RESIZE){
        CGPoint pointInP = [preStamp NVtoRV:pointInV];
        
        CGFloat x_offset = (resize.x < 0) ? offset.x : offset.x + preStamp.size.width;
        CGFloat y_offset = (resize.y < 0) ? offset.y : offset.y + preStamp.size.height;
        
        CGFloat x_mobile = pointInP.x + x_offset;
        CGFloat y_mobile = pointInP.y + y_offset;
        CGFloat x_fix = [Stamp rect:preStamp.rect xy:-1 smallBig: -1 * resize.x];
        CGFloat y_fix = [Stamp rect:preStamp.rect xy:1 smallBig:-1 * resize.y];
        
        CGFloat w_per_h = preStamp.size.width / (preStamp.size.height * 1.0);
        
        if (resize.x == 0) {
            stamp.center = CGPointMake(preStamp.centerInRV.x, (y_mobile + y_fix) * 0.5f);
            stamp.center = [preStamp RVtoNV:stamp.center];
            stamp.size = CGSizeMake( stamp.size.width, abs(y_mobile - y_fix));
        }else if (resize.y == 0){
            stamp.center = CGPointMake((x_mobile + x_fix) * 0.5f, preStamp.centerInRV.y);
            stamp.center = [preStamp RVtoNV:stamp.center];
            stamp.size = CGSizeMake(abs(x_mobile - x_fix), stamp.size.height);
        }else{
            //角
            CGFloat width = abs(x_mobile - x_fix);
            CGFloat height = abs(y_mobile - y_fix);
            if (width / (height * 1.0) < w_per_h) {
                x_mobile = x_fix + height * w_per_h * ((x_mobile < x_fix) ? -1 : 1);
            } else{
                y_mobile = y_fix + width / w_per_h * ((y_mobile < y_fix) ? -1 : 1);
            }
            stamp.center = CGPointMake((x_mobile + x_fix) * 0.5f, (y_mobile + y_fix) * 0.5f);
            stamp.center = [preStamp RVtoNV:stamp.center];
            stamp.size = CGSizeMake(abs(x_mobile - x_fix), abs(y_mobile - y_fix));
        }
        [stamp updateImage];
        [self drawStampWithDots:YES];
    } else if(stampMode == STAMP_ROTATE){
        float x = stamp.center.x - pointInV.x;
        float y = stamp.center.y - pointInV.y;
        stamp.angle = -1 * atan2(x, y);
        [stamp updateImage];
        [self drawStampWithDots:YES];
    }
    
#endif
}
- (void)endStamp:(NSSet *)touches event:(UIEvent *)event{
//    NSLog(@"SASA %s",__func__);
#if STAMP_MODE == 1
    [touchM moveTouches:touches event:event stamp:stamp atView:self];
    NSUInteger touchNum = [touchM touchNumber:event];
  
    // スタンプの移動が一旦止まるとセットする
    stampMoveFirst = YES;

    if(touchNum==0) {
        [self drawStamp:NO];
    } else {
        [self drawStamp:YES];
    }
#endif
}
//スタンプを描画. //DELC SASAGE
#if STAMP_MODE == 1
- (void)drawStamp:(BOOL)flag {
    CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
#ifndef STAMP_CLIP
    
    // 変更後のスタンプサイズを設定
    [vwStampEdit setFrame:stamp.rectInNV];
    if(flag) {
        // 一旦停止したスタンプを再度移動するときに、古いスタンプ画像を消す
        // 但し毎回 setNeedsDisplay を行うと動作が重くなるため、移動開始の初回のみ
        if(stampMoveFirst) {
            CGContextDrawImage(canvasContext, self.bounds, lastImage);
            [self setNeedsDisplay];
            stampMoveFirst = NO;
        }
        vwStampEdit.hidden = NO;
        vwStampEdit.image = [self mirrorImage:stamp.cashRotateImage];
    } else {
        vwStampEdit.hidden = YES;
        CGContextDrawImage(canvasContext, self.bounds, lastImage);
        CGContextSetBlendMode(canvasContext, kCGBlendModeNormal);
        if (hasStamp){
            CGContextDrawImage(canvasContext, stamp.rectInNV, stamp.rotateAndUpSideDownImage.CGImage);
        }
        [self setNeedsDisplay];
    }
#else
    CGContextDrawImage(canvasContext, self.bounds, lastImage);
#endif
//    CGContextSetBlendMode(canvasContext, kCGBlendModeNormal);
//    //CGContextDrawImage(canvasContext, stamp.rectInNV, stamp.rotateAndUpSideDownImage.CGImage);
//    if (flag) {
//        CGContextDrawImage(canvasContext, stamp.rectInNV, stamp.cashRotateImage.CGImage);
//    } else {
//        CGContextDrawImage(canvasContext, stamp.rectInNV, stamp.rotateAndUpSideDownImage.CGImage);
//    }
//    
//    [self setNeedsDisplay];
}
#else
- (void)drawStampWithDots:(BOOL)flag{
    CGContextSaveGState(canvasContext);
    CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
    CGContextDrawImage(canvasContext, self.bounds, lastImage);
    CGContextRestoreGState(canvasContext);
    CGContextSetBlendMode(canvasContext, kCGBlendModeNormal);
    if (flag) {
        CGContextDrawImage(canvasContext, stamp.rectInNV, stamp.cashRotateImage.CGImage);
    } else{
        CGContextDrawImage(canvasContext, stamp.rectInNV, stamp.rotateAndUpSideDownImage.CGImage);
    }
    
    [self setNeedsDisplay];
}

#endif
//スタンプを削除
- (void)deleteStamp{
    NSLog(@"%s",__func__);
    CGContextSaveGState(canvasContext);
    CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
    CGContextDrawImage(canvasContext, self.bounds, lastImage);
    CGContextRestoreGState(canvasContext);
    [self setNeedsDisplay];
    CGImageRelease(lastImage);
    lastImage = CGBitmapContextCreateImage(canvasContext);
    _determinStamp = YES;
}
//スタンプをタッチする前の状態に戻す。
- (void)undoStamp{
#if STAMP_MODE == 1
    /*
     CGContextSaveGState(canvasContext);
     CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
     CGContextDrawImage(canvasContext, self.bounds, lastImageForStamp);
     CGContextRestoreGState(canvasContext);
     [self setNeedsDisplay];
     */
    Stamp *tmpStamp = [[Stamp alloc] initWithStamp:stamp];

    NSLog(@"%s",__func__);
    stamp = preStamp;
    [stamp updateImage];
    preStamp = tmpStamp;
    [self drawStamp:NO];
#else
    NSLog(@"%s",__func__);
    stamp = preStamp;
    [stamp updateImage];
    [self drawStampWithDots:NO];
#endif
}

//2012 7/4 保存された線分を描画
- (void)drawObjects:(BOOL)reWrite{

    if (reWrite) {
        // Canvasを白の透明で塗りつぶす
        CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);			// CGBlendModeCopy:消しゴム
        [self setDrawColor:ERASE_COLOR_NO];
        CGContextFillRect(canvasContext, 
                          CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
        // BlendModeを戻す
        CGContextSetBlendMode(canvasContext, kCGBlendModeDarken);

    }
    // for (PictureDrawParts* drawObj in pictObjects) 
    for (NSUInteger i = 0; i < [pictObjects count]; i++)
    {
        PictureDrawParts* drawObj = [pictObjects objectAtIndex:i];
        [drawObj drawObject:canvasContext contextSize:self.bounds.size];
    }
}

// タッチ終了
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
#ifdef DEBUG
	NSLog(@"%s", __func__);
#endif
	// DrawModeによるタッチ終了時の処理
	[self touchEndByDrawMode:touches withEvent:event];
		
	if (pickTouch && ([touches member:pickTouch] != nil)) {
		pickTouch = nil;
	}
	if ([[event allTouches] count] == [touches count]) {
		_touchMode = MODE_RELEASED;
		[scrollViewParent setCanCancelContentTouches:YES];
	}
}

// UIScrollViewがフリックやピンチを確認した時も送られてくる。 
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
	NSLog(@"touchesCancelled");
	
	pickTouch = nil;
	_touchMode = MODE_RELEASED;
	[scrollViewParent setCanCancelContentTouches:YES];
    //DELC SASAGE
    if(_drawMode == MODE_STAMP){
        [self endStamp:touches event:event];
    }
}

#pragma mark public_methods

// lockモードの変更
- (void) changeLockMode:(BOOL)isLock
{
	// lockモードのみ有効となる
	/*
	self.hidden = !isLock; 
	self.alpha = (isLock)? 0.1f :0.0f;
	*/
	
	if (isLock)
	{
		// 管理モードを指が放された状態から始める
		_touchMode = MODE_RELEASED;
		// 描画モードを機能しないで始める
		_drawMode = MODE_VOID;
	} else {
#if STAMP_MODE == 1
        if(!_determinStamp && IsDirty && (_drawMode != MODE_VOID))
            [self drawStamp:NO];
#else 
#if STAMP_MODE >1
        if(!_determinStamp) {
            [self drawStampWithDots:NO];
        }
#endif
#endif
        _determinStamp = YES;
    }
}

// メール送信時の画像固定
- (void) sendMailMode
{
/*
	if (isLock)
	{
		// 管理モードを指が放された状態から始める
		_touchMode = MODE_RELEASED;
		// 描画モードを機能しないで始める
		_drawMode = MODE_VOID;
	} else {
*/
#if STAMP_MODE == 1
        if(!_determinStamp)
            [self drawStamp:NO];
#else
#if STAMP_MODE >1
        if(!_determinStamp)
            [self drawStampWithDots:NO];
#endif
#endif
        _determinStamp = YES;
//    }
}

// 描画領域のAll Clear
- (void) allClearCanvas
{
	// Canvasを白の透明で塗りつぶす
	CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);			// CGBlendModeCopy:消しゴム
	[self setDrawColor:ERASE_COLOR_NO];
	CGContextFillRect(canvasContext, 
					  CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
	
	// 再描画
	[self setNeedsDisplay];
	
    hasStamp = NO;
    
    if(lastImage!=nil) {
        CGImageRelease(lastImage);
        lastImage = nil;
    }
    
	// BlendModeを戻す
	CGContextSetBlendMode(canvasContext, kCGBlendModeDarken);
	// undo用imageの初期化
//    if(lastImage!=nil) {
//        CGImageRelease(lastImage);
//        lastImage = nil;
//    }
//    hasStamp = NO;  // Stampオブジェクトは存在しても表示しない。
//	lastImage = CGBitmapContextCreateImage(canvasContext);
}

// 描画領域のAll Clear2
- (void) allClearCanvas:(BOOL)stat
{
	// Canvasを白の透明で塗りつぶす
	CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);			// CGBlendModeCopy:消しゴム
	[self setDrawColor:ERASE_COLOR_NO];
	CGContextFillRect(canvasContext,
					  CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));

    if(self.lastDrawAction!=nil)
        self.lastDrawAction.paintDrawType = PAINT_DRAW_TYPE_INIT;
    if(lastImage!=nil) {
		CGImageRelease(lastImage);
        lastImage = nil;
    }
	
	// 再描画
	[self setNeedsDisplay];
	
	// BlendModeを戻す
	CGContextSetBlendMode(canvasContext, kCGBlendModeDarken);
}

// 区分線の削除
- (void) deleteSeparate
{
	// 区分線の状態変更:区分線描画に
	[self changeSaparate2Draw:YES];
	_drawMode = MODE_SPARATE_DRAW;
}

// 描画Imageを取得
- (UIImage*)getCanvasImage
{
	CGImageRef imageRef = CGBitmapContextCreateImage(canvasContext);
	return ([[UIImage alloc] initWithCGImage:imageRef]);
}

// 描画オブジェクトの初期化
-(void) initDrawObject
{
    [self.pictObjects removeAllObjects];
    /*[self.lastDrawAction release];
    self.lastDrawAction = nil;*/
#ifdef PICTURE_ALL_CLEAR_ALERT
    // Alertダイアログの初期化
    modifyCheckAlert = [[UIAlertView alloc] init];
    modifyCheckAlert.title = @"画像描画";
    modifyCheckAlert.message = @"編集した画像を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集内容は\n破棄されます）";
    modifyCheckAlert.delegate = self;
    [modifyCheckAlert addButtonWithTitle:@"は　い"];
    [modifyCheckAlert addButtonWithTitle:@"いいえ"];
#endif
    setUndo = NO;
}

#pragma mark PicturePaintPalletDelegate

// 描画モード変更
// args: command=PALLET_DRAW_COLOR->UIColor command=PALLET_DRAW_WIDTH->NSNumber(float)
-(void) OnDrawModeChange:(id)sender changedCommand:(PALLET_BUTTON_COMMAND)command args:(id)args;
{
    //スタンプ・モードだった時には、点などを消しておく DELC SASAGE
#if STAMP_MODE==1
    if (_drawMode == MODE_STAMP) {
        [self drawStamp:NO];
    }
#else
#if STAMP_MODE > 1
    if (_drawMode == MODE_STAMP) {
        [self drawStampWithDots:NO];
    }
#endif
#endif
	switch (command) {
		case PALLET_SEPARATE_DRAW:
		// 区分線描画			：a
			_drawMode = MODE_SPARATE_DRAW;
			break;
		case PALLET_SEPARATE:
		// 区分線（グレーアウト）：b
			_drawMode = MODE_SPARATE;
			break;
		case PALLET_SEPARATE_DELETE:
		// 区分線削除			：c
			// 区分線の状態変更:区分線描画に
			[self changeSaparate2Draw:YES];
			_drawMode = MODE_SPARATE_DRAW;
			break;
		case PALLET_LINE:
            // 直線				：d
            NSLog(@"PALLET_LINE");
            CGImageRelease(lastImage);
            lastImage = CGBitmapContextCreateImage(canvasContext);
			_drawMode = MODE_LINE;
			break;
		case PALLET_CIRCLE:
            CGImageRelease(lastImage);
            lastImage = CGBitmapContextCreateImage(canvasContext);
			_drawMode = MODE_CIRCLE;
			break;
		case PALLET_SPLINE:
		// スプライン			：e
			_drawMode = MODE_SPLINE;
			break;
		case PALLET_ERASE:
            // 消しゴム			：f
            //スタンプ描画のときはスタンプを消す。
            if (!_determinStamp) {
                _determinStamp = YES;
//                [self deleteStamp];
            }
            _drawMode = MODE_ERASE;
			break;
        case PALLET_CHARA:
        // 文字挿入			：m
            _drawMode = MODE_CHARA;
            break;
		case PALLET_DRAW_COLOR:
		// 描画色				：g〜i
			// [self setDrawColor:[((NSNumber*)args) intValue]];
			_drawColorNo = [((NSNumber*)args) intValue];
			break;
		case PALLET_DRAW_WIDTH:
		//  描画太さ			：j〜l
			[self setDrawWidth:[((NSNumber*)args) intValue]];
			break;
        case PALLET_STAMP:
        //  スタンプ
            if (_drawMode != MODE_STAMP) {
                _drawMode = MODE_VOID;
            }
            break;
        case PALLET_VOID:
            _drawMode = MODE_VOID;
            break;

        case PALLET_ALL_CLEAR:
        // 全消去
#ifdef PICTURE_ALL_CLEAR_ALERT
             [modifyCheckAlert show];
             _modifyCheckAlertWait = -1;
             
             // ダイアログの応答待機
             NSInteger wait;
             while ((wait = _modifyCheckAlertWait) < 0)
             {
             [[NSRunLoop currentRunLoop]
             runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
             }
             
             // はいが押された
             if (wait == 0)
             { [self _allClear]; }
#else
            [self _allClear];
#endif
            break;
		case PALLET_UNDO:
            // 元に戻す
            if (!_determinStamp || (_drawMode==MODE_STAMP)) {
                [self undoStamp];
            }else{
                [self undoPaint];
			}
			break;
        case PALLET_ROTATION:
            // 画像を回転
            [ppvController rotateImage];
            break;
		default:
			break;
	}
}

-(UIImage*)mirrorImage:(UIImage*)img
{
    //グラフィックスコンテキストを作る
    CGSize size = { img.size.width, img.size.height };
    UIGraphicsBeginImageContext(size);
    
    //反転させた画像を描画
    CGRect rect;
    rect.origin = CGPointMake(0, 0);
    rect.size = CGSizeMake(img.size.width, img.size.height);
    UIImage* wImage = [UIImage imageWithCGImage:img.CGImage scale:1.0f orientation:UIImageOrientationDownMirrored];
    [wImage drawInRect:rect];
    
    //反転させて描画した画像を取得する
    UIImage* revImage;
    revImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return revImage;
}

@end
