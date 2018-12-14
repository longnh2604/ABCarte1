//
//  Common.m
//  iPadCamera
//
//  Created by MacBook on 11/03/28.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/CALayer.h>
#import <UIKit/UIKit.h>

#import <AudioToolbox/AudioToolbox.h>

#include <AVFoundation/AVFoundation.h>  

#import "Common.h"
// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
#import "UIAleartViewCallback.h"
#endif

///
/// 共通クラス
///
@implementation Common

#pragma mark public_methods_static

// Contorlの角を丸める
+ (void)cornerRadius4Control:(UIView*)view
{
    CALayer *layer = [view layer];
	[layer setMasksToBounds:YES];
	[layer setCornerRadius:12.0f];
}

// 女性（または男性）の名前色を取得
+ (UIColor*) getNameColorWithSex:(BOOL)isMen
{
    CGFloat r, g, b;
    
    if (isMen)
    {
        // 男性：青色
        r = 0.0f;
        g = 0.0f;
        b = 1.0f;
    }
    else
    {
        // 女性：ピンク系
        r = 1.0f;
        g = 0.275f;     // 70 / 255
        b = 0.584f;     // 149 / 255
    }
    
    return ([UIColor colorWithRed:r green:g blue:b alpha:1.0f]);
}

// スクロールViewの背景色を取得
+ (UIColor*) getScrollViewBackColor
{
	
    CGFloat r, g, b;
	
	r = 0.882f;		// 225 / 255
	g = 0.894f;     // 228 / 255
	b = 0.914f;     // 149 / 255
    
    return ([UIColor colorWithRed:r green:g blue:b alpha:1.0f]);
}

// ユーザ情報の背景色を取得
+ (UIColor*) getUserInfoBackColor
{
	CGFloat r, g, b;
	
	r = 0.208f;		//  53 / 255
	g = 0.2f;		//  51 / 255
	b = 0.239f;     //  61 / 255
    
    return ([UIColor colorWithRed:r green:g blue:b alpha:1.0f]);
	
}

// TextFieldの入力文字数を制限する:shouldChangeCharactersInRangeイベント対応
+ (BOOL)checkInputTextLengh:(UITextField *)textField inRange:(NSRange)range 
		  replacementString:(NSString *)string
				  maxLength:(NSInteger)length
{
	// 入力文字制限:REGIST_NUMBER_LENGTH以下でOK
	NSMutableString *text = [[textField.text mutableCopy] autorelease];
	[text replaceCharactersInRange:range withString:string];
	return ( [text length] <= length );
}

// 数値入力TextFieldの入力文字種別と文字数を制限する:shouldChangeCharactersInRangeイベント対応
+ (BOOL)checkNumericInputTextLengh:(UITextField *)textField inRange:(NSRange)range 
				 replacementString:(NSString *)string
						 maxLength:(NSInteger)length
{
	// 削除と改行は常にOK
	if ( ([string length] <= 0) || 
		( ([string length] > 0) && ([string isEqualToString:@"\n"]) ) )
	{	return (YES); }
	
	// 数値入力チェック
	static NSString *regEx = @"[0-9]";			// 数値の正規表現
	NSRange rangeChk = [string rangeOfString:regEx
									 options:NSRegularExpressionSearch];	// 正規表現検索
	if (rangeChk.location == NSNotFound)
	{	return (NO); }		// 数値以外はNG

	// 入力文字数チェック
	return ([Common checkInputTextLengh:textField inRange:range 
					  replacementString:string
							  maxLength:length]);
}

// CaLuLuホームページを開く
+ (void) openCaluLuHomePage
{
	@try
	{
		// Safariを起動してHPを開く
		[[UIApplication sharedApplication] openURL:
			[NSURL URLWithString:@"http://www.calulu.jp"]];
	}
	@catch (NSException* exception) {
		NSLog(@"openCaluLuHomePage: Caught %@: %@", 
				[exception name], [exception reason]);
	}
}

