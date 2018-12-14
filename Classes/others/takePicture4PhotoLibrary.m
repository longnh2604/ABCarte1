//
//  takePicture4PhotoLibrary.m
//  iPadCamera
//
//  Created by 強 片山 on 12/11/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "takePicture4PhotoLibrary.h"

#import "camaraViewController.h"

#ifdef USE_ACCOUNT_MANAGER
#import "AccountManager.h"
#define TRIAL_VERSION
#endif

#import "userDbManager.h"
#import "OKDImageFileManager.h"

#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"

#import "Common.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define TAKE_PICTURE_ALERT_SAVE_CHECK   0x01
#define TAKE_PICTURE_ALERT_GO_HOME_PAGE 0x10

///
/// 写真アルバムからの取り込みクラス
///
@implementation takePicture4PhotoLibrary

@synthesize userID;
@synthesize histID;

#pragma mark - private_methods

// ライブラリから取り込み回数取得し、超過していないかを確認する
- (BOOL) isImportPictureEnable
{
#ifdef USE_ACCOUNT_MANAGER
	// アカウントにログイン済みかを確認
	if([AccountManager isLogined])
	{	return (YES); }
#endif
	
	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	
	NSInteger nums;
	
	// 既にインポートした枚数を取得
	if( ! [defaluts objectForKey:IMPORT_PICT_ENABLE_NUMS_KEY] )
	{	nums = 0; }
	else 
	{
		nums = [defaluts integerForKey:IMPORT_PICT_ENABLE_NUMS_KEY];
	}
	
	// ここでインポートしたことにして枚数を加算して保存する
	nums++;
	[defaluts setInteger:nums forKey:IMPORT_PICT_ENABLE_NUMS_KEY];
	
	// インポート枚数を比較
	return (nums <= TRIAL_VER_IMPORT_PICTURE_NUM);
}

// 保存確認のダイアログ表示
- (void) _showSaveCheckAlert
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"写真アルバムの取り込み"
                                               message:@"この画像を取り込みますか？" 
                                              delegate:self
                                     cancelButtonTitle:@"はい"
                                     otherButtonTitles:@"いいえ" ,nil];
    alert.tag = TAKE_PICTURE_ALERT_SAVE_CHECK;
    
    [alert show];
    
    [alert release];
}


// 確認ダイアログを表示してCaLuLuホームページを開く
- (void)openCaLuLuHpWithMsg
{
	UIAlertView *alert = [[UIAlertView alloc]
                             initWithTitle:@"ご案内"
                             message:@"お試し版では\nこれ以上の取り込みができません。\n製品版のご案内のため\nABCarteホームページを開きます。"
                             delegate:self
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:@"キャンセル", nil
                             ];
    
    alert.tag = TAKE_PICTURE_ALERT_GO_HOME_PAGE;
    
    [alert show];
    
    [alert release];

}

// Imageの保存
- (bool)saveImageFile:(UIImage*)cameraImage
{
	UIImage *image = cameraImage;
    
	// Imageファイル管理を選択ユーザIDで作成する
	OKDImageFileManager *imgFileMng 
        = [[OKDImageFileManager alloc] initWithUserID:self.userID];
	
	// Imageの保存：実サイズ版と縮小版の保存
	//		fileName：パスなしの実サイズ版のファイル名
	NSString *fileName = [imgFileMng saveImage:image];
	
	if (! fileName)
	{
        // 保存に失敗
		[ imgFileMng release];
		return (NO);
	}
#ifdef DEBUG
	NSLog(@"save photo album's file: => %@", fileName);
#endif
	// データベース内の写真urlはDocumentフォルダ以下で設定 -> TODO:変更必要
	NSString *docPictUrl = 
        [NSString stringWithFormat:@"Documents/User%08d/%@",self.userID, fileName];
	
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	// 保存したファイル名（パスなしの実サイズ版）でデータベースの履歴用のユーザ写真を追加
	bool stat = [usrDbMng insertHistUserPicture:self.histID 
									 pictureURL:docPictUrl];	// docPictUrl -> fileName
	
	// 保存したファイル名（パスなしの実サイズ版でデータベースの履歴テーブルの代表画像の更新:既設の場合は何もしない
//    stat |= [usrDbMng updateHistHeadPicture:self.histID pictureURL:docPictUrl    // docPictUrl -> fileName
//                            isEnforceUpdate:NO];
    
    [usrDbMng updateUserPictureByNewUrl:fileName newUrl:nil];
	
	[usrDbMng release];
	
	[ imgFileMng release];
	
	return (stat);
}

