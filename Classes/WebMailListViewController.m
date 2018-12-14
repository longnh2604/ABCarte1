//
//  WebMailListViewController.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/08.
//
//

#import <QuartzCore/QuartzCore.h>
#import "WebMailListViewController.h"
#import "OKDImageFileManager.h"
#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"
#import "Common.h"
#import "Badge.h"
#import "userFmdbManager.h"
#import "userDbManager.h"
#import "mstUser.h"
#import "TextLogTableViewController.h"
#import "HistListViewController.h"

#import "UserInfoListViewController.h"

#ifndef INDICATE_ALERT_DEFINE
#import "SVProgressHUD.h"
#endif

@interface WebMailListViewController ()

@end

@implementation WebMailListViewController
@synthesize userId ,nextUrl, delegate;
#pragma mark public
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        mailsView = [[PullScrollView alloc] initWithDelegate:self];
        titleViews = [[[NSMutableArray alloc] init] retain];
        activeTitleView = nil;
        
        dateLabel = [[UILabel alloc] init];
        titleLabel = [[UILabel alloc] init];
        timeLabel = [[UILabel alloc] init];
        mailView = [[UIView alloc] init];
        
        mailContentLabel = [[UITextView alloc]init];
        mailContentLabel.editable = false;
        mailContentLabel.dataDetectorTypes = UIDataDetectorTypeLink;
        mailContentLabel.linkTextAttributes = @{NSForegroundColorAttributeName: [UIColor blueColor]};
        mailContentLabel.font = [UIFont systemFontOfSize:17.0f];
        mailContentLabel.scrollEnabled = NO;
        mailContentLabel.backgroundColor = [UIColor clearColor];
        
        checkButton = [UIButton buttonWithType:UIButtonTypeCustom];
		delMail = [[DeleteWebMail alloc] initWithDelegate:self];
        // data initialization
        mails = [[[NSMutableArray alloc] init] retain];
        mailIndex = -1;
        mailId = -1;
        userId = -1;
        mailsViewHidden = YES;
        nextUrl = @"default";
        gettingFirstMails = NO;
        isSending = NO;
        submitButton.enabled =YES;
    }
    return self;
}
- (void)refreshWithUserId:(USERID_INT)_userId{
    userId = _userId;
    nextUrl = @"default";
    mailIndex = 0;
    mailId = -1;
    since = NSIntegerMax;
    [self getLocalMails];
    // 一覧表示がONの場合のみサーバへwebメールステータスのチェックを行う
    if (!mailsViewHidden) {
        [self getWebMails:NO];
    }
    mailsViewHidden = NO;
    [self rotateSubviews];
    
    //設定した通知を解除
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SetEmailTitleInWebMailList" object:nil];
    //リストポップアップで何かを選択されたときの通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupEmailTitle:) name:@"SetEmailTitleInWebMailList" object:nil];
}
- (void)getWebMails:(BOOL)force {
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    // あるユーザのある日時（unix time)以前のメールを取得する
    NSInteger until = [manager selectUntilWithUserId:userId];
    [manager release];
    // 連打防止のため、60秒待つ（サーバ側負荷軽減のため）
    if (force || (until + 60 < [[NSDate date] timeIntervalSince1970])) {
        SelectWebMails *select = [[SelectWebMails alloc] initWithDelegate:self];
        [select selectMailsWithUser:userId since:until];
        //[select selectMailsWithUser:userId since:0];
    } else {
        if (mailsView.inProcess) {
            [mailsView processEnd];
        }
    }
    /*
    gettingFirstMails = YES;
    SelectWebMails *select = [[SelectWebMails alloc] initWithDelegate:self];
    [select selectMailsWithUser:userId];
     */
}
- (void)getLocalMails{
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    NSArray *arr = [manager selectMailsSince:since userId:userId];
    for (WebMail *mail in arr) {
        NSInteger sendTimeStamp = (NSInteger)[mail.sendDate timeIntervalSince1970];
        if (sendTimeStamp < since) {
            since = sendTimeStamp;
        }
        [mails addObject:mail];
    }
    [self reloadMails];
}
- (void)reloadMails{
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
    // 削除
    activeTitleView = nil;
    for (int i = 0; i < titleViews.count; i++) {
        [(UIView *)titleViews[i] removeFromSuperview];
    }
    [titleViews removeAllObjects];
    // user idの違うものを削除
    NSMutableArray *tempMails = [NSMutableArray arrayWithArray:mails];
    for (WebMail *mail in tempMails) {
        if (mail.userID != userId) {
            [mails removeObject:mail];
        }
    }
    // 昇順に並び替え
    [mails sortUsingComparator:^NSComparisonResult(WebMail *mail1,WebMail *mail2){
        return [mail2.sendDate compare:mail1.sendDate];
    }];
    //重複を削除
    tempMails = [NSMutableArray arrayWithArray:mails];
    NSInteger mailIdForCheck = -1;
    for (int i = 0; i < tempMails.count; i++) {
        WebMail *tempMail = (WebMail *)tempMails[i];
        if (tempMail.mailId == mailIdForCheck) {
            [mails removeObject:tempMail];
        }
        mailIdForCheck = tempMail.mailId;
    }
    //[self getTestMails];
    int i = 0;
    int getBottom = 0;
    for (WebMail *_mail in mails) {
        WebMailTitleView *titleView = [[WebMailTitleView alloc] initWithMail:_mail];
        titleView.tag = i; //indexを記憶
        titleView.delegate = self;
        [titleViews addObject: titleView];
        CGRect tf = titleView.frame;
        titleView.frame = CGRectMake( tf.origin.x, 10 + 105 * i, tf.size.width, tf.size.height);
        [mailsView addSubview:titleView];
        
        getBottom = titleView.frame.origin.y + titleView.frame.size.height;
        i++;
    }
    CGRect mf = mailsView.frame;
    mailsView.contentSize = CGSizeMake(mf.size.width, getBottom);
    mailIndex = [self mailIdToMailIndex:mailId]; //idからmailIndexを復号

	// UI Update
	[self setMail];
	if (mailsView.inProcess) {
		[mailsView processEnd];
	}
}

