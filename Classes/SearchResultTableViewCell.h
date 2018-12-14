//
//  SearchResultTableViewCell.h
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/04.
//
//

/*
 ** IMPORT
 */
#import <UIKit/UIKit.h>
#import "Badge.h"
#import "BroadcastMailUserInfo.h"

@protocol SearchResultTableViewDelegate
-(void) touchSelectedButtonDelegate;
@end

/*
 ** INTERFACE
 */
@interface SearchResultTableViewCell : UITableViewCell
{
	/*
	 UIパーツ
	 */
	IBOutlet UILabel *userName;
	IBOutlet UILabel *userMailAddress;
	IBOutlet UIButton *selectedCell;
	IBOutlet UIButton *unselectedCell;
    IBOutlet UILabel *blockMail;

	/*
	 設定データ
	 */
	NSInteger _userId;
	BOOL _chkSelectRow;
	BroadcastMailUserInfo* _mailUserInfo;
	BOOL _enableSelect;
    
    id<SearchResultTableViewDelegate> btnCallbackDelegate;
}

/*
 ** PROPERTY
 */
@property(nonatomic, assign) UILabel* userName;
@property(nonatomic, assign) UILabel* userMailAddress;
@property(nonatomic, assign) UILabel* blockMail;
@property NSInteger userId;
@property(nonatomic, assign) CGFloat inset;
@property(nonatomic, retain) BroadcastMailUserInfo* mailUserInfo;
@property(nonatomic, assign) BOOL enableSelect;

/**
 初期化
 @param
 @return 
 */
- (void) initialize;

/**
 */
-(void) setCallbackDelegate:(id<SearchResultTableViewDelegate>) delegate;

/**
 setRegistNumberWithIntValue
 登録IDの設定
 @param registId
 @param isSet
 @return なし
 */
- (void) setRegistNumberWithIntValue:(NSInteger)registId isNameSet:(BOOL)isSet;

/**
 ボタンの選択／非選択状態を変更する
 @param selected YES:選択 NO:非選択
 */
- (void) setSelectedButton:(BOOL)selected;

@end
