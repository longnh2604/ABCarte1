//
//  OKDThumbnailItemView.m
//  iPadCamera
//
//  Created by MacBook on 10/09/07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OKDThumbnailItemView.h"

#import "./model/OKDImageFileManager.h"

@implementation OKDThumbnailItemView

@synthesize IsSelected;
@synthesize delegate;
@synthesize imgId;
@synthesize selectImgId;
@synthesize updateTime;
@synthesize picDate;
@synthesize finalDateTime;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		// タイトル表示用ラベルの作成
		lblTitle = [[[UILabel alloc]initWithFrame:CGRectMake(0.0f, 0.0f, frame.size.width, TITLE_HIGHT)] autorelease];
		[lblTitle setFont:[UIFont systemFontOfSize:9.5f]]; 
		// [lblTitle setTextColor:[UIColor whiteColor]];
		[lblTitle setTextAlignment:NSTextAlignmentCenter];
		[lblTitle setOpaque:NO];
		[lblTitle setAdjustsFontSizeToFitWidth:YES];
		[self addSubview:lblTitle];
		
		// Image表示の作成
		imgView = [[UIImageView alloc] initWithFrame:
					CGRectMake(0.0f, TITLE_HIGHT, frame.size.width, frame.size.height - TITLE_HIGHT)];     //  autorelease
		[imgView setBackgroundColor:[UIColor darkGrayColor]];
        imgView.contentMode = UIViewContentModeScaleAspectFit;
		[self addSubview:imgView];
        		
		// 選択ボタンの作成
		btnSelected = [UIButton buttonWithType:UIButtonTypeCustom];
		[btnSelected sizeToFit];
		[btnSelected setFrame:CGRectMake(0.0f, TITLE_HIGHT, frame.size.width, frame.size.height - TITLE_HIGHT)];
		[btnSelected addTarget:self action:@selector(onSelectButton) forControlEvents:UIControlEventTouchUpInside];     // UIControlEventTouchDownだとスワイプで選択されてしまう
		[btnSelected setBackgroundImage:[UIImage imageNamed:@"frame_no_select.png"] forState:UIControlStateNormal];
		[self addSubview:btnSelected];
		
		// 選択番号Imageの作成
		imgSelectNumber = [[[UIImageView alloc] initWithFrame:
				CGRectMake(1.0f, (TITLE_HIGHT + 1.0f), SELECT_NUMBER_SIZE, SELECT_NUMBER_SIZE)] autorelease];
		[imgSelectNumber setImage:[UIImage imageNamed:@"selectCircle2.png"]];
		imgSelectNumber.hidden = YES;
		[self addSubview:imgSelectNumber];
		
		// 選択番号Labelの作成
		lblSelectNumber = [[[UILabel alloc] initWithFrame:
				CGRectMake(1.0f, (TITLE_HIGHT + 1.0f), SELECT_NUMBER_SIZE, SELECT_NUMBER_SIZE)] autorelease];
#ifdef CALULU_IPHONE
		lblSelectNumber.font = [UIFont boldSystemFontOfSize:11.0f];
#else
        lblSelectNumber.font = [UIFont boldSystemFontOfSize:17.0f];
#endif
		lblSelectNumber.contentMode = UIViewContentModeCenter;
		lblSelectNumber.textAlignment = NSTextAlignmentCenter;
		lblSelectNumber.textColor = [UIColor whiteColor];
		lblSelectNumber.backgroundColor 
			= [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.0f];		// 背景を透過
		lblSelectNumber.hidden = YES;
		[self addSubview:lblSelectNumber];
        
//        dateTime = [[[UILabel alloc]initWithFrame:CGRectMake(0.0f, 0.0f, 0, 0)] autorelease];
//        [dateTime setFont:[UIFont systemFontOfSize:9.5f]];
//        // [lblTitle setTextColor:[UIColor whiteColor]];
//        [dateTime setTextAlignment:NSTextAlignmentCenter];
//        [dateTime setOpaque:NO];
//        [dateTime setAdjustsFontSizeToFitWidth:YES];
//        [self addSubview:dateTime];
        
        finalDateTime = [[[UILabel alloc]initWithFrame:CGRectMake(0.0f, 0.0f, 0, 0)] autorelease];
        [finalDateTime setFont:[UIFont systemFontOfSize:9.5f]];
        [finalDateTime setTextAlignment:NSTextAlignmentCenter];
        [finalDateTime setOpaque:NO];
        [finalDateTime setAdjustsFontSizeToFitWidth:YES];
        [self addSubview:finalDateTime];
        
		self.IsSelected = NO;
    }
	
    return self;
}

// 選択の設定
-(void) setSelect:(BOOL)set
{
	if (set == self.IsSelected)
	{ return; }
	
	// 状態を保存
	self.IsSelected = set;
	
	// ボタンの設定
	[self setButtonState];
}

// 選択ボタンのClick
-(void)onSelectButton
{
	// 状態を反転
	self.IsSelected = ! self.IsSelected;
	
	// ボタンの設定
	[self setButtonState];
		
}

