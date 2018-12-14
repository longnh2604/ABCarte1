//
//  SRangeSlider.m
//  SRangeSliderTest
//
//  Created by 捧 隆二 on 2013/12/30.
//  Copyright (c) 2013年 捧 隆二. All rights reserved.
//
#import "RangeSlider.h"

@interface RangeSlider (PrivateMethods)
- (float)xForValue:(float)value;
- (float)valueForX:(float)x;
- (void)updateTrackHighlight;
- (void)reloadThumb;
@end

@implementation RangeSlider
@synthesize minimumValue, maximumValue, minimumLimitValue, maximumLimitValue, selectedValue1, selectedValue2,delegate;
- (id)init {
    self = [super init];
    if (self) {
        
        // Initialization code
        _maxThumbOn = false;
        _minThumbOn = false;
        _padding = 11;  //20 is a good value // 0 にすると端っこでタッチが感知されにくくなる
        
        minimumValue = 0;
        selectedValue1 = 0;
        maximumValue = 0;
        selectedValue2 = 0;
        minimumLimitValue = INT32_MIN;
        maximumLimitValue = INT32_MAX;
        _trackBackground = [[UIImageView alloc] init];
        _track = [[UIImageView alloc] init];
        _trackCannotSlide = [[UIImageView alloc] init];
        _minThumb = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"handle.png"]
                                      highlightedImage:[UIImage imageNamed:@"handle-hover.png"]];
        _maxThumb = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"handle.png"]
                                      highlightedImage:[UIImage imageNamed:@"handle-hover.png"]];
        delegate = nil;
    }
    return self;
}
//- (id)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        [self setFrame:frame];
//    }
//    return self;
//}

- (void)setFrame:(CGRect)frame {
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
    [super setFrame:frame];
    _trackCannotSlide.image = nil;
    _trackCannotSlide.image = [RangeSlider trackBackgroundImage:CGSizeMake(self.frame.size.width - 2 *(_padding - 9), 8)
                                                       topColor:[UIColor colorWithRed:0.9f green:0.3f blue:0.3f alpha:1.0f]
                                                      downColor:[UIColor colorWithRed:0.95f green:0.9f blue:0.9f alpha:1.0f]];
    _trackCannotSlide.frame = CGRectMake(_padding - 9, (self.frame.size.height - 8) * 0.5f,
                                        self.frame.size.width - 2 *(_padding - 9), 9);
    [self addSubview:_trackCannotSlide];
    _trackBackground.image = nil;
    _trackBackground.image = [RangeSlider trackBackgroundImage:CGSizeMake(self.frame.size.width - 2 *(_padding - 9), 8)
                                                      topColor:[UIColor colorWithRed:0.51f green:0.51f blue:0.51f alpha:1.0f]
                                                     downColor:[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f]];
    _trackBackground.frame = CGRectMake(_padding - 9, (self.frame.size.height - 8) * 0.5f,
                                        self.frame.size.width - 2 *(_padding - 9), 9);
    [self addSubview:_trackBackground];
    _track.image = nil;
    _track.image =[RangeSlider trackBackgroundImage:CGSizeMake(self.frame.size.width - 2 *(_padding - 9), 8)
                                           topColor:[UIColor colorWithRed:0.05f green:0.23f blue:0.54f alpha:1.0f]
                                          downColor:[UIColor colorWithRed:0.45f green:0.65f blue:0.95f alpha:1.0f]];
    _track.frame = _trackBackground.frame;
    [self addSubview:_track];
    
    _minThumb.frame = CGRectMake(0,0, self.frame.size.height,self.frame.size.height);
    // Just place the image in the middle, don't scale
    _minThumb.contentMode = UIViewContentModeCenter;
    _minThumb.center = CGPointMake([self xForValue:selectedValue1],
                                   (self.frame.size.height / 2));
#ifdef DEBUG
    NSLog(@"_minThumb frame:%@",NSStringFromCGRect(_minThumb.frame));
#endif
    [self addSubview:_minThumb];
    _maxThumb.frame = CGRectMake(0,0, self.frame.size.height,self.frame.size.height);
    // Just place the image in the middle, don't scale
    _maxThumb.contentMode = UIViewContentModeCenter;
    _maxThumb.center = CGPointMake([self xForValue:selectedValue2],
                                   (self.frame.size.height / 2));
    [self addSubview:_maxThumb];
    [self updateTrackHighlight];
}

