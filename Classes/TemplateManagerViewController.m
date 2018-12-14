//
//  TemplateManagerViewController.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/02/26.
//
//

/*
 ** IMPORT
 */
#import "Common.h"
#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"
#import "TemplateManagerViewController.h"
#import "TemplateCreatorViewController.h"
#import "TemplateListTableViewCell.h"
#import "userDbManager.h"
#import "ThumbnailViewController.h"
#import "OKDImageFileManager.h"

/*
 ** DEFINE
 */
#define CATEGORY_SEARCH_SAVE_KEY  @"CategorySearchData"
#define ALERT_TAG_DELETE_TEMPLATE	100
#define ALERT_TAG_INSERT_CATEGORY	101
#define ALERT_TAG_EDIT_CATEGORY		102
#define ALERT_TAG_DELETE_CATEGORY	103
#define ALERT_TAG_CLEARALL_CATEGORY	104

@implementation TemplateManagerViewController

/*
 ** PROPERTY
 */
@synthesize userId;


#pragma mark iOS_Frmaework
/**
 initWithNibName
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self )
	{
        // Custom initialization
		// 初期のウィンドウの位置を設定しておく
		_windowView = WIN_VIEW_BROADCASTMAIL_USER_LIST;
		// カテゴリー管理の確保
		_commonInfoMng = [[CommonPopupInfoManager alloc] init];
		// カテゴリー名
		_arrayCategoryStrings = [[NSMutableArray alloc] init];
		// テンプレートリスト管理の確保
		_templInfoList = [[TemplateInfoListManager alloc] initWithDelegate:self];
		// 選択されているカテゴリー名のロード
		[self initCategoryData];
        
        _previewPicturesList = [[NSMutableArray alloc] init];
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
	
	// Mainビューの取得
	MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// カラーの取得
	UIColor* bkColor = [mainVC getColorTable:BK_COLOR_DEFAULT]; // 現在はデフォルト設定で背景色を設定しておく
	
    // 背景色の変更 RGB:D8BFD8
    [self.view setBackgroundColor:bkColor];
	
	// カテゴリーをロードする
	[self loadCategoryName];

	// ロードする
	[self refiningTemplateDatabaseWithCategory:_strSelectCategory];

	// swipe
	[self setupSwipeRightView];
    
    [btnTemplateEditor setEnabled:NO];
    [btnTemplateEditor setAlpha:0.5f];
    [btnTemplateDelete setEnabled:NO];
    [btnTemplateDelete setAlpha:0.5f];
    
    [self setTemplateAllNum];
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if ( iOSVersion >= 7.0 ){
        previewBody.frame = CGRectMake(previewBody.frame.origin.x, -20, previewBody.frame.size.width, previewBody.frame.size.height);
    }
}

/**
 viewDidUnload
 */
- (void) viewDidUnload
{
	// ボタン類の解放
	[btnTemplateCreator release];
	btnTemplateCreator = nil;
	[btnTemplateDelete release];
	btnTemplateDelete = nil;
	[btnTemplateEditor release];
	btnTemplateEditor = nil;
	[btnTemplateCategory release];
	btnTemplateCategory = nil;
	// テーブルビューの解放
	[templateTableView release];
	templateTableView = nil;
	// ポップオーバーの解放
	[popOverCtrlCategory release];
	popOverCtrlCategory = nil;
	// カテゴリーリスト管理の解放
	[_commonInfoMng release];
	_commonInfoMng = nil;
	// テンプレートリスト管理の解放
	[_templInfoList release];
	_templInfoList = nil;

	[super viewDidUnload];
}

/**
 viewWillAppear
 */
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    [self rotateToInterfaceOrientation:self.interfaceOrientation WillRotate:false];
}

/**
 viewDidAppear
 */
- (void) viewDidAppear:(BOOL)animated
{
	switch( _windowView )
	{
	case WIN_VIEW_TEMPLATE_MANAGE:
		{
			// なにもしない
		}
		break;
			
	case WIN_VIEW_TEMPLATE_CREATOR:
		{
			// 位置を初期化しておく
			_windowView = WIN_VIEW_TEMPLATE_MANAGE;
            /*
			// カテゴリーをロードする
			[self loadCategoryName];
			// ロードする
			[self refiningTemplateDatabaseWithCategory:_strSelectCategory];
			// テーブルビューのリロード
			[templateTableView reloadData];
			// 再選択
			if ( _oldIndexPath != nil )
			{
				[templateTableView selectRowAtIndexPath:_oldIndexPath
											   animated:YES
										 scrollPosition:UITableViewScrollPositionNone];
			}*/
		}
		break;
			
	default:
		break;
	}
	[super viewDidAppear:animated];
}

/**
 viewDidDisappear
 */
- (void) viewDidDisappear:(BOOL)animated
{
	// 選択されている
	[self saveCategoryData];
	
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Overriden to allow any orientation.
    return YES;
}

/**
 didRecieveMemoryWarning
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
	// ボタン類の解放
	[btnTemplateCreator release];
	[btnTemplateDelete release];
	[btnTemplateEditor release];
	[btnTemplateCategory release];
	// テーブルビューの解放
	[templateTableView release];
	// ポップオーバーの解放
	[popOverCtrlCategory release];
	// カテゴリーリスト管理の解放
	[_commonInfoMng release];
	// カテゴリー名の解放
	[_arrayCategoryStrings removeAllObjects];
	[_arrayCategoryStrings release];
	// テンプレートリスト管理の解放
	[_templInfoList release];

    [_previewPicturesList removeAllObjects];
	[_previewPicturesList release];
    
	[super dealloc];
}


#pragma mark Delegate
/**
 OnSwipeRightView
 @param sender
 @return void
 */
- (void) OnSwipeRightView:(id) sender
{
	[self OnReturnUserInfoList];
}

/**
 OnSwipeLeftView
 */
- (void) OnSwipeLeftView:(id) sender
{
	[self OnGotoTemplateCreator:sender];
}

/**
 OnClickedCategoryEditor
 */
