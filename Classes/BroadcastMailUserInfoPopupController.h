//
//  BroadcastMailUserInfoPopupController.h
//  iPadCamera
//
//  Created by yoshida on 2014/07/01.
//
//

#import <UIKit/UIKit.h>
#import "PopUpViewContollerBase.h"
#import "BroadcastMailUserInfo.h"

/*
 
 */
@protocol BroadcastMailUserInfoPopupDelegate <PopUpViewContollerBaseDelegate>
-(BOOL) touchUserInfoSelectedButton:(BroadcastMailUserInfo*) mailUserInfo;
@end

@interface BroadcastMailUserInfoPopupController : PopUpViewContollerBase <UIPopoverControllerDelegate>
{
    IBOutlet UIView*            _viewUserInfo;      //
    IBOutlet UILabel*           _lblUserNum;		//
    IBOutlet UILabel*           _lblUserName;		//
    IBOutlet UILabel*           _lblUserBirthDay;	//
    IBOutlet UILabel*           _lblUserAddress;	//
    IBOutlet UILabel*           _lblUserBlockMail;	//
    IBOutlet UIImageView*       _imgUserImage;      //
    IBOutlet UIBarButtonItem*   _btnSelected;       //
    IBOutlet UIBarButtonItem*   _btnbtnCancel;      //
    
    BroadcastMailUserInfo*      _mailUserInfo;      //
    NSMutableDictionary*        _headPictureList;	// 代表写真リストのキャッシュ

    
    id<BroadcastMailUserInfoPopupDelegate> broadcastMailUserInfoPopupDelegate;

}

/**
 */
- (id)initWithUserInfo:(BroadcastMailUserInfo*)userInfo
               PopupId:(NSInteger)popupId
              CallBack:(id)callBack;

@end
