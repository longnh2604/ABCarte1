//
//  CamSelectView.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/06/12.
//
//

#import "CamSelectView.h"

#define MOVEMENT_NUM    70
#define MOVEMENT_LABEL  40

#define KIND_BTN    0
#define KIND_LABEL  1

@implementation CamSelectView

@synthesize btnEnable;

/**
 * ボタン表示で初期化する場合
 */
- (id)initWithFrame:(CGRect)frame btnObj:(NSArray *)btnOjb initSel:(NSInteger)initSel
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    self = [super initWithFrame:frame];
    if (self) {
        self.scrollEnabled = NO;
        self.contentSize = CGSizeMake(self.contentSize.width, MOVEMENT_NUM*[btnOjb count]);
        
        float pos = 0;
        for (NSString *name in btnOjb) {
            UIImageView *img = [[UIImageView alloc]initWithFrame:CGRectMake(5, pos, 60, 60)];
            img.image = [UIImage imageNamed:name];
            [self addSubview:img];
            pos += MOVEMENT_NUM;
        }
        
        [self setContentOffset:CGPointMake(self.contentOffset.x, -70 - 25 + (initSel * MOVEMENT_NUM)) animated:NO];
        
        btnNum = [btnOjb count] - 1;
        btnSel = initSel;
        self.delegate = self;
        self.camselDelegate = nil;
        _isScrolling = NO;
        btnEnable = YES;
        slide = MOVEMENT_NUM;
        kind = KIND_BTN;
    }
    return self;
}

/**
 * ラベル表示で初期化する場合
 */
- (id)initWithFrame:(CGRect)frame labelObj:(NSArray *)labelOjb initSel:(NSInteger)initSel
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    self = [super initWithFrame:frame];
    if (self) {
        self.scrollEnabled = NO;
        self.contentSize = CGSizeMake(self.contentSize.width, MOVEMENT_LABEL * [labelOjb count]);
        labels = [[NSMutableArray alloc] init];
        
        float pos = 7;
        for (NSString *name in labelOjb) {
            UILabel *lbl = [[UILabel alloc]initWithFrame:CGRectMake(5, pos, 70, 40)];
            lbl.numberOfLines = 2;
            lbl.text = name;
            lbl.backgroundColor = [UIColor clearColor];
            lbl.textColor = [UIColor whiteColor];
            lbl.font = [UIFont boldSystemFontOfSize:14];
            [self addSubview:lbl];
            pos += MOVEMENT_LABEL;
            [labels addObject:lbl];
        }
        
        [self setContentOffset:CGPointMake(self.contentOffset.x, -70 - 15 + (initSel * MOVEMENT_LABEL)) animated:NO];
        
        btnNum = [labelOjb count] - 1;
        btnSel = initSel;
        self.delegate = self;
        self.camselDelegate = nil;
        _isScrolling = NO;
        btnEnable = YES;
        slide = MOVEMENT_LABEL;
        kind = KIND_LABEL;
    }
    return self;
}

#pragma mark touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchPoint = [[touches anyObject] locationInView:self];
}

//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    CGPoint offset = self.contentOffset;
//    CGPoint movePoint = [[touches anyObject] locationInView:self];
//    NSLog(@"%s[%.3f]", __func__, movePoint.y);
//
//    [self setContentOffset:CGPointMake(offset.x, offset.y + touchPoint.y - movePoint.y) animated:NO];
//    touchPoint = movePoint;
//}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_isScrolling==YES || btnEnable==NO) {
        return;
    }
    _isScrolling = YES;
    CGPoint endPoint = [[touches anyObject] locationInView:self];
    
    // タッチした方向を決める数値(正:上方向 負:下方向)
    CGFloat moveDir = touchPoint.y - endPoint.y;
    
    [self selectScroll:moveDir];
}

#pragma mark UIScrollViewDelegate

// アニメーションによるスクロールが終了したときに呼ばれる
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    _isScrolling = NO;
}

#pragma mark -
#pragma mark MoveCameraIcon

/**
 * カメラアイコンを移動させる
 */
- (void)selectScroll:(CGFloat)moveDir
{
    CGPoint offset = self.contentOffset;
#ifdef DEBUG
    NSLog(@"%s [%.1f : %.1f]", __func__, offset.x, offset.y);
#endif

    // 上方向に移動
    if (moveDir > 50 && btnSel < btnNum) {
        [self setContentOffset:CGPointMake(offset.x, offset.y + slide) animated:YES];
        btnSel++;
        // 選択カメラに変更が有った時に呼び出し
        [self.camselDelegate CamSelectKind:btnSel];
    // 下方向に移動
    } else if (moveDir < -50 && btnSel > 0) {
        [self setContentOffset:CGPointMake(offset.x, offset.y - slide) animated:YES];
        btnSel--;
        // 選択カメラに変更が有った時に呼び出し
        [self.camselDelegate CamSelectKind:btnSel];
    } else
        _isScrolling = NO;
    
    [self setLabelColor:btnSel];
}

/**
 * カメラアイコンの表示位置を設定する
 */
- (void)setPos:(NSInteger)pos
{
    if (pos >= 0 && pos <= btnNum) {
        [self setContentOffset:CGPointMake(self.contentOffset.x, -70 - 25 + (btnSel * slide)) animated:NO];
        [self setLabelColor:btnSel];
    }
}

/**
 * 選択されたラベルの色を変える
 */
- (void)setLabelColor:(NSInteger)selected
{
    if (kind==KIND_LABEL) {
        // アニメーション終了後にラベルの色を変えるため
        double delayInSeconds = 0.2;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            for (NSInteger i=0; i<[labels count]; i++) {
                if (i==selected) {
                    ((UILabel *)[labels objectAtIndex:i]).textColor = [UIColor orangeColor];
                }
                else {
                    ((UILabel *)[labels objectAtIndex:i]).textColor = [UIColor whiteColor];
                }
            }
        });
    }
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
    if (kind==KIND_LABEL) {
        for (UILabel *lbl in labels) {
            [lbl release];
        }
        [labels removeAllObjects];
    }
    [super dealloc];
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
