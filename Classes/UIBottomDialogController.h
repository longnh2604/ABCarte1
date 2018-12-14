//
//  UIBottomDialogController.h
//  iPadCamera
//
//  Created by  on 11/11/06.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

///
/// 下から表示されるダイアログのコントローラクラス
///
@interface UIBottomDialogController : NSObject{
    
    UIView              *_continerView;             // コンテナとなるView
    UIViewController    *_displayViewController;    // 表示するViewController
    
    BOOL                _isDispBottom;              // 下側に表示するか（デフォルト）
}

// 初期化
- (id) initWithParentView:(UIView*)parentView;

// ダイアログの表示(下側表示)
- (void)presentDialogViewController:(UIViewController*)controller animated:(BOOL)animated;
// ダイアログの表示
- (void)presentDialogViewController:(UIViewController*)controller animated:(BOOL)animated isDispBottom:(BOOL)isBottom;
// ダイアログを閉じる
- (void)dismissDialogViewControllerAnimated:(BOOL)animated;

// 画面の回転
-(void)rotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;

@end

///
/// 画面をLockするControllerクラス
///
@interface UILockWindowController : UIBottomDialogController
@end
