//
//  PhotoCommentPopup.h
//  iPadCamera
//
//  Created by 聡史 伊藤 on 12/06/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "PopUpViewContollerBase.h"
#import "def64bit_common.h"

@interface PhotoCommentPopup : PopUpViewContollerBase{
    IBOutlet    UILabel     *lblTitle;
    IBOutlet    UIImageView *selectImage;
    IBOutlet    UITextView  *textMemo;
    IBOutlet    UITextField *textTitle;
    IBOutlet    UIScrollView *scrView;
    IBOutlet    UIView      *baseView;
    NSString    *pictureURL;
    USERID_INT   selectUserID;
    HISTID_INT   selectHistID;
    IBOutlet UIButton           *btnOk;     // OKボタン
    IBOutlet UIButton           *btnCancel; // キャンセルボタン
}
@property(nonatomic,retain) NSString *pictureURL;
@property(nonatomic)        USERID_INT selectUserID;
@property(nonatomic)        HISTID_INT selectHistID;

// タイトルTextFieldのEnterキーイベント
- (IBAction)onTextTitleDidEnd:(id)sender;

- (id) initPhotoSettingWithPictureURL:(NSString *)selectPictureURL    
                         selectUserID:(USERID_INT)userID
                         selectHistID:(HISTID_INT)histID
                              popUpID:(NSUInteger)popUpID 
                             callBack:(id)callBack;
@end
