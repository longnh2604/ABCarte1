//
//  RangeSlider.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2014/01/09.
//
//

#import <UIKit/UIKit.h>
@protocol RangeSliderDelegate;

@interface RangeSlider : UIControl {
    float minimumValue;            // 表示下限
    float maximumValue;            // 表示上限
    float minimumLimitValue;       // 可動下限
    float maximumLimitValue;       // 可動上限
    float selectedValue1;          // つまみ1
    float selectedValue2;          // つまみ2
    BOOL _maxThumbOn;
    BOOL _minThumbOn;
    float _padding;
    UIImageView * _minThumb;
    UIImageView * _maxThumb;
    UIImageView * _track;
    UIImageView * _trackBackground;
    UIImageView * _trackCannotSlide;
}

@property (nonatomic) float minimumValue;
@property (nonatomic) float maximumValue;
@property (nonatomic) float minimumLimitValue;
@property (nonatomic) float maximumLimitValue;
@property (nonatomic) float selectedValue1;
@property (nonatomic) float selectedValue2;
@property (nonatomic, retain) id<RangeSliderDelegate> delegate;
- (float)selectedMinimumValue;
- (float)selectedMaximumValue;
@end

@protocol RangeSliderDelegate <NSObject>
- (void)rangeSliderValueChanged:(RangeSlider *)slider changedSliderNum:(NSInteger)changedSliderNum;
@end