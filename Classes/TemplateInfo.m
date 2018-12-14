//
//  TemplateInfo.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/05.
//
//

/*
 ** IMPORT
 */
#import "TemplateInfo.h"
#import "userDbManager.h"

@implementation TemplateInfo

/*
 ** PROPERTY
 */
@synthesize tmplId = _tmplId;
@synthesize strTemplateTitle = _strTemplateTitle;
@synthesize dateTemplateUpdate = _dateTemplateUpdate;
@synthesize strTemplateBody = _strTemplateBody;
@synthesize categoryId = _categoryId;
@synthesize categoryName = _categoryName;
@synthesize pictureUrls = _pictureUrls;
@synthesize selected = _selected;

#pragma mark iOS_Frmaework
/**
 init
 */
- (id) init
{
	self = [super init];
	if ( self )
	{
		// 初期化
		self.tmplId = nil;
		self.strTemplateTitle = nil;
		self.strTemplateBody = nil;
		self.categoryId = nil;
		self.categoryName = nil;
		// 選択状態はOFF
		[self setSelected:NO];
		// URL文字列の確保
		_pictureUrls = [[NSMutableArray alloc] init];
	}
	return self;
}

/**
 dealloc
 */
- (void) dealloc
{
	// URL文字列の解放
	[_pictureUrls removeAllObjects];
	[_pictureUrls release];

	[super dealloc];
}

/**
 画像の場所を削除する
 */
- (BOOL) removePictUrlByUrl:(NSString*) url
{
	if ( url == nil || [url length] == 0 )
		return NO;

	for ( NSArray* urlInfo in _pictureUrls )
	{
		NSString* urlObj = (NSString*)[urlInfo objectAtIndex:1];
		if ( [urlObj isEqualToString:url] == YES )
		{
			// URLが該当したので削除する
			[_pictureUrls removeObject:urlInfo];
		}
	}
	return YES;
}

/**
 テンプレートの本文を作って返す
 */
- (NSString*) makeTemplateBody
{
    int daySeconds = 24*60*60;

    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy年MM月dd日"];

    // 2016/5/13 TMS 本文未入力の対応
    if(_strTemplateBody == nil)
        _strTemplateBody = @"";
    
    NSString* templateBody = [NSString stringWithString:_strTemplateBody];   //  本文をコピー;
    
    NSDictionary* replace = [self makeReplaceValue:_tmplId];
    
    // 日付
    NSString* replaceDate = [replace objectForKey:@"DATE"];
    NSString* replaceDateYear = [df stringFromDate:[NSDate dateWithTimeIntervalSinceNow:365*daySeconds]];
    
    // 汎用フィールド
    NSString* replaceGen1Field = [replace objectForKey:@"FIELD1"];
    NSString* replaceGen2Field = [replace objectForKey:@"FIELD2"];
    NSString* replaceGen3Field = [replace objectForKey:@"FIELD3"];
    // 文字列を置き換える
    templateBody = [templateBody stringByReplacingOccurrencesOfString:@"{__DATE__}" withString:replaceDate];
    templateBody = [templateBody stringByReplacingOccurrencesOfString:@"{__DATE+YEAR__}" withString:replaceDateYear];
    templateBody = [templateBody stringByReplacingOccurrencesOfString:@"{__DATE＋YEAR__}" withString:replaceDateYear];
    templateBody = [templateBody stringByReplacingOccurrencesOfString:@"{__FIELD1__}" withString:replaceGen1Field];
    templateBody = [templateBody stringByReplacingOccurrencesOfString:@"{__FIELD2__}" withString:replaceGen2Field];
    templateBody = [templateBody stringByReplacingOccurrencesOfString:@"{__FIELD3__}" withString:replaceGen3Field];

    while( 1 ){
        NSRange range = [templateBody rangeOfString:@"\\{__DATE\\+[0-9]*__\\}" options:NSRegularExpressionSearch | NSBackwardsSearch];
        if ( (range.location + range.length) <= [templateBody length]) {
            
            NSString *replacingString = [templateBody substringWithRange:range];
            NSRange range2 = [replacingString rangeOfString:@"\\+[0-9]*" options:NSRegularExpressionSearch | NSBackwardsSearch];
            int addDays = [[replacingString substringWithRange:range2] intValue];
            NSString *afterText = [df stringFromDate:[NSDate dateWithTimeIntervalSinceNow:addDays*daySeconds]];
            
            templateBody = [templateBody stringByReplacingOccurrencesOfString:replacingString withString:afterText];
        }
        else
        {
            break;
        }
    }

    while( 1 ){
        NSRange range = [templateBody rangeOfString:@"\\{__DATE\\＋[0-9]*__\\}" options:NSRegularExpressionSearch | NSBackwardsSearch];
        if ( (range.location + range.length) <= [templateBody length]) {
            
            NSString *replacingString = [templateBody substringWithRange:range];
            NSString *replacingString2 = [templateBody substringWithRange:range];
            replacingString2 = [replacingString2 stringByReplacingOccurrencesOfString:@"＋" withString:@"+"];
            NSRange range2 = [replacingString2 rangeOfString:@"\\+[0-9]*" options:NSRegularExpressionSearch | NSBackwardsSearch];
            int addDays = [[replacingString2 substringWithRange:range2] intValue];
            NSString *afterText = [df stringFromDate:[NSDate dateWithTimeIntervalSinceNow:addDays*daySeconds]];
            
            templateBody = [templateBody stringByReplacingOccurrencesOfString:replacingString withString:afterText];
        }
        else
        {
            break;
        }
    }
    
    [df release];

    return templateBody;
}