- (void) OnClickedItemEditor:(id)sender
					   Event:(NSInteger)event
					   Index:(NSInteger)cellIndex
						Mode:(NSInteger)mode

{
	EditorPopup* editor = (EditorPopup*)sender;
	NSString* strCancel = @"取消";
	UISpecialAlertView* alert = nil;

	// ポップオーバーを閉じる
	if ( popOverCtrlCategory != nil )
		[popOverCtrlCategory dismissPopoverAnimated:YES];
	
	switch ( event )
	{
	case CLICKED_SELECT:
		{
			// 選択なし
			if ( cellIndex == -1 )
			{
				[templateTableView reloadData];
				break;
			}

			// 選択されたカテゴリーを設定しておく
			_strSelectCategory = [editor getCellNameFromIndex:cellIndex];

			// 絞り込み検索
			[self refiningTemplateDatabaseWithCategory:_strSelectCategory];
			
			// テーブルビューの再描画
			[templateTableView reloadData];
            
            // テンプレートの選択がreloadDataで外れるので編集ボタンと消去ボタンを非活性化
            [btnTemplateEditor setEnabled:NO];
            [btnTemplateEditor setAlpha:0.5f];
            [btnTemplateDelete setEnabled:NO];
            [btnTemplateDelete setAlpha:0.5f];
            
            //  プレビューを初期画面一旦戻す。
            [self updatePreview:nil];
            [lblAttachmentImgNum setHidden:YES];
		}
		break;

	case CLICKED_INSERT:
		{
			// アラートビューの設定
			alert = [[UISpecialAlertView alloc] initWithTitle:[[editor strKindName] stringByAppendingString:@"の追加"]
													  message:[[editor strKindName] stringByAppendingString:@"を追加します"]
													 delegate:self
											cancelButtonTitle:@"追加"
											otherButtonTitles:strCancel, nil ];
			// アラートビューにテキストフィールド追加
			[alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
			[alert setTag:ALERT_TAG_INSERT_CATEGORY];
			// テキストフィールド
			UITextField* textField = [alert textFieldAtIndex:0];
			[textField setPlaceholder:[[editor strKindName] stringByAppendingString:@"を追加してください"]];
			// Blockを追加
			[alert showWithCallback:^(NSInteger buttonIndex){
				// cancel
				if ( buttonIndex != 0 )
					return;

				// カテゴリーのタイトルを取得
				NSString* strCategory = [[alert textFieldAtIndex:0] text];
				if ( [strCategory length] == 0 )
				{
					[Common showDialogWithTitle:@"カテゴリーの追加"
										message:@"カテゴリー名が入っていません"];
					return;
				}

				// DB取得
				userDbManager* dbMng = [[userDbManager alloc] init];
				if ( dbMng == nil ) return;

                // 既存カテゴリーのチェック
                if ( [dbMng chkCategoryName:strCategory] == false){
                    [Common showDialogWithTitle:@"カテゴリー名の重複"
                                        message:@"すでに同名のカテゴリー名が登録済みです。"];
                    // DB解放
                    [dbMng release];
                    
                    return;
                }
                
				// 作成日時
				NSTimeInterval date = [[NSDate date] timeIntervalSince1970];

				// カテゴリーを追加
				[dbMng insertCategory:strCategory Date:date];
				[self loadCategoryName];
				
				// DB解放
				[dbMng release];
			}];
		}
		break;
			
	case CLICKED_DELETE:
		{
			if ( cellIndex == -1 )
			{
				// 非選択のアラートを表示
				alert = [self createAlertViewForNoSelect];
			}
			else
			{
				// 選択されているセルの名前
				__block NSString* cellName = [editor getCellNameFromIndex:cellIndex];

				// アラートビューの設定
				alert = [[UISpecialAlertView alloc] initWithTitle:[[editor strKindName] stringByAppendingString:@"の削除"]
														  message:[[editor getCellNameFromIndex:cellIndex] stringByAppendingString:@"を削除します"]
														 delegate:self
												cancelButtonTitle:@"削除"
												otherButtonTitles:strCancel, nil ];
				[alert setTag:ALERT_TAG_DELETE_CATEGORY];
				// Blockを追加
				[alert showWithCallback:^(NSInteger buttonIndex){
					// cancel
					if ( buttonIndex != 0 )
						return;
					
					// DB取得
					userDbManager* dbMng = [[userDbManager alloc] init];
					if ( dbMng == nil ) return;
					
					// 削除するカテゴリーの確認
					NSString* categoryId = [editor getCellCommonIDFromIndex:cellIndex];
					if ( [dbMng isCategoryDefaultWithID:categoryId] == NO )
					{
						// DBの削除
						[dbMng deleteCategory:categoryId];
						[self initCategoryData];

						// 削除完了メッセージ
						NSString* msg = [NSString stringWithFormat:@"%@が削除されました", cellName];
						[Common showDialogWithTitle:@"カテゴリーの削除" message:msg];
					}
					else
					{
						// カテゴリー「なし」は削除できない
						[Common showDialogWithTitle:@"注意" message:@"このカテゴリーは削除できません"];
					}

					// DB解放
					[dbMng release];
					
					// リロード
                    NSString *templateId = nil;
                    NSString *categoryName = nil;
                    NSInteger section, row;
                    if( [_templInfoList getSelectedInfo:&section RowNum:&row] ){
                        TemplateInfo *selectTemplate = [_templInfoList getTemplateInfoBySection:section RowNum:row];
                        templateId = [selectTemplate tmplId];
                        categoryName = [selectTemplate categoryName];
                        //  消去されたカテゴリが選択中のテンプレートのカテゴリかのチェック
                        if( [categoryId isEqualToString:[selectTemplate categoryId]] )
                        {
                            //  消去されたカテゴリに入っていたテンプレートのカテゴリは「なし」になる
                            categoryName = @"なし";
                        }
                    }
                    [self finishedTemplateCreatorView:categoryName
                                           TemplateId:templateId];
				}];
			}
		}
		break;

	case CLICKED_EDIT:
		{
			if ( cellIndex == -1 )
			{
				// 非選択のアラートを表示
				alert = [self createAlertViewForNoSelect];
			}
			else
			{
				// DB取得
				userDbManager* dbMng = [[userDbManager alloc] init];
				if ( dbMng == nil ) return;
				
				// 編集するカテゴリーの確認
				NSString* categoryId = [editor getCellCommonIDFromIndex:cellIndex];
				if ( [dbMng isCategoryDefaultWithID:categoryId] == YES )
				{
					// カテゴリー「なし」は編集できない
					[Common showDialogWithTitle:@"注意" message:@"このカテゴリーは編集できません"];
					[dbMng release];
					break;
				}
				[dbMng release];
				
				// アラートビューの設定
				alert = [[UISpecialAlertView alloc] initWithTitle:[[editor strKindName] stringByAppendingString:@"の編集"]
														  message:[[editor getCellNameFromIndex:cellIndex] stringByAppendingString:@"を編集します"]
														 delegate:self
												cancelButtonTitle:@"編集"
												otherButtonTitles:strCancel, nil ];
				
				// アラートビューにテキストフィールド追加
				[alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
				[alert setTag:ALERT_TAG_EDIT_CATEGORY];
				// アラートのテキストフィールドへ文字列追加
				UITextField* textField = [alert textFieldAtIndex:0];
				[textField setText:[editor getCellNameFromIndex:cellIndex]];
				// Blockを追加
				[alert showWithCallback:^(NSInteger buttonIndex){
					// cancel
					if ( buttonIndex != 0 )
						return;
					
					// DB取得
					userDbManager* dbMng = [[userDbManager alloc] init];
					if ( dbMng == nil ) return;

					// テキストフィールド
					UITextField* textField = [alert textFieldAtIndex:0];
					NSString* newText = [textField text];

					// カテゴリーのタイトルを取得
					if ( [newText length] == 0 )
					{
						[Common showDialogWithTitle:@"カテゴリーの編集"
											message:@"カテゴリー名が入っていません"];
						return;
					}
					
					
                    // 既存カテゴリーのチェック
                    if ( [dbMng chkCategoryName:newText] == false){
                        [Common showDialogWithTitle:@"カテゴリー名の重複"
                                            message:@"すでに同名のカテゴリー名が登録済みです。"];
                        // DB解放
                        [dbMng release];
                        
                        return;
                    }
                    
                    // 旧テキストフィールド
					NSString* oldText = [editor getCellNameFromIndex:cellIndex];
					if ( [newText compare:oldText] == NSOrderedSame )
						return;
					
					// 更新日時
					NSTimeInterval date = [[NSDate date] timeIntervalSince1970];

					// DBの編集
					[dbMng updateCategory:[editor getCellCommonIDFromIndex:cellIndex]
									 Date:date
								 NewValue:newText];
					[self loadCategoryName];
					
					// DB解放
					[dbMng release];
                    
                    //  編集されたカテゴリが選択中のカテゴリかのチェック
                    if( [_strSelectCategory isEqualToString:oldText] )
                    {
                        _strSelectCategory = newText;
                    }
                    
					// リロード
                    NSString *templateId = nil;
                    NSString *categoryName = nil;
                    NSInteger section = 0, row = 0;
                    if( [_templInfoList getSelectedInfo:&section RowNum:&row] ){
                        TemplateInfo *selectTemplate = [_templInfoList getTemplateInfoBySection:section RowNum:row];
                        templateId = [selectTemplate tmplId];
                        categoryName = [selectTemplate categoryName];
                        //  編集されたカテゴリが選択中のテンプレートのカテゴリかのチェック
                        if( [categoryId isEqualToString:[selectTemplate categoryId]] )
                        {
                            //  消去されたカテゴリに入っていたテンプレートのカテゴリは「なし」になる
                            categoryName = newText;
                        }
                    }
                    [self finishedTemplateCreatorView:categoryName
                                           TemplateId:templateId];
				}];
			}
		}
		break;

	case CLICKED_CLOSE:
		{
			// 何もしない
		}
		break;
			
	case CLICKED_CLEAR_ALL:
		{
			// アラートビューの設定
			alert = [[UISpecialAlertView alloc] initWithTitle:@"全て削除"
													  message:@"カテゴリーを全て削除します"
													 delegate:self
											cancelButtonTitle:@"削除"
											otherButtonTitles:strCancel, nil ];
			[alert setTag:ALERT_TAG_CLEARALL_CATEGORY];
			// Blockを追加
			[alert showWithCallback:^(NSInteger buttonIndex){
				// cancel
				if ( buttonIndex != 0 )
					return;
				
				// DB取得
				userDbManager* dbMng = [[userDbManager alloc] init];
				if ( dbMng == nil ) return;
				
				// DBの全て削除
				[dbMng deleteAllCategories];
				[self initCategoryData];
				
				// 削除完了メッセージ
				[Common showDialogWithTitle:@"カテゴリーの削除" message:@"全てのカテゴリーが削除されました"];

				// DB解放
				[dbMng release];

				// リロード
                NSString *templateId = nil;
                NSString *categoryName = nil;
                NSInteger section = 0, row = 0;
                if( [_templInfoList getSelectedInfo:&section RowNum:&row] ){
                    TemplateInfo *selectTemplate = [_templInfoList getTemplateInfoBySection:section RowNum:row];
                    templateId = [selectTemplate tmplId];
                    categoryName = @"なし";
                }
                [self finishedTemplateCreatorView:categoryName
                                       TemplateId:templateId];
			}];
		}
		break;
			
	default:
		break;
	}
}

/**
 テンプレートリストのリロード
 */
- (void)reloadTemplateList{
    
    [self initCategoryData];
				
    NSString *templateId = nil;
    NSString *categoryName = nil;
    NSInteger section = 0, row = 0;
    if( [_templInfoList getSelectedInfo:&section RowNum:&row] ){
        TemplateInfo *selectTemplate = [_templInfoList getTemplateInfoBySection:section RowNum:row];
        templateId = [selectTemplate tmplId];
        categoryName = @"なし";
    }

    [self finishedTemplateCreatorView:categoryName
                           TemplateId:templateId];
}

/**
 alertView
 テンプレート削除時のアラートに対応
 */
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSInteger tag = [alertView tag];
	if ( tag == ALERT_TAG_INSERT_CATEGORY
	||   tag == ALERT_TAG_DELETE_CATEGORY
	||   tag == ALERT_TAG_EDIT_CATEGORY
	||   tag == ALERT_TAG_CLEARALL_CATEGORY )
	{
		// アラートの非表示
		[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
	}
	else
	{
		// キャンセル時は何もしない
		if ( buttonIndex != 0 ) return;
		
		// 一覧の現在選択中のrowを取得
		NSIndexPath *indexPath = [templateTableView indexPathForSelectedRow];
		if ( indexPath == nil ) return;

		// テンプレート情報の取得
		TemplateInfo* info = [_templInfoList getTemplateInfoBySection:indexPath.section
															   RowNum:indexPath.row];
		
		// テンプレートのタイトルを取得しておく
		NSString* msg = [NSString stringWithFormat:@"%@が削除されました", [info strTemplateTitle]];

		// DBオープン
		userDbManager* userDbMng = [[userDbManager alloc] initWithDbOpen];

		// DBから削除
		BOOL ret = [userDbMng deleteTemplateWithID:[info tmplId]];
		if ( ret == YES )
		{
			// テンプレート情報から削除
			[_templInfoList removeTemplateInfoBySection:indexPath.section
												 RowNum:indexPath.row];
            
			// テーブルビューの再描画
			[templateTableView reloadData];
            
            //  プレビューを初期画面一旦戻す。
            [self updatePreview:nil];
            [lblAttachmentImgNum setHidden:YES];
            
            
		}

		// DBクローズ
		[userDbMng closeDataBase];
		[userDbMng release];

		// 削除完了メッセージ
		[Common showDialogWithTitle:@"テンプレートの削除" message:msg];
        
        //  テンプレート数更新
        [self setTemplateAllNum];       //  全体のテンプレート数
        NSInteger templateNum = 0;
        NSInteger templateCategoryNum = [_templInfoList getSectionCounts];
        for( NSInteger i = 0; i < templateCategoryNum; i++ ){
            templateNum += [_templInfoList getTemplateInfoCountsWithSection:i];
        }
        lblSelectedCategoryNum.text
            = [NSString stringWithFormat:@"%ld件表示中", (long)templateNum];       //  カテゴリのテンプレート数
	}
}

/**
 テンプレートの作成が終了した際に呼び出される
 */
- (void) finishedTemplateCreatorView:(NSString*)categoryName
                          TemplateId:(NSString*)templateId
{
    NSString *categoryNameNasi = @"なし";
    
	// カテゴリーをロードする
	[self loadCategoryName];
	// ロードする
    if( ![_strSelectCategory isEqualToString:categoryNameNasi]
       && categoryName != nil
       && ![_strSelectCategory isEqualToString:categoryName] ){
        if( [categoryName length] == 0 )    categoryName = categoryNameNasi;
        _strSelectCategory = categoryName;
    }
    [self refiningTemplateDatabaseWithCategory:_strSelectCategory];
    
	// テーブルビューのリロード
	[templateTableView reloadData];
    
    //  indexPathを取得する
    NSIndexPath* indexPath = nil;
    if(templateId != nil)
    {
        //  選択されているカテゴリの番号を探す
        NSInteger nasiSection;    //  なし　のセクション番号を保存しておく
        NSInteger section = [_templInfoList getSectionCounts] - 1;
        for( ; section >= 0; section-- )
        {
            TemplateInfo* info = [_templInfoList getTemplateInfoBySection:section
                                                                   RowNum:0];
            if( [info categoryName] == nil ){
                nasiSection = section;
                if( [categoryName isEqualToString:categoryNameNasi] ){
                    break;
                }
            }
            if([categoryName isEqualToString:[info categoryName]])    break;
        }
        if( section < 0 )   section = nasiSection;      //  セクションが見つからないのはカテゴリが消去された可能性があるのでカテゴリ　なし　から探す
        //  作成・編集されたTemplateInfoの番号を探す
        NSInteger row = [_templInfoList getTemplateInfoCountsWithSection:section] - 1;
        for( ; row >= 0; row-- )
        {
            TemplateInfo* info = [_templInfoList getTemplateInfoBySection:section
                                                                   RowNum:row];
            if([templateId isEqualToString:[info tmplId]])  break;
        }
        indexPath = [NSIndexPath indexPathForRow:row
                                       inSection:section];
    }
    else
    {
        indexPath = _oldIndexPath;
    }
    
    if( indexPath != nil )
    {
        // 再選択
        [templateTableView selectRowAtIndexPath:indexPath
                                       animated:YES
                                 scrollPosition:UITableViewScrollPositionMiddle];
        
        // テンプレート情報
        [_templInfoList UnselectedAll];
        [_templInfoList selecteInfo:indexPath.section RowNum:indexPath.row];
        TemplateInfo* templateInfo = [_templInfoList getTemplateInfoBySection:indexPath.section
                                                                       RowNum:indexPath.row];
        
        [self updatePreview:templateInfo];
        if( _previewPicturesList != nil ){
            lblAttachmentImgNum.text = [NSString stringWithFormat:@"添付画像の数：%ld", (long)_previewPicturesList.count ];
            [lblAttachmentImgNum setHidden:NO];
        }
        else{
            [lblAttachmentImgNum setHidden:YES];
        }
    }
    
    [self setTemplateAllNum];
}


#pragma mark TableView_DataSource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
	return [_templInfoList getSectionCounts];
}

/**
 tableView: numberOfRowsInSection:
 セクションに含まれるセル数を返す
 */
- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
	return [_templInfoList getTemplateInfoCountsWithSection:section];
}

