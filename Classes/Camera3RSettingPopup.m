//
//  Camera3RSettingPopup.m
//  iPadCamera
//
//  Created by Long on 2018/02/14.
//

#import "Camera3RSettingPopup.h"

@interface Camera3RSettingPopup ()

@end

@implementation Camera3RSettingPopup

- (instancetype)init
{
    self = [super initWithNibName:@"3RSettingPopup" bundle:nil];
    if (self != nil)
    {
        // Further initialization if needed
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _btnConfirm.layer.cornerRadius = 20;
    _btnConfirm.clipsToBounds = true;
    _btnReset.layer.cornerRadius = 20;
    _btnReset.clipsToBounds = true;
    _btnCancel.layer.cornerRadius = 20;
    _btnCancel.clipsToBounds = true;
    
    _mjpegStreamSetting = [[MjpegStreamSetting alloc] init];
    [self fetchingData];
}

- (void)fetchingData {
    
    _brightnessSlider.minimumValue = 0;
    _brightnessSlider.maximumValue = 100;
    _brightnessSlider.value = 50;
    [_brightnessSlider addTarget:self action:@selector(BrightnessValueChange:) forControlEvents:UIControlEventValueChanged];
    _brightnessSlider.continuous = NO;
    
    _contrastSlider.minimumValue = 0;
    _contrastSlider.maximumValue = 100;
    _contrastSlider.value = 50;
    [_contrastSlider addTarget:self action:@selector(BrightnessValueChange:) forControlEvents:UIControlEventValueChanged];
    _contrastSlider.continuous = NO;
    
    _saturationSlider.minimumValue = 0;
    _saturationSlider.maximumValue = 100;
    _saturationSlider.value = 50;
    [_saturationSlider addTarget:self action:@selector(BrightnessValueChange:) forControlEvents:UIControlEventValueChanged];
    _saturationSlider.continuous = NO;
    
    _hueSlider.minimumValue = 0;
    _hueSlider.maximumValue = 100;
    _hueSlider.value = 50;
    [_hueSlider addTarget:self action:@selector(BrightnessValueChange:) forControlEvents:UIControlEventValueChanged];
    _hueSlider.continuous = NO;
    
    _gammaSlider.minimumValue = 0;
    _gammaSlider.maximumValue = 100;
    _gammaSlider.value = 50;
    [_gammaSlider addTarget:self action:@selector(BrightnessValueChange:) forControlEvents:UIControlEventValueChanged];
    _gammaSlider.continuous = NO;
    
    _sharpnessSlider.minimumValue = 0;
    _sharpnessSlider.maximumValue = 100;
    _sharpnessSlider.value = 50;
    [_sharpnessSlider addTarget:self action:@selector(BrightnessValueChange:) forControlEvents:UIControlEventValueChanged];
    _sharpnessSlider.continuous = NO;
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_brightnessSlider release];
    [_contrastSlider release];
    [_saturationSlider release];
    [_hueSlider release];
    [_gammaSlider release];
    [_sharpnessSlider release];
    [_contentView release];
    [_btnConfirm release];
    [_btnConfirm release];
    [_btnReset release];
    [_btnCancel release];
    [super dealloc];
}

-(void) BrightnessValueChange:(UISlider *)paramSender{
    
    if([paramSender isEqual:_brightnessSlider]){
        
        [_mjpegStreamSetting setProperty:@"Brightness" ID:_brightnessID Value:paramSender.value];
        
    }else if([paramSender isEqual:_contrastSlider]){
        
        [_mjpegStreamSetting setProperty:@"Contrast" ID:_contrastID Value:paramSender.value];
        
    }else if([paramSender isEqual:_saturationSlider]){
        
        [_mjpegStreamSetting setProperty:@"Saturation" ID:_saturationID Value:paramSender.value];
        
    }else if([paramSender isEqual:_hueSlider]){
        
        [_mjpegStreamSetting setProperty:@"Hue" ID:_hueID Value:paramSender.value];
        
    }else if([paramSender isEqual:_gammaSlider]){
        
        [_mjpegStreamSetting setProperty:@"Gamma" ID:_gammaID Value:paramSender.value];
        
    }else if([paramSender isEqual:_sharpnessSlider]){
        
        [_mjpegStreamSetting setProperty:@"Sharpness" ID:_sharpnessID Value:paramSender.value];
    }
}

- (IBAction)onConfirmPressed:(id)sender {
    
}

- (IBAction)onResetPressed:(id)sender {
    property_control_info_t property = [_mjpegStreamSetting getProperty:@"Brightness"];
    _brightnessID = property.pId;
    _brightnessSlider.minimumValue = property.pMin;
    _brightnessSlider.maximumValue = property.pMax;
    _brightnessSlider.value = property.pDefaultValue;
    
    property = [_mjpegStreamSetting getProperty:@"Contrast"];
    _contrastID = property.pId;
    _contrastSlider.minimumValue = property.pMin;
    _contrastSlider.maximumValue = property.pMax;
    _contrastSlider.value = property.pDefaultValue;
    
    property = [_mjpegStreamSetting getProperty:@"Saturation"];
    _saturationID = property.pId;
    _saturationSlider.minimumValue = property.pMin;
    _saturationSlider.maximumValue = property.pMax;
    _saturationSlider.value = property.pDefaultValue;
    
    property = [_mjpegStreamSetting getProperty:@"Hue"];
    _hueID = property.pId;
    _hueSlider.minimumValue = property.pMin;
    _hueSlider.maximumValue = property.pMax;
    _hueSlider.value = property.pDefaultValue;
    
    property = [_mjpegStreamSetting getProperty:@"Gamma"];
    _gammaID = property.pId;
    _gammaSlider.minimumValue = property.pMin;
    _gammaSlider.maximumValue = property.pMax;
    _gammaSlider.value = property.pDefaultValue;
    
    property = [_mjpegStreamSetting getProperty:@"Sharpness"];
    _sharpnessID = property.pId;
    _sharpnessSlider.minimumValue = property.pMin;
    _sharpnessSlider.maximumValue = property.pMax;
    _sharpnessSlider.value = property.pDefaultValue;
}

- (IBAction)onCancelPressed:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}
@end
