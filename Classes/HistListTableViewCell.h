//
//  HistListTableViewCell.h
//  iPadCamera
//
//  Created by MacBook on 10/12/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UITableViewItemButton;
@class UIFlickerButton;

@class OKDLongTouchSuport;

// 履歴一覧のTableViewCellクラス
@interface HistListTableViewCell : UITableViewCell 
{
	IBOutlet UIImageView	*picture;			//画像
	IBOutlet UILabel		*workDate;			//施術日
	IBOutlet UILabel		*workItemTitle;		//施術内容タイトル
	IBOutlet UILabel		*workItem;			//施術内容
	IBOutlet UILabel		*workItemTitle2;	//施術内容2タイトル
	IBOutlet UILabel		*workItem2;			//施術内容2
	IBOutlet UILabel		*memoTitle;			//メモタイトル
	IBOutlet UILabel		*memo;				//メモ
	
	IBOutlet UITableViewItemButton *btnFlicker;	// フリッカボタン
	IBOutlet UIFlickerButton *btnCameraView;	// カメラ画面遷移ボタン
	
	OKDLongTouchSuport		*_longTouchSuport;	// 長押しサポートクラス
	
	NSInteger				cellRow;		// このセルのテーブル上のRow
}

@property (assign) UIImageView	*picture;
@property (assign) UILabel		*workDate;
@property (assign) UILabel		*workItem;
@property (assign) UILabel		*workItem2;
@property (assign) UILabel		*memo;

@property (nonatomic) NSInteger	cellRow;
@property (nonatomic) CGFloat inset;

// 初期化処理
- (void) initialize:(id)ownerView tableView:(UITableView*)tableView;

// sectionとindexの設定
- (void) setSectionIndex:(NSUInteger)section index:(NSUInteger)idx;

@end