/**
 tableView: titleForHeaderInSection:
 セクションのヘッダータイトルを返す
 */
- (NSString*) tableView:(UITableView*) tableView titleForHeaderInSection:(NSInteger)section
{
	return [_templInfoList getSectionTitle:section];
}

/**
 tableView: cellForRowAtIndexPath:
 セルの内容を返す
 */
- (UITableViewCell*) tableView:(UITableView*) tableView
		 cellForRowAtIndexPath:(NSIndexPath*) indexPath
{
	static NSString *CellIndentifier = @"template_info_cell";
	TemplateListTableViewCell* cell = (TemplateListTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIndentifier];
	if ( cell == nil )
	{
		UIViewController* viewController = [[UIViewController alloc] initWithNibName:@"TemplateListTableViewCell" bundle:nil];
		cell = (TemplateListTableViewCell*)[viewController view];
		[viewController release];

		// Mainビューの取得
		MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		UIColor* bkNoSelectCell = [mainVC getColorTable:BK_NOSELECT_CELL]; // 非選択状態のセルの背景色
		UIColor* bkSelectedCell = [mainVC getColorTable:BK_SELECTED_CELL]; // 選択状態のセルの背景色

        // Cell選択時に青色にする(iOS7対応)
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
        [cell.selectedBackgroundView setBackgroundColor:bkSelectedCell];
        cell.selectedBackgroundView.layer.cornerRadius = 10.0f;
        cell.selectedBackgroundView.layer.masksToBounds = YES;
        // 背景色：F0FFFF
        cell.backgroundColor = bkNoSelectCell;
	}

	// セルの内容更新
	[self updateCell:cell IndexPath:indexPath];
	
	return cell;
}

