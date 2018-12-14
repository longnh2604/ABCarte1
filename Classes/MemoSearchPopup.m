//
//  MemoSearchPopup.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/24.
//
//

/*
 ** IMPORT
 */
#import "MemoSearchPopup.h"
#import "userDbManager.h"
#import "fcUserWorkItem.h"
#import "Common.h"

@interface MemoSearchPopup ()
{
	/*
	 UIパーツ
	 */
	IBOutlet UIBarButtonItem* btnAndSearch;
	IBOutlet UITableView* memoView;
    IBOutlet UIButton *btnSearch;
    IBOutlet UIButton *btnCancel;
    IBOutlet UITextField *txtFreeWord;

	/*
	 設定データ
	 */
	CommonPopupInfoManager* _commonInfoManager;
	fcUserWorkItem* _userWorkItem;
	id<MemoSearchPopupDelegate> _delegate;
}

/*
 ** Handler
 */
- (IBAction) OnAndSearch:(id)sender;
- (IBAction) OnSearch:(id)sender;
- (IBAction) OnCancel:(id)sender;

/*
 ** Method
 */
- (void) UpdateTableViewAtCell:(TemplateCategoryViewCell*) cell
				   atIndexPath:(NSIndexPath*) indexPath
					CommonInfo:(CommonPopupInfo*) commonInfo;

@end

@implementation MemoSearchPopup

/*
 ** PROPERTY
 */
@synthesize popOverController;

#pragma mark iOS_Framework
/**
 initWithNibName
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
		_commonInfoManager = [[CommonPopupInfoManager alloc] init];
		// User Work Item
		_userWorkItem = [[fcUserWorkItem alloc] init];
    }
    return self;
}

/**
 viewDidLoad
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    if (iOSVersion>=7.0f) {
        NSArray *arr = @[btnSearch, btnCancel];
        for (id parts in arr) {
            [parts setBackgroundColor:[UIColor whiteColor]];
            [[parts layer] setCornerRadius:6.0];
            [parts setClipsToBounds:YES];
            [[parts layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
            [[parts layer] setBorderWidth:1.0];
        }
    }

    // メモのラベルを設定ファイルから読み込む
    NSDictionary *lables = [Common getMemoLabelsFromDefault];
    lbl1 = [lables objectForKey:@"memo1Label"];
    lbl2 = [lables objectForKey:@"memo2Label"];

	// メモの読み込み
	[self loadWorkItem];
	// 共通情報の設定
	[self setupCommonInfo];
}

/**
 viewDidUnload
 */
- (void) viewDidUnload
{
	// UIパーツの解放
	[btnAndSearch release];
	btnAndSearch = nil;
	[btnSearch release];
	btnSearch = nil;
	[btnCancel release];
	btnCancel = nil;
	[memoView release];
	memoView = nil;
	// 共通情報の解放
	[_commonInfoManager release];
	_commonInfoManager = nil;
    [btnSearch release];
    btnSearch = nil;
    [btnCancel release];
    btnCancel = nil;
    [txtFreeWord release];
    txtFreeWord = nil;
	[super viewDidUnload];
}

/**
 viewWillAppear
 */
- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
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
- (void) dealloc
{
	// UIパーツの解放
	[btnAndSearch release];
	[btnSearch release];
	[btnCancel release];
	[memoView release];
	// 共通情報の解放
	[_commonInfoManager release];

    [btnSearch release];
    [btnCancel release];
    [txtFreeWord release];
	[super dealloc];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark EditorPopup_DataSource
/**
 セクション数を返す
 */
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return [_commonInfoManager getCommonInfoCounts];
}

/**
 tableView: numberOfRowsInSection:
 セクションに含まれるセル数を返す
 */
- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
	NSMutableArray* strings = [_commonInfoManager getCommonInfoArrayBySection:section];
	return [strings count];
}

/**
 tableView: titleForHeaderInSection:
 セクションのヘッダータイトルを返す
 */
- (NSString*) tableView:(UITableView*) tableView titleForHeaderInSection:(NSInteger)section
{
	return (section == 0) ? lbl1 : lbl2;
}

/**
 tableView: cellForRowAtIndexPath:
 セルの内容を返す
 */
- (UITableViewCell*) tableView:(UITableView*) tableView
		 cellForRowAtIndexPath:(NSIndexPath*) indexPath
{
	static NSString *CellIndentifier = @"popup_tableview_cell";
	TemplateCategoryViewCell* cell = (TemplateCategoryViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIndentifier];
	if ( cell == nil )
	{
		UIViewController* viewController = [[UIViewController alloc] initWithNibName:@"TemplateCategoryViewCell" bundle:nil];
		cell = (TemplateCategoryViewCell*)[viewController view];
		[viewController release];
	}
	
	// 共通情報の取得
	CommonPopupInfo* commonInfo = [_commonInfoManager getCommonInfoArrayBySection:indexPath.section Row:indexPath.row];
	[self UpdateTableViewAtCell:cell atIndexPath:indexPath CommonInfo:commonInfo];
	
	return cell;
}

