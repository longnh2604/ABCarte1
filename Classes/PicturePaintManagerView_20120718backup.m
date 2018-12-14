//
//  PicturePaintManagerView.m
//  iPadCamera
//
//  Created by MacBook on 11/03/04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PicturePaintManagerView.h"

#import "PicturePaintPalletView.h"

#import "PictureDrawParts.h"

#import "CharacterInsertPopup.h"
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
@synthesize redoDrawAction;
@synthesize IsDirty;

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
- (void) setDrawColor :(int)colorNo
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
		case ERASE_COLOR_NO:
		// 消しゴム:　背景色
			r = 1.0f;
			g = 1.0f;
			b = 1.0f;
			a = 0.5f;
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
		case 1:
			lineWidth = 4.0f;
			break;
		case 2:
			lineWidth = 6.0f;
			break;
		case 3:
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
	if ((_touchMode != MODE_SPLINE) && (_touchMode != MODE_ERASE) && (_touchMode != MODE_LINE))
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
						  (isWrite)? kCGBlendModeNormal : kCGBlendModeCopy);
	
	// 描画色の設定
	[self setDrawColor:(isWrite)? _drawColorNo : ERASE_COLOR_NO];
	
        CGContextStrokePath(canvasContext);	
	
    }else {
        //2012 7/4 伊藤 前回の線分の終点から新しい線分を延ばす
        PictureDrawParts* pict = [self.pictObjects lastObject];
        [pict apendLine:endPos];
        [pict drawNewObject:canvasContext];
    }
	// drawRect(再描画指示)
    if ((_touchMode != MODE_SPLINE) && (_touchMode != MODE_ERASE) )
    {
        // スプライン系はnew_iPad(iPad3)では描画が追いつかない
        [self setNeedsDisplay]; 
    }
    else {
        // スプライン系はnew_iPad(iPad3)では再描画で全範囲だと描画が追いつかないので
        // 再描画する範囲を求める（正規化つき）
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
    }
    
}

// 元に戻す
- (void) undoPaint
{
    /*
	CGImageRef image = CGBitmapContextCreateImage(canvasContext);
	CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
	CGContextDrawImage(canvasContext, self.bounds, lastImage);
	CGImageRelease(lastImage);
	lastImage = image;*/
    if ([pictObjects count] > 0) {
        CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
        CGContextDrawImage(canvasContext, self.bounds, lastImage);
        
        // 直線描画前に戻す
        [self.redoDrawAction addObject:[pictObjects lastObject]];
        [self.pictObjects removeLastObject];
        if ([pictObjects count] == 0) {
            //全消去後は初期状態
            self.IsDirty = NO;
        }
        
        [self drawObjects:NO];
        [self setNeedsDisplay];
    }
}

// やり直す
- (void) redoPaint
{

    if ([redoDrawAction count] > 0) {
        CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
        CGContextDrawImage(canvasContext, self.bounds, lastImage);
        // 直線描画前に戻す
        [self.pictObjects addObject:[self.redoDrawAction lastObject]];
        [self.redoDrawAction removeLastObject];
        if ([pictObjects count] > 0) {
            //リドゥーで必ず編集済みになる
            self.IsDirty = YES;
        }
        [self drawObjects:NO];
        [self setNeedsDisplay];
    }
}

