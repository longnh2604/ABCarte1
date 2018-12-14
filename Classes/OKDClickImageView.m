 //
//  OKDClickImageView.m
//  iPadCamera
//
//  Created by MacBook on 10/09/08.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "iPadCameraAppDelegate.h"
#import "OKDClickImageView.h"

#import "UIFlickerButton.h"

@implementation OKDClickImageView

@synthesize delegate;
@synthesize IsSelected;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
		
		// 選択ボタンの作成
		/*
		btnSelected = [UIButton buttonWithType:UIButtonTypeCustom];
		[btnSelected sizeToFit];
		[btnSelected setFrame:frame];
		[btnSelected addTarget:self action:@selector(onSelectButton) forControlEvents:UIControlEventTouchDown];
		[self addSubview:btnSelected];
		*/
    }
    return self;
}

-(id)init:(UIImage*)image selectedNumber:(u_int)number ownerView:(id)ownerView
{
	if ((self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 10.0f, 10.0f)])) {
        // Initialization code
		
		self.IsSelected = NO;
		
		// Viewの作成(選択時に枠として表示されるように)
		selectedView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 10.0f, 10.0f)] autorelease];
		selectedView.hidden = YES;
		[self addSubview:selectedView];
		backgroundView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 10.0f, 10.0f)] autorelease];
		[backgroundView setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
		//backgroundView.hidden = YES;
		[self addSubview:backgroundView];
		
		
		// Image表示の作成
		imgView = [ [[UIImageView alloc] initWithImage:image] autorelease];
        orgSize = image.size;
		imgView.contentMode = UIViewContentModeScaleAspectFit;
		[self addSubview:imgView];
		
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
    [imgView setFrame:rect];
	// [btnSelected setFrame:rect];
}

// サイズの設定 モーフィング用
-(void)setSizeMorphing:(CGRect)frame
{
    
    [self setFrame:frame];
    
    // 画像Viewと選択ボタンも設定する
    CGRect rect = CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height);
    /*
     self.IsSelected = NO;
     selectedView.hidden = YES;
     */
    [selectedView setFrame:rect];
    
    CGFloat selectWitdh =5.0f;

    rect = CGRectMake(selectWitdh/2.0f, selectWitdh/2.0f, frame.size.width - selectWitdh, frame.size.height - selectWitdh);
    [backgroundView setFrame:rect];
    [imgView setFrame:rect];
}

// Viewに設定された画像サイズを返す
- (CGSize)getSize
{
    return orgSize;
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
		[delegate OnOKDClickImageViewSelected :tagID image:imgView.image];
	}	
}

-(void) setImageNumber:(int)number
{
    if (self.IsSelected){
        NSLog(@"sub view %@",self.subviews);
        if([[self.subviews objectAtIndex:5] isKindOfClass:[UIImageView class]]){
            UIImageView *imageView = [self.subviews objectAtIndex:5];
            NSLog(@"imagetag %ld",(long)imageView.tag);
            if (imageView.tag > number){
                long tagImg = imageView.tag - 1;
                NSString *imageNumber=[NSString stringWithFormat:@"choice_%ld.png", tagImg];
                imageView.tag = tagImg;
                [imageView setImage:[UIImage imageNamed:imageNumber]];
            }
        }
    }
    // 状態を変更
    
}
// 選択状態の設定
-(void) setSelected:(BOOL)isSelected frameColor:(UIColor*)color numberSelected:(NSInteger)number
{
	// 状態を変更
	self.IsSelected = isSelected;

	// 画像Viewのサイズを変更する
	if (self.IsSelected)
	{
		if (color) 
		{
            if (number != 0) {
                NSString *imageNumber=[NSString stringWithFormat:@"choice_%ld.png", (long)number];
                NSLog(@"%ld",(long)number);
                
                UIImage *image = [UIImage imageNamed:imageNumber];
                UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                
                imageView.tag = number;
                imageView.alpha = 0.8;
                imageView.frame = CGRectMake(0,0, 150 , 150);
                imageView.center = CGPointMake(self.frame.size.width  / 2,
                                               self.frame.size.height / 2);
                // add the imageview to the superview
                [self insertSubview:imageView atIndex:5];
            }
            
            [selectedView setBackgroundColor:color];
		}
		selectedView.hidden = NO;
	}
	else 
	{
		selectedView.hidden = YES;
	}
}

#pragma mark touch_events

-(void) clickImageViewTouchedRaize
{
	if ( (self.delegate != nil) &&
		([self.delegate respondsToSelector:@selector(OnOKDClickImageViewTouched:)]) )
	{
		//NSUInteger tagID = self.tag;
		//[delegate OnOKDClickImageViewTouched :tagID];
		[delegate OnOKDClickImageViewTouched :self];
	}		
}

// Tapイベント
-(void)onTapImageView:(id)sender
{
	// 状態を反転
	self.IsSelected = ! self.IsSelected;

	// タッチイベント発生
	[self clickImageViewTouchedRaize];
}

// Double Tapイベント
-(void)onDoubleTapImageView:(id)sender
{
	if (self.delegate != nil) {
		NSUInteger tagID = self.tag;
		[delegate OnOKDClickImageViewSelected :tagID image:imgView.image];
	}
}

- (void)removeFromSuperview
{
	// NSLog(@"ClickImageView removeFromSuperview");
	
	
	
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
	
	[super dealloc];
}


@end
