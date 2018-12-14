//
//  fcUserWorkItem.m
//  iPadCamera
//
//  Created by MacBook on 10/10/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "fcUserWorkItem.h"

#import "Common.h"

@implementation fcUserWorkItem

@synthesize userID;
@synthesize userName;
@synthesize workItemDate;
@synthesize workItemListString, workItemListNumber, workItemStrings;
@synthesize workItemListString2, workItemListNumber2, workItemStrings2;
@synthesize histID;
@synthesize headPictureUrl;
@synthesize picturesUrls, userMemos, videosUrls;
@synthesize mailUserUnread, mailReplyUnread, mailCheck;

// 初期化（コンストラクタ）
-(id) initWithWorkItem:(USERID_INT)usrID userName:(NSString*)usrName
{
	if (self = [super init])
	{
		// 基本内容の設定
		userID = usrID;
		userName = usrName;
		
		// インスタンスの初期化
		workItemDate = nil;
		workItemListString = [NSMutableString string];
		[workItemStrings retain];
		workItemListNumber = [NSMutableArray array];
		[workItemListNumber retain];
		workItemStrings = nil;
		workItemListString2 = [NSMutableString string];
		[workItemStrings2 retain];
		workItemListNumber2 = [NSMutableArray array];
		[workItemListNumber2 retain];
		workItemStrings2 = nil;
		
		headPictureUrl = nil;
		picturesUrls = userMemos = videosUrls = nil;
	}
	
	return(self);
}

// 初期化（コンストラクタ:履歴用）
-(id) initWithUserID:(USERID_INT)usrID
{
	if (self = [super init])
	{
		// 基本内容の設定
		userID = usrID;
		histID = 0;
		headPictureUrl = nil;
		userName = nil;
		
		// インスタンスの初期化
		workItemDate = nil;
		workItemStrings = nil;
		workItemStrings2 = nil;
		
		workItemListString = [NSMutableString string];
		[workItemListString retain];
		workItemListNumber = [NSMutableArray array];
		[workItemListNumber retain];
		workItemListString2 = [NSMutableString string];
		[workItemListString2 retain];
		workItemListNumber2 = [NSMutableArray array];
		[workItemListNumber2 retain];
		
		picturesUrls = [NSMutableArray array];
		[picturesUrls retain];
		userMemos = [NSMutableArray array];
		[userMemos retain];
        videosUrls = [NSMutableArray array];
        [videosUrls retain];
	}
	
	return(self);
}

// 最新施術日の設定
-(void) setNewWorkDateByString:(NSString*)workDateString
{
    /*
	newWorkDate = ([workDateString length] > 0)? 
	[[NSDate alloc] initWithString:
		[NSString stringWithFormat:@"%@ 23:59:59 +0900", workDateString]] 
	: nil;
    */
    
    if (workItemDate)
    {   
        [workItemDate release];
        workItemDate = nil;
    }
    
    workItemDate = [Common convertDate2Sqlite:workDateString];
    if (workItemDate)
    {   [workItemDate retain]; }
    
}

// 施術内容の設定
-(void) setWorkItemByString:(NSString*)workItem
{
	if ([workItem length] <= 0)
	{ return; }
	
	if ([workItemListString length] > 0)
	{
		[workItemListString appendString:@"・"];
	}
	
	[workItemListString appendString:workItem];
	
	[workItemListNumber addObject:workItem];
}
// 施術内容の設定:itemNumber >= 1
-(void) setWorkItemByNumber:(NSUInteger)itemNumber
{
	if (itemNumber > [workItemStrings count])
	{	return;}
	
	NSString* item = (NSString*)[workItemStrings objectAtIndex:(itemNumber - 1)];
	
	[self setWorkItemByString:item];
	[workItemListNumber addObject:[NSString stringWithFormat:@"%ld", (long)itemNumber]];
}