/**
 セルの内容更新
 @param cell セル
 @param indexPath インデックス
 @return なし
 */
- (void) updateCell:(TemplateListTableViewCell*) cell IndexPath:(NSIndexPath*) indexPath
{
	// テンプレート情報
	TemplateInfo* info = [_templInfoList getTemplateInfoBySection:indexPath.section
														   RowNum:indexPath.row];
	// テンプレートのタイトルを設定
	cell.templTitle.text = [info strTemplateTitle];
	// テンプレートの更新日時を設定
	cell.templUpdateDate.text = [Common getDateStringByLocalTime:[info dateTemplateUpdate]];
	// テンプレート本文を設定
	cell.templPreview.text = [info strTemplateBody];
}


#pragma mark TableView_Delegate
/**
 tableView: didSelectRowAtIndexPath:
 セルタップ時に呼び出される
 */
- (void) tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath*) indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;

	// テンプレート情報
	TemplateInfo* info = [_templInfoList getTemplateInfoBySection:indexPath.section
														   RowNum:indexPath.row];

    // 全て非選択状態
    [_templInfoList UnselectedAll];
    [_templInfoList selecteInfo:indexPath.section RowNum:indexPath.row];
    // 選択
    [info setSelected:YES];
    // 左スワイプを設定
    [self setupSwipeLeftView:YES];
    
    [self updatePreview:info];
    /**
     updatePreviewで_previewPicturesListが更新される
     */
    if( _previewPicturesList != nil ){
        lblAttachmentImgNum.text = [NSString stringWithFormat:@"添付画像の数：%ld", (long)_previewPicturesList.count ];
        [lblAttachmentImgNum setHidden:NO];
    }
    else{
        [lblAttachmentImgNum setHidden:YES];
    }
    
    [btnTemplateEditor setEnabled:YES];
    [btnTemplateEditor setAlpha:1.0f];
    [btnTemplateDelete setEnabled:YES];
    [btnTemplateDelete setAlpha:1.0f];
}

