//
//  userInfo.m
//  iPadCamera
//
//  Created by MacBook on 10/10/21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "defines.h"
#import "userInfo.h"

#import "Common.h"

@implementation userInfo

@synthesize userID;
// @synthesize name;
@synthesize firstName, secondName, middleName;
@synthesize registNumber;
@synthesize sex;
@synthesize pictureURL;
@synthesize lastWorkDate;
@synthesize birthDate;
#ifdef CLOUD_SYNC
@synthesize shopName;
#endif
@synthesize notification_error;
@synthesize histID;

// 初期化（コンストラクタ）
- (id)initWithUserInfo:(USERID_INT) usrID
             firstName:(NSString*)fstName
			secondName:(NSString*)secName
            middleName:(NSString*)midName
		  registNumber:(NSString*)regNum
				   sex:(NSInteger)sx
			pictureURL:(NSString*)pictUrl
		  lastWorkDate:(NSString*)lastwkDate
			  birthDay:(NSString*)birthDay
#ifdef CLOUD_SYNC
              shopName:(NSString*)sName
#endif
{
	if (self = [super init])
	{
		userID = usrID;
		// [self setNameWithFirstSecond:fstName secondName:secName];
		// name = [NSString stringWithFormat:@"%@　%@", fstName, secName];
		// NSLog(@"firstName=%@ secondName=%@", fstName, secName);
		// [self setNameWithFirstSecond:fstName secondName:secName];
		firstName = fstName;
		secondName =secName;
        middleName =midName;
		registNumber 
			= ([regNum length] > 0)? [regNum intValue] : REGIST_NUMBER_INVALID;	// 無効値は空文字
		sex = sx;
		pictureURL = pictUrl;
/*
		lastWorkDate = ([lastwkDate length] > 0)? 
			[[NSDate alloc] initWithString:[NSString stringWithFormat:@"%@ 23:59:59 +0900", lastwkDate]] : nil;
*/
		lastWorkDate = [Common convertDate2Sqlite:lastwkDate];
        birthDate = [Common convertDate2Sqlite:birthDay];

        if (lastWorkDate)
        {   [lastWorkDate retain]; }
        if (birthDate)
        {   [birthDate retain]; }
        
#ifdef CLOUD_SYNC
		shopName = sName;
#endif
		notification_error = 0;
	}
	
	return (self);
}

- (void) dealloc
{
    lastWorkDate = nil;
    pictureURL = nil;
    secondName = nil;
    firstName = nil;
    middleName = nil;
    
#ifdef CLOUD_SYNC
    shopName = nil;
#endif
    
    [super dealloc];
}

// 姓と名で名前を設定
- (void)setNameWithFirstSecond:(NSString*)fstName secondName:(NSString*)secName
{
	/*
	name = [NSString stringWithFormat:@"%@　%@", 
			([fstName length] > 0)? fstName : @"  ", 
			([secName length] > 0)? secName : @"  " ];
	*/
	// name = [fstName stringByAppendingString:secName];
	// name = fstName;
}

// ユーザ名の取得
- (NSString*) getUserName
{
	if ( [self isSetUserName] )
	{
		// 姓と名のいずれかが設定されている場合は、そのまま姓と名を返す
		NSString *userName = [NSString stringWithFormat:@"%@　%@%@",
                              ([firstName length] > 0)? firstName : @"  ",
                              ([middleName length] > 0)? [NSString stringWithFormat:@"%@　", middleName] : @"",
                              ([secondName length] > 0)? secondName : @"  " ];
	
		return (userName);
	}
	else if (registNumber != REGIST_NUMBER_INVALID)
	{
		// 姓と名の両方が設定されていない場合は、お客様番号を返す
		return ([NSString stringWithFormat:
					REGIST_NUMBER_STRING_FORMAT, (long)registNumber]);
	}
	else 
	{
		// 姓と名の両方およびお客様番号も設定されていない場合は、空文字とする（通常はありえない）
		return (@"   ");
	}

}

// 最新施術日を和暦で取得
- (NSString*) getLastWorkDate:(BOOL)isJapanese
{
	if (! lastWorkDate)
	{
		// 未だ設定されていない
        return (isJapanese)? @"(施術なし)" : @"------";
	}
	
	// 時刻書式指定子を設定
    NSDateFormatter* form = [[NSDateFormatter alloc] init];
    [form setDateStyle:NSDateFormatterFullStyle];
    [form setTimeStyle:NSDateFormatterNoStyle];
    
    // ロケールを設定
    NSLocale* loc = [[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"];
    [form setLocale:loc];
    
    // カレンダーを指定
    NSCalendar* cal;
    NSString *lastDate;
	
    // 和暦を出力するように書式指定:曜日まで出す
    if (isJapanese) {
        cal = [[NSCalendar alloc] initWithCalendarIdentifier: NSJapaneseCalendar];
        [form setCalendar: cal];
        
        // 和暦を出力するように書式指定:曜日まで出す
        [form setDateFormat:@"年MM月dd日　EEEE"];
        
        //西暦出力用format
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy"];

        lastDate = [NSString stringWithFormat:@"%@%@",
                    [formatter stringFromDate:lastWorkDate],
                    [form stringFromDate:lastWorkDate]];
        [formatter release];
    } else {
        cal = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
        [form setCalendar: cal];
        [form setDateFormat:@"　MM / dd / yyyy"];
        
        lastDate = [form stringFromDate:lastWorkDate];
    }
    
	[form release];
    [cal release];
    [loc release];
	
	return(lastDate);
}

// 生年月日を西暦で取得
- (NSString*) getBirthDayByLocalTimeAD:(BOOL)isJapanese
{
    if (! birthDate)
    {
        // 生年月日は未だ設定されていない
        return (isJapanese)? @"----年--月--日" : @" ------ ";
    }
    
    if (isJapanese) {
        NSDateFormatter* form = [[[NSDateFormatter alloc] init] autorelease];
        [form setCalendar: [[NSCalendar alloc] initWithCalendarIdentifier:NSJapaneseCalendar]];
        [form setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]];
        [form setDateFormat:@"年MM月dd日"];
        
        NSDateFormatter* form_en = [[[NSDateFormatter alloc] init] autorelease];
        [form_en setCalendar: [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]];
        [form_en setDateFormat:@"yyyy"];
        return [[form_en stringFromDate:birthDate] stringByAppendingString:[form stringFromDate:birthDate]];
    }
    else {
        NSDateFormatter* form_en = [[[NSDateFormatter alloc] init] autorelease];
        [form_en setCalendar: [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]];
        [form_en setDateFormat:@"MM / dd / yyyy"];
        
        return [form_en stringFromDate:birthDate];
    }
}

// ユーザ名が設定されているか
- (BOOL) isSetUserName
{
	// 漢字の姓または名のいずれかが設定されていれば、ユーザ名が設定されているとする
	return (([firstName length] > 0) 
				|| ([secondName length] > 0) );
}

// お客様番号が有効であるか
- (BOOL) isRegistNumberValid
{
	return (self.registNumber != REGIST_NUMBER_INVALID);
}

@end