/**
 ユーザー名以外の置き換え文字を作る
 */
- (NSDictionary*) makeReplaceValue:(NSString*)templateId
{
    // DBオープン
	userDbManager* userDbMng = [[userDbManager alloc] initWithDbOpen];
    
    // 置き換え文字列の取得
    NSMutableDictionary* replaceValue = [[NSMutableDictionary alloc] init];
    
    // 日付
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy年MM月dd日"];
    [replaceValue setObject:[df stringFromDate:[NSDate date]] forKey:@"DATE"];
    
    // 汎用フィールド
    NSString *gen1FieldId = nil, *gen2FieldId = nil, *gen3FieldId = nil;
    BOOL stat = [userDbMng getGenFieldIdByTemplateId:templateId
                                         Gen1FieldId:&gen1FieldId
                                         Gen2FieldId:&gen2FieldId
                                         Gen3FieldId:&gen3FieldId];
    if ( stat == YES )
    {
        if ( gen1FieldId != nil )
        {
            // Field1
            NSString* fieldId = [userDbMng getGenFieldDataByID:gen1FieldId];
            if ( fieldId != nil && [fieldId length] > 0 )
                [replaceValue setObject:fieldId forKey:@"FIELD1"];
            else
                [replaceValue setObject:@"" forKey:@"FIELD1"];
        }
        else
        {
            // Field1 - 空白で置換されるように空白を入れておく
            [replaceValue setObject:@"" forKey:@"FIELD1"];
        }
        if ( gen2FieldId != nil )
        {
            // Field2
            NSString* fieldId = [userDbMng getGenFieldDataByID:gen2FieldId];
            if ( fieldId != nil && [fieldId length] > 0 )
                [replaceValue setObject:fieldId forKey:@"FIELD2"];
            else
                [replaceValue setObject:@"" forKey:@"FIELD2"];
        }
        else
        {
            // Field2 - 空白で置換されるように空白を入れておく
            [replaceValue setObject:@"" forKey:@"FIELD2"];
        }
        if ( gen3FieldId != nil )
        {
            // Field3
            NSString* fieldId = [userDbMng getGenFieldDataByID:gen3FieldId];
            if ( fieldId != nil && [fieldId length] > 0 )
                [replaceValue setObject:fieldId forKey:@"FIELD3"];
            else
                [replaceValue setObject:@"" forKey:@"FIELD3"];
        }
        else
        {
            // Field3 - 空白で置換されるように空白を入れておく
            [replaceValue setObject:@"" forKey:@"FIELD3"];
        }
    }
    
    [df release];
    
    // DBクローズ
	[userDbMng closeDataBase];
	[userDbMng release];
    
    return replaceValue;
}


@end
