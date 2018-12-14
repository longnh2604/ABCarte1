//
//  CategorySearchPopup.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/02/28.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>
#import "TemplateCategoryViewCell.h"
#import "CommonPopupInfoManager.h"

/*
 ** DECLARE
 */
@protocol CategorySearchPopupDelegate;

/*
 ** INTERFACE
 */
@interface CategorySearchPopup : UIViewController
<
	UITableViewDataSource,
	UITableViewDelegate
>
{
	IBOutlet UIBarButtonItem *btnCategoryCancel;
	IBOutlet UITableView *viewCategory;

	/*
	 設定データ
	 */
	id<CategorySearchPopupDelegate> _delegate;
	UIPopoverController* _popOverController;
	CommonPopupInfoManager* _infoManager;
}

/*
 ** PROPERTY
 */
@property(nonatomic, assign) id <CategorySearchPopupDelegate> delegate;
@property(nonatomic, retain) UIPopoverController* popOverController;


/**
 InitWithCategory
 カテゴリー検索ポップアップの初期化
 @param category カテゴリー
 @param delegate デリゲート
 @param popOver ポップオーバーコントローラー
 */
- (id) InitWithCategory:(id) category delegate:(id) callback popOver:(UIPopoverController*) popOver;

/**
 OnClickedCategoryCancel
 カテゴリー検索のキャンセルボタンが押された
 */
- (IBAction) OnClickedCategoryCancel:(id) sender;

@end

/*
 ** PROTOCOL
 */
@protocol CategorySearchPopupDelegate <NSObject>

/**
 OnCategoryClicked
 カテゴリー検索のカテゴリーが選択された際に呼び出される
 @param sender 送り元
 @param index カテゴリーのインデックス
 */
- (void) OnCategoryClicked:(id) sender CategoryTitle:(NSString*) title;

/**
 OnCategoryCanceled
 カテゴリー検索がキャンセルされた
 */
- (void) OnCategoryCanceled:(id) sender;

@end
