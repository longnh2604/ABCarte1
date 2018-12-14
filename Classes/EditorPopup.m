//
//  EditorPopup.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/02/28.
//
//

/*
 ** IMPORT
 */
#import "EditorPopup.h"

@implementation EditorPopup

/*
 ** PROPERTY
 */
@synthesize popupMode = _popupMode;
@synthesize strPopupTitle = _strPopupTitle;
@synthesize strKindName = _strKindName;
@synthesize delegate = _delegate;
@synthesize popOverController = _popOverController;


#pragma mark iOS_Framework
/**
 initWithNibName
 */
- (id) initWithNibName:(NSString *) nibNameOrNil bundle:(NSBundle *) nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if ( self )
	{
		// 共通情報の確保
		_arrayCellNames = nil;
		_commonInfoManager = [[CommonPopupInfoManager alloc] init];
		_defMode = YES;
		_deleting = NO;
		_editMode = POPUP_EDIT_UNSELECT;
		self.contentSizeForViewInPopover = CGSizeMake(420, 513);
	}
	return self;
}

/**
 viewDidLoad
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	// ナビゲーションバーの設定
	[self setupNavigationBarWithTitle:_strPopupTitle];
	// ボタン表示の設定
	[self setupButton:YES];
    
    // iOS8だと、イメージと並んでタイトル文字が表示されてしまうため
    [btnClosePopup setTitle:@"" forState:UIControlStateNormal];
    [btnClearAll setTitle:@"" forState:UIControlStateNormal];
    [btnModeChange setTitle:@"" forState:UIControlStateNormal];
    [btnInsertList setTitle:@"" forState:UIControlStateNormal];
    [btnDeleteList setTitle:@"" forState:UIControlStateNormal];
    [btnUpdateList setTitle:@"" forState:UIControlStateNormal];
    [btnEditList setTitle:@"" forState:UIControlStateNormal];
    [btnCancelEdit setTitle:@"" forState:UIControlStateNormal];
}

/**
 viewDidUnload
 */