#pragma mark - life_cycle

// 選択画像のプレビューを指定
#ifndef CALULU_IPHONE
- (id) initWithPreView:(UIImageView*)preview popupButton:(UIButton*)btn
#else
- (id) initWithPreView:(UIImageView*)preview popupButton:(UIButton*)btn parentViewController:(UIViewController*)parentVC
#endif
{
    if ((self = [super init] ) )
    {
        _vwPreview = preview;
        [_vwPreview retain];
        _vwPreview.hidden = YES;        // プレビューは初期状態で非表示
        
        _btnPopup = btn;
        [_btnPopup retain];
        
#ifdef CALULU_IPHONE
        _parentVC = parentVC;
        [_parentVC retain];
#endif
    }
    
    return (self);
}

- (void) dealloc
{
    Block_release(_hEvent); 
    
    [_vwPreview release];
    [_btnPopup release];
    
#ifdef CALULU_IPHONE
    [_parentVC release];
#endif
    
    [super dealloc];
}

#pragma mark - public_methods


// 写真ライブラリより写真を取り込む
- (void) takePicureWithCompliteHandler:(onCompleteTakePicture)handler
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"写真アルバムから取り込み"
                                                            message:@"写真アルバムが開けませんでした。\n(誠に恐れ入りますが\n再度操作をお願いいたします"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];	 
        return;
    };
    
    // 完了ハンドラの保存
    if (_hEvent)
    {   Block_release(_hEvent); }
    _hEvent = Block_copy(handler);
    
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    // iOS5以下の場合動画を無効とする or 動画契約がない場合
    if (iOSVersion<6.0f || ![AccountManager isMovie]) {
        imgPicker.mediaTypes = @[(NSString *)kUTTypeImage];
    } else {
        imgPicker.mediaTypes = @[(NSString *)kUTTypeMovie,(NSString *)kUTTypeImage]; // DELC SASAGE
    }
    imgPicker.delegate = self;
    
#ifndef CALULU_IPHONE
    if (imagePopController) {
        [imagePopController release];
    }
    
    imagePopController = [[UIPopoverController alloc] initWithContentViewController:imgPicker];
    imagePopController.delegate = self;
    [imagePopController presentPopoverFromRect:_btnPopup.bounds
                                        inView:_btnPopup
                      permittedArrowDirections:UIPopoverArrowDirectionAny
                                      animated:YES];
    [imgPicker release];
#else
    [_parentVC presentModalViewController:imgPicker animated:YES];  
    [imgPicker autorelease];
#endif
 

}

#pragma mark - UIImagePickerControllerDelegate

// (void)imagePickerController:(UIImagePickerController *)picker
//       didFinishPickingImage:(UIImage *)image
//                 editingInfo:(NSDictionary *)editingInfo
// iOS3でdeprecatedになったため、ローカルメソッドとして利用
- (void)_imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    NSLog(@"Get phote library Image size=%f X %f", image.size.width, image.size.height );
    
#ifndef CALULU_IPHONE
    [imagePopController dismissPopoverAnimated:YES];
#else
    [_parentVC dismissModalViewControllerAnimated:YES]; 