// やり直す
- (void) allDelete
{
    
    if ([redoDrawAction count] > 0) {
        CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
        CGContextDrawImage(canvasContext, self.bounds, lastImage);
        // 直線描画前に戻す
        [self.pictObjects addObject:[self.redoDrawAction lastObject]];
        [self.redoDrawAction removeLastObject];
        
        [self drawObjects:NO];
        [self setNeedsDisplay];
    }
}

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
	// 初期状態は非表示
	// self.hidden = YES;
	
	// Canvas（オフスクリーン）の作成
	canvasContext = createCanvasContext(self.bounds.size.width, self.bounds.size.height);
	// Canvasを白の透明で塗りつぶす
	CGContextSetRGBFillColor(canvasContext, 1.0f, 1.0f, 1.0f, 0.0f);
	CGContextFillRect(canvasContext, 
					  CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
	// undo用imageの初期化
	lastImage = CGBitmapContextCreateImage(canvasContext);
	lastImageForLine = CGBitmapContextCreateImage(canvasContext);
	
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
    self.pictObjects = [[NSMutableArray alloc]init];
    self.redoDrawAction = [[NSMutableArray alloc]init];
    
    altAllDelete = [[UIAlertView alloc]initWithTitle:@"全消去"
                                               message:@"全ての線分を消去しますか？\n(この操作は取り消せません)" 
                                              delegate:self
                                     cancelButtonTitle:@"はい"
                                     otherButtonTitles:@"いいえ" ,nil];
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
    
    NSLog(@"drawRect start    %f/%f width %f/%f",
          rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

- (void)dealloc {
    
	CGImageRelease(lastImage);
	CGImageRelease(lastImageForLine);
	CGContextRelease(canvasContext);	//	解放
    
    //2012 7/4 伊藤
    [self.pictObjects release];
    [self.redoDrawAction release];
	[super dealloc];
}

#pragma mark touch_events

// タッチ開始
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"touchesBegan");
	
    //2012 07/10 伊藤 リドゥ消去
    [redoDrawAction removeAllObjects];
	// 指が放されていなければ何もしない
	if (_touchMode != MODE_RELEASED)
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
		
        [self drawObjects:NO];
		_touchMoveCount4Line = 0;
	}
	
    if (_drawMode == MODE_CHARA) {
        //ポップアップを開く
        if (PopupCharacterInsert)
        {
            [PopupCharacterInsert release];
            PopupCharacterInsert = nil;
        }
        CGPoint touchPos = [pickTouch locationInView:self];

        // 文字編集のViewControllerのインスタンス生成
        CharacterInsertPopup *vcCharaInsert 
        = [[CharacterInsertPopup alloc]initCharacterInsertWithPictList:self.pictObjects
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
        [PopupCharacterInsert presentPopoverFromRect:CGRectMake(touchPos.x, touchPos.y, 0, 0)
                                             inView:self
                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                            animated:YES];
        [vcCharaInsert release];
    }else if (_drawMode == MODE_CHARA_MOVE) {
        targetPict = nil;
        CGPoint touchPos = [pickTouch locationInView:self];

        NSInteger i = [pictObjects count] - 1;
        while (i >= 0) {
            PictureDrawParts* pict = [pictObjects objectAtIndex:i];
            if([pict thisTouch:touchPos]){
                lineStartPos = [pickTouch locationInView:self];
                targetPict = pict;
                [self drawObjects:NO];
                [self setNeedsDisplay];
                break;
            }
            i--;
        }
    }
    if(_drawMode == MODE_SPLINE ){
        [self addLine:lineStartPos endPos:lineStartPos isWrite:YES];
        drawAllDispFlg = 0;
    }else if(_drawMode == MODE_ERASE){
        [self addLine:lineStartPos endPos:lineStartPos isWrite:NO];
    }
    
    NSLog(@"%d : %d",_drawMode,MODE_SPARATE);
    if (_drawMode == MODE_SPARATE) {
        CGPoint touchPos = [pickTouch locationInView:self];
        // 区分線の上をタッチしたか(幅を広く取る)
        if (touchPos.x >= vwSaparete.frame.origin.x - vwSaparete.frame.size.width&&
            touchPos.x <= vwSaparete.frame.origin.x + vwSaparete.frame.size.width * 2) {
            if (touchPos.y >= vwSaparete.frame.origin.y - vwSaparete.frame.size.height&&
                touchPos.y <= vwSaparete.frame.origin.y + vwSaparete.frame.size.height * 2) {
                moveSapareteLine = YES;
                lineStartPos = touchPos;
                NSLog(@"touchLine");
            }
            
        }
    }
    
	NSUInteger c = [[event allTouches] count];			//	現在追跡中のタッチイベントの数が、触れている指の数。
	if (c >= 2) {										//	ここで判定しないとピンチが取りこぼされるときがある。
		_touchMode = MODE_VOID;
	}
	if (_touchMode != MODE_VOID) {
		[scrollViewParent setCanCancelContentTouches:NO];		//	UIScrollViewに取られないようにする。
	}
	
    // self.clipsToBounds = YES;
}

- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    switch (popUpID) {
        case 0:
            // 編集フラグをここで設定
            self.IsDirty = YES;
            break;
            
        default:
            break;
    }
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
			NSUInteger c = [[event allTouches] count];				//	現在追跡中のタッチイベントの数が、触れている指の数。
			if (c == 1){
				_touchMode = _drawMode;
			}
			else {
				_touchMode = MODE_VOID;
				[scrollViewParent setCanCancelContentTouches:YES];	//	UIScrollViewにまかせる。
			}
			
			NSLog(@"_touchMode=%d", _touchMode);
		}
		if ((_touchMode == MODE_SPLINE) || (_touchMode == MODE_ERASE) || (_touchMode == MODE_LINE) ) 
		{
			CGImageRelease(lastImageForLine);
			lastImageForLine = CGBitmapContextCreateImage(canvasContext);
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
	}
	else if(_touchMode == MODE_LINE)
	{
		// if ( (++_touchMoveCount4Line) % 1 == 0)
		{
			// NSLog(@"touchMoveCount4Line start.");
				
			// 直線描画前に戻す
			CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);
			CGContextDrawImage(canvasContext, self.bounds, lastImageForLine);
			
			// 直線描画
			CGPoint lineEndPos = [touch locationInView:self];
			[self drawLine:lineStartPos endPosition:lineEndPos isWrite:YES];
			
			// NSLog(@"touchMoveCount4Line done.");
			
			// 編集フラグをここで設定
			self.IsDirty = YES;
		}
	}else if(_touchMode == MODE_CHARA_MOVE && targetPict != nil){
        //2012 7/12 伊藤 文字列の移動処理
        CGPoint lineEndPos = [touch locationInView:self];

        CGPoint movePos;
        movePos = CGPointMake(lineEndPos.x - lineStartPos.x,lineEndPos.y - lineStartPos.y);
        [targetPict movePoint:movePos];
        [self drawObjects:YES];
        [self setNeedsDisplay];
        lineStartPos = lineEndPos;
    }
    if (_touchMode == MODE_SPARATE && moveSapareteLine) {
        //2012 7/12 伊藤 区分線の移動処理
        CGPoint lineEndPos = [touch locationInView:self];
        
        if (lineEndPos.x < 0 + vwSaparete.frame.size.width / 2) {
            lineEndPos.x = 0 + vwSaparete.frame.size.width / 2;
        }
        if (lineEndPos.y < 0 + vwSaparete.frame.size.height / 2) {
            lineEndPos.y = 0 + vwSaparete.frame.size.height / 2;
        }
        if (lineEndPos.x > VIEW_WIDTH - vwSaparete.frame.size.width / 2) {
            lineEndPos.x = VIEW_WIDTH - vwSaparete.frame.size.width / 2;
        }
        if (lineEndPos.y > VIEW_HEIGHT - vwSaparete.frame.size.height / 2) {
            lineEndPos.y = VIEW_HEIGHT - vwSaparete.frame.size.height / 2;
        }
        
        CGPoint lineStartPosition;
        CGPoint lineEndPosition;
        if (_isSparatePortraite) {
            lineStartPosition = CGPointMake(lineEndPos.x,0);
            lineEndPosition = CGPointMake(lineEndPos.x, VIEW_HEIGHT);
        }else {
            lineStartPosition = CGPointMake(0,lineEndPos.y);
            lineEndPosition = CGPointMake(VIEW_WIDTH,lineEndPos.y);
        }

        [self drawSparateLine:lineStartPosition endPosition:lineEndPosition];
        _sparatePos = lineEndPos;

        lineStartPos = lineEndPos;  
	}
}

