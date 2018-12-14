//
//  SendMailHistoryPopup.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/02/28.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>
#import "SendMailHistoryTableViewCell.h"
#import "SendMailHistoryInfoManager.h"

/*
 ** DECLARE
 */
@protocol SendMailHistoryPopupDelegate;

/*
 ** ENUM
 */
enum SendMailHistoryEvent
{
	HIST_CLICKED_DELETE = 0,
	HIST_CLICKED_CANCEL = 1,
};

/*
 ** INTERFACE
 ** 送信履歴のインターフェース
 */
@interface SendMailHistoryPopup : UIViewController
<
	UITableViewDataSource,
	UITableViewDelegate
>
{
	IBOutlet UIButton *btnDeleteHistory;
	IBOutlet UIButton *btnCancelHistory;
	IBOutlet UITableView *viewSendMailHistory;
	/*
	 ユーザーデータ
	 */
	NSInteger _mailHistId;
	id<SendMailHistoryPopupDelegate> _delegate;
	UIPopoverController* _popOverController;
	SendMailHistoryInfoManager* _infoManager;
}

/*
 ** PROPERTY
 */
@property(nonatomic, assign) id <SendMailHistoryPopupDelegate> delegate;
@property(nonatomic, retain) UIPopoverController* popOverController;

/*
 ** METHOD
 */

/**
 initWithMailHistId
 インターフェースの初期化
 */
- (id) initWithMailHistId:(NSInteger) mailHistId delegate:(id) callback popOverController:(UIPopoverController*) controller;

/**
 OnDeleteHistory
 履歴削除が押された
 */
 - (IBAction) OnDeleteHistory:(id) sender;

/**
 OnCancelHistory
 履歴一覧がキャンセルされた
 */
- (IBAction) OnCancelHistory:(id) sender;

@end

/*
 ** PROTOCOL
 ** 送信履歴のデリゲート
 */
@protocol SendMailHistoryPopupDelegate <NSObject>

/**
 OnItemClicked
 アイテムのクリックイベントを送信
 @param sender
 @param event
 */
- (void) OnItemClicked:(id) sender Event:(NSInteger) event;

@end