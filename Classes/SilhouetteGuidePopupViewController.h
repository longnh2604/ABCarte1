#import <UIKit/UIKit.h>

@protocol SilhouetteGuidePopupDelegate <NSObject>
@optional
- (void)OnShowSilhouetteGuide:(id)sender;
- (void)OnHideSilhouetteGuide;
@end

@interface SilhouetteGuidePopupViewController : UIViewController
@property (nonatomic, assign) id <SilhouetteGuidePopupDelegate> delegate;
@end