/**
 createAlertViewForNoSelect
 非選択の場合のアラートを表示する
 */
- (UISpecialAlertView*) createAlertViewForNoSelect
{
	return [[UISpecialAlertView alloc] initWithTitle:@"選択"
											 message:@"選択されていません"
											delegate:self
								   cancelButtonTitle:@"取消"
								   otherButtonTitles:nil, nil];
}


#pragma mark LocalMethod
/**
 setupSwipe
 */
- (BOOL) setupSwipeRightView
{
	UISwipeGestureRecognizer* swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(OnSwipeRightView:)];
	if ( swipeRight == nil ) return NO;
	swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
	swipeRight.numberOfTouchesRequired = 1;
	[self.view addGestureRecognizer:swipeRight];
	[swipeRight release];
	return YES;
}

/**
 setupSwipeLeftView
 */
- (BOOL) setupSwipeLeftView:(BOOL) regist
{
	if ( regist == YES )
	{
		BOOL bFind = NO;
		NSArray* array = [self.view gestureRecognizers];
		for ( UISwipeGestureRecognizer* swipe in array )
		{
			// 左スワイプを検索
			if ( swipe.direction == UISwipeGestureRecognizerDirectionLeft )
			{
				bFind = YES;
				break;
			}
		}
		if ( bFind == NO )
		{
			// 左スワイプを追加
			UISwipeGestureRecognizer* swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(OnSwipeLeftView:)];
			if ( swipeLeft == nil ) return NO;
			swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
			swipeLeft.numberOfTouchesRequired = 1;
			[self.view addGestureRecognizer:swipeLeft];
			[templateTableView addGestureRecognizer:swipeLeft];
			[swipeLeft release];
		}
	}
	else
	{
		NSArray* array = [self.view gestureRecognizers];
		for ( UISwipeGestureRecognizer* swipe in array )
		{
			// 左スワイプを削除
			if ( swipe.direction == UISwipeGestureRecognizerDirectionLeft )
			{
				[self.view removeGestureRecognizer:swipe];
				[templateTableView removeGestureRecognizer:swipe];
				break;
			}
		}
	}
	return YES;
}

/**
 */
