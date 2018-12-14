//
//  VideoSaveViewController.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/11/25.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MovieResource.h"
#import "def64bit_common.h"

@protocol VideoSaveViewControllerDelegate <NSObject>
- (void)finishVideoSave:(BOOL)isSaved;
@end

@interface VideoSaveViewController : UIViewController<UIAlertViewDelegate> {
    
    IBOutlet UIView *mainView;
    IBOutlet UILabel *lblVideoDuration;
    IBOutlet UILabel *lblMaxDuration;
    IBOutlet UILabel *lblDescription;
    IBOutlet UIButton *btnCut;
    IBOutlet UIButton *btnClear;
    IBOutlet UIScrollView *scrollView;
    IBOutlet UIButton *btnSave;
    IBOutlet UIButton *btnDontSave;
    IBOutlet UIActivityIndicatorView *indicator;
    BOOL isAllDisplay;
    AVAsset         *asset;
    UIImage         *overlayImage;
    HISTID_INT      histId;
    MovieResource   *movie;
    NSMutableArray  *buttons;
    NSInteger       startIndex;
    NSInteger       representativeIndex;
    NSTimeInterval  duration;
    CGFloat         frameDuration;
    CGFloat         maxDuration;    // 自動停止時間
    CGFloat         maxRecTime;     // 最大録画時間
    NSURL           *url;
    
    NSInteger       thumbWidth;
    NSInteger       thumbHeight;
    NSInteger       thumbCols;
    BOOL            _isSuccess;
}
- (void)show;
@property(retain) AVAssetImageGenerator *imageGenerator;
@property(nonatomic, assign) id<VideoSaveViewControllerDelegate> saveDelegate;
@property(retain) UIImage *overlayImage;
- (IBAction)OnCut;
- (IBAction)OnClear;
- (IBAction)OnSave;
- (IBAction)OnDontSave;
- (void)setVideoUrl:(NSURL *)url movie:(MovieResource *)movie histId:(HISTID_INT)histId;
@end
