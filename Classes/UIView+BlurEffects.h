//
//  UIView+BlurEffects.h
//
//  Created by griffin_stewie on 2013/10/06.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BlurEffectsType) {
    BlurEffectsTypeLight,
    BlurEffectsTypeExtraLight,
    BlurEffectsTypeDark,
};

@interface UIView (BlurEffects)
- (UIImage *)blurredSnapshot;
- (UIImage *)blurredSnapshotWithBlurType:(BlurEffectsType)type;
@end