// DrawModeによるタッチ終了時の処理
- (void)touchEndByDrawMode:(NSSet*)touches
{
	UITouch *touch = nil;
	if (pickTouch) {
		touch = [touches member:pickTouch];
	}
	if (touch == nil) {										//	対象の指は動いていない。
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
            if (moveSapareteLine) {
                moveSapareteLine = NO;
            }else{
                // 区分線（グレーアウト）モード
                endPos = [touch locationInView:self];
                // touch位置に応じてグレーアウトViewを設定
                [self grayOutViewByTouchPos:endPos];
            }
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

			break;
        case MODE_SPLINE:
        case MODE_ERASE:
            // スプライン系は途中で点線になる場合があるので、ここで全範囲で再描画 
            [self setNeedsDisplay];
            break;
        case MODE_CHARA_MOVE:
            targetPict.thisSelect = NO;
            targetPict = nil;
            [self drawObjects:YES];
            [self setNeedsDisplay];
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
    [self.pictObjects addObject:pictObj];
    
    [pictObj release];	
}

//2012 7/4 保存された線分を描画
- (void)drawObjects:(BOOL)reWrite{

    if (reWrite) {
        // Canvasを白の透明で塗りつぶす
        CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);			// CGBlendModeCopy:消しゴム
        [self setDrawColor:0];
        CGContextFillRect(canvasContext, 
                          CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
        // BlendModeを戻す
        CGContextSetBlendMode(canvasContext, kCGBlendModeDarken);

    }
    for (PictureDrawParts* drawObj in self.pictObjects) {
        [drawObj drawObject:canvasContext];
    }
}

// タッチ終了
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"touchesEnded");
	
	// DrawModeによるタッチ終了時の処理
	[self touchEndByDrawMode:touches];
		
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
	}
}

// 描画領域のAll Clear
- (void) allClearCanvas
{
	// Canvasを白の透明で塗りつぶす
	CGContextSetBlendMode(canvasContext, kCGBlendModeCopy);			// CGBlendModeCopy:消しゴム
	[self setDrawColor:0];
	CGContextFillRect(canvasContext, 
					  CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
	
	// 再描画
	[self setNeedsDisplay];
	
	// BlendModeを戻す
	CGContextSetBlendMode(canvasContext, kCGBlendModeDarken);
	
	// undo用imageの初期化
	CGImageRelease(lastImage);
	lastImage = CGBitmapContextCreateImage(canvasContext);
	
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


#pragma mark PicturePaintPalletDelegate

// 描画モード変更
// args: command=PALLET_DRAW_COLOR->UIColor command=PALLET_DRAW_WIDTH->NSNumber(float)
-(void) OnDrawModeChange:(id)sender changedCommand:(PALLET_BUTTON_COMMAND)command args:(id)args;
{
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
			_drawMode = MODE_LINE;
			break;
		case PALLET_SPLINE:
		// スプライン			：e
			_drawMode = MODE_SPLINE;
			break;
		case PALLET_ERASE:
		// 消しゴム			：f
#ifdef CALULU_IPHONE
			_drawMode = MODE_ERASE;
#else
            _drawColorNo = [((NSNumber*)args) intValue];
#endif
			break;
        case PALLET_CHARA:
        // 文字挿入			：m
            _drawMode = MODE_CHARA;
            break;
        case PALLET_CHARA_MOVE:
        // 文字移動
            _drawMode = MODE_CHARA_MOVE;
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
		case PALLET_UNDO:
		// 元に戻す
			[self undoPaint];
			
			break;
        case PALLET_REDO:
            // 元に戻す
			[self redoPaint];
			break;
        case PALLET_ALLDELETE:
            [altAllDelete show];
            break;
		default:
			break;
	}
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(altAllDelete == alertView){
        switch(buttonIndex){
            case 0:
                [pictObjects removeAllObjects];
                [redoDrawAction removeAllObjects];
                [self drawObjects:YES];
                [self setNeedsDisplay];
                
                //全消去後は初期状態
                self.IsDirty = NO;
                break;
            default:
                break;
        }
    }
}
@end
