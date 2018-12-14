//
//  mstUser.h
//  iPadCamera
//
//  Created by MacBook on 10/10/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "def64bit_common.h"

// 性別
typedef enum {
	Lady,
	Men,
} SEX_TYPE;

// 血液型
typedef NS_ENUM(int, BLOAD_TYPE) {
	BloadTypeA = 1,
	BloadTypeB,
	BloadTypeO,
	BloadTypeAB,
	BloadTypeUnKnown = 0xffff,
};

@interface mstUser : NSObject 
{
	USERID_INT			userID;
	NSString			*firstName;			// 姓
	NSString			*secondName;		// 名
    NSString            *middleName;        // ミドルネーム
	NSString			*firstNameCana;		// 姓（かな）
	NSString			*secondNameCana;	// 名（かな）
	NSInteger           registNumber;		// お客様番号
	SEX_TYPE			sex;				// 性別
	
	NSString			*pictuerURL;		// 写真のURL
	
    NSString            *postal;            // 郵便番号
    NSString            *adr1;              // 住所１：都道府県
    NSString            *adr2;              // 住所２：郡/市区町村
    NSString            *adr3;              // 住所３：その他地番など
    NSString            *adr4;              // 住所４：その他地番など２
    NSString            *tel;               // 電話番号
     NSString           *mobile;               // 電話番号
	NSDate				*birthDay;			// 生年月日
	BLOAD_TYPE			bloadType;			// 血液型
	NSString			*syumi;				// 趣味
    NSString            *email1;            //アドレス1
    //NSString            *email2;            //アドレス2
	BOOL				blockMail;			// 受信拒否設定
	NSString			*memo;				// メモ
    // 2016/8/12 TMS 顧客情報に担当者を追加
    NSString            *responsible;        // 担当者
#ifdef CLOUD_SYNC
    NSString			*shopName;			// 店舗名  : 表示用
    SHOPID_INT          shopID;             // 店舗ID  : 設定用
#endif
}

@property(nonatomic)			USERID_INT	userID;
@property(nonatomic, retain)	NSString	*firstName;
@property(nonatomic, retain)	NSString	*secondName;
@property(nonatomic, retain)	NSString	*middleName;
@property(nonatomic, retain)	NSString	*firstNameCana;
@property(nonatomic, retain)	NSString	*secondNameCana;
@property(nonatomic)			NSInteger   registNumber;
@property(nonatomic)			SEX_TYPE	sex;
@property(nonatomic, retain)	NSString	*pictuerURL;
@property(nonatomic, retain)    NSString    *postal;
@property(nonatomic, retain)    NSString    *adr1;
@property(nonatomic, retain)    NSString    *adr2;
@property(nonatomic, retain)    NSString    *adr3;
@property(nonatomic, retain)    NSString    *adr4;
@property(nonatomic, retain)    NSString    *tel;
@property(nonatomic, retain)    NSString    *mobile;
@property(nonatomic, retain)	NSDate		*birthDay;
@property(nonatomic)			BLOAD_TYPE	bloadType;
@property(nonatomic, retain)	NSString	*syumi;
@property(nonatomic, retain)	NSString	*email1;
@property(nonatomic, retain)	NSString	*email2;
@property(nonatomic, assign)	BOOL		blockMail;
@property(nonatomic, retain)	NSString	*memo;
// 2016/8/12 TMS 顧客情報に担当者を追加
@property(nonatomic, retain)	NSString	*responsible;
#ifdef CLOUD_SYNC
@property(nonatomic, copy)      NSString	*shopName;
@property(nonatomic)            SHOPID_INT	shopID;
#endif

// 新規ユーザ作成時のコンストラクタ
- (id) initWithNewUser:(NSString*) fstName secondName:(NSString*)secName
            middleName:(NSString*) midName
		 firstNameCana:(NSString*) fstNameCana secondNameCana:(NSString*)secNameCana
		  registNumber:(NSString*) registNum
				   sex:(SEX_TYPE) sexType;

// 生年月日の設定
-(void) setBirthDayByString:(NSString*)birthString;

// 血液型の設定
-(void) setBloadTypeByInt:(NSInteger)type;

			
// 生年月日（和暦）の取得
- (NSString*) getBirthDayByLocalTime;
// 生年月日（西暦）の取得
- (NSString*) getBirthDayByLocalTimeAD;
- (NSString*) getBirthDayByLocalTimeAD:(BOOL)isJapanese;

// 血液型を文字列で取得
- (NSString*) getBloadTypeByStrig;

// ユーザ名の取得
- (NSString*) getUserName;

// ユーザ名が設定されているか
- (BOOL) isSetUserName;

// お客様番号が有効であるか
- (BOOL) isRegistNumberValid;

// お客様番号の取得
- (NSString*) getRegistNumber;

@end
