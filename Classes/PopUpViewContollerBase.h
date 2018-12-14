//
//  PopUpViewContollerBase.h
//  iPadCamera
//
//  Created by MacBook on 10/10/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@protocol PopUpViewContollerBaseDelegate;

#import <UIKit/UIKit.h>

// PopUpするUIViewControllerの基本クラス
@interface PopUpViewContollerBase : UIViewController 
{
	NSUInteger				_popUpID;
	id						_delegateObject;
	
	UIPopoverController		*popoverController;
	id <PopUpViewContollerBaseDelegate> delegate;

}

@property(nonatomic, retain)		UIPopoverController* popoverController;
@property(nonatomic, copy)    id <PopUpViewContollerBaseDelegate> delegate;

- (id) initWithPopUpID:(NSUInteger)popUpID;
- (id) initWithPopUpViewContoller:(NSUInteger)popUpID 
				popOverController:(UIPopoverController*)controller callBack:(id)callBackDelegate;
- (id) initWithPopUpViewContoller:(NSUInteger)popUpID 
				popOverController:(UIPopoverController*)controller callBack:(id)callBackDelegate
                          nibName:(NSString*)nibName;

// 設定ボタンクリック
- (IBAction) OnSetButton:(id)sender;
// キャンセルボタンクリック
- (IBAction) OnCancelButton:(id)sender;
// このViewContlloerを閉じる
- (void) closeByPopoverContoller;

#pragma mark - override_methods
// delegate objectの設定:設定ボタンのclick時にsetDelegateObjectの前にコールされる
// NOを返すとイベントを中止する
//    remark : このメソッドにて設定値の検証を行い、ダイアログを表示する
//             デフォルトはYESを返す
- (BOOL) preProcessValidate;

// delegate objectの設定:設定ボタンのclick時にコールされる 
// nilを返すとイベントを中止する
//    remark : このメソッドにてダイアログを表示するとUIがロックする
- (id) setDelegateObject;

// alertの表示
- (void)alertViewSwow:(NSString*)message;

@end

// PopUpViewのイベント
@protocol PopUpViewContollerBaseDelegate<NSObject>
@optional
// 設定（または確定など）をクリックした時のイベント
- (void)OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object;
// 設定を閉じたあとのイベント
- (void)OnPopupViewFinished:(NSUInteger)popUpID setObject:(id)object Sender:(id)sender;
@end