- (float)xForValue:(float)value
{
    float x,a,b,p;
    //a:スライダーの全体サイズ
    a = (self.frame.size.width - (_padding*2));
    //b:スライダー上での割合
    b = (value - minimumValue) / (maximumValue - minimumValue);
    if(isnan(b))b = 0;
    if(isinf(b))b = 0;
    p = _padding;
    x = a * b + p;
    return x;
    //    return (self.frame.size.width-(_padding*2))*((value - minimumValue) / (maximumValue - minimumValue))+_padding;
}
- (float)valueForX:(float)x{
    return minimumValue + (x-_padding) / (self.frame.size.width-(_padding*2)) * (maximumValue - minimumValue);
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    NSLog(@"begin touch");
//    CGPoint touchPoint = [touch locationInView:self];
//    if(CGRectContainsPoint(_minThumb.frame, touchPoint)){
//        _minThumbOn = true;
//    }else if(CGRectContainsPoint(_maxThumb.frame, touchPoint)){
//        _maxThumbOn = true;
    //    }
    CGFloat threshold = 40;
    CGFloat touchX = [touch locationInView:self].x;
    CGFloat minX = _minThumb.center.x;
    CGFloat maxX = _maxThumb.center.x;
    if ((abs(touchX - minX) < abs(touchX - maxX)) && (abs(touchX - minX) < threshold)) {
        // 小つまみのほうが近く、閾値よりも近い
        _minThumbOn = true;
    } else if(abs(touchX - maxX) < threshold){
        // 大つまみのほうが近い
        _maxThumbOn = true;
    }
    return YES;
}

-(void)updateTrackHighlight{
    float tmp_x,tmp_y,tmp_width,tmp_height;
    tmp_x = _minThumb.center.x;
    tmp_y = _track.center.y - (_track.frame.size.height/2);
    tmp_width = _maxThumb.center.x - _minThumb.center.x;
    tmp_height = _track.frame.size.height;
    _track.frame = CGRectMake(tmp_x, tmp_y, tmp_width, tmp_height);
}

-(void)updateTrackBackground{
    float tmp_x,tmp_y,tmp_width,tmp_height;
    tmp_x = [self xForValue:self.minimumLimitValue] - 9;
    tmp_y = _trackBackground.center.y - (_trackBackground.frame.size.height/2);
    tmp_width = [self xForValue:self.maximumLimitValue] - [self xForValue:self.minimumLimitValue]+ 2 *  9;
    tmp_height = _trackBackground.frame.size.height;
    _trackBackground.frame = CGRectMake(tmp_x, tmp_y, tmp_width, tmp_height);
}
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    _minThumbOn = false;
    _maxThumbOn = false;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event{
    if(!_minThumbOn && !_maxThumbOn){
        return YES;
    }
    CGPoint touchPoint = [touch locationInView:self];
    NSInteger changedSliderNum = 1;
    if(_minThumbOn){
        changedSliderNum = 1;
        _minThumb.center = CGPointMake(MIN([self xForValue:maximumLimitValue],MAX([self xForValue:minimumLimitValue],touchPoint.x)), _minThumb.center.y);
        //_minThumb.center = CGPointMake(MIN([self xForValue:maximumValue],MAX([self xForValue:minimumValue],touchPoint.x)), _minThumb.center.y);
    }
    if(_maxThumbOn){
        changedSliderNum = 2;
        //_maxThumb.center = CGPointMake(MIN([self xForValue:maximumValue],MAX([self xForValue:minimumValue],touchPoint.x)), _maxThumb.center.y);
        _maxThumb.center = CGPointMake(MIN([self xForValue:maximumLimitValue],MAX([self xForValue:minimumLimitValue],touchPoint.x)), _maxThumb.center.y);
    }
    [self setNeedsDisplay];
    
    // For min
    selectedValue1 = [self valueForX:_minThumb.center.x];
    NSLog(@"Lower value is now %f", selectedValue1);
    // For max
    selectedValue2 = [self valueForX:_maxThumb.center.x];
    NSLog(@"Upper value is now %f", selectedValue2);
    // Below the if statements
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    // Inside continueTrackingWithThumb, above [self setNeedsDisplay];
    [self updateTrackHighlight];
    if (self.delegate && [self.delegate respondsToSelector:@selector(rangeSliderValueChanged:changedSliderNum:)]){
        [self.delegate rangeSliderValueChanged:self changedSliderNum:changedSliderNum];
    }
    return YES;
}