- (void)viewDidUnload
{
	// ナビゲーションバーの解放
	[navibarTitle release];
	navibarTitle = nil;
	// ビューの解放
	[viewCategory release];
	viewCategory = nil;
	// ボタン類の解放
	[btnClosePopup release];
	btnClosePopup = nil;
	[btnClearAll release];
	btnClearAll = nil;
	[btnModeChange release];
	btnModeChange = nil;
	[btnInsertList release];
	btnInsertList = nil;
	[btnDeleteList release];
	btnDeleteList = nil;
	[btnUpdateList release];
	btnUpdateList = nil;
	[btnEditList release];
	btnEditList = nil;
	[btnCancelEdit release];
	btnCancelEdit = nil;

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
 viewWillAppear
 */
- (void) viewWillAppear:(BOOL)animated
{
	NSInteger nCount = [_commonInfoManager getCommonInfoCounts];
	for ( NSInteger i = 0; i < nCount; i++ )
	{
		CommonPopupInfo* info = [_commonInfoManager getCommonInfoByRow:i];
		if ( [info selected] == YES )
		{
			// ここで選択しておく
			// 選択しておかないと、ポップオーバーを閉じる際に
			// セルが選択されていない事となる
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0 ];
			[viewCategory selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
		}
	}
	[super viewWillAppear:animated];
}

/**
 viewDidDisappear
 */
- (void) viewDidDisappear:(BOOL)animated
{
	// インデックスを取得する
	NSIndexPath *indexPath = [viewCategory indexPathForSelectedRow];

	// セルの状態で判定する
	NSInteger index = 0;
	if ( indexPath != nil )
	{
		// インデックスのデータが選択されているか？
		CommonPopupInfo* info = [_commonInfoManager getCommonInfoByRow:indexPath.row];
		index = ([info selected] == YES) ? indexPath.row : -1;
	}
	else
	{
		// 選択されていない
		index = -1;
	}

	// 削除中は通知しない
	if ( _deleting == NO )
	{
		// 選択と同一の動作をする
		[[self delegate] OnClickedItemEditor:self
									   Event: CLICKED_SELECT
									   Index:index
										Mode:_popupMode];
	}
}

/**
 dealloc
 */
- (void)dealloc
{
	// ナビゲーションバーの解放
	[navibarTitle release];
	// ビューの解放
	[viewCategory release];
	// ボタン類の解放
	[btnClosePopup release];
	[btnClearAll release];
	[btnModeChange release];
	[btnInsertList release];
	[btnDeleteList release];
	[btnUpdateList release];
	[btnEditList release];
	[btnCancelEdit release];

	[super dealloc];
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
	return [_commonInfoManager getCommonInfoCounts];
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
	CommonPopupInfo* commonInfo = [_commonInfoManager getCommonInfoByRow:indexPath.row];
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
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	
	if ( [_commonInfoManager getSelectByRow:indexPath.row] == YES )
	{
		// セレクションに対して非選択
		[_commonInfoManager setSelectByRow:NO RowNum:indexPath.row];
		// チェックマークを外す
		cell.accessoryType = UITableViewCellAccessoryNone;
		// モード切り替え
		_editMode = POPUP_EDIT_UNSELECT;
	}
	else
	{
		// 全て非選択状態にしておく
		[_commonInfoManager setSelectAll:NO];
		// 全てのセルに対してチェックマークを外しておく
		NSInteger rows = [tableView numberOfRowsInSection:0];
		for ( NSInteger i = 0; i < rows; i++ )
		{
			NSIndexPath* path = [NSIndexPath indexPathForRow:i inSection:0];
			UITableViewCell* vc = [tableView cellForRowAtIndexPath:path];
			vc.accessoryType = UITableViewCellAccessoryNone;
		}
		// セレクションに対して選択
		[_commonInfoManager setSelectByRow:YES RowNum:indexPath.row];
		// チェックマークをつける
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		// モード切り替え
		_editMode = POPUP_EDIT_SELECT;
	}

	// 編集モードのボタン切り替え
	[self setupEditModeButton];
}


#pragma mark EditorPopup_Method
/**
 InitWithCategory
 */
- (id) initWithCategory:(id) category
				  title:(NSString*) title
		   selectString:(NSString*) selectString
			   delegate:(id) callback
				popOver:(UIPopoverController*) popOver;
{
	self = [self initWithNibName:@"EditorPopup" bundle:nil];
	if ( self )
	{
		_arrayCellNames = (NSMutableArray*)category;
		_popupMode = POPUP_MODE_CATEGORY;
		_strPopupTitle = title;
		_strKindName = @"カテゴリー";
		_delegate = callback;
		_popOverController = popOver;
		// 共通情報の設定
		[self setupCommonInfo:selectString];
	}
	return self;
}

/**
 initWithGeneral
 */
- (id) initWithGeneral:(id) general
				 title:(NSString*) title
		  selectString:(NSString*) selectString
			  delegate:(id) callback
			   popOver:(UIPopoverController*) popOver
				 GenNo:(NSInteger) genNo
{
	self = [self initWithNibName:@"EditorPopup" bundle:nil];
	if ( self )
	{
		_arrayCellNames = (NSMutableArray*)general;
		_popupMode = genNo;
		_strPopupTitle = title;
		_strKindName = @"汎用フィールド";
		_delegate = callback;
		_popOverController = popOver;
		// 共通情報の設定
		[self setupCommonInfo:selectString];
	}
	return self;
}

/**
 getCellNameFromIndex
 */
- (NSString*) getCellNameFromIndex:(NSInteger) index
{
	if ( index < 0 ) return nil;
	return [_commonInfoManager getCommonInfoTitleByRow:index];
}

/**
 IDを取得する
 */
- (NSString*) getCellCommonIDFromIndex:(NSInteger)index
{
	return [[_commonInfoManager getCommonInfoByRow:index] CommonId];
}

/**
 setupNavigationBarWithTitle
 ナビゲーションバーの設定
 @param strTitle ナビゲーションバーのタイトル文字列
 @return なし
 */
- (void) setupNavigationBarWithTitle:(NSString*) strTitle
{
	if ( [strTitle length] == 0 )
	{
		// タイトル設定されていない場合
		navibarTitle.topItem.title = @"編集";
	}
	else
	{
		// タイトル設定されている場合
		navibarTitle.topItem.title = strTitle;
	}
}

/**
 setupCommonInfo
 */
- (BOOL) setupCommonInfo:(NSString*) selectString
{
	if ( _arrayCellNames == nil ) return NO;
	for ( NSMutableArray* _obj in _arrayCellNames )
	{
		NSString* cmnId = (NSString*)[_obj objectAtIndex:0];
		NSString* title = (NSString*)[_obj objectAtIndex:1];
		NSTimeInterval update = [(NSNumber*)[_obj objectAtIndex:2] doubleValue];
		if ( [title length] == 0 ) continue;

		// 設定
		CommonPopupInfo* _commonInfo = [[[CommonPopupInfo alloc] init] autorelease];
		[_commonInfo setCommonId:cmnId];
		[_commonInfo setStrTitle:title];
		[_commonInfo setUpdateTime:update];
		[_commonInfo setSelected:NO];
		// 追加
		[_commonInfoManager setCommonInfo:_commonInfo];
	}
	if ( selectString != nil )
	{
		NSInteger nCount = [_commonInfoManager getCommonInfoCounts];
		for ( NSInteger i = 0; i < nCount; i++ )
		{
			CommonPopupInfo* info = [_commonInfoManager getCommonInfoByRow:i];
			if ( [[info strTitle] compare:selectString] == NSOrderedSame )
			{
				// 選択する
				[info setSelected:YES];
			}
		}
	}
	return YES;
}

/**
 setupButton
 ボタンを切り替える
 @param defMode YES:デフォルト NO:編集モード
 @return なし
 */
- (void) setupButton:(BOOL) defMode
{
	if ( defMode == YES )
	{
		// 表示させる
		[btnClearAll setHidden:NO];
		[btnModeChange setHidden:NO];
		[btnClosePopup setHidden:NO];
		// 表示しない
		[btnEditList setHidden:YES];
		[btnInsertList setHidden:YES];
		[btnDeleteList setHidden:YES];
		[btnUpdateList setHidden:YES];
		[btnCancelEdit setHidden:YES];
		// 選択
		[btnModeChange setSelected:NO];
	}
	else
	{
		// 表示させる
		[btnEditList setHidden:NO];
		[btnInsertList setHidden:NO];
		[btnDeleteList setHidden:NO];
		[btnModeChange setHidden:NO];
		// 表示しない
		[btnClearAll setHidden:YES];
		[btnClosePopup setHidden:YES];
		[btnUpdateList setHidden:YES];
		[btnCancelEdit setHidden:YES];
		// 選択
		[btnModeChange setSelected:YES];
	}
}

/**
 setupEditModeButton
 編集モード時のボタンの変更
 */
- (void) setupEditModeButton
{
	if ( _defMode == NO )
	{
		// モード変更ボタンが編集モード時のみ
		[btnEditList setEnabled:(_editMode == POPUP_EDIT_UNSELECT) ? NO : YES];
		[btnInsertList setEnabled:(_editMode == POPUP_EDIT_UNSELECT) ? YES : NO];
		[btnDeleteList setEnabled:(_editMode == POPUP_EDIT_UNSELECT) ? NO : YES];
		[btnModeChange setEnabled:(_editMode == POPUP_EDIT_UNSELECT) ? YES : NO];
	}
}

/**
 全て消去ボタンと編集モード切り替えボタンの有効・無効を切り替える
 */
- (void) enabledEditBtn:(BOOL) enabled
{
    [btnClearAll setEnabled:enabled];
    [btnClearAll setHidden:!enabled];
    [btnModeChange setEnabled:enabled];
    [btnModeChange setHidden:!enabled];
}

#pragma mark EditorPopup_Delegate


#pragma mark EditorPopup_Handler
/**
 OnClosePopup
 閉じるボタンが押された
 */
- (IBAction) OnClosePopup:(id)sender
{
	[[self delegate] OnClickedItemEditor:self
								   Event: CLICKED_CLOSE
								   Index:0
									Mode:_popupMode];
}

/**
 OnClearAll
 全てクリアボタンが押された
 */
- (IBAction) OnClearAll:(id)sender
{
	[[self delegate] OnClickedItemEditor:self
								   Event: CLICKED_CLEAR_ALL
								   Index:-1
									Mode:_popupMode];
}

/**
 OnModeChange
 モード変更ボタンが押された
 */
- (IBAction) OnModeChange:(id) sender
{
	// 選択されているセル
	NSIndexPath *indexPath = [viewCategory indexPathForSelectedRow];
	
	// ボタン表示の設定
	NSString *imgName = nil;
	_defMode = (_defMode == YES) ? NO : YES;
	if ( _defMode != YES )
	{
		imgName = @"wkItem_mode_change_on.png";
	}
	else
	{
		imgName = @"wkItem_mode_change_off.png";
	}
	
	// モード切り替えボタンのimage変更
	[btnModeChange setImage:[UIImage imageNamed:imgName]
				   forState: UIControlStateNormal];

	[self setupButton:_defMode];
	if ( indexPath != nil )
	{
		[self setupEditModeButton];
	}
}

/**
 OnInsertList
 挿入ボタンが押された
 */
- (IBAction) OnInsertList:(id) sender
{
	[[self delegate] OnClickedItemEditor:self
								   Event: CLICKED_INSERT
								   Index:-1
									Mode:_popupMode];
}

/**
 OnDeleteList
 削除ボタンが押された
 */
- (IBAction) OnDeleteList:(id)sender
{
	NSIndexPath *indexPath = [viewCategory indexPathForSelectedRow];
	NSInteger index = (indexPath == nil) ? -1 : indexPath.row;

	// 削除中フラグ
	_deleting = YES;

	// デリゲートの呼び出し
	[[self delegate] OnClickedItemEditor:self
								   Event: CLICKED_DELETE
								   Index:index
									Mode:_popupMode];

}

/**
 OnUpdateList
 更新ボタンが押された
 */
- (IBAction) OnUpdateList:(id)sender
{
	// 関係なし
}

/**
 OnEditList
 編集ボタンが押された
 */
- (IBAction) OnEditList:(id)sender
{
	
	NSIndexPath *indexPath = [viewCategory indexPathForSelectedRow];
	NSInteger index = (indexPath == nil) ? -1 : indexPath.row;
	
	[[self delegate] OnClickedItemEditor:self
								   Event: CLICKED_EDIT
								   Index:index
									Mode:_popupMode];
}

/**
 OnCancelEdit
 キャンセルボタンが押された
 */
- (IBAction) OnCancelEdit:(id) sender
{
	// 関係なし
}

/**
 OnDoubleTapGestureInTableView
 */
- (IBAction) OnDoubleTapGestureInTableView:(id)sender
{
	// インデックスを取得する
	NSIndexPath *indexPath = [viewCategory indexPathForSelectedRow];
	NSInteger index = (indexPath == nil) ? -1 : indexPath.row;
	if ( index == -1 ) return;

	// 選択と同一の動作をする
	[[self delegate] OnClickedItemEditor:self
								   Event: CLICKED_SELECT
								   Index:index
									Mode:_popupMode];
}


@end