-(void) setTemplateAllNum
{
    userDbManager *usrDbMng = [[userDbManager alloc] init];
	NSMutableArray* _arrayTemplateInfo = nil;
    
    // 全検索する
    _arrayTemplateInfo = [usrDbMng loadTemplateDatabase];
	[usrDbMng release];
    
    lblTemplateAllNum.text = [NSString stringWithFormat:@"全登録件数%ld件", (long)[_arrayTemplateInfo count]];
}

/**
 カテゴリー名を取得する
 */
- (void) loadCategoryName
{
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	if ( [_arrayCategoryStrings count] > 0 )
	{
		// 何かしら文字列が追加されていた場合は一旦破棄する
		[_arrayCategoryStrings removeAllObjects];
	}
	[usrDbMng loadCategoryName:&_arrayCategoryStrings];
	[usrDbMng release];
}

/**
 loadTemplateDatebase
 */
- (BOOL) loadTemplateDatabase
{
	// DBから全部取得する
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	NSMutableArray* _arrayTemplateInfo = [usrDbMng loadTemplateDatabase];
	[usrDbMng release];

	// 選択されていたテンプレートを取得しておく
	NSInteger section = 0, row = 0;
	BOOL bSelected = [_templInfoList getSelectedInfo:&section RowNum:&row];
	
	// テンプレートのリストに設定する
	if ( [[_templInfoList dicTemplateInfo] count] > 0 )
	{
		// 削除しておく
		[_templInfoList removeAllObjects];
	}
	[_templInfoList setTemplateList:_arrayTemplateInfo];

	// 選択されていたテンプレートを再度選択しておく
	if ( bSelected == YES )
	{
		[_templInfoList selecteInfo:section RowNum:row];
	}
	return YES;
}

/**
 カテゴリーでテンプレートを絞り込みする
 */
- (BOOL) refiningTemplateDatabaseWithCategory:(NSString*)strCategory
{
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	NSMutableArray* _arrayTemplateInfo = nil;
	if ( strCategory == nil || [strCategory isEqualToString:@"なし"] == YES )
	{
		// 全検索する
        // 2016/5/10 TMS テンプレートの並び順をタイトル順にする
		_arrayTemplateInfo = [usrDbMng loadTemplateDatabaseOrderBy];
	}
	else
	{
		// DBから絞り込み検索で取得する
        // 2016/5/10 TMS テンプレートの並び順をタイトル順にする
		_arrayTemplateInfo = [usrDbMng refiningTemplateDatabaseWithCategoryOrderBy:strCategory];
	}
	[usrDbMng release];
	
	// 選択されていたテンプレートを取得しておく
	NSInteger section = 0, row = 0;
	BOOL bSelected = [_templInfoList getSelectedInfo:&section RowNum:&row];
	
	// テンプレートのリストに設定する
	if ( [[_templInfoList dicTemplateInfo] count] > 0 )
	{
		// 削除しておく
		[_templInfoList removeAllObjects];
	}
	[_templInfoList setTemplateList:_arrayTemplateInfo];
	
	// 選択されていたテンプレートを再度選択しておく
	if ( bSelected == YES )
	{
		[_templInfoList selecteInfo:section RowNum:row];
	}
    
    lblSelectedCategoryName.text = strCategory;
    
    NSInteger templateNum = 0;
    NSInteger templateCategoryNum = [_templInfoList getSectionCounts];
    for( int i = 0; i < templateCategoryNum; i++ ){
        templateNum += [_templInfoList getTemplateInfoCountsWithSection:i];
    }
    lblSelectedCategoryNum.text = [NSString stringWithFormat:@"%ld件表示中", (long)templateNum];
    
	return YES;
}

/**
 initCategoryData
 */
- (void) initCategoryData
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	_strSelectCategory = [defaults stringForKey:CATEGORY_SEARCH_SAVE_KEY];
}

/**
 saveCategoryData
 */
- (BOOL) saveCategoryData
{
	if ( _strSelectCategory == nil ) return NO;
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:_strSelectCategory forKey:CATEGORY_SEARCH_SAVE_KEY];
	return YES;
}

#pragma mark Preview_Method
-(void) updatePreview:(TemplateInfo*)templateInfo
{
    if( templateInfo == nil ){
        previewSubject.text = @"テンプレートの件名が表示されます。";
        previewMailBody.text = @"テンプレートの本文が表示されます。";
        //  サブビューを消去
        for( UIView* subView in [previewPictures subviews]){
            [subView removeFromSuperview];
        }
        [_previewPicturesList removeAllObjects];
        //  プレビューの表示位置を先頭にする
        [preview setContentOffset:CGPointMake(0, -20) animated:NO];

        return;
    }
    
    //  メール件名
    previewSubject.text = [templateInfo strTemplateTitle];
    
    //  メール本文
    NSString* templateBody = [templateInfo makeTemplateBody];
    
    // 名前
    userDbManager* usrDbMng = [[userDbManager alloc] init];
    mstUser *user = [usrDbMng getMstUserByID:1];
    [usrDbMng release];
    
    NSString* replaceName = @"お客様名";
    if( user != nil ){
        replaceName = [user getUserName];
    }
    
    // 文字列を置き換える
    templateBody = [templateBody stringByReplacingOccurrencesOfString:@"{__NAME__}" withString:replaceName];
    
    previewMailBody.text = templateBody;
    
    //  メール添付画像
    NSArray* templatePictures = [templateInfo pictureUrls];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:@"accountIDSave"];
    NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];
    OKDImageFileManager* imgFileMng = [[OKDImageFileManager alloc] initWithFolder:folderName];
    NSInteger idx = 0;
    
    //  サブビューを消去
    for( UIView* subView in [previewPictures subviews]){
        [subView removeFromSuperview];
    }
    [_previewPicturesList removeAllObjects];
    
	//  送信画像情報の作成
	for ( NSArray* pictInfo in templatePictures )
	{
		NSString* strPictId = [pictInfo objectAtIndex:0];
		NSString* localPath = [pictInfo objectAtIndex:1];
		NSString* fileName = [localPath lastPathComponent];
        
        // サムネイルViewの作成
		OKDThumbnailItemView *thumbnailView = [OKDThumbnailItemView alloc];
		[[thumbnailView initWithFrame: CGRectMake(100.0f, 50.0f, ITEM_WITH, ITEM_HEIGHT)] autorelease];
		[thumbnailView setFileName:fileName];
        
		// Document以下のファイル名に変換
		NSString* docFileName = [[NSString alloc] initWithString:[fileName lastPathComponent]];
		docFileName = [docFileName substringToIndex:[docFileName length] - 4];
		[thumbnailView setTitle:docFileName];
        
        thumbnailView.delegate = nil;
        thumbnailView.tag = idx;
        [thumbnailView setImgId:strPictId];
        [thumbnailView setUpdateTime:0];
        [thumbnailView writeToTemplateThumbnail:imgFileMng];
        
        [_previewPicturesList addObject:thumbnailView];
        [previewPictures addSubview:thumbnailView];
        
        idx++;
	}
    
    [imgFileMng release];
    
    [self previewPicturesLayout];
    
    //  プレビューの表示位置を先頭にする
    [preview setContentOffset:CGPointMake(0, -20) animated:NO];

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
    [df setDateFormat:@"yyyy/MM/dd"];
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

