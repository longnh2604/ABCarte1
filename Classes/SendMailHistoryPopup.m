//
//  SendMailHistoryPopup.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/02/28.
//
//

/*
 ** IMPORT
 */
#import "SendMailHistoryPopup.h"
#import "userFmdbManager.h"

@implementation SendMailHistoryPopup

/*
 ** PROPERTY
 */
@synthesize delegate = _delegate;
@synthesize popOverController;


#pragma mark iOS_Frmaework
/**
 viewDidLoad
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
	// メール送信エラーを取得する
	[self loadWebMailError];
}

/**
 viewDidUnload
 */
- (void)viewDidUnload
{
	[btnDeleteHistory release];
	btnDeleteHistory = nil;
	[btnCancelHistory release];
	btnCancelHistory = nil;
	[viewSendMailHistory release];
	viewSendMailHistory = nil;
	[super viewDidUnload];
}

/**
 didReceiveMemoryWarning
 */
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 dealloc
 */
- (void)dealloc
{
	[btnDeleteHistory release];
	[btnCancelHistory release];
	[viewSendMailHistory release];
	[_infoManager release];
	[super dealloc];
}


#pragma mark SendMailHistory_Method
/**
 initWithMailHistId
 */
- (id) initWithMailHistId:(NSInteger) mailHistId
				 delegate:(id) callback
		popOverController:(UIPopoverController*) controller
{
	self = [super initWithNibName:@"SendMailHistoryPopup" bundle:nil];
	if ( self )
	{
		_infoManager = [[SendMailHistoryInfoManager alloc] init];
		_mailHistId = mailHistId;
		[self setDelegate:callback];
		_popOverController = controller;
		self.contentSizeForViewInPopover = CGSizeMake(365.0f, 420.0f);
	}
	return self;
}

/**
 メール送信エラーを取得する
 */
- (BOOL) loadWebMailError
{
	userFmdbManager* userFmdbMng = [[userFmdbManager alloc] init];
	[userFmdbMng initDataBase];
	NSArray* array = [userFmdbMng getWebMailError];
	for ( NSMutableArray* obj in array )
	{
		SendMailHistoryInfo* info = [[[SendMailHistoryInfo alloc] init]autorelease];
		[info setStrMailTitle:[obj objectAtIndex:0]];
		[info setCountSendMail:[(NSNumber*)[obj objectAtIndex:1] intValue]];
		[info setCountSendError:[(NSNumber*)[obj objectAtIndex:2] intValue]];
		[_infoManager setMailHistoryInfo:info];
	}
	[userFmdbMng release];
	return YES;
}


#pragma mark SendMailHistory_DataSource
/**
 セクション数を返す
 */
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

/**
 tableView: numberOfRowsInSection:
 セクションに含まれるセル数を返す
 */
- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
	return [_infoManager getHistoryCounts];
}

/**
 tableView: titleForHeaderInSection:
 セクションのヘッダータイトルを返す
 */
- (NSString*) tableView:(UITableView*) tableView titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

/**
 tableView: cellForRowAtIndexPath:
 セルの内容を返す
 */
- (UITableViewCell*) tableView:(UITableView*) tableView
		 cellForRowAtIndexPath:(NSIndexPath*) indexPath
{
	static NSString *CellIndentifier = @"sendmail_history_tableview_cell";
	SendMailHistoryTableViewCell* cell = (SendMailHistoryTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIndentifier];
	if ( cell == nil )
	{
		UIViewController* viewController = [[UIViewController alloc] initWithNibName:@"SendMailHistoryTableViewCell" bundle:nil];
		cell = (SendMailHistoryTableViewCell*)[viewController view];
		[viewController release];
	}
	
	// 共通情報の取得
	SendMailHistoryInfo* historyInfo = [_infoManager getMailHistoryInfoByRow:indexPath.row];
	
	// セルにタイトルを設定
	cell.labelMailTitle.text = [historyInfo strMailTitle];
	cell.labelMailHistory.text = [NSString stringWithFormat:@"送信：%ld", (long)[historyInfo countSendMail]];
#if 0
//	cell.labelMailError.text = [NSString stringWithFormat:@"エラー：%d", [historyInfo countSendError]];
#endif
	return cell;
}


#pragma mark SendMailHistory_DataSource
/**
 tableView: didSelectRowAtIndexPath:
 セルが選択された際に呼び出される
 */
- (void) tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath*) indexPath
{
}


#pragma mark SendMailHistory_Handler
/**
 OnDeleteHistory
 */
- (IBAction) OnDeleteHistory:(id) sender
{
	// 履歴削除
	[[self delegate] OnItemClicked:self Event:HIST_CLICKED_DELETE];
}

/**
 OnCancelHistory
 */
- (IBAction) OnCancelHistory:(id) sender
{
	// 履歴キャンセル
	[[self delegate] OnItemClicked:self Event:HIST_CLICKED_CANCEL];
}

@end
