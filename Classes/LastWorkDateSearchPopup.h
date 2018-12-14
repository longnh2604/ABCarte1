//
//  LastWorkDateSearchPopup.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/24.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>

/*
 ** INTERFACE
 */
@interface LastWorkDateSearchPopup : UIViewController
<
	UIPickerViewDataSource,
	UIPickerViewDelegate
>

/*
 ** PROPERTY
 */
@property(nonatomic, retain) UIPopoverController* popOverController;

/**
 ポップアップの初期化
 @param delegate デリゲート
 @return ポップアップのポインタ
 */
- (id) initWithDelegate:(id) delegate;

/**
 選択されている期限を取得する
 @param start 開始日
 @param end 終了日
 */
- (void) getSelectedTerm:(NSDateComponents**)start End:(NSDateComponents**)end;

/**
 うるう年の判定
 */
+ (BOOL) isLeapYear:(NSInteger)year;


@end

/*
 ** PROTOCOL
 */
@protocol LastWorkDateSearchPopupDelegate <NSObject>

/**
 検索、取消ボタンが押された時に呼び出される
 @param sender 呼び出し元
 @param cancel 取消かどうか
 @return なし
 */
- (void) OnLastWorkDateSearch:(id)sender Cancel:(BOOL) cancel;

@end
