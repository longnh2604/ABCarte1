//
//  OKDClickImageView.m
//  iPadCamera
//
//  Created by MacBook on 10/09/08.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "iPadCameraAppDelegate.h"
#import "ClickVideoView.h"

#import "UIFlickerButton.h"
#import "OKDImageFileManager.h"
#import "SVProgressHUD.h"
#import "Common.h"

@implementation ClickVideoView

@synthesize delegate;
@synthesize IsSelected;
@synthesize readError;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

-(id)init:(MovieResource *)_movie selectedNumber:(u_int)number
{
	if ((self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 10.0f, 10.0f)])) {
        // Initialization code
        movie = _movie;
        [movie retain];
		
		self.IsSelected = NO;
		// Viewの作成(選択時に枠として表示されるように)
		selectedView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 10.0f, 10.0f)] autorelease];
		selectedView.hidden = YES;
		[self addSubview:selectedView];
		backgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 10.0f, 10.0f)] autorelease];
		//[backgroundView setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
		[backgroundView setBackgroundColor:[UIColor blackColor]];
		//backgroundView.hidden = YES;
		[self addSubview:backgroundView];
		
        // 画像
        UIImage *image = _movie.thumbnail;
        if (movie.movieIsExists) {
            image =  [self createThumbnailImage:movie.videoAsset];
        }
        if (image == nil) {
            //[self retain];
            //[imgView retain];
            OKDImageFileManager *imgFileMng
            = [[OKDImageFileManager alloc] initWithUserID:_movie.userId];
            image = [imgFileMng getThumbnailSizeImage:[_movie.thumbnailPath lastPathComponent]];
            [imgFileMng release];
        }
		imgView = [ [[UIImageView alloc] initWithImage:image] autorelease];
		/*
         imgView = [[[UIImageView alloc] initWithFrame :
         CGRectMake(0.0f, 0.0f, 20.0f, 20.0f)] autorelease];
         [imgView setImage:image];
         */
        imgView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:imgView];
		// Image表示の作成
		
		//
		// タッチイベントのセットアップ
		//
		// ダブルタップ
		UITapGestureRecognizer *doubleTapGestuer = 
			[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDoubleTapImageView:)];
		doubleTapGestuer.numberOfTapsRequired = 2;
		[self addGestureRecognizer:doubleTapGestuer];

		// シングルタップ
		UITapGestureRecognizer *tapGestuer =
			[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapImageView:)];
		tapGestuer.numberOfTapsRequired = 1;			// タップの数（=2でダブルタップ）
		tapGestuer.numberOfTouchesRequired = 1;			// 指の本数
		[tapGestuer requireGestureRecognizerToFail: doubleTapGestuer];
		[self addGestureRecognizer:tapGestuer];
		[tapGestuer release];
		[doubleTapGestuer release];
		
		// 選択番号Imageの作成
		imgSelectNumber = [[[UIImageView alloc] initWithFrame:
							CGRectMake(1.0f, 1.0f, SELECT_NUMBER_SIZE, SELECT_NUMBER_SIZE)] autorelease];
		[imgSelectNumber setImage:[UIImage imageNamed:@"selectCircle2.png"]];
		[self addSubview:imgSelectNumber];
		
		// 選択番号Labelの作成
		lblSelectNumber = [[[UILabel alloc] initWithFrame:
							CGRectMake(1.0f, 1.0f, SELECT_NUMBER_SIZE, SELECT_NUMBER_SIZE)] autorelease];
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
		lblSelectNumber.text = [NSString stringWithFormat:@"%u", number];
		[self addSubview:lblSelectNumber];
        
        self.IsSelected = NO;
        
    }
    return self;
	
}

// Imageの生成
-(UIImage*) makeImage:(UIImage*)oriImage imgWidth:(CGFloat)width imgHeight:(CGFloat)height
{
	// グラフィックコンテキストを作成
	CGSize size ={width, height};
	UIGraphicsBeginImageContext(size);
	
	// 画像を縮小して描画する
	CGRect rect;
	rect.origin = CGPointZero;
	rect.size = size;
	[oriImage drawInRect:rect];
	
	// 描画した画像を取得する
	UIImage* drawedImage =
	UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	// [drawedImage autorelease];
	
	return (drawedImage);
}

// サイズの設定
-(void)setSize:(CGRect)frame
{
	[self setFrame:frame];
		
	// 画像Viewと選択ボタンも設定する
	CGRect rect = CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height);
	/*
	self.IsSelected = NO;
	selectedView.hidden = YES;
	*/
	[selectedView setFrame:rect];
#ifdef CALULU_IPHONE
    CGFloat selectWitdh =8.0f;
#else
    CGFloat selectWitdh =20.0f;
#endif
	rect = CGRectMake(selectWitdh/2.0f, selectWitdh/2.0f, frame.size.width - selectWitdh, frame.size.height - selectWitdh);
	[backgroundView setFrame:rect];
    imgView.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height - 30); // スライダーの分、減じる
    if (player) {
        player.frame = rect;
    }
	//0312[imgView setFrame:rect];
	// [btnSelected setFrame:rect];
}