// 施術内容2の設定
-(void) setWorkItemByString2:(NSString*)workItem
{
	if ([workItem length] <= 0)
	{ return; }
	
	if ([workItemListString2 length] > 0)
	{
		[workItemListString2 appendString:@"・"];
	}
	
	[workItemListString2 appendString:workItem];
	[workItemListNumber2 addObject:workItem];
}
// 施術内容2の設定:itemNumber >= 1
-(void) setWorkItemByNumber2:(NSUInteger)itemNumber
{
	if (itemNumber > [workItemStrings2 count])
	{	return;}
	
	NSString* item = (NSString*)[workItemStrings2 objectAtIndex:(itemNumber - 1)];
	
	[self setWorkItemByString2:item];
	[workItemListNumber2 addObject:[NSString stringWithFormat:@"%ld", (long)itemNumber]];
}

// 最新施術日を和暦で取得
-(NSString*) getNewWorkDateByLocalTime
{
    return [self getNewWorkDateByLocalTime:_isJapanese];
}

/**
 * 最新施術日を和暦で取得(言語環境指定有り)
 */
-(NSString*) getNewWorkDateByLocalTime:(BOOL)isJapanese
{
    _isJapanese = isJapanese;
	if (! workItemDate)
	{
		// 未だ設定されていない
		// return (@"----年--月--日　--曜日");
        return (isJapanese)? NO_DEFINE_NEW_WORK_DATE_STR : NO_DEFINE_NEW_WORK_DATE_ENG;
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
    NSString *workDate;
    
    // 和暦を出力するように書式指定:曜日まで出す
    if (isJapanese) {
        cal = [[NSCalendar alloc] initWithCalendarIdentifier: NSJapaneseCalendar];
        [form setCalendar: cal];
        
        // 和暦を出力するように書式指定:曜日まで出す
        [form setDateFormat:@"年MM月dd日　EEEE"];
        
        //西暦出力用format
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy"];
        
        workDate = [NSString stringWithFormat:@"%@%@",
                    [formatter stringFromDate:workItemDate],
                    [form stringFromDate:workItemDate]];
        [formatter release];
    } else {
        cal = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
        [form setCalendar: cal];
        [form setDateFormat:@"　MM / dd / yyyy"];
        
        workDate = [form stringFromDate:workItemDate];
    }
	
    [form release];
    [cal release];
    [loc release];
	
	return(workDate);
}

// 施術内容のリセット
-(void) resetWorkItem
{
	//[workItemListString stringByAppendingString:@""];
	[workItemStrings release];
	workItemListString = [NSMutableString string];
	
	if([workItemListNumber count] > 0)
	{
		[workItemListNumber removeAllObjects];
	}
}

// 施術内容(文字と数値)のリセット
-(void) resetWorkItemList
{
	// [workItemListString setString: @""];
	// [workItemListString deleteCharactersInRange:NSMakeRange(0, [workItemListString length])];
	if (workItemListString)
	{
		[workItemListString release];
		workItemListString = nil;
	}
	workItemListString = [NSMutableString string];
	
	if([workItemListNumber count] > 0)
	{
		[workItemListNumber removeAllObjects];
	}
}

//	先頭memoの取得
-(NSString*) getTopMemo
{
	return ( ([self.userMemos count] > 0)?
			[self.userMemos objectAtIndex:(NSUInteger)0] : NO_TOP_MEMO_STR);
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __func__);
#endif
	if (workItemDate)
	{	[workItemDate release];
        // [self.workItemDate release];
    }
	if (workItemStrings)
	{
        [workItemStrings removeAllObjects];
        [workItemStrings release];
    }
	if (workItemListNumber)
	{
        [workItemListNumber removeAllObjects];
        [workItemListNumber release];
    }
	if (workItemStrings2)
	{
        [workItemStrings2 removeAllObjects];
        [workItemStrings2 release];
    }
	if (workItemListNumber2)
	{
        [workItemStrings removeAllObjects];
        [workItemListNumber2 release];
    }
    
    workItemListString2 = nil;
    workItemListString = nil;
	
	if (picturesUrls)
	{
        [picturesUrls removeAllObjects];
        [picturesUrls release];
    }
	if (userMemos)
	{
        [userMemos removeAllObjects];
        [userMemos release];
    }
	if (videosUrls)
    {
        [videosUrls removeAllObjects];
        [videosUrls release];
    }

    [super dealloc];
}


@end