// ボタンの設定
- (void) setButtonState
{
	// ボタンImageの変更
	[btnSelected setBackgroundImage:
		[UIImage imageNamed:(self.IsSelected == YES)? @"frame_select.png" : @"frame_no_select.png"] 
						   forState:UIControlStateNormal];
	
	if (self.delegate != nil) {
		NSUInteger tagID = self.tag;
		[delegate SelectThumbnail :tagID image:nil select:self.IsSelected];		// image:[self getImage]
	}
	
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

// ファイル名の設定
-(void) setFileName:(NSString*)fileName
{
	// メンバのファイル名を保存
	_fileName = [[NSString alloc] initWithString: fileName];

}

// サムネイルImageの描画：ファイル名設定後のに実行
-(void) writeToThumbnail:(OKDImageFileManager*) imgFileMng
{
	if (! imgFileMng)
	{	return; }
	
	// Imageファイル管理クラスにてサムネイル画像を取得
	UIImage *drawImg = [imgFileMng getThumbnailSizeImage:_fileName];
	
	// ImageViewに縮小版のImageを設定
	[imgView setImage:drawImg];
}

// サムネイルImageの描画：ファイル名設定後のに実行
-(void) writeToTemplateThumbnail:(OKDImageFileManager*) imgFileMng
{
	if (! imgFileMng)
	{	return; }
	
	// Imageファイル管理クラスにてサムネイル画像を取得
	UIImage *drawImg = [imgFileMng getTemplateThumbnailSizeImage:_fileName];
	
	// ImageViewに縮小版のImageを設定
	[imgView setImage:drawImg];
}

// Imageの描画：ファイル名設定後のに実行
-(void) writeToImage
{
	NSData *fileDat = [NSData dataWithContentsOfFile:_fileName];
	//[fileDat autorelease];
	
	UIImage *img = [UIImage imageWithData:fileDat];
	if (img == nil)
	{ 
		return; 
	}
	// [img autorelease];
	
	// 描画サイズ
	CGRect imgRect 
	= CGRectMake(0.0f, 0.0f, btnSelected.bounds.size.width, btnSelected.bounds.size.height);
	
	// グラフィックコンテキストを作成
	UIGraphicsBeginImageContext(imgRect.size);
	// グラフィックコンテキストに描画
	[img drawInRect:imgRect];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *drawImg = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
	
	// オリジナルのImageを解放
	img = nil;
	// [fileDat release];
	fileDat = nil;
	
	// ImageViewに縮小版のImageを設定
	[imgView setImage:drawImg];
	
}

// ファイル名によるImageの設定
-(void) setImageWithFile:(NSString*)fileName
{
	// メンバのファイル名を保存
	_fileName = [[NSString alloc] initWithString: fileName];
	
	// Timerにより別スレッドでImageを描画する
	[NSTimer scheduledTimerWithTimeInterval:0.1f 
				target:self 
				selector:@selector(imageWrite:) 
				userInfo:nil 
				repeats:NO];
	// NSLog(@"fire imageWrite timer in %@", _fileName);
	// [tm fire];
}

// Imageの描画：Timerスレッド
-(void) imageWrite:(NSTimer*)timer
{
	//NSLog(@"reise imageWrite timer in %@", _fileName);
	[self writeToImage];	
	// NSLog(@"complite imageWrite timer in %@", _fileName);
}

// タイトルの設定
-(void) setTitle:(NSString*)title
{
    [lblTitle setBackgroundColor:[UIColor whiteColor]];
    [lblTitle setTextColor:[UIColor blackColor]];
	[lblTitle setText:title];
}

-(void) setDate:(NSDate*)date {
    // サムネイルタイトルの書式にする
    NSDateFormatter *formatter2 = [[[NSDateFormatter alloc] init] autorelease];
    [formatter2 setLocale:[NSLocale systemLocale]];
    [formatter2 setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter2 setDateFormat:@"20yy年MM月dd日HH時mm分ss秒"];
    
    [finalDateTime setText:[formatter2 stringFromDate:date]];
    picDate = date;
}

// 実サイズImageの取得
-(UIImage*) getRealSizeImage:(OKDImageFileManager*) imgFileMng
{
	UIImage *img = [imgFileMng getRealSizeImage:_fileName];
	
	return (img);
}
// サムネイルImageの取得
-(UIImage*) getThumbnailImage
{
	return (imgView.image);
}

// Imageの取得
-(UIImage*) getImage
{
	NSData *fileDat = [NSData dataWithContentsOfFile:_fileName];
	UIImage *img = [UIImage imageWithData:fileDat];
	
	fileDat = nil;
	
	return (img);
}

// ファイル名の取得
-(NSString*) getFileName
{
	return ( [[NSString alloc] initWithString: _fileName]);
	// return (_fileName);
}

// 選択番号の設定：number=選択番号（０で非表示とする）
- (void) setSelectNumber:(u_int)number
{
	BOOL hide = (number <= 0);
	
	imgSelectNumber.hidden = hide;
	lblSelectNumber.hidden = hide;	
	lblSelectNumber.text = [NSString stringWithFormat:@"%u", number];
}

- (void)dealloc {
    
	// [lblTitle removeFromSuperview];
	/*
	[lblTitle release];
	
	[imgView release];
	
	[btnSelected release];
	
	[imgSelectNumber release];
	
	[lblSelectNumber release];
	*/
    
    [imgView release];
	 
	[_fileName release];
	
	[super dealloc];
}

@end