// 選択番号の非表示の設定
-(void) setSelectNumberHidden:(BOOL)isHidden
{
	imgSelectNumber.hidden = isHidden;
	lblSelectNumber.hidden = isHidden;
}

// 選択ボタンのClick
-(void)onSelectButton
{
	if (self.delegate != nil) {
		NSUInteger tagID = self.tag;
        [delegate OnClickVideoViewSelected:tagID];
		//0312[delegate OnOKDClickImageViewSelected :tagID image:imgView.image];
	}	
}

// 選択状態の設定
-(void) setSelected:(BOOL)isSelected frameColor:(UIColor*)color
{
    BOOL isSelectedPrev = self.IsSelected;
	// 状態を変更
	self.IsSelected = isSelected;
    
    readError = NO;

	// 画像Viewのサイズを変更する
	if (self.IsSelected)
	{
		if (color) 
		{
			[selectedView setBackgroundColor:color];
		}
		selectedView.hidden = NO;
        //player.isSliderHidden = NO;
        // 色が変わっただけのときはなにもしない。
        if (!movie.movieIsExists && !movie.movieIsExistsInCash) {
            [SVProgressHUD showWithStatus:@"しばらくお待ちください" maskType:SVProgressHUDMaskTypeGradient];
            if (![movie syncDL:^(NSUInteger totalBytes){
                [SVProgressHUD setStatus:[NSString stringWithFormat: @"しばらくお待ちください\n\n(動画：%ld[KB]受信済み)",
                                          (long)(totalBytes/1024)]];
            }]){
                [Common showDialogWithTitle:@"動画" message:@"動画が取得できません"];
                NSLog(@"movie does't exist and cannot download movie");
                readError = YES;
            }
            [SVProgressHUD dismiss];
        }
        if (!isSelectedPrev) {
            [self deletePlayer];
            if (!readError) {
                [self setPlayer];
            } else {
                player = nil;
            }
        }
	}
	else
	{
		selectedView.hidden = YES;
        //player.isSliderHidden = YES;
        [self deletePlayer];
	}
}
- (void)setPlayer {
    // 動画
    player = [[SimplePlayer alloc] init];
    if(movie.movieIsExistsInCash) {
        [player setVideoUrl:[[NSURL alloc] initFileURLWithPath:movie.movieCashPath]];
    } else {
        [player setVideoUrl:movie.movieURL];
    }
    player.frame = backgroundView.frame;
    //[self addSubview:player];
    [self insertSubview:player aboveSubview:imgView];
}
- (void)deletePlayer {
    if (player) {
        [player removeFromSuperview];
        [player release];
        player = nil;
    }
}
- (UIImage*)createThumbnailImage:(AVAsset*)asset {
    UIImage *img = nil;
    if ([asset tracksWithMediaCharacteristic:AVMediaTypeVideo]) {
        AVAssetImageGenerator *imageGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        [imageGen setAppliesPreferredTrackTransform:YES];
        NSError* error = nil;
        CMTime actualTime;
        
        CGImageRef halfWayImageRef = [imageGen copyCGImageAtTime:kCMTimeZero actualTime:&actualTime error:&error];
        
        if (halfWayImageRef != NULL) {
            UIImage* myImage = [[UIImage alloc]initWithCGImage:halfWayImageRef];
            CGImageRelease(halfWayImageRef);
            img =  myImage;
        }
        [imageGen release];
    }
    return img;
}
#pragma mark touch_events

-(void) clickImageViewTouchedRaize
{
	if ( (self.delegate != nil) &&
		([self.delegate respondsToSelector:@selector(OnClickVideoViewTouched:)]) )
	{
		//NSUInteger tagID = self.tag;
		//[delegate OnOKDClickImageViewTouched :tagID];
		[delegate OnClickVideoViewTouched: self];
	}		
}

// Tapイベント
-(void)onTapImageView:(id)sender
{
	// 状態を反転
	//self.IsSelected = ! self.IsSelected;

	// タッチイベント発生
	[self clickImageViewTouchedRaize];
}

// Double Tapイベント
-(void)onDoubleTapImageView:(id)sender
{
	if (self.delegate != nil) {
		NSUInteger tagID = self.tag;
		[delegate OnClickVideoViewSelected:tagID];
	}
}

- (BOOL)isPortrait {
    CGSize size = [MovieResource naturalSizeOfAVPlayer:player.player];
    return size.height > size.width;
}
- (void)removeFromSuperview
{
	[super removeFromSuperview];
}

- (void)dealloc {
	// [btnSelected release];
	
	//[lblSelectNumber release];
	lblSelectNumber = nil;
	//[imgSelectNumber release];
	imgSelectNumber = nil;
	//[btnSelected release];
	btnSelected = nil;
	//[imgView release];
	imgView = nil;
    if (player) {
        [player release];
    }
    [movie release];
	[super dealloc];
}


@end