/**
 画像のレイアウト
 */
-(void) previewPicturesLayout
{
    if( [_previewPicturesList count] <= 0 )     return;
    
    int picturesAreaW = previewPictures.frame.size.width - 40;
    int xNum = picturesAreaW / (ITEM_WITH + 20);
    if( xNum <= 0)  xNum = 1;       //  0割回避
    
    CGFloat w = (picturesAreaW / xNum);
    CGFloat h = ITEM_HEIGHT + 10;
    int x = 20 + (w - ITEM_WITH) / 2;
    
    for( OKDThumbnailItemView* view in _previewPicturesList ){
        NSInteger i = view.tag;
        int posX = x + w * (i % xNum);
        int posY = h * (i / xNum);
        [view setFrame:CGRectMake( posX, posY, ITEM_WITH, ITEM_HEIGHT)];
    }
    
    w = previewPictures.frame.size.width;
    h = h + (h * ( ([_previewPicturesList count] - 1) / xNum));
    previewPictures.contentSize = CGSizeMake(w, h);
}

#pragma mark Instance_Method
/**
 初期化
 */
- (id) initWithDelegate:(id)delegate
{
	self = [self initWithNibName:@"TemplateManagerViewController" bundle:nil];
	if ( self )
	{
		// デリゲート
		_delegate = delegate;
	}
	return self;
}


#pragma mark Handler
/**
 OnReturnUserInfoList
 */
- (IBAction) OnReturnUserInfoList
{
	MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	UIInterfaceOrientation orient = self.interfaceOrientation;
	if ( UIInterfaceOrientationIsPortrait(orient) )
	{
		// 縦なら横に強制的に値だけ変更
		[mainVC setBeforeInterfaceOrient:UIInterfaceOrientationLandscapeLeft];
	}
	else
	{
		// 横なら縦に強制的に値だけ変更
		[mainVC setBeforeInterfaceOrient:UIInterfaceOrientationPortrait];
	}
	[mainVC closePopupWindow:self];
}

/**
 OnGotoTemplateCreator
 */
- (IBAction) OnGotoTemplateCreator:(id)sender
{
	// 一覧の現在選択中のrowを取得
	NSIndexPath* indexPath = [templateTableView indexPathForSelectedRow];
	if ( indexPath == nil )
	{
		NSInteger section = 0, row = 0;
		if ( [_templInfoList getSelectedInfo:&section RowNum:&row] == YES )
		{
			// indexPathを作成しておく
			indexPath = [NSIndexPath indexPathForRow:row inSection:section];
		}
	}
	if ( _oldIndexPath )
	{
		[_oldIndexPath release];
		_oldIndexPath = nil;
	}
	_oldIndexPath = indexPath;
	[_oldIndexPath retain];

	// テンプレート情報
	TemplateInfo* info = [_templInfoList getTemplateInfoBySection:indexPath.section
														   RowNum:indexPath.row];
	
	// 確保
	TemplateCreatorViewController* controller = [TemplateCreatorViewController alloc];
	[controller initWithTemplateInfo:info Delegate:self];

	// popup表示
	MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	[mainVC showPopupWindow:controller];
	
	// 遷移先の設定
	_windowView = WIN_VIEW_TEMPLATE_CREATOR;
	
	// 後片付け
	[controller release];
}

/**
 OnTemplateCreator
 */
- (IBAction) OnTemplateCreator:(id)sender
{
	// 確保
	TemplateCreatorViewController* controller = [TemplateCreatorViewController alloc];
	[controller initWithTemplateInfo:nil Delegate:self];
	
	// popup表示
	MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	[mainVC showPopupWindow:controller];
	
	// 遷移先の設定
	_windowView = WIN_VIEW_TEMPLATE_CREATOR;
	
	// 後片付け
	[controller release];
}

/**
 OnTemplateDelete
 */
- (IBAction) OnTemplateDelete:(id)sender
{
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [templateTableView indexPathForSelectedRow];
	if ( indexPath == nil )
	{
		[Common showDialogWithTitle:@"注意" message:@"テンプレートが選択されていません"];
		return;
	}

	//テンプレート削除用アラートの表示
	UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"テンプレートの削除"
														message:@"選択しているテンプレートを削除しますか？"
													   delegate:self
											  cancelButtonTitle:@"削除"
											  otherButtonTitles:@"取消", nil];
	[alertView setTag:ALERT_TAG_DELETE_TEMPLATE];
	[alertView show];
	[alertView release];
}

/**
 OnTemplateEditor
 */