// webMail画面の表示・非表示通知
-(void) notifyViewShowWithFlag:(BOOL)isShow
{
    // viewの表示設定
    if (self.view)
    {   self.view.hidden = ! isShow; }
    
    // 非表示の場合、キーボードを閉じて内容もクリア
    if (! isShow) {
        [replyTitleView resignFirstResponder];
        [replyTextView resignFirstResponder];
        
        replyTitleView.text = @"";
        replyTextView.text = @"";
    }
}

#pragma mark override
- (void)viewDidLoad
{
    [super viewDidLoad];
    upButton =  [[UIBarButtonItem alloc] initWithBarButtonSystemItem:103 target:nil action:nil];
    //customize controls
    replyTitleView.placeholder = @"件名を入力して下さい";
    replyTitleView.delegate = self;
    
    replyTextView.layer.cornerRadius = 10.0f;
    replyTextView.layer.borderColor = [UIColor colorWithWhite:0.7f alpha:1.0f].CGColor;
    replyTextView.layer.borderWidth = 1.0f;
    replyTextView.layer.shadowColor = [UIColor blackColor].CGColor;
    replyTextView.layer.shadowOffset = CGSizeMake(-2.0f, -2.0f);
    replyTextView.placeholder = @"メッセージを入力してください";
    replyTextView.delegate = self;
    //---- Mails View
    mailsView.backgroundColor = [UIColor colorWithWhite:0.6f alpha:0.8f];

    mailsView.frame = CGRectMake( -262, 44, 262, 724);
    mailsView.hidden = YES;

    [self.view addSubview:mailsView];
    //---- Content View
    [checkButton setBackgroundImage:[UIImage imageNamed:@"button_push_w160Xh32.png"] forState:UIControlStateSelected];
    [checkButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [checkButton setBackgroundImage:[UIImage imageNamed:@"button_normal_w160Xh32.png"] forState:UIControlStateNormal];
    [checkButton setTitleColor:[UIColor colorWithWhite:0.4f alpha:1.0f] forState:UIControlStateNormal];
    [checkButton setTitle:@"対応済み" forState:UIControlStateNormal];
    [checkButton setTitle:@"未対応チェック" forState:UIControlStateSelected];
    [checkButton setSelected:YES];
    [checkButton addTarget:self action:@selector(check) forControlEvents:UIControlEventTouchUpInside];
    
    [mailView addSubview:checkButton];
    [mailView addSubview:mailContentLabel];
    
    [mailView addSubview:timeLabel];
    [contentView addSubview:dateLabel];
    [contentView addSubview:titleLabel];
    [contentView addSubview:mailView];
    
    // キーボード表示・非表示の通知の登録
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    //リストポップアップで何かを選択されたときの通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupEmailTitle:) name:@"SetEmailTitleInWebMailList" object:nil];
#ifdef MAIL_DELETE_DISABLE
    btnMailDelete.enabled = NO;
#endif
}
#pragma bar button
- (IBAction)catalog:(id)sender{
    if ([MainViewController isNowDeviceOrientationPortrate]) {
        // 縦画面
        [UIView animateWithDuration:0.25f animations:^(void){
            CGRect mf = mailsView.frame;
//            mailsViewHidden = !mailsView.hidden;
            mailsView.hidden = NO;
            if (mailsViewHidden) {
                mf.origin.x = -1 * mf.size.width;
            } else {
                mailsView.hidden = NO;
                mf.origin.x = 0;
                // 最新のメール状態の確認を行う
                [self getWebMails:NO];
            }
            mailsView.frame = mf;
        } completion:^(BOOL finished){
            if (mailsViewHidden) {
                mailsView.hidden = YES;
            }
        }];
    } else {
        // 横画面
        [self rotateCatalog];
    }
}
- (void)rotateCatalog{
    CGRect mf = mailsView.frame;
    if ([MainViewController isNowDeviceOrientationPortrate]) {
        mailsView.hidden = NO;
        // 縦画面
        if (mailsView.hidden){
            mf.origin.x = -1 * mf.size.width;
        } else {
            mf.origin.x = 0;
        }
        mf.size.height = 724.f;
    } else {
        // 横画面
        mf.origin.x = 0;
        mf.size.height = 478.f;
        mailsView.hidden = NO;
    }
    mailsView.frame = mf;
}
- (IBAction)up:(id)sender{
    mailIndex--;
    if (mailIndex < 0) {
        mailIndex = 0;
        [self bounce:contentView offset: -100];
    } else{
        [self setMail];
    }
}
- (IBAction)down:(id)sender{
    mailIndex++;
    if (mailIndex >= mails.count) {
        mailIndex = mails.count - 1;
    } else{
        [self setMail];
    }
}
- (IBAction)back:(id)sender{
    self.view.hidden = YES;
}
- (IBAction)submit:(id)sender{
    // 送信が２重で行われないように
    if (isSending){
        return;
    }
    if ([replyTitleView.text isEqualToString:@""]) {
        UIAlertView *errorAlert =[[UIAlertView alloc] initWithTitle:@"送信エラー" message:@"件名を入力してください" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
        return; //空文字の時は送れない。
    }
    isSending = YES;
    submitButton.enabled = NO;
    // 送信者情報
    NSString *senderName = @"";
    NSString *senderEmail = @"";
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    NSMutableArray *infoBeanArray = [manager selectMailSmtpInfo:1];
    if([infoBeanArray count] != 0){
        mstUserMailItemBean *bean = [infoBeanArray objectAtIndex:0];
        senderName = bean.smtp_user;
        senderEmail = bean.sender_addr;
    }
    
    // タイトルを保存
    [manager insertMailTitle: replyTitleView.text];
    [manager release];
    
    WebMailSender *mailSender = [[WebMailSender alloc] initWithDelegate:self];
    mailSender.dissmissPopupFlag = NO;
    
    // メール送信待機ダイアログ表示
    [SVProgressHUD showWithStatus:@"メール送信中...." maskType:SVProgressHUDMaskTypeGradient];
    
    // メール送信処理
    [mailSender mailSendTaskWithUserId:userId
                            senderName:[senderName retain]
                           senderEmail:[senderEmail retain]
                                 title:[replyTitleView.text retain]
                                  body:[replyTextView.text retain]
                              pictures:@[]];
}

// WebMail削除機能
- (IBAction)trushbox:(id)sender
{
	if ( mailId == 0 )
		return;

	NSString* strMailTitle = nil;
	NSString* strMailDate = nil;
	for ( WebMail* mail in mails )
	{
		if ( mail.mailId == mailId )
		{
			strMailTitle = mail.title;
			strMailDate = [Common getDateStringByLocalTime:mail.sendDate];
			break;
		}
	}
	
	// タイトルの作成
	NSString* strTitle = [strMailDate stringByAppendingString:@" : "];
	strTitle = [strTitle stringByAppendingString:strMailTitle];

	// アラートを表示する
	delProtect = 0;
	if ( alertMailDelete )
	{
		[alertMailDelete release];
		alertMailDelete = nil;
	}
	if ( !alertMailDelete )
	{
		alertMailDelete =
		[[UIAlertView alloc] initWithTitle:strTitle
								   message:@"選択されたメールを削除します。\nよろしいですか？\n(削除すると元に戻せません。)"
								  delegate:self
						 cancelButtonTitle:@"は　い"
						 otherButtonTitles:@"いいえ", nil];
	}
	[alertMailDelete show];
}

#pragma mark WebMailUtility
/**
 Webメールのタイトルを取得する
 @param fmDb	FMDB
 @param mailId	メールID
 @return Webタイトル名
 */
- (NSString*) getWebMailTitle:(userFmdbManager*) fmDb
					   MailID:(NSInteger) mail_id
{
	NSString* strTitle = [fmDb selectMailTitleWhereMailId:mail_id];
	return strTitle;
}

/**
 Webメールの送信日付を取得する
 @param fmDb	FMDB
 @param mailId	メールID
 @return Webの送信日付
 */
- (NSString*) getWebMailDate:(userFmdbManager*) fmDb MailID:(NSInteger) mail_id
{
	// メールIDよりメール作成日時の取得

	// for UNIX
	NSInteger nDate = [fmDb selectMailDateWhereMailId:mail_id];
	NSDate *createDate = [NSDate dateWithTimeIntervalSince1970:nDate];

	// 文字列に変換
	NSString* strDate = [Common getDateStringByLocalTime:createDate];
//	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
//	NSString* strDate = [dateFormatter stringFromDate:createDate];;
	return strDate;
}

#pragma mark delegate
- (void)mailSendThreadEnd:(NSDictionary *)respDic Code:(NSInteger)code
{
    isSending = NO;
    submitButton.enabled = YES;
    replyTitleView.text = @"";
    replyTextView.text = @"";
    [replyTitleView endEditing:NO];
    [replyTextView endEditing:NO];
    // メールの読み込み直し
    [self getWebMails:YES];
    
    // メール送信待機ダイアログを閉じる
    [SVProgressHUD dismiss];
}
- (void)finishedSelectMails:(NSMutableArray *)_mails
                    nextUrl:(NSString *)_nextUrl
                 serverDate:(NSDate *)serverDate
                     userId:(USERID_INT)_userId
                  exception:(NSException *)exception
{
    // メールを取りに行っている間にUI上のユーザが変わっていたら、何もしない
    if (userId != _userId){
        [self reloadMails];
        return;
    }
    // 既読情報を取りに行く
    GetWebMailUserStatus *getStatus = [[GetWebMailUserStatus alloc] initWithDelegate:self];
    [getStatus getStatus:userId];
    // エラーなら何もしない
    if (exception != nil) {
        NSLog(@"%@",exception);
        [self reloadMails];
        return;
    }
    // ユーザ情報取得
    userDbManager *dbManager = [[userDbManager alloc] init];
    mstUser *user = [dbManager getMstUserByID:userId];
    [dbManager release];
    
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    // 送信者情報取得
    NSString *senderName = @"";
    NSMutableArray *infoBeanArray = [manager selectMailSmtpInfo:1];
    if([infoBeanArray count] != 0){
        mstUserMailItemBean *bean = [infoBeanArray objectAtIndex:0];
        senderName = bean.smtp_user;
    }
    NSMutableArray *tempMailArray = [NSMutableArray arrayWithArray:mails];
    for (WebMail *mail in _mails) {
#ifdef DEBUG
        NSLog(@"%d %@", mail.check, mail.title);
#endif
        for (WebMail *m in tempMailArray) {
            if (mail.mailId == m.mailId) {
                [mails removeObject:m];
            }
        }
        mail.userID = userId;
        if (mail.fromUser) {
            mail.from = [NSString stringWithFormat:@"%@　%@様", user.firstName,user.secondName];
        } else if([mail.from isEqualToString:@""]){
            mail.from = senderName;
        }
        [mails addObject:mail];
    }
    FMDatabase *db = [manager databaseConnect];
    BOOL ok = YES;
    [db open];
    [db beginTransaction];
    for (WebMail *mail in _mails) {
        ok = [manager insertMail:mail WithDb:db];
        if (!ok) {
            break;
        }
    }

    [manager updateUntil:[serverDate timeIntervalSince1970]  userId:userId db:db];
    if(ok) {
        [db commit];
    } else {
        [db rollback];
    }
    [db close];
    [manager release];
    if (!(gettingFirstMails && [nextUrl isEqualToString:@""])) {
        nextUrl = _nextUrl;
    }
    //[nextUrl retain];
    [self reloadMails];
}
- (void)pullDownDidEnd{
    [self getWebMails:NO];
}
- (void)pullUpDidEnd{
    [self getLocalMails];
    /*
     if ([nextUrl isEqualToString:@""]) {
     [mailsView processEnd];
     } else {
     SelectWebMails *select = [[SelectWebMails alloc] initWithDelegate:self];
     gettingFirstMails = NO;
     [select selectMailsWithUrl:nextUrl];
     }
     */
}
- (void)finishedGetWebMailUserStatus:(USERID_INT)_userId
							  unread:(NSInteger)unread
						  userUnread:(NSInteger)userUnread
							   check:(NSInteger)check
				  notification_error:(NSInteger)notification_error
						   exception:(NSException *)exception
{
    NSString *string;
    if (exception == nil) {
        string = [NSString stringWithFormat:
                  @"お客様未読:%ld件 返信未読:%ld件 未対応: %ld件 送信エラー:%ld件",
                  (long)userUnread, (long)unread, (long)check, (long)notification_error];

        // 一件のユーザWebMailステータスを即時更新する
        WebMailUserStatus *status = [[WebMailUserStatus alloc] init];
        status.userId = _userId;
        status.unread = unread;
        status.userUnread = userUnread;
        status.check = check;
        status.notification_error = notification_error;
        
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        UIViewController *vc
        = [ mainVC getVC4ViewControllersWithClass:[UserInfoListViewController class]];
        if (vc)
        {   [(UserInfoListViewController*)vc setWebMailUserStatus:status UserID:_userId]; }

    } else {
        // 通信に失敗した時にはローカルから取得
        string = @"現在お客様のメール既読状況が確認できません";
        /*
        userFmdbManager *manager = [[userFmdbManager alloc]init];
        [manager initDataBase];
        WebMailUserStatus *status = [manager getStatus: userId];
        string = [NSString stringWithFormat:
                  @"お客様未読:%d件 返信未読:%d件 返信チェック: %d件",
                  status.userUnread, status.unread, status.check];
         */
    }
    if (userId == _userId ) {
        ((UIButton *)userStatusLabel.customView).titleLabel.text = string;
        [delegate setStatusText:string];
    }
}
- (void)finishedReadWebMail:(NSInteger)_mailId{
    NSLog(@"read");
    // 既読にしたときにチェック状態にする
    CheckWebMail *checkManager = [[CheckWebMail alloc] initWithDelegate:self];
    [checkManager checkMail:_mailId];
    // メールの読み込み直し
    [self getWebMails:YES];
}
- (void)finishedCheckWebMail:(NSInteger)_mailId{
    // [checkButton setSelected:!checkButton.isSelected];
    //
    [self getWebMails:YES];
    // ローカルのDBも書き換える
}

// Webメール削除のデリゲート
- (void) finishedDeleteWebMail:(NSInteger)_mailId
{
	NSLog(@"finishedDeleteWebMail");
	// メールの読み込み直し
    [self getWebMails:NO];
}

// Webメール削除アラートのデリゲート
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// メール削除アラート、「はい」選択以外は処理しない
	if ( alertView != alertMailDelete )
		return;
	if ( buttonIndex != 0 )
		return;
	if ( delProtect > 0 )
		return;

	// 連打防止策
	delProtect++;

	// DBから該当メールを削除する
	userFmdbManager* usrFMDB = [[userFmdbManager alloc] init];
	if ( usrFMDB == nil ) return;
	[usrFMDB initDataBase];
	[usrFMDB removeWebMailWhereMailId:mailId];
	[usrFMDB release];

	// WebMailリストから該当メールを削除する
	for ( WebMail* _mail in mails )
	{
		if ( _mail.mailId != mailId )
			continue;

		for( WebMailTitleView* _titelview in titleViews )
		{
			if ( [_titelview isEqualWebMail:_mail] )
			{
				[_titelview removeFromSuperview];
				[titleViews removeObject:_titelview];
				break;
			}
		}
		[mails removeObject:_mail];
		break;
	}

	// 削除したメールIDを保存しておく
	// reloadMailsでmailIdが変更されてしまう
	NSInteger saveDelMailId = mailId;
	
	// 次のメールを表示させる
	[self reloadMails];

    // サーバーのメール削除
	[delMail deleteWebMail:saveDelMailId];
}

#pragma mark data control
- (void)setMail{
    MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC viewScrollLock:YES];
    
#ifdef INDICATE_ALERT_DEFINE
    UIAlertView *indicatorAlert =
    [[UIAlertView alloc] initWithTitle:@"しばらくお待ちください" message:@"　" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake( 125, 80, 30, 30 )] autorelease];
    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [indicatorAlert addSubview:indicator];