// 日付を数値(yyyymmdd)に変更する
+ (NSUInteger) convDate2Uint:(NSDate*)date
{
	if (! date)
	{	return NSUIntegerMax; }
	
	NSCalendar *cal 
	= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	// 年、月、日を求める
	unsigned int flag = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	
	NSDateComponents *comps = [cal components:flag fromDate:date];
	
	NSUInteger uintDate 
	= ([comps year] * 10000) + ([comps month] * 100) + [comps day];
	
	[cal release];
	
	return (uintDate);
}


// view画面をフラッシュする
+ (void)flashViewWindowWithParentView:(UIView*)view flashView:(UIView*)flashView
{
	// flashするviewを白色背景で作成
	// UIView *flashView =[ [UIView alloc] initWithFrame:view.frame];
	[flashView setFrame:
		CGRectMake(0.0f, 0.0f, view.frame.size.width, view.frame.size.height)];
	flashView.backgroundColor = [UIColor whiteColor];
	
	// parentに加える -> 表示される
	// [view addSubview:flashView];
	
	// 初期は非表示なので表示する
	flashView.hidden = NO;
	
	// Animationで透明にしていく
	flashView.alpha = 1.0f;
	
	// アニメーションの開始
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:1.5];
	
	flashView.alpha = 0.0f;
	// flashView.hidden = NO;
	
	// アニメーションの完了と実行
	[UIView commitAnimations];
	
	// flashViewの解放
	// [flashView removeFromSuperview];
	
	/*[flashView release];
	flashView = nil; */
}

// soundの再生
+ (BOOL) playSoundWithResouceName:(NSString*)resName ofType:(NSString*)type
{
    if ([resName isEqualToString:@"shutterSound"])
    {
        // カメラシャッター音はシステムサウンドとする
        AudioServicesPlaySystemSound(1108);
        return (YES);
    }
    
	NSString *path = [[NSBundle mainBundle] pathForResource:resName ofType:type];  
	if (! path)
	{
		NSLog(@"Error at playSound  not found url at resName:%@  ofType:%@", 
			  resName, type);
		return (NO);
	}
	
	BOOL stat = NO;
	
	@try
	{
		NSURL *url = [NSURL fileURLWithPath:path];
	
		NSError *error = nil;
	
		AVAudioPlayer *audio = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error]; 
		// audio.volume = 0.3f;
		stat = [audio play]; 
	
		if (error)
		{
			NSLog(@"Error at playSound  due to error in domain %@ with error code %ld",
			  error.domain, (long)error.code);
			stat = NO;
		}
	}
	@catch (NSException* exception) {
		NSLog(@"playSoundWithResouceName: Caught %@: %@", 
			  [exception name], [exception reason]);
	}
	
	return (stat);
}

// static SystemSoundID _soundID = (SystemSoundID)-1L;
// SystemSoundの再生
+ (BOOL) playSystemSoundWithResouceName:(NSString*)resName ofType:(NSString*)type 
								  soundID:(UInt32*)outSoundID
{
	if (*outSoundID == (UInt32)0)
	{
		NSString *path = [[NSBundle mainBundle] pathForResource:resName ofType:type];  
		if (! path)
		{
			NSLog(@"Error at playSystemSound  not found url at resName:%@  ofType:%@", 
				  resName, type);
			return (NO);
		}
	
		@try
		{
			NSURL *url = [NSURL fileURLWithPath:path];	
			AudioServicesCreateSystemSoundID((CFURLRef)url, (SystemSoundID*)outSoundID);
		}
		@catch (NSException* exception) {
			NSLog(@"playSystemSoundWithResouceName: Caught %@: %@", 
				  [exception name], [exception reason]);
		}
		
		if (*outSoundID == (UInt32)0)
		{
			NSLog(@"Error at playSystemSound by AudioServicesCreateSystemSoundID");
			return (NO);			
		}
	}
	
	BOOL stat = NO;
	@try
	{
		SystemSoundID soundID = (SystemSoundID)(*outSoundID);
		AudioServicesPlaySystemSound(soundID);
		stat = YES;
	}
	@catch (NSException* exception) {
		NSLog(@"playSystemSoundWithResouceName at PlaySystemSoun: Caught %@: %@", 
			  [exception name], [exception reason]);
	}
	
	return (stat);
	
}
static NSMutableDictionary* _memoLabelTable;
// メモのラベルを設定ファイルから読み込む
+ (NSDictionary*) getMemoLabelsFromDefault
{
	if (! _memoLabelTable)
	{
		_memoLabelTable = [NSMutableDictionary dictionary];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		//memo1 label default value
		if (![defaults stringForKey:@"memo1Label"]) 
		{
			[defaults setObject:@"メ　モ１" forKey:@"memo1Label"];
		}
		//memo2 label default value
		if (![defaults stringForKey:@"memo2Label"]) 
		{
			[defaults setObject:@"メ　モ２" forKey:@"memo2Label"];
		}
		// freeMemo
		if (![defaults stringForKey:@"memoFreeLabel"]) 
		{
			[defaults setObject:@"メ　モ" forKey:@"memoFreeLabel"];
		}
		
		[defaults synchronize];
		
		[_memoLabelTable setObject:[defaults stringForKey:@"memo1Label"] 
							forKey:@"memo1Label"];
		[_memoLabelTable setObject:[defaults stringForKey:@"memo2Label"] 
							forKey:@"memo2Label"];
		[_memoLabelTable setObject:[defaults stringForKey:@"memoFreeLabel"] 
							forKey:@"memoFreeLabel"];
		
		[_memoLabelTable retain];
	}
	
	return (_memoLabelTable);
}

