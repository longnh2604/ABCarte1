//
//  MainViewController.h
//  iPadCamera
//
//  Created by MacBook on 11/04/06.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UICancelableScrollView.h"

#define PAGE_NUMS       6				// フリックするpage数

#define INDICATOR_VIEW_TAG  12000       // indicatorのtag番号s

/*
 ** ENUM
 */
NS_ENUM(NSInteger, BackgroundColorTableIndex)
{
	BK_COLOR_DEFAULT = 0,
	BK_SELECTED_CELL = 1,
	BK_NOSELECT_CELL = 2,
	BK_COLOR_CHIC    = -1,
};

// MainViewクラスのdelegate
@protocol MainViewControllerDelegate<NSObject>

@optional

// 新規View画面への遷移
//		return: 次に表示する画面のViewController  nilで遷移をキャンセル
- (UIViewController*) OnTransitionNewView:(id)sender;

// 新規View画面への遷移でViewがLoadされた後にコールされる
- (void) OnTransitionNewViewDidLoad:(id)sender transitionVC:(UIViewController*)tVC;

// 既存View画面への遷移
- (BOOL) OnTransitionExsitView:(id)sender transitionVC:(UIViewController*)tVC;


// 画面終了の通知
- (BOOL) OnUnloadView:(id)sender;

// 画面ロックモード変更:実装しない場合は、view.hidden= isLock
- (void) OnWindowLockModeChange:(BOOL)isLock;

// ロック画面への遷移確認:実装しない場合は遷移可とみなす
- (BOOL) OnDisplayChangeEnable:(id)sender disableReason:(NSMutableString*) message;

// Touchイベントを伝えるか：NOを返すと伝えない
- (BOOL) OnCheckTouchDeleverd:(id)sender touchPoint:(CGPoint)pt touchView:(UIView*)view;

// スクロール実施の確認 : NOを返すとスクロールをキャンセル
- (BOOL) OnCheckScrollPerformed:(id)sender touchView:(UIView*)view;


@end

@class SecurityManagerView, UIBottomDialogController;

// Web参考資料
@class ReferenceWeb;

// @class UICancelableScrollView;
// @protocol UICancelableScrollViewDelegate;

///
/// 複数ViewのスクロールをサポートするMainのViewクラス
///
@interface MainViewController : UIViewController<UIScrollViewDelegate, UIAlertViewDelegate, UICancelableScrollViewDelegate> {
	
	IBOutlet UICancelableScrollView	*scrollView;	// フリックのコンテナ
    IBOutlet UIPageControl	*pageControl;			// ページコントール
	
	IBOutlet SecurityManagerView *vwSecurityManage;	// セキュリティ管理Viewクラス
	
	NSMutableArray			*viewControllers;		// フリックするViewContllerのリスト
	NSInteger				nowViewIndex;			// 現在表示されているViewのindex
	
	UIInterfaceOrientation	beforeInterfaceOrient;	// 画面遷移する前のデバイスの向き

	NSInteger				_skippedPage;			// スキップされたページ番号（0で無効）
    
    UIBottomDialogController    *_bottomDialog;     // 下表示ダイアログ
    
    ReferenceWeb            *_viewReferenceWeb;     // Web参考資料表示
	NSMutableDictionary		*bkColorTable;			// 背景色のカラーテーブル
	NSInteger				_colorIndex;			// カラーテーブルのインデックス
    BOOL                    inScroll;               // 画面切り替えのスクロール中を表すフラグ
    
    @public
    BOOL                    preventScroll;
}

// @property(nonatomic, assign)	id<MainViewControllerDelegate> delegate;
/**
 PROPERTY
 */
@property(nonatomic, assign) NSInteger colorIndex;
@property(nonatomic, assign) UIInterfaceOrientation beforeInterfaceOrient;

/**
 METHOD
 */
// pageContorlのchangePageイベント
- (IBAction)onChangePage:(id)sender;

// popupWindowの表示
- (BOOL) showPopupWindow:(UIViewController*)popupVC;

// popupWindowを閉じる
- (void) closePopupWindow:(UIViewController*)closePopupView;

// modalViewの表示
+ (void) showModalView:(UIViewController*)modalView;
// modalViewを閉じる
+ (void) closeModalView;

