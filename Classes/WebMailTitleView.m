//
//  WebMailTitleView.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/08.
//
//

#import "WebMailTitleView.h"
#import "Common.h"
#import <QuartzCore/QuartzCore.h>

@implementation WebMailTitleView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
- (id)initWithMail:(WebMail *)_mail{
    // 12
    self = [super init];
    if (self) {
        mail = _mail;
        self.frame = mail.fromUser ? CGRectMake(20, 0, 235, 100) : CGRectMake(10, 0, 235, 100);
        if (mail.fromUser) {
            self.backgroundColor = [WebMailTitleView userColor];
        } else{
            self.backgroundColor = [WebMailTitleView accountColor];
        }
        // initialize controls
        nameLabel = [[UILabel alloc] init];
        nameLabel.frame = mail.fromUser ?  CGRectMake(115, 5, 115, 15) :CGRectMake(5, 5, 225, 15);
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.font = [UIFont boldSystemFontOfSize:10.0f];
        nameLabel.text = mail.from;
        nameLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
        nameLabel.textAlignment = mail.fromUser ? NSTextAlignmentRight : NSTextAlignmentLeft;
        
        checkLabel = [[UILabel alloc] init];
        checkLabel.frame = CGRectMake(60, 5, 55, 15);
        checkLabel.backgroundColor = [UIColor clearColor];
        checkLabel.font = [UIFont boldSystemFontOfSize:10.0f];
        checkLabel.text = @"チェック";
        checkLabel.textAlignment = NSTextAlignmentRight;
        checkLabel.textColor = [WebMailTitleView checkColor];
        checkLabel.hidden = !mail.check || !mail.fromUser;
        
        unreadLabel = [[UILabel alloc] init];
        unreadLabel.frame = mail.fromUser ? CGRectMake(5, 5, 225, 15) :CGRectMake(175, 5, 55, 15);
        unreadLabel.backgroundColor = [UIColor clearColor];
        unreadLabel.font = [UIFont boldSystemFontOfSize:10.0f];
        unreadLabel.text = ((mail.errorMail == 0) ? (mail.fromUser ? @"返信未読" : @"お客様未読") : @"送信エラー");
        unreadLabel.textAlignment = mail.fromUser ? NSTextAlignmentLeft : NSTextAlignmentRight;
        unreadLabel.textColor = mail.fromUser ? [WebMailTitleView unreadColor] : [WebMailTitleView userUnreadColor];
        unreadLabel.hidden = ((mail.errorMail == 0) ? (mail.fromUser ? !mail.unread : !mail.userUnread) : NO);
        
        contentView = [[UIView alloc] init];
        //contentView.frame = CGRectMake(mail.fromUser ? 5 : 0, 20, 253, 75);
        contentView.frame = CGRectMake( 5, 20, 225, 75);
        contentView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1.0f];
        
        dateLabel = [[UILabel alloc] init];
        dateLabel.frame = CGRectMake(5 , 5, 145, 15);
        dateLabel.text = [WebMailTitleView getDateStringByLocalTime: mail.sendDate];
        dateLabel.font = [UIFont boldSystemFontOfSize:14.0f];
        dateLabel.textColor = [WebMailTitleView dateColor];
        dateLabel.backgroundColor = [UIColor clearColor];
        
        weekLabel = [WebMailTitleView weekLabelByDate:mail.sendDate];
        
        timeLabel = [[UILabel alloc] init];
        timeLabel.frame = CGRectMake(162 , 5, 60, 15);
        timeLabel.textAlignment = NSTextAlignmentRight;
        timeLabel.text = [mail getSendHHmm];
        timeLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
        timeLabel.font = [UIFont systemFontOfSize:12.0f];
        timeLabel.backgroundColor = [UIColor clearColor];
        
        titleLabel = [[UILabel alloc] init];
        titleLabel.frame = CGRectMake(5, 20, 220 , 40);
        titleLabel.text = mail.title;
        titleLabel.font = [UIFont boldSystemFontOfSize:13.0f];
        titleLabel.textColor = [UIColor colorWithWhite:0.62f alpha:1.0f];
        titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        titleLabel.numberOfLines = 3;
        titleLabel.backgroundColor = [UIColor clearColor];
        
        contentView.layer.cornerRadius = 3;
        
        [self addSubview:nameLabel];
        [self addSubview:checkLabel];
        [self addSubview:unreadLabel];
        [self addSubview:contentView];
        [contentView addSubview:dateLabel];
        [contentView addSubview:weekLabel];
        [contentView addSubview:timeLabel];
        [contentView addSubview:titleLabel];
        
        self.layer.cornerRadius = 3;
        self.layer.borderColor = [UIColor blueColor].CGColor;
        // initialize parameters
        isTouch = NO;
    }
    return self;
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    isTouch = YES;
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (isTouch) {
        [self.delegate touchTitleView:self];
    }
    isTouch = NO;
}
- (void)setSelected:(BOOL)isSelected {
    
}
- (BOOL)fromUser{
    return mail.fromUser;
}
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
    
    // ロケールを設定
    NSLocale* loc = [[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"];
    [form setLocale:loc];
    
    // カレンダーを指定
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier: NSJapaneseCalendar];
    [form setCalendar: cal];
    
    // 和暦を出力するように書式指定
    //[form setDateFormat:@"GGyy年MM月dd日　EEEE"];	// 曜日まで出す場合；@"GGyy年MM月dd日EEEE"
	[form setDateFormat:@"年MM月dd日"];
	
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
+ (UILabel *)weekLabelByDate:(NSDate*)date{
    
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(120 , 5, 50, 15);
    label.font = [UIFont boldSystemFontOfSize:14.0f];
    //dateLabel.textColor = [WebMailTitleView dateColor];
    label.backgroundColor = [UIColor clearColor];
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
	[form setDateFormat:@"EEEE"];
    // テキスト設定
	label.text = [form stringFromDate:date];
    NSDateComponents *comps = [cal components:(NSWeekCalendarUnit | NSWeekdayCalendarUnit | NSWeekdayOrdinalCalendarUnit)
                        fromDate:date];
    NSInteger weekday = [comps weekday];
    if (weekday == 1) {
        label.textColor = [WebMailTitleView sundayColor];
    } else if (weekday == 7){
        label.textColor = [WebMailTitleView saturdayColor];
    } else {
        label.textColor = [WebMailTitleView dateColor];
    }
    [form release];
    [cal release];
    [loc release];
    return label;
}
+ (UIColor *)userColor{
    return [UIColor colorWithRed:0.693f green:0.772f blue:0.871f alpha:1.0f];       // lightSteelBlue
}
+ (UIColor *)accountColor{
    return [UIColor colorWithRed:0.87f green:0.87f blue:0.87f alpha:1.0f];
}
+ (UIColor *)userUnreadColor {
    //return [UIColor colorWithRed:0.153f green:0.614f blue:0.016f alpha:1.0f];
    return [UIColor colorWithRed:0.0f green:0.5f blue:0.0f alpha:1.0f];
}
+ (UIColor *)unreadColor {
    return [UIColor colorWithRed:0.852f green:0.645f blue:0.125f alpha:1.0f];       // goldenrod
    //return [UIColor colorWithRed:0.298f green:0.944f blue:0.253f alpha:1.0f];
}
+ (UIColor *)checkColor {
    return [UIColor colorWithRed:0.8f green:0.3f blue:0.3f alpha:1.0f];
}
+ (UIColor *)dateColor {
    return [UIColor colorWithRed:0.498f green:0.498f blue:0.498f alpha:1.0f];
}
+ (UIColor *)sundayColor {
    return [UIColor colorWithRed:0.996f green:0.0f blue:0.09f alpha:1.0f];
}
+ (UIColor *)saturdayColor {
    return [UIColor colorWithRed:0.009f green:0.0f blue:0.896f alpha:1.0f];
}

// Webメールオブジェクトの確認
- (BOOL) isEqualWebMail:(WebMail*)_mail
{
	return (mail == _mail) ? YES : NO;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
@end
