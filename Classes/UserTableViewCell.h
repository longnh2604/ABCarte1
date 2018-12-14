//
//  UserTableViewCell.h
//  Setting
//
//  Created by MacBook on 10/10/16.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IBDesignableView.h"

@class UITableViewItemButton;
@class UIFlickerButton;

@class OKDLongTouchSuport;

@interface UserTableViewCell : UITableViewCell
{
	IBOutlet UIImageView	*picture;           //画像
	IBOutlet UILabel		*userName;          //名前
    IBOutlet UILabel        *userNameHonoTitle;     // 敬称
	IBOutlet UILabel		*userRegistNumberTitle;	// お客様番号タイトル
    IBOutlet UILabel        *userRegistNumber;		// お客様番号
	IBOutlet UILabel		*sex;               //性別
    IBOutlet UILabel        *birthday;          //生年月日
	IBOutlet UILabel		*lastDate;          //前回施術日
    IBOutlet UILabel        *lblLatestTitle;    // 最新施術日タイトル
	// IBOutlet UILabel		*lastDateYo;	//前回施術日(曜日)
	IBOutlet UILabel		*lastDo;            //前回施術内容
	
	IBOutlet UITableViewItemButton *btnFlicker;	// フリッカボタン
	IBOutlet UIFlickerButton *btnCameraView;	// カメラ画面遷移ボタン
	IBOutlet UIImageView	*imgTitle;			// タイトル背景
    IBOutlet UILabel        *lblShopName;       // 店舗名
	
	OKDLongTouchSuport		*_longTouchSuport;	// 長押しサポートクラス
	
	NSInteger				userID;				// ユーザID
}

@property (retain, nonatomic) IBOutlet UIView *selectedBGView;
@property (assign) UIImageView	*picture;
@property (assign) UILabel		*userName;
@property (assign) UILabel		*userRegistNumber;
@property (assign) UILabel		*sex;
@property (assign) UILabel      *birthday;
@property (assign) UILabel		*lastDate;
@property (assign) UILabel		*lastDo;
@property (assign) UILabel		*lblShopName;
@property (retain, nonatomic) IBOutlet IBDesignableView *mailUserUnread;    // お客様未読
@property (retain, nonatomic) IBOutlet IBDesignableView *mailError;         // メールエラー
@property (retain, nonatomic) IBOutlet IBDesignableView *mailReplyUnread;   // 返信未読
@property (retain, nonatomic) IBOutlet IBDesignableView *mailCheck;         // 返信チェック
@property (retain, nonatomic) IBOutlet UILabel *mailUserUnreadLabel;
@property (retain, nonatomic) IBOutlet UILabel *mailErrorLabel;
@property (retain, nonatomic) IBOutlet UILabel *mailReplyUnreadLabel;
@property (retain, nonatomic) IBOutlet UILabel *mailCheckLabel;
@property (retain, nonatomic) IBOutlet UILabel *mailTitleOnUserUnreadLabel;
@property (retain, nonatomic) IBOutlet UILabel *mailTitleOnErrorLabel;
@property (retain, nonatomic) IBOutlet UILabel *mailTitleOnReplyUnreadLabel;
@property (retain, nonatomic) IBOutlet UILabel *mailTitleOnCheckLabel;
@property (retain, nonatomic) IBOutlet UILabel *mailTitleOffUserUnreadLabel;
@property (retain, nonatomic) IBOutlet UILabel *mailTitleOffErrorLabel;
@property (retain, nonatomic) IBOutlet UILabel *mailTitleOffReplyUnreadLabel;
@property (retain, nonatomic) IBOutlet UILabel *mailTitleOffCheckLabel;

@property (assign) NSInteger	userID;
@property (nonatomic) CGFloat inset;

// 初期化処理
- (void) initialize:(id)ownerView tableView:(UITableView*)tableView;

// sectionとindexの設定
- (void) setSectionIndex:(NSUInteger)section index:(NSUInteger)idx;

// 性別の設定
- (void) setSexText:(NSInteger)sexValue;

// お客様番号の設定 isNameSet:ユーザ名が設定されているか？
- (void) setRegistNumberWithIntValue:(NSInteger)registNum isNameSet:(BOOL)isSet;

// 店舗名の設定
- (void) setShopName:(NSString*)sName;

// 言語環境設定
- (void)setLanguage:(BOOL)isJapanese;

@end
