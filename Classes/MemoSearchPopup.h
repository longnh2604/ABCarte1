//
//  MemoSearchPopup.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/24.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>
#import "TemplateCategoryViewCell.h"
#import "CommonPopupInfoManager.h"

/*
 ** INTERFACE
 */
@interface MemoSearchPopup : UIViewController
<
	UITableViewDataSource,
	UITableViewDelegate
>
{
    NSString    *lbl1;      // メモ検索のインデックス１
    NSString    *lbl2;      // メモ検索のインデックス２
}

/*
 ** PROPERTY
 */
@property(nonatomic, retain) UIPopoverController* popOverController;

/**
 初期化する
 @param delegate
 @return ポップアップ自身
 */
- (id) initWithDelegate:(id) delegate;

/**
 共通情報を取得する
 */
- (BOOL) getMemoStringInArray:(NSMutableDictionary*) arrayInfo;

@end

/*
 ** PROTOCOL
 */
@protocol MemoSearchPopupDelegate <NSObject>

/**
 メモによる検索
 @param sender 呼び出しもと
 @param cancel キャンセルしているか？
 @return なし
 */
- (void) OnMemoSearch:(id) sender Kind:(NSInteger) kind;

@end
