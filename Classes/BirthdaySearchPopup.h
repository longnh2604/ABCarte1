//
//  BirthdaySearchPopup.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/20.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>

/*
 ** DEFINE
 */
#define SEGMENT_BIRTHDAY  0
#define SEGMENT_MONTH     1
#define SEGMENT_YEAR      2
#define DEF_SEGMENT_INDEX SEGMENT_BIRTHDAY

/*
 ** INTERFACE
 */
@interface BirthdaySearchPopup : UIViewController
<
	UIPickerViewDataSource,
	UIPickerViewDelegate
>

/*
 ** PROPERTY
 */
@property(nonatomic, retain) UIPopoverController* popOverController;

/**
 初期化
 @param delegate デリゲート
 @return なし
 */
- (id) initWithDelegate:(id) delegate;

/**
 セグメントのインデックスを取得する
 @param
 @return
 */
- (NSInteger) getSegmentIndex;

/**
 検索する誕生日を取得する
 @return 誕生日
 @remark 誕生日を検索時にのみ取得できる
 */
- (NSDate*) getBirthDay;

/**
 検索する誕生月を取得する
 @param 検索開始月か
 */
- (NSDate*) getBirthMonth:(BOOL)startSearch;

/**
 検索する誕生年を取得する
 @param 検索開始年か
 */
- (NSDate*) getBirthYear:(BOOL)startSearch;

@end


/*
 ** DELEGATE
 */
@protocol BirthdaySearchPopupDelegate <NSObject>

/**
 検索が押された時に呼び出される
 @param sender 呼び出し元
 @param cancel キャンセルされているか
 @return なし
 */
- (void) OnSearch:(id) sender Cancel:(BOOL) cancel;

@end
