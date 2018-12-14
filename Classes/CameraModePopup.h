//
//  CameraModePopup.h
//  iPadCamera
//
//  Created by TMS on 2018/01/5.
//
//

#import "PopUpViewContollerBase.h"
#import "AccountManager.h"

@protocol CameraModePopupDelegate;


@interface CameraModePopup : PopUpViewContollerBase
<
PopUpViewContollerBaseDelegate
>
{
}
@property (nonatomic, assign) id <CameraModePopupDelegate> cm_delegate;

- (void)setCameraMode:(NSInteger)cameraMode;

@end

// カメラモード関連デリゲート
@protocol CameraModePopupDelegate <NSObject>
@optional

- (void)onCameraModeSet:(id)sender;

@end
