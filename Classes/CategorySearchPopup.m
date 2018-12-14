//
//  CategorySearchPopup.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/02/28.
//
//

/*
 ** IMPORT
 */
#import "CategorySearchPopup.h"

@implementation CategorySearchPopup

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
}

/**
 viewDidUnload
 */
- (void)viewDidUnload
{
	[viewCategory release];
	viewCategory = nil;
	[btnCategoryCancel release];
	btnCategoryCancel = nil;
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
	[viewCategory release];
	[btnCategoryCancel release];
	[_infoManager release];
	[super dealloc];
}


#pragma mark CategorySearch_Method
/**
 InitWithCategory
 */
- (id) InitWithCategory:(id) category delegate:(id) callback popOver:(UIPopoverController*) popOver
{
	self = [super initWithNibName:@"CategorySearchPopup" bundle:nil];
	if ( self )
	{
		_infoManager = [[CommonPopupInfoManager alloc] init];
		_delegate = callback;
		_popOverController = popOver;
		self.contentSizeForViewInPopover = CGSizeMake(300, 439);
	}
	return self;
}


#pragma mark EditorPopup_DataSource
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
	return [_infoManager getCommonInfoCounts];
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
	static NSString *CellIndentifier = @"popup_tableview_cell";
	TemplateCategoryViewCell* cell = (TemplateCategoryViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIndentifier];
	if ( cell == nil )
	{
		UIViewController* viewController = [[UIViewController alloc] initWithNibName:@"TemplateCategoryViewCell" bundle:nil];
		cell = (TemplateCategoryViewCell*)[viewController view];
		[viewController release];
	}
	
	// 共通情報の取得
	CommonPopupInfo* commonInfo = [_infoManager getCommonInfoByRow:indexPath.row];
	
	// セルにタイトルを設定
	cell.labelCategoryTitle.text = [commonInfo strTitle];
	// 選択されていたらチェックマークをつける
	cell.accessoryType = [commonInfo selected] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cell;
}


#pragma mark EditorPopup_DataSource
/**
 tableView: didSelectRowAtIndexPath:
 セルが選択された際に呼び出される
 */
- (void) tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath*) indexPath
{
	// 全て非選択状態にしておく
	[_infoManager setSelectAll:NO];
	// セレクションに対して選択
	[_infoManager setSelectByRow:YES RowNum:indexPath.row];
	// ポップオーバーを閉じる
	[_popOverController dismissPopoverAnimated:YES];
}


#pragma mark CategorySearch_Handler
/**
 OnClickedCategoryCancel
 */
- (IBAction) OnClickedCategoryCancel:(id) sender
{
	[[self delegate] OnCategoryCanceled:sender];
}



@end