-(void)setSelectedMinimumValue:(float)_selectedMinimumValue{
    selectedValue1 = _selectedMinimumValue;
    [self reloadThumb];
}

-(void)setSelectedMaximumValue:(float)_selectedMaximumValue{
    selectedValue2 = _selectedMaximumValue;
    [self reloadThumb];
}
-(float)selectedMinimumValue {
    return MIN(selectedValue1, selectedValue2);
}
-(float)selectedMaximumValue {
    return MAX(selectedValue1, selectedValue2);
}
// つまみ
-(void)setSelectedValue1:(float)_selectedValue1 {
    selectedValue1 = _selectedValue1;
    [self reloadThumb];
}
-(void)setSelectedValue2:(float)_selectedValue2 {
    selectedValue2 = _selectedValue2;
    [self reloadThumb];
}
-(void)reloadThumb{
    _minThumb.center = CGPointMake([self xForValue:selectedValue1],
                                   (self.frame.size.height / 2));
#ifdef DEBUG
    NSLog(@"_minThumb frame:%@",NSStringFromCGRect(_minThumb.frame));
#endif
    _maxThumb.center = CGPointMake([self xForValue:selectedValue2],
                                   (self.frame.size.height / 2));
    [self updateTrackHighlight];
}

- (void)setMinimumValue:(float)_minimumValue {
    minimumValue = _minimumValue;
    if (minimumLimitValue <= minimumValue) {
        minimumLimitValue = minimumValue;
    }
    [self reloadThumb];
}

- (void)setMaximumValue:(float)_maximumValue {
    maximumValue = _maximumValue;
    if (maximumLimitValue >= maximumValue) {
        maximumLimitValue = maximumValue;
    }
    [self reloadThumb];
}
- (void)setMinimumLimitValue:(float)_minimumLimitValue {
    minimumLimitValue = _minimumLimitValue;
    selectedValue1 = MAX(selectedValue1, minimumLimitValue);
    selectedValue2 = MAX(selectedValue2, minimumLimitValue);
    [self reloadThumb];
    [self updateTrackBackground];
}
- (void)setMaximumLimitValue:(float)_maximumLimitValue {
    maximumLimitValue = _maximumLimitValue;
    selectedValue1 = MIN(selectedValue1, maximumLimitValue);
    selectedValue2 = MIN(selectedValue2, maximumLimitValue);
    [self reloadThumb];
    [self updateTrackBackground];
}
+ (UIImage *)trackBackgroundImage:(CGSize)size topColor:(UIColor *)topColor downColor:(UIColor *)downColor {
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(size);
    // 現在のコンテキストのビットマップをUIImageとして取得
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat r =MIN(rect.size.height, rect.size.width) * 0.5f;
    CGMutablePathRef circle=CGPathCreateMutable();
    CGPathAddArc(circle, NULL, rect.size.width - r, CGRectGetMidY(rect), r, -1 * M_PI_2, M_PI_2, NO);
    CGPathAddArc(circle, NULL, r, CGRectGetMidY(rect), r, M_PI_2, 3 * M_PI_2, NO);
    CGColorRef color1 = topColor.CGColor;
    CGColorRef color2 = downColor.CGColor;
    CGGradientRef gradient;
    CGFloat locations[2] = { 0.0, 1.0 };
    NSArray *colors = [NSArray arrayWithObjects:(__bridge id)color1, (__bridge id)color2, nil];
    
    gradient = CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)colors, locations);
    
    CGFloat startX = CGRectGetMidX(rect);
    CGFloat endX = startX;
    CGFloat startY = CGRectGetMinY(rect);
    CGFloat endY = CGRectGetMaxY(rect);
    CGPoint topCenter = CGPointMake(startX, startY);
    CGPoint midCenter = CGPointMake(endX, endY);
    //fill the circle with gradient
    CGContextAddPath(context, circle);
    CGContextSaveGState(context);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, topCenter, midCenter, 0);
    CGContextRestoreGState(context);
    CGGradientRelease(gradient);
    CFRelease(circle);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    // コンテキストを閉じる
    UIGraphicsEndImageContext();
    return image;
}
@end