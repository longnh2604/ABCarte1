//
//  Camera3RSettingPopup.h
//  iPadCamera
//
//  Created by Long on 2018/02/14.
//

#import <UIKit/UIKit.h>
#import "MjpegStreamSetting.h"
#import "MjpegStreamView.h"

@interface Camera3RSettingPopup : UIViewController

@property (retain, nonatomic) IBOutlet UIView *contentView;
@property (retain, nonatomic) IBOutlet UISlider *brightnessSlider;
@property (retain, nonatomic) IBOutlet UISlider *contrastSlider;
@property (retain, nonatomic) IBOutlet UISlider *saturationSlider;
@property (retain, nonatomic) IBOutlet UISlider *hueSlider;
@property (retain, nonatomic) IBOutlet UISlider *gammaSlider;
@property (retain, nonatomic) IBOutlet UISlider *sharpnessSlider;

@property (retain, nonatomic) IBOutlet UIButton *btnConfirm;
@property (retain, nonatomic) IBOutlet UIButton *btnReset;
@property (retain, nonatomic) IBOutlet UIButton *btnCancel;

- (IBAction)onConfirmPressed:(id)sender;
- (IBAction)onResetPressed:(id)sender;
- (IBAction)onCancelPressed:(id)sender;

@property (retain,nonatomic) MjpegStreamView *mjpegStreamView;
@property (retain,nonatomic) MjpegStreamSetting *mjpegStreamSetting;

@property (readwrite) int brightnessID;
@property (readwrite) int contrastID;
@property (readwrite) int saturationID;
@property (readwrite) int hueID;
@property (readwrite) int gammaID;
@property (readwrite) int sharpnessID;

@end
