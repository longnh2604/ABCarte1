//
//  AppSettingPopupVC.h
//  iPadCamera
//
//  Created by Long on 2018/01/29.
//

#import <UIKit/UIKit.h>
#import "iPadCameraAppDelegate.h"
#import "camaraViewController.h"
#import "HistDetailViewController.h"
#import "userFmdbManager.h"
#import "AccountInfoForWebMail.h"

@interface AppSettingPopupVC : UIViewController<UIScrollViewDelegate,UITextFieldDelegate,AccountInfoForWebMailDelegate> {
    NSTimeInterval  _prevWaitInterval;
}

// Outlet
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *heightInforView;

@end