#endif
    // [indicator startAnimating];
    // [indicatorAlert show];
    BOOL isIndAlertShow = NO;
    
    // mails view
    if (titleViews.count > mailIndex) {
        for (WebMailTitleView *v in titleViews) {
            v.layer.borderWidth = 0;
        }
        activeTitleView = (WebMailTitleView *)titleViews[mailIndex];
        activeTitleView.layer.borderWidth = 4;
    }
    // Remove
    NSMutableArray *arr = [NSMutableArray array];
    for (UIView *v in mailView.subviews) {
        if ([v isKindOfClass:[UIImageView class]]) {
            [arr addObject:v];
        }
    }
    for (int i = 0; i < arr.count; i++) {
        [(UIImageView *)arr[i] removeFromSuperview];
    }
    contentView.contentOffset = CGPointZero;
    // Add
    WebMail *mail;
    if (mails.count > mailIndex) {
        mail = mails[mailIndex];
        mailId = mail.mailId;
    } else{
        mail = [[[WebMail alloc] init] autorelease];
    }
    dateLabel.frame = CGRectMake(20, 10, 708, 30);
    dateLabel.textAlignment = NSTextAlignmentLeft;
    dateLabel.text = [Common getDateStringByLocalTime:mail.sendDate];
    dateLabel.font = [UIFont boldSystemFontOfSize:25.0f];
    dateLabel.textColor = [UIColor colorWithWhite:0.7f alpha:1.0f];
    
    if ([MainViewController isNowDeviceOrientationPortrate]) {
        titleLabel = [self makeLabel:titleLabel X:20 Y:50 W:450 LineNumber:2 Text:mail.title FontSize:25.0f];
    } else {
        titleLabel = [self makeLabel:titleLabel X:20 Y:50 W:708 LineNumber:2 Text:mail.title FontSize:25.0f];
    }
    
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = [UIFont boldSystemFontOfSize:25.0f];
    titleLabel.textColor = [UIColor colorWithWhite:0.85f alpha:1.0f];
    int tl_bottom = titleLabel.frame.origin.y + titleLabel.frame.size.height + 5;
    //-- Mail View
    timeLabel.frame = CGRectMake(568, 2, 95, 30);
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.text = [mail getSendHHmm];
    timeLabel.textColor = [UIColor whiteColor];
    timeLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    timeLabel.backgroundColor = [UIColor clearColor];
    
    int bottom = 0;
    const int above = 36;
    const int half = 344;
    const int margin = 10;
    
    OKDImageFileManager *imgFileMng = [[OKDImageFileManager alloc] initWithUserID:userId];
    for (int i = 0; i < mail.pictures.count; i++) {
        
        // 対象画像ファイル名：パスなし
		NSString* fullPath = mail.pictures[i];
        NSString *aFile = [mail.pictures[i] lastPathComponent];
        
        // ファイルがローカルにない場合のみ、Indicatorダイアログを表示
        if ( (! [imgFileMng isExsitFileWithOutPath:aFile isThumbnail:YES]) && (! isIndAlertShow) ) {
#if 0 // flicker対応 kikuta - start - 2014/01/29 -
#ifndef INDICATE_ALERT_DEFINE
            [SVProgressHUD showWithStatus:@"しばらくお待ちください" maskType:SVProgressHUDMaskTypeGradient];
#else
            [indicator startAnimating];
            [indicatorAlert show];
#endif
            isIndAlertShow = YES;
#endif // flicker対応 kikuta - start - 2014/01/29 -
        }
        
        UIImageView *imageV = nil;
        NSRange searchResult1 = [fullPath rangeOfString:@"common"];
        NSRange searchResult2 = [fullPath rangeOfString:@"Common"];
        
        if ( searchResult1.location == NSNotFound && searchResult2.location == NSNotFound )
        {
            if ([MainViewController isNowDeviceOrientationPortrate]) {
                imageV = [[UIImageView alloc] initWithImage:
                          [WebMailListViewController resizedImage:[imgFileMng getThumbnailSizeImage:aFile]
                                                             size:CGSizeMake(210, 158)]];
            } else {
                imageV = [[UIImageView alloc] initWithImage:
                          [WebMailListViewController resizedImage:[imgFileMng getThumbnailSizeImage:aFile]
                                                             size:CGSizeMake(320, 240)]];
            }
        }
        else
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString* accID = [defaults stringForKey:@"accountIDSave"];
            NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];
            OKDImageFileManager* imgFolderMng = [[OKDImageFileManager alloc] initWithFolder:folderName];
            
            if ([MainViewController isNowDeviceOrientationPortrate]) {
                imageV = [[UIImageView alloc] initWithImage:
                          [WebMailListViewController resizedImage:[imgFolderMng getTemplateThumbnailSizeImage:aFile]
                                                             size:CGSizeMake(210, 158)]];
            } else {
                imageV = [[UIImageView alloc] initWithImage:
                          [WebMailListViewController resizedImage:[imgFolderMng getTemplateThumbnailSizeImage:aFile]
                                                             size:CGSizeMake(320, 240)]];
            }
        }
        CGSize is = imageV.frame.size;
        if (i % 2 == 0) {
            // 左側
            if ( i == mail.pictures.count - 1) {
                //右側に配置する写真がないので真ん中に
                if ([MainViewController isNowDeviceOrientationPortrate]) {
                    imageV.frame = CGRectMake(half - is.width, above + 250 * (i / 2), is.width, is.height);
                } else {
                    imageV.frame = CGRectMake(half - is.width * 0.5f, above + 250 * (i / 2), is.width, is.height);
                }
            } else {
                if ([MainViewController isNowDeviceOrientationPortrate]) {
                    imageV.frame = CGRectMake(half - is.width - margin - 140, above + 250 * (i / 2), is.width, is.height);
                } else {
                    imageV.frame = CGRectMake(half - is.width - margin, above + 250 * (i / 2), is.width, is.height);
                }
            }
        } else {
            if ([MainViewController isNowDeviceOrientationPortrate]) {
                imageV.frame = CGRectMake(half + margin - 140, above + 250 * (i / 2), is.width, is.height);
            } else {
                imageV.frame = CGRectMake(half + margin, above + 250 * (i / 2), is.width, is.height);
            }
        }
        