// 下表示modalDialogの表示
+ (void) showBottomModalDialog:(UIViewController*)modalView parentView:(UIView*)parentView;
// 下表示modalDialogの表示
+ (void) showBottomModalDialog:(UIViewController*)modalView;
// modalDialogの表示
+ (void) showModalDialog:(UIViewController*)modalView parentView:(UIView*)parentView isDispBottom:(BOOL)isBottom;
// modalDialogを閉じる(上／下表示ダイアログ共用)
+ (void) closeBottomModalDialog;
// modalDialogが表示されているか？(上／下表示ダイアログ共用)
+ (BOOL) isDisplayBottomModalDialog;

// メッセージPopup windowの表示
+ (void) showMessagePopupWithMessage:(NSString*)msg;
// ロック画面の表示
+ (void) showLockWindowWithMessage:(NSString*)msg;
// ロック画面を閉じる
+ (void) closeLockWindow;

// viewのスクロールのロック
- (void) viewScrollLock:(BOOL)isLock;

// 次のViewControllerを取得する
- (UIViewController*) getNextControlWithSelf:(UIViewController*)myVC;

// 呼び出しもと（前の）のViewControllerを取得する
- (UIViewController*) getPrevControlWithSelf:(UIViewController*)myVC;

// 現在のデバイスの向きを取得
- (UIInterfaceOrientation) getNowDeviceOrientation;

// 現在のデバイスの向きを取得(UIScreenオブジェクトより取得)
- (UIInterfaceOrientation) getNowDeviceOrientationWithScreen;

// 現在のデバイスの向きがPortrateであるかを取得する
+ (BOOL) isNowDeviceOrientationPortrate;

// 次に表示されるViewをスキップする
- (void)skipNextPage:(BOOL)isSkip;
// 前ページのViewをスキップする
- (void)skipBeforePage:(BOOL)isSkip;

//3ページ以降、全てのView削除　連続ページめくり対策　6/22　伊藤
- (BOOL)unloadAllViewSend;

// 現在表示中Viewから任意の位置のViewControllerを取得する
- (UIViewController*)getViewControllerFromCurrentView:(UIViewController*)myVC pageTo:(NSInteger)page;

// UserInfoViewControllerを取得する
- (UIViewController*)getUserInfoViewController;

// 現在表示中ViewControllerを取得
- (UIViewController*) getNowCurrentViewController;

// 表示中のページ番号を取得
- (NSInteger) getNowPage;

// NavigationControllerより指定クラスのVCを取得
- (UIViewController*) getVC4NaviCtrlWithClass:(Class)aClass;

// ViewContllerのリストより指定クラスのVCを取得
- (UIViewController*) getVC4ViewControllersWithClass:(Class)aClass;

// 前ページへ戻る
- (void) backBeforePage;
// 次ページへ進む
- (void) fowordNextPage;

//スクロールビューの大きさを指定　連続ページめくり対策　6/22　伊藤
- (void)setScrollViewWidth:(BOOL)nextViewSet;

//set scrollview bounce
- (void)setScrollViewBounce:(BOOL)bounce;

// 画面ロック状態の取得
- (BOOL) isWindowLockState;
// セキュリティーロック状態の取得
- (BOOL) isWindowLockStateALL;
// 現在表示されているページの次のページから以降のページを削除
- (void) deleteViewControllersFromNextIndex;
// ViewControllerの最終ページのオブジェクトを取得
- (id)getLastViewController;

#ifdef USE_ACCOUNT_MANAGER
// アカウント継続でのエラーハンドラ
- (void) onAccountContinueError;

// アカウントの未ログインでのダイアログ表示
+ (BOOL) showAccountNoLoginDialog:(NSString *)content;
#endif

// Indicatorの表示
+ (void) showIndicator;
// Indicatorの表示
+ (void) showIndicatorWithViewController:(UIViewController*)parentVc;

// Indicatorを閉じる
+ (void) closeIndicator;
// Indicatorを閉じる
+ (void) closeIndicatorWithViewController:(UIViewController*)parentVc;


+ (void)setDbdownloadEnd:(BOOL)stat;
+ (BOOL)getDbdownloadEnd;

// Web参照画像の表示
+ (void) showReferenseWeb;

/**
 getColorTable
 @param index カラーテーブルのインデックス
 @return カラーテーブル
 */
- (UIColor*) getColorTable:(NSInteger) index;

// メインViewを返す
- (UIView *)getMainViewController;

@end
