//
//  UserTableViewCell.m
//  Setting
//
//  Created by MacBook on 10/10/16.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "defines.h"

#import "UserTableViewCell.h"

#import "UITableViewItemButton.h"

#import "Common.h"
#import "OKDStopWatch.h"

#ifdef CLOUD_SYNC
#import "shop/ShopManager.h"
#endif

@implementation UserTableViewCell

@synthesize picture;
@synthesize userName, sex, lastDate, lastDo, userRegistNumber;
@synthesize userID;
@synthesize lblShopName;
@synthesize mailUserUnread, mailReplyUnread, mailCheck, mailError;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
        [self bringSubviewToFront:mailUserUnread];
        [self bringSubviewToFront:mailReplyUnread];
        [self bringSubviewToFront:mailCheck];
        [self bringSubviewToFront:mailError];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    NSLog(selected ? @"selected Yes" : @"selected No");
    [super setSelected:selected animated:animated];
    self.selectedBGView.hidden = !selected;
}
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    NSLog(highlighted ? @"highlight Yes" : @"highlight No");
    [super setHighlighted:highlighted animated:animated];
    self.selectedBGView.hidden = !highlighted;
}

// UITableViewCellの横幅を調整する
- (void)setFrame:(CGRect)frame
{
    frame.origin.x += self.inset;
    frame.size.width -= 2 * self.inset;
    [super setFrame:frame];
}

// 初期化処理
- (void) initialize:(id)ownerView tableView:(UITableView*)tableView
{
	// 名前ラベルImageの角を丸くする
    [Common cornerRadius4Control:imgTitle];

	// TableViewItemButtonの初期化
	[btnFlicker initialize:ownerView tableView:tableView];
	[btnCameraView initialize:ownerView];
	
	// 長押しイベントサポートクラスの初期化
	_longTouchSuport 
		= [[OKDLongTouchSuport alloc]initWithEventHandler:ownerView sender:self];
}

// sectionとindexの設定
- (void) setSectionIndex:(NSUInteger)section index:(NSUInteger)idx
{
	// TableViewItemButtonにsectionとindexを設定する
	btnFlicker.section = section;
	btnFlicker.rowIndex = idx;
}

/**
 * 言語設定の状況確認
 */
- (BOOL)checkIsJapanese
{
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    NSString *country = [df stringForKey:@"USER_COUNTRY"];
    return ([country isEqualToString:@"ja-JP"] || [country isEqualToString:@"ja"]);
}

// 性別の設定
#define STRING_SEX_FEMALE ([self checkIsJapanese] ? @"女性" : @"FEMALE")
#define STRING_SEX_MALE ([self checkIsJapanese] ? @"男性" : @"MALE")
#define COLOR_SEX_FEMALE [UIColor colorWithRed:0.93 green:0.43 blue:0.60 alpha:1.0]
#define COLOR_SEX_MALE [UIColor colorWithRed:0.08 green:0.60 blue:0.87 alpha:1.0]
- (void) setSexText:(NSInteger)sexValue
{
    sex.text = (sexValue == 0) ? STRING_SEX_FEMALE : STRING_SEX_MALE;
    sex.textColor = (sexValue == 0) ? COLOR_SEX_FEMALE : COLOR_SEX_MALE;
}

// お客様番号の設定 isNameSet:ユーザ名が設定されているか？
- (void) setRegistNumberWithIntValue:(NSInteger)registNum isNameSet:(BOOL)isSet;
{
	// コントロールの表示
	BOOL isDisplay = YES;
	
	// 設定されていない場合は、表示しない
	if (registNum == REGIST_NUMBER_INVALID)
	{	isDisplay = NO; }
	
	// ユーザ名が設定されていない場合は、お客様番号がユーザ名となるので表示しない
	if (! isSet)
	{	isDisplay = NO; }
	
	// 表示する
	userRegistNumberTitle.hidden = ! isDisplay;
	userRegistNumber.hidden = ! isDisplay;
	
	// 書式指定で設定する
	userRegistNumber.text 
		= [NSString stringWithFormat:REGIST_NUMBER_STRING_FORMAT, (long)registNum];
}

// 店舗名の設定
- (void) setShopName:(NSString*)sName
{
#ifndef CLOUD_SYNC
    // 通常版は店舗名は表示しない
    if (! lblShopName.hidden) {
        lblShopName.hidden = YES;
    }
#else
    
    // クラウド版は店舗アカウントの有無で判定する
    if (! ([[ShopManager defaultManager] isAccountShop]) )
    {
        // 店舗アカウントのない場合は非表示とする
        if (! lblShopName.hidden) {
            lblShopName.hidden = YES;
        }
    }
    else {
        if (lblShopName.hidden) {
            lblShopName.hidden = NO;
        }
        lblShopName.text = sName;
    }
#endif
    
}
- (void)dealloc
{
    [userNameHonoTitle release];
	[mailError release];
    [lblLatestTitle release];
    [_selectedBGView release];
    [super dealloc];
}

#pragma mark touches_events

// タッチ開始
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
#ifdef DEBUG
	NSLog(@"UserTableView touchesBegan");
#endif
	
	[super touchesBegan:touches withEvent:event];
	
	// 長押し判定の開始
	[_longTouchSuport beginLongTouchEvent];
}

// タッチ終了
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
#ifdef DEBUG
	NSLog(@"UserTableView touchesEnded");
#endif
	
	[super touchesEnded:touches withEvent:event];
	
	// 長押し判定の中断
	[_longTouchSuport chancelLongTouchEvent];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
#ifdef DEBUG
	NSLog(@"UserTableView touchesCancelled");
#endif
	
	[super touchesCancelled:touches withEvent:event];
	
	// 長押し判定の中断
	[_longTouchSuport chancelLongTouchEvent];
}

#pragma mark ControlEvent

// フリッカーボタンのクリック
- (IBAction) OnFlickerClilck
{
	// self.selected = YES;
}
// フリッカーボタンのダブルタップ
- (IBAction) OnFlickerDblClilck
{
	
}

/**
 * 言語環境設定
 */
- (void)setLanguage:(BOOL)isJapanese
{
    if (isJapanese) {
        lblLatestTitle.text = @"最新来店日";
        userRegistNumberTitle.text = @"お客様番号";
        userNameHonoTitle.hidden = NO;
    } else {
        lblLatestTitle.text = @"Latest day";
        userRegistNumberTitle.text = @"Number";
        userNameHonoTitle.hidden = YES;
    }
}

@end
