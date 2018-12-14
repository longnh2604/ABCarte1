//
//  CamSelectDotView.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/06/26.
//
//

#import "CamSelectDotView.h"

#define MOVEMENT_LABEL  40

@implementation CamSelectDotView

@synthesize camselDelegate;

/**
 * 選択位置を示すポイント画像と、選択ボタン数とともに初期化を行う
 */
- (id)initWithFrame:(CGRect)frame btnName:(NSString *)btnName btnNum:(NSInteger)btnNum
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentSize = CGSizeMake(self.contentSize.width, self.frame.size.height * 2.0);

        UIImageView *img = [[UIImageView alloc]initWithFrame:CGRectMake(4, self.contentSize.height/2, 10, 10)];
        img.image = [UIImage imageNamed:btnName];
        [self addSubview:img];
        
        selBorder = [[UIView alloc]initWithFrame:CGRectMake(15, self.contentSize.height/4 + (MOVEMENT_LABEL * 2) + 15, 70, 40)];
        [selBorder.layer setBorderColor:[[UIColor orangeColor] CGColor]];
        [selBorder.layer setBorderWidth:1.0f];
        [selBorder setAlpha:0.0f];
        [self addSubview:selBorder];
        [selBorder release];
        
        self.delegate = self;
        self.camselDelegate  = nil;
        
        defaultPoint = CGPointMake(0, self.contentSize.height/4 + (MOVEMENT_LABEL * 2) + 8);
        [self setContentOffset:defaultPoint animated:NO];
        
        self.scrollEnabled = YES;
        self.showsVerticalScrollIndicator = NO;
        
        _btnNum = btnNum;
    }
    return self;
}

// 指が離れた場合に呼ばれる
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
#ifdef DEBUG
    NSLog(@"%s [%d]", __func__, decelerate);
#endif
    if (!decelerate) {
        // 惰性スクロールなしの場合
        [self selectScroll:scrollView withCall:YES];
    }
}

// 惰性スクロールが有る場合
 - (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    [self selectScroll:scrollView withCall:YES];
}

// touchesEndedの為にtouchesBeganをオーバライドしておくことが必要
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [selBorder setAlpha:1.0f];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [selBorder setAlpha:1.0f];
}

/**
 * スクロール後に指を離してから、タップしたりするとそこでスクロールが終了してしまう。
 * タップ後に指定の位置にアニメーションさせるために必要
 */
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    [super touchesEnded:touches withEvent:event];
    // ボタン位置を変化させるが、scrollViewWillBeginDeceleratingからselectScrollが既に呼ばれているため
    // delegate呼び出しは実施しない
    [self selectScroll:self withCall:NO];
}

/**
 * カメラ選択ボタンを移動させる
 */
- (void)selectScroll:(UIScrollView *)scrollView withCall:(BOOL)withCall
{
    CGPoint endPoint = scrollView.contentOffset;
    
    NSInteger pos = roundf((defaultPoint.y - endPoint.y) / MOVEMENT_LABEL);
    if (pos < 0) {
        pos = 0;
    } else if (pos > (_btnNum - 1)) {
        pos = _btnNum - 1;
    }
#ifdef DEBUG
    NSLog(@"drag out[%ld][%.3f:%.3f]", (long)pos, scrollView.contentOffset.x, scrollView.contentOffset.y);
#endif
    self.userInteractionEnabled = NO;
    
    [scrollView setContentOffset:CGPointMake(defaultPoint.x, defaultPoint.y - (pos * MOVEMENT_LABEL)) animated:YES];

    [UIView animateWithDuration:1.5f
                     animations:^{
                         [selBorder setAlpha:0.0f];
                     }
                     completion:^(BOOL finished) {
                         self.userInteractionEnabled = YES;
                     }
     ];
    
    if (withCall) {
        if ([self.camselDelegate respondsToSelector:@selector(CamSelectKind:)]) {
            [self.camselDelegate CamSelectKind:pos];
        }
    }
}

/**
 * 選択位置の設定
 */
- (void)setPos:(NSInteger)pos
{
    NSInteger _pos;
    if (pos < 0) {
        _pos = 0;
    } else if (pos > _btnNum - 1) {
        _pos = _btnNum - 1;
    }
    [self setContentOffset:CGPointMake(defaultPoint.x, defaultPoint.y - (pos * MOVEMENT_LABEL)) animated:NO];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
