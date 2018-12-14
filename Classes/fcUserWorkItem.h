//
//  fcUserWorkItem.h
//  iPadCamera
//
//  Created by MacBook on 10/10/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "def64bit_common.h"

#define NO_DEFINE_NEW_WORK_DATE_STR		@"(施術なし)"		// 最新施術日設定なし文字列
#define NO_DEFINE_NEW_WORK_DATE_ENG     @" ------ "     // 最新施術日設定なし文字列(英語環境時)
#define	NO_TOP_MEMO_STR					@"(なし)"		// 先頭memoの文字列

// 施術内容のItemクラス
@interface fcUserWorkItem : NSObject 
{
	USERID_INT		userID;					//ユーザID
	NSDate			*workItemDate;			//最新施術日：（履歴の場合は施術日）
	NSMutableString	*workItemListString;	//施術内容（文字）
	NSMutableArray	*workItemListNumber;	//施術内容（数値）
	NSMutableString	*workItemListString2;	//施術内容2（文字）
	NSMutableArray	*workItemListNumber2;	//施術内容2（数値）
	
	////////////////////////////////////////////////////
	// 以下のメンバは、最新施術内容で使用する
	////////////////////////////////////////////////////
	NSString		*userName;				//ユーザ名
	NSMutableArray	*workItemStrings;		//施術
	NSMutableArray	*workItemStrings2;		//施術2
	
	////////////////////////////////////////////////////
	// 以下のメンバは、履歴一覧および施術カルテで使用する
	////////////////////////////////////////////////////
	HISTID_INT		histID;					//履歴ID
	NSString		*headPictureUrl;		//代表写真
	NSMutableArray	*picturesUrls;			//写真リスト：施術カルテのみ
	NSMutableArray	*videosUrls;		    //動画リスト DELC SASAGE
	NSMutableArray	*userMemos;				//メモリスト
    
    NSInteger       mailUserUnread;         //お客様未読
    NSInteger       mailReplyUnread;        //返信未読
    NSInteger       mailCheck;              //返信チェック
    
    BOOL            _isJapanese;            // 言語環境フラグ
}

@property(nonatomic, readonly)			USERID_INT	userID;
@property(nonatomic, retain, readonly)	NSString	*userName;
@property(nonatomic, retain)	NSDate				*workItemDate;
@property(nonatomic, retain)	NSMutableString		*workItemListString;
@property(nonatomic, retain)	NSMutableArray		*workItemListNumber;
@property(nonatomic, retain)	NSMutableArray		*workItemStrings;
@property(nonatomic, retain)	NSMutableString		*workItemListString2;
@property(nonatomic, retain)	NSMutableArray		*workItemListNumber2;
@property(nonatomic, retain)	NSMutableArray		*workItemStrings2;

@property(nonatomic)			HISTID_INT			histID;
@property(nonatomic, copy)		NSString			*headPictureUrl;
@property(nonatomic, retain)	NSMutableArray		*picturesUrls;
@property(nonatomic, retain)	NSMutableArray		*videosUrls;
@property(nonatomic, retain)	NSMutableArray		*userMemos;

@property(nonatomic, assign)    NSInteger           mailUserUnread;
@property(nonatomic, assign)    NSInteger           mailReplyUnread;
@property(nonatomic, assign)    NSInteger           mailCheck;

// 初期化（コンストラクタ:最新施術内容用）
-(id) initWithWorkItem:(USERID_INT)usrID userName:(NSString*)usrName;

// 初期化（コンストラクタ:履歴用）
-(id) initWithUserID:(USERID_INT)usrID;

// 最新施術日の設定
-(void) setNewWorkDateByString:(NSString*)workDateString;

// 施術内容の設定
-(void) setWorkItemByString:(NSString*)workItem;
// 施術内容の設定
-(void) setWorkItemByNumber:(NSUInteger)itemNumber;
// 施術内容2の設定
-(void) setWorkItemByString2:(NSString*)workItem;
// 施術内容2の設定
-(void) setWorkItemByNumber2:(NSUInteger)itemNumber;


// 最新施術日を和暦で取得
-(NSString*) getNewWorkDateByLocalTime;
// 最新施術日を和暦で取得(言語環境指定有り)
-(NSString*) getNewWorkDateByLocalTime:(BOOL)isJapanese;

// 施術内容のリセット
-(void) resetWorkItem;

// 施術内容(文字と数値)のリセット
-(void) resetWorkItemList;

//	先頭memoの取得
-(NSString*) getTopMemo;

//  最新施術日を取得 (for Xcode4 waring -> cocoa naming convention....)
// -(NSDate*) getnewWorkDate;

@end
