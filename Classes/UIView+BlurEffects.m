//
//  UIView+BlurEffects.m
//
//  Created by griffin_stewie on 2013/10/06.
//
//

#import "UIView+BlurEffects.h"
#import "UIImage+ImageEffects.h"

@implementation UIView (BlurEffects)

- (UIImage *)blurredSnapshot
{
    return [self blurredSnapshotWithBlurType:BlurEffectsTypeLight];
}

- (UIImage *)blurredSnapshotWithBlurType:(BlurEffectsType)type
{
    /// Original Code: iOS 7 blurring techniques — Damir Tursunović http://damir.me/posts/ios7-blurring-techniques
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, self.window.screen.scale);
    
    // There he is! The new API method
//    [self drawViewHierarchyInRect:self.frame afterScreenUpdates:NO];
    if ([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    } else {
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    // Get the snapshot
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();

    // Now apply the blur effect using Apple's UIImageEffect category
    UIImage *blurredSnapshotImage = nil;
    switch (type) {
        case BlurEffectsTypeLight:
            blurredSnapshotImage = [snapshotImage applyLightEffect];
            break;
        case BlurEffectsTypeExtraLight:
            blurredSnapshotImage = [snapshotImage applyExtraLightEffect];
            break;
        case BlurEffectsTypeDark:
            blurredSnapshotImage = [snapshotImage applyDarkEffect];
            break;
        default:
            break;
    }

    // Be nice and clean your mess up
    UIGraphicsEndImageContext();
    
    return blurredSnapshotImage;
}

@end