//        if ( searchResult1.location == NSNotFound && searchResult2.location == NSNotFound )
//        {
//            imageV = [[UIImageView alloc] initWithImage:
//                      [WebMailListViewController resizedImage:[imgFileMng getThumbnailSizeImage:aFile]
//                                                         size:CGSizeMake(320, 240)]];
//        }
//        else
//        {
//            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//            NSString* accID = [defaults stringForKey:@"accountIDSave"];
//            NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];
//            OKDImageFileManager* imgFolderMng = [[OKDImageFileManager alloc] initWithFolder:folderName];
//
//            imageV = [[UIImageView alloc] initWithImage:
//                      [WebMailListViewController resizedImage:[imgFolderMng getTemplateThumbnailSizeImage:aFile]
//                                                         size:CGSizeMake(320, 240)]];
//        }
//
//        CGSize is = imageV.frame.size;
//        if ([MainViewController isNowDeviceOrientationPortrate]) {
//            if (i % 2 == 0) {
//                // 左側
//                if ( i == mail.pictures.count - 1) {
//                    //右側に配置する写真がないので真ん中に
//                    imageV.frame = CGRectMake(20, above + 250 * (i / 2), is.width, is.height);
//                } else {
//                    imageV.frame = CGRectMake(20, above + 250 * (i / 2), is.width, is.height);
//                }
//            } else {
//                imageV.frame = CGRectMake(is.width * 0.8f, above + 250 * (i / 2), is.width, is.height);
//            }
//        } else {
//            if (i % 2 == 0) {
//                // 左側
//                if ( i == mail.pictures.count - 1) {
//                    //右側に配置する写真がないので真ん中に
//                    imageV.frame = CGRectMake(half - is.width * 0.5f, above + 250 * (i / 2), is.width, is.height);
//                } else {
//                    imageV.frame = CGRectMake(half - is.width - margin, above + 250 * (i / 2), is.width, is.height);
//                }
//            } else {
//                imageV.frame = CGRectMake(half + margin - 120, above + 250 * (i / 2), is.width, is.height);
//            }
//        }
        
        [mailView addSubview:imageV];
        bottom = imageV.frame.origin.y + imageV.frame.size.height;
    }
    bottom += 10;
    
    if ([MainViewController isNowDeviceOrientationPortrate]) {
        mailContentLabel = [self makeLinkedLabel:mailContentLabel X:20 Y:bottom W:400 LineNumber:0 Text:mail.content FontSize:17.0f];
    } else {
        mailContentLabel = [self makeLinkedLabel:mailContentLabel X:20 Y:bottom W:648 LineNumber:0 Text:mail.content FontSize:17.0f];
    }
    
    bottom = mailContentLabel.frame.origin.y + mailContentLabel.frame.size.height + 10;
    // チェックボタン
    if ([MainViewController isNowDeviceOrientationPortrate]) {
        checkButton.frame = CGRectMake(250, bottom, 160, 32);
    } else {
        checkButton.frame = CGRectMake(500, bottom, 160, 32);
    }
    bottom = checkButton.frame.origin.y + checkButton.frame.size.height + 10;
    [checkButton setSelected:mail.check];
    checkButton.hidden = !mail.fromUser;
    
    mailView.layer.cornerRadius = 2;
    //mailView.backgroundColor =  [UIColor colorWithRed:0.841f green:0.865f blue:0.88f alpha:1.0f];
    mailView.backgroundColor = mail.fromUser ? [UIColor colorWithRed:0.911f green:0.943f blue:0.99f alpha:1.0f]
                                             : [WebMailTitleView accountColor];