/**
 UpdateTableViewAtCell
 */
- (void) UpdateTableViewAtCell:(TemplateCategoryViewCell*) cell
				   atIndexPath:(NSIndexPath*) indexPath
					CommonInfo:(CommonPopupInfo*) commonInfo
{
	// セルにタイトルを設定
	cell.labelCategoryTitle.text = [commonInfo strTitle];
	cell.accessoryType = [commonInfo selected] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	[cell setHighlighted:YES];
}


#pragma mark EditorPopup_DataSource
/**
 tableView: didSelectRowAtIndexPath:
 セルが選択された際に呼び出される
 */
- (void) tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath*) indexPath
{
	// 選択／非選択にする
	CommonPopupInfo* commonInfo = [_commonInfoManager getCommonInfoArrayBySection:indexPath.section Row:indexPath.row];
	[commonInfo setSelected:([commonInfo selected] == YES) ? NO: YES];

	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	cell.accessoryType = [commonInfo selected] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}


#pragma mark Instance_Method
/**
 初期化
 */
- (id) initWithDelegate:(id) delegate
{
	self = [self initWithNibName:@"MemoSearchPopup" bundle:nil];
	if ( self )
	{
		// デリゲート
		_delegate = delegate;
		// サイズ設定
		self.contentSizeForViewInPopover = CGSizeMake(325, 601);
	}
	return self;
}

/**
 共通情報を取得する
 */
- (BOOL) getMemoStringInArray:(NSMutableDictionary*) arrayInfo
{
	if ( arrayInfo == nil ) return NO;
	NSInteger count = [_commonInfoManager getCommonInfoCounts];
	for ( NSInteger i = 0; i < count; i++ )
	{
		NSArray* array = [_commonInfoManager getCommonInfoArrayBySection:i];
		NSMutableArray* arrayObj = [[[NSMutableArray alloc]init]autorelease];
		for ( CommonPopupInfo* info in array )
		{
			if ( [info selected] == YES )
			{
				// 選択されているメモ文字列
				[arrayObj addObject:[info strTitle]];
			}
		}
        // 検索フリーワードの追加
        if ([txtFreeWord.text length] > 0) {
            [arrayObj addObject:txtFreeWord.text];
        }
		[arrayInfo setObject:arrayObj forKey:[[NSNumber numberWithInteger:i] description]];
    }
    // 検索フリーワードが設定されている場合、フリーメモ検索用の情報を設定する
    if ([txtFreeWord.text length] > 0) {
        NSMutableArray* arrayObj = [[[NSMutableArray alloc]init]autorelease];
        [arrayObj addObject:txtFreeWord.text];
        [arrayInfo setObject:arrayObj forKey:[[NSNumber numberWithInteger:2] description]];
    }
	return ([arrayInfo count] > 0) ? YES : NO;
}


#pragma mark Instance_Method
/**
 メモをDBから読み込む
 */
- (BOOL) loadWorkItem
{
	userDbManager* userDbMng = [[userDbManager alloc] initWithDbOpen];
	if ( userDbMng == nil ) return NO;

	// メモ１取得
	[userDbMng getWorkItemListWithWorkItem:_userWorkItem];
	// メモ２取得
	[userDbMng getWorkItemListWithWorkItem2:_userWorkItem];
	
	[userDbMng closeDataBase];
	[userDbMng release];
	return YES;
}

- (BOOL) setupCommonInfo
{
	// メモ１を設定
	NSMutableArray* _memo1 = [NSMutableArray array];
	for ( NSString* strTitle in [_userWorkItem workItemStrings] )
	{
		CommonPopupInfo* info = [[[CommonPopupInfo alloc] init] autorelease];
		[info setStrTitle:strTitle];
		[info setSelected:NO];
		[_memo1 addObject:info];
	}

	// メモ２を設定
	NSMutableArray* _memo2 = [NSMutableArray array];
	for ( NSString* strTitle in [_userWorkItem workItemStrings2] )
	{
		CommonPopupInfo* info = [[[CommonPopupInfo alloc] init] autorelease];
		[info setStrTitle:strTitle];
		[info setSelected:NO];
		[_memo2 addObject:info];
	}

	[_commonInfoManager setCommonInfoInArray:_memo1];
	[_commonInfoManager setCommonInfoInArray:_memo2];
	return YES;
}


#pragma mark Event_Handler
/**
 AND検索
 */
- (IBAction) OnAndSearch:(id)sender
{
	[_delegate OnMemoSearch:self Kind:1];
}


/**
 OR検索
 */
- (IBAction) OnSearch:(id)sender
{
	[_delegate OnMemoSearch:self Kind:2];
}

/**
 キャンセルボタン
 */
- (IBAction) OnCancel:(id)sender
{
	[_delegate OnMemoSearch:self Kind:0];
}

@end
