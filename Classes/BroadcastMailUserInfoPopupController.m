//
//  BroadcastMailUserInfoPopupController.m
//  iPadCamera
//
//  Created by yoshida on 2014/07/01.
//
//

#import "BroadcastMailUserInfoPopupController.h"
#import "userInfo.h"
#import "mstUser.h"
#import "userDbManager.h"
#import "OKDImageFileManager.h"

@interface BroadcastMailUserInfoPopupController ()

@end

@implementation BroadcastMailUserInfoPopupController

#pragma mark iOS_Framework
- (void)viewDidLoad
{
    [super viewDidLoad];
//    CGRect viewRect = [self view].frame.size;
    self.contentSizeForViewInPopover = [self view].frame.size;
    
    if( _mailUserInfo == nil )  return;
    userInfo* userInfo = _mailUserInfo.userInfo;
    
    //  マスターデータ取得
    userDbManager* usrDbMng = [[userDbManager alloc] init];
    mstUser *user = [usrDbMng getMstUserByID:[userInfo userID]];
    [usrDbMng release];
	   
    if( user.registNumber < 0 ){
        _lblUserNum.text = @"未設定";
    }
    else{
        _lblUserNum.text = [NSString stringWithFormat:@"%ld", (long)user.registNumber];
    }
    _lblUserName.text = [user getUserName];
    _lblUserBirthDay.text = [user getBirthDayByLocalTimeAD];
    _lblUserAddress.text = _mailUserInfo.mailAddress;
    if( _mailUserInfo.blockMail ){
        _lblUserBlockMail.text = @"受信しない";
    }
    else{
        _lblUserBlockMail.text = @"受信する";        
    }
    
    if( userInfo.pictureURL != nil && [userInfo.pictureURL length] > 0 ){
        OKDImageFileManager *imgFileMng = [[OKDImageFileManager alloc] initWithUserID:[userInfo userID]];
        UIImage *loadImg = [imgFileMng getTemplateRealSizeImage:userInfo.pictureURL];
        float h = loadImg.size.height / _imgUserImage.frame.size.height;
        float w = loadImg.size.width / h;
        float x = (_imgUserImage.frame.size.width - w) / 2;
        
        // リサイジングする
        UIGraphicsBeginImageContext(_imgUserImage.frame.size);
        [loadImg drawInRect:CGRectMake(x, 0, w, _imgUserImage.frame.size.height)];
        UIImage* drawImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    
        [imgFileMng release];
        if( drawImg != nil ){
            [_imgUserImage setImage:drawImg];
        }
    }
    
    if( _mailUserInfo.selected ){
        _btnSelected.title = @"選択解除";
    }
    else{
        _btnSelected.title = @"選択する";
    }
}

// 写真の表示
- (UIImage*) makeImagePictureWithUID:(NSString*) pictUrl userID:(NSInteger)userID
{
	if ( (!pictUrl) || ((pictUrl) && ([pictUrl length] <= 0) )){
        return nil;
    }
		
	// 代表写真リストの初期化確認
	if ( _headPictureList == nil ){
        _headPictureList = [NSMutableDictionary dictionary];
        [_headPictureList retain];
    }
	
	// 代表写真リストのキャッシュより画像を取得
	UIImage *cashImage = [_headPictureList objectForKey:pictUrl];
	return cashImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 dealloc
 */
- (void) dealloc
{
	// UIパーツのリリース
	[_lblUserNum release];
	[_lblUserName release];
	[_lblUserBirthDay release];
	[_lblUserAddress release];
	[_lblUserBlockMail release];
	[_imgUserImage release];
	[super dealloc];
}


#pragma mark instance_method
- (id)initWithUserInfo:(BroadcastMailUserInfo*)mailUserInfo
               PopupId:(NSInteger)popupId
              CallBack:(id)callBack
{
    _mailUserInfo = mailUserInfo;
    broadcastMailUserInfoPopupDelegate = callBack;

	self = [super initWithPopUpViewContoller:popupId
						   popOverController:nil
									callBack:callBack
									 nibName:@"BroadcastMailUserInfoPopupController"];
    
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark event_handler

/**
 キャンセルボタン
 */
- (IBAction) OnCancel:(id)sender
{
	if ( delegate != nil )
	{
		[delegate OnPopUpViewSet:-1 setObject:nil];
	}
    
	[self closeByPopoverContoller];
}

/**
 選択ボタン
 */
- (IBAction) OnSelected:(id)sender
{
    bool selected = [broadcastMailUserInfoPopupDelegate touchUserInfoSelectedButton:_mailUserInfo];
    if( selected ){
        _btnSelected.title = @"選択解除";
    }
    else{
        _btnSelected.title = @"選択する";
    }
}

@end
