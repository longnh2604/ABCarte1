//
//  StampSelectView.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/07/06.
//
//

#import <QuartzCore/CALayer.h>
#import "StampSelectView.h"
#import "PicturePaintPalletView.h"
#import "PicturePaintViewController.h"

@implementation StampSelectView
// 初期化
- (id)initWithFrame:(CGRect)frame{
	// 縦画面で原点位置で仮作成：setPositionWithRotateメソッドで確定
	//self = [super initWithFrame:CGRectMake
    //        (0.0f, 0.0f, PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
    self = [super initWithFrame:frame];
    if (self) {
		// 角を丸める
		CALayer *layer = [self layer];
		[layer setMasksToBounds:YES];
		[layer setCornerRadius:12.0f];
        self.backgroundColor = [UIColor whiteColor];
		
        self.hidden = YES;
		self.alpha = 0.85f;
        //スタンプを配置
        [self setStamps];
        //
        stampAtBegan = nil;
        self.stampDelegate = nil;
    }
    return self;
}
//回転時の位置を決める。
- (void) setPositionWithRotate:(CGPoint)origin isPortrate:(BOOL)isPortrate{
    if (isPortrate) {
        //スタンプの選択画面をパレットの上に表示 //DELC SASAGE
        [self setFrame:CGRectMake(origin.x, origin.y - (PORTRAIT_VIEW_HEIGHT + 5), PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
    } else{
        //スタンプ選択が画面を
        [self setFrame:CGRectMake(origin.x, origin.y - (PORTRAIT_VIEW_HEIGHT + 5), PORTRAIT_VIEW_WIDTH, PORTRAIT_VIEW_HEIGHT)];
    }
}
- (void)removeAndSetStamps{
    NSMutableArray *oss = [NSMutableArray array];
    for (UIView *v in self.subviews) {
        [oss addObject:v];
    }
    for (UIView *v in oss) {
        [v removeFromSuperview];
    }
    
    [self setContentSize:CGSizeMake(0, 0)];
    [self setStamps];
}
- (void)setStamps{
    int w = 5, h = 5;
    CGFloat buttonHeight;
    CGFloat buttonWidth;
    stamps = [[NSMutableArray array] retain];
    NSArray *stampStrs = [self getStamps];
    for (NSString *stampStr in stampStrs) {
        UIImage *stampImage = [UIImage imageWithContentsOfFile:stampStr];
        
        OriginailStamp *stampImageView = [[OriginailStamp alloc] initWithImage:stampImage];
        stampImageView.userInteractionEnabled = YES;

        // スタンプサイズが選択ビューより小さくなるときの位置補正
        if((stampImage.size.height/4) < (PORTRAIT_VIEW_HEIGHT - 10)) {
            buttonHeight = stampImage.size.height/4;
            buttonWidth  = stampImage.size.width/4;
            h = (PORTRAIT_VIEW_HEIGHT - (stampImage.size.height / 4)) / 2;
        } else {
            buttonHeight = PORTRAIT_VIEW_HEIGHT - 10;
            buttonWidth = (stampImage.size.height <= 0) ? 0 : stampImage.size.width / stampImage.size.height  * buttonHeight;
            h = 5;
        }
        stampImageView.frame = CGRectMake(w, h, buttonWidth, buttonHeight);
        
        [self addSubview:stampImageView];
        [stamps addObject:stampImageView];
        w = w + buttonWidth + 10;
        [self setContentSize:CGSizeMake(w, buttonHeight)];
        [stampImageView release];
    }
}
// このユーザのStamp一覧の取得 //DELC SASAGE
- (NSArray*)getStamps
{
    NSMutableArray *_stamps = [NSMutableArray array];
    //Stampディレクトリの下のdefault, group, usrディレクトリからスタンプを得る.
    NSArray *stampDirectories = @[@"default",@"group",@"user"];
    for (NSString *directory in stampDirectories) {
        NSArray *dFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:
                           [NSString stringWithFormat:@"%@/Documents/stamp/%@", NSHomeDirectory(), directory] error:NULL];
        for (NSString* aFile in dFiles)
        {
            if ([[aFile pathExtension] isEqualToString:@"jpg"] ||
                [[aFile pathExtension] isEqualToString:@"png"] ||
                [[aFile pathExtension] isEqualToString:@"gif"]) {
                [_stamps addObject:[NSString stringWithFormat:@"%@/Documents/stamp/%@/%@", NSHomeDirectory(), directory, aFile]];
            }
        }
    }
    return _stamps;
}

- (void)setStampsUnselected{
    for (UIView *os in self.subviews) {
        if ([os isKindOfClass:[OriginailStamp class]]) {
            os.backgroundColor = [UIColor clearColor];
        }
    }
}
- (void)selectStamp:(OriginailStamp *)originalStamp{
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
    for (OriginailStamp *os in stamps) {
        os.backgroundColor = [UIColor clearColor];
    }
    originalStamp.backgroundColor = [UIColor blueColor];
    PicturePaintViewController *ppVC = [self viewController];
    if (ppVC == nil) {
        Stamp *stamp = [[Stamp alloc] initWithImage:originalStamp.image];
        [self.stampDelegate setSelectedStamp:stamp];
    } else {
        [ppVC setStampFromImage:originalStamp.image];
    }
}
- (PicturePaintViewController*)viewController
{
    for (UIView* next = [self superview]; next; next = next.superview)
    {
        UIResponder* nextResponder = [next nextResponder];
        
        if ([nextResponder isKindOfClass:[PicturePaintViewController class]])
        {
            return (PicturePaintViewController*)nextResponder;
        }
    }
    
    return nil;
}
#pragma mark touch events
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
#ifdef DEBUG
    NSLog(@"touch stamp select");
#endif
    CGPoint point = [[touches anyObject] locationInView:self];
    for (OriginailStamp *os in stamps) {
        if (CGRectContainsPoint(os.frame, point)) {
            stampAtBegan = os;
        }
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
#ifdef DEBUG
    NSLog(@"touch end stamp select");
#endif
    CGPoint point = [[touches anyObject] locationInView:self];
    if (stampAtBegan != nil && CGRectContainsPoint(stampAtBegan.frame, point)) {
        [self selectStamp:stampAtBegan];
    } else{
        stampAtBegan = nil;
    }
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    stampAtBegan = nil;
}

- (void)dealloc
{
    [stamps removeAllObjects];
    [super dealloc];
}
@end