+ (void)reloadMemo {
    _memoLabelTable = NULL;
}

// 日付を和暦で取得
+ (NSString*) getDateStringByLocalTime:(NSDate*) date
{
	// 日付の指定のない場合は、当日とする
	if (! date)
	{
		date = [NSDate date];
	}
	
	// 時刻書式指定子を設定
    NSDateFormatter* form = [[NSDateFormatter alloc] init];
    [form setDateStyle:NSDateFormatterFullStyle];
    [form setTimeStyle:NSDateFormatterNoStyle];
  	[form setTimeZone:[NSTimeZone systemTimeZone]];
  
    // ロケールを設定
    NSLocale* loc = [[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"];
    [form setLocale:loc];
    
    // カレンダーを指定
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier: NSJapaneseCalendar];
    [form setCalendar: cal];
    
    // 和暦を出力するように書式指定
    //[form setDateFormat:@"GGyy年MM月dd日　EEEE"];	// 曜日まで出す場合；@"GGyy年MM月dd日EEEE"
	[form setDateFormat:@"年MM月dd日　EEEE"];
	
	//西暦出力用format
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy"];	
	
    // NSString *workDate = [form stringFromDate:newWorkDate];
	NSString *workDate = [NSString stringWithFormat:@"%@%@",
						  [formatter stringFromDate:date],
						  [form stringFromDate:date]];
	
    [formatter release];	
	
    [form release];
    [cal release];
    [loc release];
	
	return(workDate);
}

// 画像がportrait（縦長）かrandscape（横長）かを判定
+ (BOOL) isImagePortrait:(UIImage*)img
{
	// 画像サイズで明らかに縦長の場合は、ここで判定
	if (img.size.width < img.size.height)
	{	return (YES); }
	
	// CGImageRefを取得
	CGImageRef cgImage = [img CGImage];
	
	// ピクセル配列へと分解
	size_t bytesPerRow = CGImageGetBytesPerRow(cgImage);
	CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
	CFDataRef data = CGDataProviderCopyData(dataProvider);
	UInt8* pixels = (UInt8*)CFDataGetBytePtr(data);
	
	int alphaCnt = 0;
	// 先頭から10×10byteが透明の場合は、portrait(縦長)とする
	// for (int y = 10; (y < 20) && (y < img.size.height); y++)
    for (int y = 50; (y < 60) && (y < img.size.height); y++)
	{
		for (int x = 10; (x < 20) && (x < img.size.width); x++)
		{
			UInt8* buf = pixels + y * bytesPerRow + x * 4;
			UInt8 a;
			a = *(buf + 0);
			
			if (a < 10)
			{	alphaCnt++; }
		}
	}
	
	return (alphaCnt > 80);
}


// sqlite日付形式からNSDateに変換する
+ (NSDate*) convertDate2Sqlite:(NSString*)dateStr
{
    // パラメータチェック
    if ((! dateStr) ||
         (dateStr && ([dateStr length] <=0 )) )
    {   return (nil); }
    
    NSDate *date;
    
    // formatterの設定
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale systemLocale]];  // 24時間表示がoffの場合、NSLocaleの設定が必要
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss z"];   // sqliteのDate関数戻りの形式
    // [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
