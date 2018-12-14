//
//  mstUser.m
//  iPadCamera
//
//  Created by MacBook on 10/10/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "defines.h"
#import "mstUser.h"

#import "Common.h"

#ifdef CLOUD_SYNC
#import "shop/ShopItem.h"
#endif

@implementation mstUser

@synthesize userID;
@synthesize firstName, secondName, middleName, firstNameCana, secondNameCana;
@synthesize registNumber;
@synthesize sex;
@synthesize pictuerURL;
@synthesize postal, adr1, adr2, adr3, adr4, tel,mobile;
@synthesize birthDay;
@synthesize bloadType;
@synthesize email1; //, email2;
@synthesize blockMail;
@synthesize syumi, memo;
// 2016/8/12 TMS 顧客情報に担当者を追加
@synthesize responsible;
#ifdef CLOUD_SYNC
@synthesize shopName;
@synthesize shopID;
#endif


// 新規ユーザ作成時のコンストラクタ
- (id) initWithNewUser:(NSString*) fstName secondName:(NSString*)secName
            middleName:(NSString*) midName
		 firstNameCana:(NSString*) fstNameCana secondNameCana:(NSString*)secNameCana
		  registNumber:(NSString*) registNum
				   sex:(SEX_TYPE) sexType
{
	if (self = [super init])
	{
		// ユーザ基本情報の初期化
		self.firstName = fstName;
		self.secondName = secName;
        self.middleName = midName;
		self.firstNameCana = fstNameCana;
		self.secondNameCana = secNameCana;
		self.registNumber 
			= ([registNum length] > 0)? [registNum intValue] : REGIST_NUMBER_INVALID;	// 無効値は空文字
		self.sex = sexType;
		
		//それ以外のメンバも初期化する
		pictuerURL = @"";
		birthDay = nil;
		bloadType = BloadTypeUnKnown;
		syumi = @"";
        email1 = @"";
        // email2 = @"";  // DELC SASAGE
		memo = @"";
#ifdef CLOUD_SYNC
        shopName = @"";
        shopID = SHOP_COMMON_ID;
#endif
        postal = @"";
        adr1 = @"";
        adr1 = @"";
        adr1 = @"";
        tel = @"";
        mobile = @"";
	}
	
	return (self);
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
//    if (firstName) [firstName release];
//    if (secondName) [secondName release];
//    if (middleName) [middleName release];
//    if (firstNameCana) [firstNameCana release];
//    if (secondNameCana) [secondNameCana release];
//    if (pictuerURL) [pictuerURL release];
//    if (postal) [postal release];
//    if (adr1) [adr1 release];
//    if (adr2) [adr2 release];
//    if (adr3) [adr3 release];
//    if (adr4) [adr4 release];
//    if (tel) [tel release];
//    if (birthDay) [birthDay release];
//    if (syumi) [syumi release];
//    if (email1) [email1 release];
//    if (memo) [memo release];
//    if (shopName) [shopName release];
    
    [super dealloc];
}

// 生年月日の設定
-(void) setBirthDayByString:(NSString*)birthString
{
	/*
    birthDay = ([birthString length] > 0)? 
		[[NSDate alloc] initWithString:
			[NSString stringWithFormat:@"%@ 23:59:59 +0900", birthString]] 
		: nil;
    */
    
    birthDay = [Common convertDate2Sqlite:birthString];
}

// 血液型の設定
-(void) setBloadTypeByInt:(NSInteger)type
{
	switch (type) {
		case 1:
			bloadType = BloadTypeA;
			break;
		case 2:
			bloadType = BloadTypeB;
			break;
		case 3:
			bloadType = BloadTypeO;
			break;
		case 4:
			bloadType = BloadTypeAB;
			break;
		default:
			bloadType = BloadTypeUnKnown;
			break;
	}
}

// 生年月日（和暦）の取得
- (NSString*) getBirthDayByLocalTime
{
	if (! birthDay)
	{
		// 生年月日は未だ設定されていない
		return (@"平成--年--月--日");
	}
	
	// 時刻書式指定子を設定
    NSDateFormatter* form = [[NSDateFormatter alloc] init];
    [form setDateStyle:NSDateFormatterFullStyle];
    [form setTimeStyle:NSDateFormatterNoStyle];
    
    // ロケールを設定
    NSLocale* loc = [[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"];
    [form setLocale:loc];
    
    // カレンダーを指定
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier: NSJapaneseCalendar];
    [form setCalendar: cal];
    
    // 和暦を出力するように書式指定
    [form setDateFormat:@"GGyy年MM月dd日"];	// 曜日まで出す場合；@"GGyy年MM月dd日EEEE"
    
    NSString *birthday = [form stringFromDate:birthDay];
	
    [form release];
    [cal release];
    [loc release];
	
	return(birthday);
}

// 生年月日（西暦）の取得
- (NSString*) getBirthDayByLocalTimeAD
{
    return [self getBirthDayByLocalTimeAD:YES];
}
- (NSString*) getBirthDayByLocalTimeAD:(BOOL)isJapanese
{
	if (! birthDay)
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

        return [[form_en stringFromDate:birthDay] stringByAppendingString:[form stringFromDate:birthDay]];
    }
    else {
        NSDateFormatter* form_en = [[[NSDateFormatter alloc] init] autorelease];
        [form_en setCalendar: [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]];
        [form_en setDateFormat:@"MM / dd / yyyy"];

        return [form_en stringFromDate:birthDay];
    }
}

// 血液型を文字列で取得
- (NSString*) getBloadTypeByStrig
{
	NSString* type;
	
	switch ((NSUInteger)bloadType)
	{
		case (NSUInteger)BloadTypeA:
			type = @"A";
			break;
		case (NSUInteger)BloadTypeB:
			type = @"B";
			break;
		case (NSUInteger)BloadTypeO:
			type = @"O";
			break;
		case (NSUInteger)BloadTypeAB:
			type = @"AB";
			break;
		default:
			type = @"--";
			break;
	}
	
	return (type);
}

// ユーザ名の取得
- (NSString*) getUserName
{
	if ( [self isSetUserName] )
	{
		// 姓と名のいずれかが設定されている場合は、そのまま姓と名を返す
		NSString *userName = [NSString stringWithFormat:@"%@　%@", 
							  ([firstName length] > 0)? firstName : @"  ", 
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

// お客様番号の取得
- (NSString*) getRegistNumber
{
	return ( (self.registNumber != REGIST_NUMBER_INVALID)?
            [NSString stringWithFormat:REGIST_NUMBER_STRING_FORMAT, (long)self.registNumber]
            : @"");
}

@end
