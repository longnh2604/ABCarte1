//
//  userInfo.h
//  iPadCamera
//
//  Created by MacBook on 10/10/21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "def64bit_common.h"

// ユーザー情報Itemクラス:TableViewCellの表示内容に基づく
@interface userInfo : NSObject 
{
	USERID_INT		userID;				// ユーザID
	// NSString		*name;				// 漢字の名前：姓＋名
	NSString		*firstName;			// 漢字の姓
	NSString		*secondName;		// 漢字の名
    NSString        *middleName;        // ミドルネーム
	NSInteger		registNumber;		// お客様番号
	
	NSInteger		sex;				// 性別 0＝女性　1=男性
	
	NSString		*pictureURL;		// 写真のURL
	NSDate			*lastWorkDate;		// 前回施術日
	NSDate			*birthDate;			// 誕生日
#ifdef CLOUD_SYNC
    NSString        *shopName;			// 店舗名
#endif
	NSInteger		notification_error;	// メールの送信エラー数
}

@property (nonatomic)       USERID_INT	userID;
// @property (nonatomic, retain)	NSString	*name;
@property (nonatomic, copy)	NSString	*firstName;
@property (nonatomic, copy)	NSString	*secondName;
@property (nonatomic, copy)	NSString	*middleName;
@property (nonatomic)		NSInteger	registNumber;
@property (nonatomic)		NSInteger	sex;
@property (nonatomic, copy)	NSString	*pictureURL;
@property (nonatomic, retain) NSDate	*lastWorkDate;
@property (nonatomic, retain) NSDate	*birthDate;
#ifdef CLOUD_SYNC
@property (nonatomic, copy) NSString    *shopName;
#endif
@property (nonatomic, assign) NSInteger notification_error;
@property (nonatomic, assign) NSInteger histID;

// 初期化（コンストラクタ）
- (id)initWithUserInfo:(USERID_INT) usrID
             firstName:(NSString*)fstName
			secondName:(NSString*)secName
            middleName:(NSString*)midName
		  registNumber:(NSString*)regNum
				   sex:(NSInteger)sex
			pictureURL:(NSString*)pictUrl
		  lastWorkDate:(NSString*)lastwkDate
			  birthDay:(NSString*)birthDay
#ifdef CLOUD_SYNC
              shopName:(NSString*)sName
#endif
;

// 姓と名で名前を設定
- (void)setNameWithFirstSecond:(NSString*)fstName secondName:(NSString*)secName;

// ユーザ名の取得
- (NSString*) getUserName;

// 最新施術日を和暦で取得
- (NSString*) getLastWorkDate:(BOOL)isJapanese;

// 生年月日を西暦で取得
- (NSString*) getBirthDayByLocalTimeAD:(BOOL)isJapanese;

// ユーザ名が設定されているか
- (BOOL) isSetUserName;

// お客様番号が有効であるか
- (BOOL) isRegistNumberValid;

@end
