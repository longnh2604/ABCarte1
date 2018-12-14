//
//  BroadcastMailSendPopup.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/05/15.
//
//

/*
 IMPORT
 */
#import <UIKit/UIKit.h>
#import "PopUpViewContollerBase.h"

/*
 
 */
@protocol BroadcastMailSendPopupDelegate <PopUpViewContollerBaseDelegate>
- (void) SendButtonCallBack:(NSMutableDictionary*)dic;
@end

/*
 INTERFACE
 */
@interface BroadcastMailSendPopup : PopUpViewContollerBase <UIPopoverControllerDelegate>

/**
 初期化する
 @param dic メールデータ
 @param tmplId テンプレートID
 @param popupId ポップアップID
 @param callback デリゲート
 @return インターフェースへのポインタ
 */
- (id) initWithMailData:(NSDictionary*)dic TemplateId:(NSString*)tmplId PopupId:(NSInteger)popupId Callback:(id)callback;

@end
