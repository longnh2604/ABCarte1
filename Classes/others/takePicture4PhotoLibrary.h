//
//  takePicture4PhotoLibrary.h
//  iPadCamera
//
//  Created by 強 片山 on 12/11/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "def64bit_common.h"

// 画像取り込み完了のイベントハンドラ定義
typedef void (^onCompleteTakePicture)(UIImage *image);

///
/// 写真アルバムからの取り込みクラス
///
@interface takePicture4PhotoLibrary : NSObject
    <UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UINavigationControllerDelegate,UIAlertViewDelegate>
{
    onCompleteTakePicture   _hEvent;                    // 画像取り込み完了のイベントハンドラ
    
    UIImageView   *_vwPreview;                          // 選択画像のプレビュー
    UIButton      *_btnPopup;                           // ポップアップするボタン
    
    UIPopoverController         *imagePopController;    //フォトライブラリ用ポップアップ
    UIAlertView                 *saveCheckAlert;        //保存確認アラート
#ifdef CALULU_IPHONE
    UIViewController            *_parentVC;             //親ViewController
#endif
}

@property (nonatomic) USERID_INT            userID;     // 対象となるuserID
@property (nonatomic) HISTID_INT            histID;     // 対象となるhistID

#ifndef CALULU_IPHONE
// 選択画像のプレビューを指定
- (id) initWithPreView:(UIImageView*)preview popupButton:(UIButton*)btn;
#else
// 選択画像のプレビューを指定
- (id) initWithPreView:(UIImageView*)preview popupButton:(UIButton*)btn parentViewController:(UIViewController*)parentVC;
#endif

// 写真ライブラリより写真を取り込む
- (void) takePicureWithCompliteHandler:(onCompleteTakePicture)handler;

@end