//    contentView.contentSize = CGSizeMake(contentView.frame.size.width,
//                                         MAX(contentView.frame.size.height, mailView.frame.origin.y + mailView.frame.size.height));
    // メールが空の時
    if (mail.mailId < 0) {
        checkButton.hidden = YES;
        dateLabel.text = @"";
        timeLabel.text = @"";
    }
    // 既読にする
    if (mail.unread && !self.view.hidden) {
        ReadWebMail *read = [[ReadWebMail alloc] initWithDelegate:self];
        [read readMail:mail.mailId];
        [checkButton setSelected:YES];
    }
    
    //resize mail view
    if ([MainViewController isNowDeviceOrientationPortrate]) {
        mailView.frame = CGRectMake(20, tl_bottom, 688 - 256, MAX(bottom + 10, 562 - tl_bottom));
        replyTitleView.frame = CGRectMake(replyTitleView.frame.origin.x, replyTitleView.frame.origin.y, 663 - 256, replyTitleView.frame.size.height);
        replyTextView.frame = CGRectMake(replyTextView.frame.origin.x, replyTextView.frame.origin.y, 600 -256, replyTextView.frame.size.height);
        submitButton.frame = CGRectMake(622 - 256, submitButton.frame.origin.y, submitButton.frame.size.width, submitButton.frame.size.height);
        timeLabel.frame = CGRectMake(timeLabel.frame.origin.x - 256, timeLabel.frame.origin.y, timeLabel.frame.size.width, timeLabel.frame.size.height);
    } else {
        mailView.frame = CGRectMake(20, tl_bottom, 688, MAX(bottom + 10, 562 - tl_bottom));
        replyTitleView.frame = CGRectMake(replyTitleView.frame.origin.x, replyTitleView.frame.origin.y, 663, replyTitleView.frame.size.height);
        replyTextView.frame = CGRectMake(replyTextView.frame.origin.x, replyTextView.frame.origin.y, 600, replyTextView.frame.size.height);
        submitButton.frame = CGRectMake(622, submitButton.frame.origin.y, submitButton.frame.size.width, submitButton.frame.size.height);
    }
    
    contentView.contentSize = CGSizeMake(contentView.frame.size.width,
                                         MAX(contentView.frame.size.height, mailView.frame.origin.y + mailView.frame.size.height));
    
    // Indicatorダイアログの非表示