//    [formatter setLocale:[NSLocale currentLocale]];     // 明示的にlocaleを設定
    
    // 引数（sqlite戻り値）yyyy-MM-ddに時刻を加える
    NSString* dateAdd = [NSString stringWithFormat:@"%@ 23:59:59 +0900",
                            dateStr];
    date = [formatter dateFromString:dateAdd];
    // [date retain];
    [formatter release];
    
    return (date);

}

// POSIX時刻から文字列に変換
+ (NSString*) convertPOSIX2String:(NSTimeInterval) timePosix
{
	// POSIX->NSDate
	NSDate* expiresDate = [NSDate dateWithTimeIntervalSince1970:timePosix];
	
	// NSDate → NSString
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[NSLocale systemLocale]];
	[dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *dateString = [dateFormatter stringFromDate:expiresDate];
	[dateFormatter release];
	
	return dateString;
}

// ダイアログを表示する
+ (void) showDialogWithTitle:(NSString*)title message:(NSString*)msg
{
    UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:title
							  message:msg
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil
							  ];
    [alertView show];
	[alertView release];	 
}

// 指定時間のローカル時間を取得
+ (NSTimeInterval) getLocaleDate:(NSDate*)date
{
	if ( date == nil )
		return 0;

	NSDateFormatter* fm = [[NSDateFormatter alloc] init];
	[fm setLocale:[NSLocale systemLocale]];
	[fm setTimeZone:[NSTimeZone systemTimeZone]];
	[fm setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString* strDate = [fm stringFromDate:date];
	NSDate* dt = [fm dateFromString:strDate];
	NSTimeInterval interval = [dt timeIntervalSince1970];
	[fm release];
	return interval;
}

// UUIDの取得
+ (NSString*) getUUID
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if ( iOSVersion < 6.0 )
	{
		CFUUIDRef uuidRef = CFUUIDCreate(NULL);
#if !__has_feature(objc_arc)
		NSString* uuid = (NSString*)CFUUIDCreateString(NULL, uuidRef);
#else
		NSString* uuid = (__bridge_transfer NSString*)CFUUIDCreateString(NULL, uuidRef);
#endif /* objc_arc */
		CFRelease(uuidRef);
		return uuid;
	}
	else
	{
		return [[NSUUID UUID] UUIDString];
	}
}

// チェックサムの生成
+ (NSInteger) getCheckSumWithText:(NSString*) text
{
	// 長さ０です
	if ( text == nil || [text length] == 0 )
		return 0;

	// チェックサム計算
	const char* src = [text UTF8String];
	const char* inp = src;
	u_long length = strlen( src );
    NSInteger sum = 0;
	for ( NSInteger i = 0; i < length; i++ )
	{
		sum += (int)(*(inp + i));
	}
	return sum;
}
// 2016/2/18 TMS グラント対応
#ifdef FOR_GRANT
// はい・いいえのダイアログを表示する
+ (void) showYesNoDialogWithTitle:(NSString *)title message:(NSString *)msg
                      isYesNoType:(BOOL)isYesNo
                    callbackParam:(id)param hCloseDialog:(CMN_onCloseDialogYesNo)hProc
{
    UIAlertView *alertView = nil;
    alertView = [[UIAlertView alloc]
                 initWithTitle:title
                 message:msg
                 callback:^(NSInteger buttonIndex)
                 {
                     if (hProc)
                     {    hProc(alertView, param, (buttonIndex == 0)); }
                 }
                 cancelButtonTitle:(isYesNo)? @"はい" : @"OK"
                 otherButtonTitles:(isYesNo)? @"いいえ" : @"キャンセル", nil
                 ];
    [alertView show];
}
#endif

@end