- (IBAction) OnTemplateEditor:(id)sender
{
	// 一覧の現在選択中のrowを取得
	NSIndexPath *indexPath = [templateTableView indexPathForSelectedRow];
	if ( indexPath == nil ) return;
	{
		NSInteger section = 0, row = 0;
		if ( [_templInfoList getSelectedInfo:&section RowNum:&row] == YES )
		{
			// indexPathを作成しておく
			indexPath = [NSIndexPath indexPathForRow:row inSection:section];
		}
	}
	if ( _oldIndexPath )
	{
		[_oldIndexPath release];
		_oldIndexPath = nil;
	}
	_oldIndexPath = indexPath;
	[_oldIndexPath retain];

	// 現在選択中のテンプレート情報を取得
	TemplateInfo* info = [_templInfoList getTemplateInfoBySection:indexPath.section
														   RowNum:indexPath.row];
	
	// 確保
	TemplateCreatorViewController* controller = [TemplateCreatorViewController alloc];
	[controller initWithTemplateInfo:info Delegate:self];
	
	// popup表示
	MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	[mainVC showPopupWindow:controller];
	
	// 遷移先の設定
	_windowView = WIN_VIEW_TEMPLATE_CREATOR;
	
	// 後片付け
	[controller release];
}

/**
 OnTemplateCategory
 */
- (IBAction) OnTemplateCategory:(id)sender
{
	if ( popOverCtrlCategory != nil )
	{
		[popOverCtrlCategory release];
		popOverCtrlCategory = nil;
	}
	
	// ポップオーバーの表示
	EditorPopup* editorPopup = [[EditorPopup alloc] initWithCategory:_arrayCategoryStrings
															   title:@"カテゴリー編集"
														selectString:_strSelectCategory
															delegate:self
															 popOver:nil];
	if ( editorPopup != nil )
	{
		popOverCtrlCategory = [[UIPopoverController alloc] initWithContentViewController:editorPopup];
		[editorPopup setPopOverController: popOverCtrlCategory];
		[popOverCtrlCategory presentPopoverFromRect:btnTemplateCategory.bounds
										   inView:btnTemplateCategory
						 permittedArrowDirections:UIPopoverArrowDirectionAny
										 animated:YES];
        [popOverCtrlCategory setPopoverContentSize:CGSizeMake(420.0f, 513.0f)];
	}
	[editorPopup release];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    BOOL nowOrientation = (self.interfaceOrientation == UIInterfaceOrientationPortrait
                           || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
    BOOL toOrientation = (toInterfaceOrientation == UIInterfaceOrientationPortrait
                          || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
    if( nowOrientation != toOrientation ){
        [self rotateToInterfaceOrientation:self.interfaceOrientation WillRotate:true];
    }
}

/**
 端末の回転によるレイアウト変更
 */
-(void) rotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation WillRotate:(bool) willRotate
{
    /**
     この関数が呼ばれた際のViewControllerの端末方向を判定している。
     willRotation~だと回転開始時の端末の向きを取得して
     */
    
    BOOL isPortrait = ( interfaceOrientation == UIInterfaceOrientationPortrait
                  || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown );     //  レイアウト変更後の画面が縦画面か？
    
    if( willRotate ){
        //  interfaceOrientationが画面のレイアウト変更前の端末の向き
        isPortrait = !isPortrait;
    }
    
    int x, y, w, h;
    int verHeightOfs = 0;     //  iOS7を基準としている
    
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if ( iOSVersion < 7.0 ){
        verHeightOfs = -20;
    }
    
    CGRect rect = [[UIScreen mainScreen] bounds];
    if( isPortrait ){
        if (rect.size.width > rect.size.height) {
            CGFloat tmp = rect.size.width;
            rect.size.width = rect.size.height;
            rect.size.height = tmp;
        }
        x = 20;
        y = 72;
        w = rect.size.width - 40;
        h = 358;
        preview.frame = CGRectMake(x, y, w, h);
        
        x = rect.size.width - 20 - btnTemplateDelete.frame.size.width;
        y = 438;
        w = btnTemplateDelete.frame.size.width;
        h = btnTemplateDelete.frame.size.height;
        btnTemplateDelete.frame = CGRectMake(x, y, w, h);
        
        x = btnTemplateDelete.frame.origin.x - 8 - btnTemplateEditor.frame.size.width;
        y = btnTemplateDelete.frame.origin.y;
        w = btnTemplateEditor.frame.size.width;
        h = btnTemplateEditor.frame.size.height;
        btnTemplateEditor.frame = CGRectMake(x, y, w, h);
        
        x = 20;
        y = 490;
        w = preview.frame.size.width;
        h = rect.size.height - 20 - y + verHeightOfs;
        templateList.frame = CGRectMake(x, y, w, h);
    }
    else{
        if (rect.size.width < rect.size.height) {
            CGFloat tmp = rect.size.width;
            rect.size.width = rect.size.height;
            rect.size.height = tmp;
        }
        x = 20;
        y = 72;
        w = rect.size.width / 2 - 30;
        h = rect.size.height - 20 - btnTemplateDelete.frame.size.height - 10 - y + verHeightOfs;
        templateList.frame = CGRectMake(x, y, w, h);
        
        x = templateList.frame.origin.x + templateList.frame.size.width - btnTemplateDelete.frame.size.width;
        y = templateList.frame.origin.y + templateList.frame.size.height + 10;
        w = btnTemplateDelete.frame.size.width;
        h = btnTemplateDelete.frame.size.height;
        btnTemplateDelete.frame = CGRectMake(x, y, w, h);
        
        x = btnTemplateDelete.frame.origin.x - 8 - btnTemplateEditor.frame.size.width;
        y = btnTemplateDelete.frame.origin.y;
        w = btnTemplateEditor.frame.size.width;
        h = btnTemplateEditor.frame.size.height;
        btnTemplateEditor.frame = CGRectMake(x, y, w, h);
        
        x = templateList.frame.origin.x + templateList.frame.size.width + 20;
        y = templateList.frame.origin.y;
        w = rect.size.width - 20 - x;
        h = rect.size.height - 20 - y + verHeightOfs;
        preview.frame = CGRectMake(x, y, w, h);
    }
    
    [self previewPicturesLayout];
}

@end