#ifndef INDICATE_ALERT_DEFINE
    if (isIndAlertShow) {
        [SVProgressHUD dismiss];
    }
#else
    if (isIndAlertShow) {
        [indicatorAlert dismissWithClickedButtonIndex:0 animated:NO];
    }
    [indicatorAlert release];
    indicatorAlert = nil;
#endif
    [mainVC viewScrollLock:NO];
}
- (void)check{
    CheckWebMail *checkManager = [[CheckWebMail alloc] initWithDelegate:self];
    if (checkButton.isSelected) {
        [checkManager uncheckMail:mailId];
    } else {
        // 仕様変更により、アンチェックできるようにする
        [checkManager checkMail:mailId];
    }
}
- (void)viewDidDisappear:(BOOL)animated {
    //設定した通知を解除
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SetEmailTitleInWebMailList" object:nil];
}
- (void)viewWillUnload:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // キーボード表示・非表示の通知の解除
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
- (void)keyboardWillShow:(NSNotification *)note{
	MainViewController *mainVC
    = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    if ([mainVC.getNowCurrentViewController isKindOfClass:[HistListViewController class]]) {
        NSTimeInterval animationDuration = [[[note userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        CGRect KBRect = [[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        KBRect = [self.view convertRect:KBRect fromView:nil];
        CGFloat KBY = KBRect.origin.y;
        CGRect cf = contentView.frame;
        CGRect rf = replyView.frame;
        CGFloat r_top = KBY - rf.size.height;
        CGFloat c_height = r_top - cf.origin.y;
        [UIView animateWithDuration:animationDuration animations:^(void){
            if ([MainViewController isNowDeviceOrientationPortrate]) {
//                contentView.frame = CGRectMake(0, cf.origin.y, 728, c_height);
//                replyView.frame = CGRectMake(20, r_top, 688, rf.size.height);
                contentView.frame = CGRectMake(256, cf.origin.y, 728 - 256, c_height);
                replyView.frame = CGRectMake(276, r_top, 688 - 256, rf.size.height);
            } else {
                if (c_height > 0) {
                    contentView.frame = CGRectMake(256, cf.origin.y, cf.size.width, c_height);
                }
                replyView.frame = CGRectMake(276, r_top, rf.size.width, rf.size.height);
                [self.view insertSubview:replyView aboveSubview:toolBack];
            }
        } completion:^(BOOL finished){
//            if (popover != nil ) {
//                [popover presentPopoverFromRect:replyTitleView.bounds inView:replyTitleView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//            }
        }];
    }
}
- (void)keyboardWillHide:(NSNotification *)note{
    NSTimeInterval animationDuration = [[[note userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect cf = contentView.frame;
    CGRect rf = replyView.frame;
    [UIView animateWithDuration:animationDuration animations:^(void){
        if ([MainViewController isNowDeviceOrientationPortrate]) {
//            contentView.frame = CGRectMake(0, cf.origin.y, 728, 554);
//            replyView.frame = CGRectMake(20, cf.origin.y + 554 + 10, 688, rf.size.height);
            contentView.frame = CGRectMake(256, cf.origin.y, 728 - 256, 554);
            replyView.frame = CGRectMake(276, cf.origin.y + 554 + 10, 688 - 256, rf.size.height);
        } else {
            contentView.frame = CGRectMake(256, cf.origin.y, cf.size.width, 318);
            replyView.frame = CGRectMake(276, 44+ 318 + 10, rf.size.width, rf.size.height);
        }
    }];
}
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [self textDidBeginEditing];
    if (textField.tag == 11) {
        NSArray     *titleArray;
        userFmdbManager *manager = [[userFmdbManager alloc]init];
        [manager initDataBase];
        titleArray = [manager selectAllMailTitle];
        [manager release];
        
        //タイトル履歴が無ければポップアップを表示しない
        if (![titleArray count]) {
            return;
        }
        //履歴表示
//        TextLogTableViewController *tableview = [[TextLogTableViewController alloc]initWithStyle:UITableViewStylePlain cellItemsArray:titleArray TaskTag:205];
//        // Popoverのインスタンス生成
//        popover = [[UIPopoverController alloc] initWithContentViewController: tableview];
        
        // Popupが表示されていない場合はここで表示する
//        if (! popover.popoverVisible) {
//            [popover presentPopoverFromRect:replyTitleView.bounds inView:replyTitleView
//                   permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//        }
    }
}
- (void)textViewDidBeginEditing:(UITextView *)textView{
    [self textDidBeginEditing];
}
- (void)textDidBeginEditing{
    NSLog(@"%s",__func__);
    // メール一覧を消す
//    [self hideMailsViewIfPortrate];
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
//    if ((textField.tag == 11) && (popover) )
//    {
//        [popover dismissPopoverAnimated:YES];
//        [popover release];
//        popover = nil;
//    }
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self rotateSubviews];
}
- (void)rotateSubviews{
    if (self.view.hidden) {
        return;
    }
    CGRect tf = toolBack.frame;
    CGRect cf = contentView.frame;
    CGRect rf = replyView.frame;
    
    if (cf.size.width < 728) {
        cf.size.width += 256;
        rf.size.width += 256;
    }
    if([MainViewController isNowDeviceOrientationPortrate]){
        //縦画面
        self.view.frame = CGRectMake(20, 220, 728, 768);
        toolBack.frame = CGRectMake(tf.origin.x, tf.origin.y, 728, tf.size.height);
        toolbar.frame = toolBack.frame;
//        catalogButton.title = @"一覧";
        catalogButton.title = @"";
        [catalogButton setStyle:UIBarButtonItemStylePlain];
        [catalogButton setEnabled:FALSE];
        
//        contentView.frame = CGRectMake(0, cf.origin.y, 728, 554);
        contentView.frame = CGRectMake(256, cf.origin.y, 728 - 256, 554);
        
//        replyView.frame = CGRectMake(20, cf.origin.y + 554 + 10, 688, rf.size.height);
        replyView.frame = CGRectMake(276, cf.origin.y + 554 + 10, 432, rf.size.height);
        
    } else{
        //横画面
        self.view.frame = CGRectMake(20, 220, 984, 522);
        toolBack.frame = CGRectMake(tf.origin.x, tf.origin.y, 984, tf.size.height);
        toolbar.frame = toolBack.frame;
        [catalogButton setTitle:@""];
        [catalogButton setStyle:UIBarButtonItemStylePlain];
        [catalogButton setEnabled:FALSE];
        contentView.frame = CGRectMake(256, cf.origin.y, cf.size.width, 318);
        replyView.frame = CGRectMake(276, 44+ 318 + 10, rf.size.width, rf.size.height);
    }
    [self rotateCatalog];
    
    [self setMail];
}
#pragma useful
//文字数、フォントに応じた高さのラベルを作る。
- (UILabel *) makeLabel:(UILabel *)label X:(int)x Y:(int)y W:(int)w LineNumber:(int)num Text:(NSString *) text FontSize:(float) fontSize{
    
    label.text = text;
    CGSize boundingSize = CGSizeMake(w ,10000);
    CGSize labelsize = [label.text sizeWithFont:[UIFont systemFontOfSize:fontSize]
                              constrainedToSize:boundingSize
                                  lineBreakMode: NSLineBreakByWordWrapping];
    
    label.font = [UIFont systemFontOfSize:fontSize];
    [label setLineBreakMode:NSLineBreakByWordWrapping];
    [label setNumberOfLines: num];
    [label setFrame:CGRectMake(x, y, w, labelsize.height)];
    
    return label;
}

- (UITextView *) makeLinkedLabel:(UITextView *)label X:(int)x Y:(int)y W:(int)w LineNumber:(int)num Text:(NSString *) text FontSize:(float) fontSize{
    
    label.text = text;
    
    CGFloat fixedWidth = label.frame.size.width;
    CGSize newSize = [label sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect newFrame = label.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    [label setFrame:CGRectMake(x, y, w, newFrame.size.height)];
    
    return label;
}
- (void)bounce:(UIScrollView *)view offset:(NSInteger)offset{
    [UIView animateWithDuration:.3 animations:^{
        if (offset < 0) {
            view.contentOffset = CGPointMake(0, offset);
        } else{
            view.contentOffset = CGPointMake(0, view.contentOffset.y + offset);
        }
    } completion:^(BOOL finished){
        [UIView animateWithDuration:.2 animations:^{
            view.contentOffset = CGPointMake(0, 0);
        }];
    }];
}
- (NSInteger)mailIdToMailIndex:(NSInteger)_mailId{
    for (int i = 0; i < mails.count; i++) {
        if (((WebMail *)mails[i]).mailId == _mailId) {
            return i;
        }
    }
    return 0;
}
#pragma WebMailTitleViewDelegate
- (void)touchTitleView:(UIView *)titleView{
    activeTitleView = (WebMailTitleView *)titleView;
    mailIndex = activeTitleView.tag;
    [self setMail];
    [self catalog:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (UIImage*)resizedImage:(UIImage*)img size:(CGSize)size
{
    CGFloat imgWidth = img.size.width;
    CGFloat imgHeight = img.size.height;
    CGFloat width_ratio  = size.width  / imgWidth;
    CGFloat height_ratio = size.height / imgHeight;
    CGFloat ratio = (width_ratio < height_ratio) ? width_ratio : height_ratio;
    CGSize resized_size = CGSizeMake(img.size.width*ratio, img.size.height*ratio);
    UIGraphicsBeginImageContext(resized_size);
    [img drawInRect:CGRectMake(0, 0, resized_size.width, resized_size.height)];
    UIImage* resized_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resized_image;
}
#pragma test data
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"touch began");
//    [self hideMailsViewIfPortrate];
}
- (void)hideMailsViewIfPortrate{
    CGRect mf = mailsView.frame;
    if ([MainViewController isNowDeviceOrientationPortrate] && !mailsView.hidden) {
        // 縦画面
        mailsView.hidden = YES;
        mailsViewHidden = YES;
        mf.origin.x = -1 * mf.size.width;
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
}

#pragma mark uiscroll view delegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat scrollPoint = scrollView.contentOffset.y + scrollView.frame.size.height;
    CGFloat contentHeight =  scrollView.contentSize.height;
    NSLog(@"SCROLL %f  %f", scrollPoint, contentHeight);
    
}

//履歴からemailタイトル取得
- (void)setupEmailTitle:(NSNotification *)notification
{
    NSLog(@"setupEmailTitle");
    NSString *data = [[notification userInfo] objectForKey:@"SelectData"];
    replyTitleView.text = data;
    
//    if (popover) {
//        [popover dismissPopoverAnimated:YES];
//        [popover release];
//        popover = nil;
//    }
}
#define ACCOUNT_ID_SAVE_KEY		@"accountIDSave"		// アカウントIDの保存用Key
#define ACCOUNT_PWD_SAVE_KEY	@"accountPwdSave"		// アカウントパスワードの保存用Key

- (void)getTestMails{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *accID  = [defaults stringForKey:ACCOUNT_ID_SAVE_KEY];
	NSString *accPwd = [defaults stringForKey:ACCOUNT_PWD_SAVE_KEY];
    
    if ((! accID) || (! accPwd)) {
        return;
    }
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:SS +0900"];
    
    [mails removeAllObjects];
    WebMail *mail1 = [[WebMail alloc] init];
    mail1.check = YES;
    mail1.fromUser = NO;
    mail1.userID = userId;
    mail1.from = @"○△×整骨院";
    mail1.to = @"岡田　まどか様";
    mail1.sendDate = [formatter dateFromString:@"2014-03-25 16:25:00"];
    mail1.title = @"本日はご来店いただきまして、ありがとうございました";
    mail1.content = @"岡田 　まどか 様\n 本日は、ご来店頂きまことに有難うございました。\n 本⽇の施術結果を送信させて頂きます。\n\n"
    "定期的なケアは美しい髪の第⼀歩!!\n\n 本⽇の施術効果を参考に、ご⾃宅でのケアも頑張って下さい^^";
    
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc] initWithUserID:mail1.userID];
    mail1.pictures = [NSMutableArray arrayWithArray: @[
                      [imgFileMng getRealSizeImage:@"110810_011201.jpg"],
                      [imgFileMng getRealSizeImage:@"110810_111203.jpg"]
                      ]];
    [mails addObject:mail1];
    
    WebMail *mail2 = [[WebMail alloc] init];
    mail2.unread = YES;
    mail2.fromUser = YES;
    mail2.userID = userId;
    mail2.from = @"岡田　まどか様";
    mail2.to = @"○△×美容院";
    mail2.sendDate = [formatter dateFromString:@"2013-03-27 21:45:00"];
    mail2.title = @"質問です。自宅でのケア方法は？";
    mail2.content = mail2.title;
    mail2.pictures = [NSMutableArray array];
    [mails addObject:mail2];
    
    WebMail *mail3 = [[WebMail alloc] init];
    mail3.unread = YES;
    mail3.fromUser = NO;
    mail3.userID = userId;
    mail3.from = @"○△×美容院";
    mail3.to = @"岡田　まどか様";
    mail3.sendDate = [formatter dateFromString:@"2013-03-31 17:25:00"];
    mail3.title = @"ご自宅でのケアについて";
    mail3.content = mail3.title;
    mail3.pictures = [NSMutableArray arrayWithArray: @[
                      [imgFileMng getRealSizeImage:@"110810_111201.jpg"]
                      ]];
    [mails addObject:mail3];
}
@end