#endif
    UIImage *oriImage = image;
    
    // 縦と横の倍率でいずれか大きいほうで画像の倍率を求める
    CGFloat widthRatio = oriImage.size.width / CAM_VIEW_PICTURE_WIDTH;
    CGFloat heightRatio = oriImage.size.height / CAM_VIEW_PICTURE_HEIGHT;
    CGFloat raito = (widthRatio >= heightRatio)? widthRatio : heightRatio;
    
    // 倍率より縮小後のサイズを求める
    CGFloat width  = oriImage.size.width / raito;
    CGFloat height = oriImage.size.height / raito;
    
    // グラフィックコンテキストを作成
	UIGraphicsBeginImageContext(CGSizeMake(CAM_VIEW_PICTURE_WIDTH, CAM_VIEW_PICTURE_HEIGHT));
    
    // グラフィックコンテキストに描画
	[oriImage drawInRect:CGRectMake((CAM_VIEW_PICTURE_WIDTH / 2) - (width / 2),
                                    (CAM_VIEW_PICTURE_HEIGHT / 2) - (height / 2), width, height)];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
    
    // プレビューの表示
    _vwPreview.image = reSizeImage;
    _vwPreview.hidden = NO;


    // 保存確認のダイアログ表示
    [self _showSaveCheckAlert];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = info[@"UIImagePickerControllerMediaType"];
    if ([mediaType isEqualToString:@"public.image"]) {
        // 画像の処理はこれまで通り、imagePickerController:didFinishPickingImage:editingInfoで
        [self _imagePickerController:picker
               didFinishPickingImage:info[@"UIImagePickerControllerOriginalImage"]
                         editingInfo:info];
        return;
    }
    NSURL *url = info[@"UIImagePickerControllerMediaURL"];

    if (url == nil) {
        // スリープからの復帰時に間違って呼ばれてしまうことがあるから。
        NSLog(@"スリープからの復帰時に間違って呼ばれてしまうことがあるから。");
        return;
    }
    [imagePopController dismissPopoverAnimated:YES];
    VideoSaveViewController *saveView = [[VideoSaveViewController alloc]
                                         initWithNibName:@"VideoSaveViewController" bundle:nil];
    [saveView show];
    MovieResource *movieResource = [[MovieResource alloc] initNewMovieWithUserId:userID];
    [saveView setVideoUrl:url movie:movieResource histId:self.histID];
    
    [movieResource release];
//    [saveView release];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    
#ifndef CALULU_IPHONE
    [imagePopController dismissPopoverAnimated:YES];
#else
    [_parentVC dismissModalViewControllerAnimated:YES]; 
#endif
    
}

#pragma - mark UIPopoverControllerDelegate
-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    if(popoverController == imagePopController){
        /*[btnOpenPhotoLibrary setBackgroundImage:[UIImage  imageNamed:@"import_photo_Library.png" ]
         forState:UIControlStateNormal];*/
    }
}


#pragma mark UIAlertViewDelegate
// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //取り込み画像の保存確認
    if (alertView.tag == TAKE_PICTURE_ALERT_SAVE_CHECK) 
    {
        if (buttonIndex == 0)
        {
    
#ifdef TRIAL_VERSION
            // トライアルバージョンの場合は撮影可能枚数を取得し、超過の場合は以降の処理を行わない
            if (! [self isImportPictureEnable] )
            {	
#ifndef USE_ACCOUNT_MANAGER
                // CaLuLuホームページを開く
                [ self openCaLuLuHpWithMsg];
#else
                [MainViewController showAccountNoLoginDialog:@"規定枚数以上の\n取込みはできません。"];
#endif
                _vwPreview.image =nil;
                _vwPreview.hidden = YES;
                return; 
            }

#endif
            if ([self saveImageFile:_vwPreview.image])
            {
                // シャッター音を鳴らす
                [Common playSoundWithResouceName:@"shutterSound" ofType:@"mp3"];
             
                // クライアントクラスに保存を通知する
                if (_hEvent)
                {
                    _hEvent(_vwPreview.image);
                }
            }
            else 
            {
                [Common showDialogWithTitle:@"写真アルバムの取り込み" 
                                    message:@"写真の取り込みに失敗しました\n(誠に恐れ入りますが\n再度操作をお願いいたします)"];
            }
        }
        
        _vwPreview.image =nil; 
        _vwPreview.hidden = YES;
    }
    
    else if (alertView.tag == TAKE_PICTURE_ALERT_GO_HOME_PAGE)
    {
        if (buttonIndex == 0)
        {
            // OKの場合のみCaLuLuホームページを開く
            [Common openCaluLuHomePage];
        }
    }
}

@end

