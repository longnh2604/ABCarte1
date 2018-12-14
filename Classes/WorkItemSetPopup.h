//
//  WorkItemSetPopup.h
//  iPadCamera
//
//  Created by MacBook on 10/12/21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "def64bit_common.h"

@protocol WorkItemSetPopupDelegate;

///<summary>
///施術内容の設定ポップアップViewControllerクラス
///</summary>
@interface WorkItemSetPopup : UIViewController 
{
	IBOutlet UILabel			*lblTitle;			// Titleラベル
	
	IBOutlet UIScrollView		*scrollView;		// スクロールView
	IBOutlet UIView				*conteinerView;		// 選択ボタンのコンテナView
	
	NSMutableDictionary		*masterTable;			// 施術マスタテーブル
	UIPopoverController		*popoverController;
	id <WorkItemSetPopupDelegate> delegate;			// 施術内容の設定ポップアップのイベント
}

@property(nonatomic, assign)	NSMutableDictionary		*masterTable;
@property(nonatomic, retain)	UIPopoverController		*popoverController;
@property(nonatomic, assign)    id <WorkItemSetPopupDelegate> delegate;

// 初期化
-(id) initWithMasterTable:(NSMutableDictionary*)mstTable 
			popOverController:(UIPopoverController*)controller callBack:(id)callBackDelegate;

// 選択状態の設定
-(void) setSelectedState:(NSMutableArray*)workItemNumberList;

// ポップアップタイトルの設定
-(void) setPopupTitleWithUserName:(NSString*)userName;

// 閉じるボタン
-(IBAction) onClose:(id)sender;
// 全てを解除
-(IBAction) onAllReset:(id)sender;

@end

// 施術内容の設定ポップアップのイベント
@protocol WorkItemSetPopupDelegate<NSObject>
@optional
// 各施術内容をクリックした時のイベント
- (void)OnWorkItemSet:(WORKITEM_INT)workItemID isSelect:(BOOL)isSelect;
// 全て選択解除
- (void)OnAllWorkItemReset;
@end
