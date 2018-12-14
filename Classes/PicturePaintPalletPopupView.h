//
//  PicturePaintPalletPopupView.h
//  iPadCamera
//
//  Created by  on 11/11/13.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef CALULU_IPHONE
#define PALLET_POPUP_BUTTON_MARGIN         2.0f       // ボタンとフレームのマージン
#else
#define PALLET_POPUP_BUTTON_MARGIN         2.0f       // ボタンとフレームのマージン
#endif
// popupのイベントハンドラ定義
typedef void (^onPalletPopupEvent)(id sender);

///
/// 写真描画のパレットPopupView
///
@interface PicturePaintPalletPopupView : UIView{
    
    BOOL                    _isShown;       // 表示されているか？
    onPalletPopupEvent      _hEvent;        // popupのイベントハンドラ
}

// 初期化
- (id) initWithParentView:(UIView*)parent popupEvent:(onPalletPopupEvent)hEvent;
// 表示する
- (void) dispPopupWithButtons:(NSArray*)buttons;
// popupを閉じる
- (void) closePopupWithAnimate:(BOOL)isAnimate;


@end
