//
//  TemplateCreatorViewController.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/02/26.
//
//

/*
 ** IMPORT
 */
#import "appCapacityManager.h"
#import "Common.h"
#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"
#import "takePicture4PhotoLibrary.h"
#import "fcUserWorkItem.h"
#import "TemplateManagerViewController.h"
#import "TemplateCreatorViewController.h"
#import "userDbManager.h"
#import "OKDImageFileManager.h"
#import "HistListViewController.h"
#import "HistDetailViewController.h"
#import "UICameraViewPicker.h"
#import <MobileCoreServices/MobileCoreServices.h>

/*
 ** DEFINE
 */
#define NAME_FIELD @"{__NAME__}"
#define DATE_FIELD @"{__DATE__}"
#define GEN1_FIELD @"{__FIELD1__}"
#define GEN2_FIELD @"{__FIELD2__}"
#define GEN3_FIELD @"{__FIELD3__}"
#define GEN_FIELD_SAVE_KEY @"GenFieldData"
#define CATEGORY_SAVE_KEY  @"CategoryData"

#define ALERT_TAG_TAKE_PICTURE		1000
#define ALERT_TAG_DELETE_NO_ALERT	1001
#define ALERT_TAG_DELETE_PICTURE	1002

#define TMPL_THUBNAIL_CONTEINER_WIDTH  595
#define TMPL_THUBNAIL_CONTEINER_HEIGHT 256

@implementation TemplateCreatorViewController

/*
 ** PROPERTY
 */
@synthesize dirty = _dirty;
@synthesize editMode = _editMode;

#pragma mark iOS_Frmaework
/**
 initWithNibName
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self )
	{
		[self setDirty:NO];
		[self setEditMode:TMPL_MODE_CREATE];
		_isTemplateSave = NO;
        isCategoryClear = NO;
		_arrayThumbailItems   = [[NSMutableArray alloc] init];
		_selectItemOrder	  = [[NSMutableArray alloc] init];
		_arrayCategoryStrings = [[NSMutableArray alloc] init];
		_arrayGenFieldStrings = [[NSMutableArray alloc] init];
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
	
	// swipe
	[self setupSwipe];

	// ボタンの長押し
	[self setupLongPressed];

	// スクロールビューの設定
	[self setupScrollViewZoom];

	// アラートの初期化
	[self initAlertDialog];

	// カテゴリーのロード
	[self loadCategoryName];

	// 汎用フィールドのロード
	[self loadGeneralFieldName];

	// DBのチェック
	[self checkCapturePictInfo];
	
	// 画像URLのロード
	[self loadPictUrls];
	
	// サムネイルItemリストの作成（写真データの読み込み含む）
	[self thumbnailItemsMake];

	// サムネイルItemのレイアウト
	[self thumbnailItemsLayout];

	// サムネイルの選択
	[self initSelectThumbnailItems];
	
	// UIコントローラーの初期化
	[self setupUIController];

	// テキストフィールドの初期化
	[self setupTextField];

	// basePanelの背景色設定
	viewBasePanel.backgroundColor = [Common getScrollViewBackColor];

	// 縦横画面の更新
	BOOL isPortrait = [MainViewController isNowDeviceOrientationPortrate];
	[self rotateSubView:isPortrait];
}

/**
 viewDidUnload
 */
-(void) viewDidUnload
{
	// ビュー類の解放
	[viewPictureConteiner release];
	viewPictureConteiner = nil;
	[viewPictureAlbum release];
	viewPictureAlbum = nil;
	[scviewPictContainer release];
	scviewPictContainer = nil;
	[scviewBasePanel release];
	scviewBasePanel = nil;
	[viewBasePanel release];
	viewBasePanel = nil;
	// アラートの解放
	[deleteNoAlert release];
	deleteNoAlert = nil;
	[deleteCheckAlert release];
	deleteCheckAlert = nil;
	// ボタン類の解放;
	btnCategoryEditor = nil;
	[btnAddNameField release];
	btnAddNameField = nil;
	[btnAddDateField release];
	btnAddDateField = nil;
	[btnAddGeneral1Field release];
	btnAddGeneral1Field = nil;
	[btnAddGeneral2Field release];
	btnAddGeneral2Field = nil;
	[btnAddGeneral3Field release];
	btnAddGeneral3Field = nil;
	[btnPictureAlbum release];
	btnPictureAlbum = nil;
	// テキストフィールドの解放
	[textCategory release];
	textCategory = nil;
	[textTitle release];
	textTitle = nil;
	[textMailBody release];
	textMailBody = nil;
	// インジケーター
	[actIndView release];
	actIndView = nil;
	// ポップオーバーの解放
	[popOverController release];
	popOverController = nil;
	[_imagePopController release];
	_imagePopController = nil;
	// ジェスチャーの解放
	[longPressGesture1 release];
	longPressGesture1 = nil;
	[longPressGesture2 release];
	longPressGesture2 = nil;
	[longPressGesture3 release];
	longPressGesture3 = nil;

	[super viewDidUnload];
}

/**
 */
- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	if ( _editMode == TMPL_MODE_EDIT )
	{
		// テキストデータの保存
		[self saveOldTextData];
	}
    
    //  ボタンの位置と本文テキスト入力フィールドからボタンまでのマージンを保存しておく。
    //  この値はキーボードが閉じた際にボタンの位置を戻すのに用いる。
    self->_btnDefaultPosY = btnAddNameField.frame.origin.y;
    self->_textMailBodyMarginBottom = btnAddNameField.frame.origin.y - (textMailBody.frame.origin.y + textMailBody.frame.size.height);
    self->_pictLocalPosY = scviewPictContainer.frame.origin.y - self->_btnDefaultPosY;
    self->_btnPictureAlbumLocalPosY = btnPictureAlbum.frame.origin.y - self->_btnDefaultPosY;

    //  キーボード表示通知設定
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

/**
 viewWillDisappear
 */
- (void) viewWillDisappear:(BOOL)animated
{
	BOOL bAlertDisp = NO;
	_isTemplateSave = NO;

	// 更新のチェック
	if ( _editMode == TMPL_MODE_CREATE )
	{
		if ( [self isExistTextData] == YES )
			bAlertDisp = YES;
	}
	else
	{
		if ( [self isTextFieldDirty] == YES
		||   [self isSelectedPicturesDirty] == YES )
			bAlertDisp = YES;
	}

	// Alertを表示する
	if ( bAlertDisp == YES )
	{
		// アラートビューの設定
		UISpecialAlertView* alert = [[UISpecialAlertView alloc] initWithTitle:@"確認"
												  message:@"テンプレートが更新されています\n保存しますか？"
												 delegate:self
										cancelButtonTitle:@"保存"
										otherButtonTitles:@"取消", nil ];
		[alert showWithCallback:^(NSInteger buttonIndex){
			// cancel
			if ( buttonIndex != 0 )
				return;
            
            NSString *templateId = nil;

			// 選択されてるカテゴリー名を保存する
//			[self saveCategoryData];
			// 汎用フィールドをユーザーデフォルトに保存する
			[self saveGeneralFieldData];
			// 選択されている画像URLを保存する
			[self saveTemplatePictInfo];
			// タイトルとテンプレート本文が更新されているか
			if ( _editMode == TMPL_MODE_CREATE )
			{
				// テンプレートのデータベースを保存する
				[self insertTemplateDatabaseWithCategory:textCategory.text
											   Gen1Field:[_dicGeneralFields objectForKey:@"1"]
											   Gen2Field:[_dicGeneralFields objectForKey:@"2"]
											   Gen3Field:[_dicGeneralFields objectForKey:@"3"]];
                templateId = _tmpTemplateId;
			}
			else
			{
				// テンプレートのデータベースを更新する
				[self updateTemplateDatabaseWithGenField:textCategory.text
											   Gen1Field:[_dicGeneralFields objectForKey:@"1"]
											   Gen2Field:[_dicGeneralFields objectForKey:@"2"]
											   Gen3Field:[_dicGeneralFields objectForKey:@"3"]];
                templateId = [_templInfo tmplId];
			}

			// デリゲートの呼び出し
			[_delegate finishedTemplateCreatorView:textCategory.text
                                        TemplateId:templateId];
		}];

		// アラート解放
		[alert release];
	}
	else
	{
        if (isCategoryClear == YES){
            [_delegate reloadTemplateList];
        }else{
            [_delegate finishedTemplateCreatorView:nil
                                    TemplateId:nil];
        }
	}
    
    //  キーボード表示通知解除
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];

	[super viewWillDisappear:animated];
}

/**
 viewDidDisappear
 */
- (void) viewDidDisappear:(BOOL) animated
{
	[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Overriden to allow any orientation.
    return YES;
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
 willRotateToInterfaceOrientation
 */
- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	BOOL isPortrait = YES;
	switch ( toInterfaceOrientation )
	{
		case UIInterfaceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
			// 縦画面
			isPortrait = YES;
			break;
			
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			// 横画面
			isPortrait = NO;
			break;
			
		default:
			isPortrait = NO;
			break;
	}
    
	// 回転の描画
	[self rotateSubView:isPortrait];
}

/**
 rotateSubView
 */
- (void) rotateSubView:(BOOL) isPortrait
{
	if ( self.view.hidden == YES )
	{
		// ビュー自体が表示されていない
		return;
	}

	// パネルサイズの設定
	CGFloat width = isPortrait ? 728.0f : 984.0f;
	CGFloat height = 964.0f;

	// パネルの設定
	[viewBasePanel setFrame:CGRectMake(0, 0, width, height)];
	[scviewBasePanel setContentSize:CGSizeMake(width, height)];

	// サムネイルItemのレイアウト
	[self thumbnailItemsLayout];
}

/**
 dealloc
 */
- (void) dealloc
{
    if (_popoverCntlWorkItemSet)
		[_popoverCntlWorkItemSet release];
	// ビュー類の解放
	[viewPictureConteiner release];
	[viewPictureAlbum release];
	[scviewPictContainer release];
	[scviewBasePanel release];
	[viewBasePanel release];
	// アラートの解放
	[deleteNoAlert release];
	[deleteCheckAlert release];
	// ボタン類の解放
	[btnCategoryEditor release];
	[btnAddNameField release];
	[btnAddDateField release];
	[btnAddGeneral1Field release];
	[btnAddGeneral2Field release];
	[btnAddGeneral3Field release];
	[btnPictureAlbum release];
	// テキストフィールドの解放
	[textCategory release];
	[textTitle release];
	[textMailBody release];
	// ポップオーバーの解放
	[popOverController release];
	[_imagePopController release];
	// インジケーター
	[actIndView release];
	// サムネイルのアイテムの解放
	[_arrayThumbailItems removeAllObjects];
	[_arrayThumbailItems release];
	// ジェスチャーの解放
	[longPressGesture1 release];
	[longPressGesture2 release];
	[longPressGesture3 release];
	// カテゴリーの文字列
	[_arrayCategoryStrings removeAllObjects];
	[_arrayCategoryStrings release];
	[_strSelectCategory release];
	// 汎用フィールド
	[_arrayGenFieldStrings removeAllObjects];
	[_arrayGenFieldStrings release];
	[_dicGeneralFields removeAllObjects];
	[_dicGeneralFields release];
	[_dicOldGeneralFields removeAllObjects];
	[_dicOldGeneralFields release];
	// テンプレートID
	[_tmpTemplateId release];
	
	[super dealloc];
}

/**
    キーボードが表示される前に呼ばれる。
    キーボードが出現する事で、キーボードに隠れてほしくないボタンの位置などレイアウトを変更している。
 */
-(void)keyboardWillShow:(NSNotification*)note
{
    CGRect keyboard = [[[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboard = [self->scviewBasePanel convertRect:keyboard fromView:nil];
    
    NSArray* btns = [NSArray arrayWithObjects:btnAddNameField,
                     btnAddDateField,
                     btnAddGeneral1Field,
                     btnAddGeneral2Field,
                     btnAddGeneral3Field,
                     btnDeletePicture, nil];
    
    UIButton* btn = [btns objectAtIndex:0];
    
    float btnButtomMargin = 5.0f;
    float btnY = keyboard.origin.y - ( btn.frame.size.height + btnButtomMargin );   //  キーボードが表示された際のボタン位置計算
    
    if( self->_btnDefaultPosY < btnY ){
        btnY = self->_btnDefaultPosY;
    }
    
    NSTimeInterval animationDuration = [[[note userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:animationDuration animations:^(void){
        //  各種レイアウト変更
        for( UIButton* btnBuf in btns ){
            if(btnBuf == nil ) break;
            btnBuf.frame = CGRectMake(btnBuf.frame.origin.x, btnY, btnBuf.frame.size.width, btnBuf.frame.size.height);
        }
        
        CGRect rect = textMailBody.frame;
        float height = (btnY - self->_textMailBodyMarginBottom) - rect.origin.y;
        textMailBody.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height);
        
        rect = scviewPictContainer.frame;
        scviewPictContainer.frame = CGRectMake(rect.origin.x, (btnY + self->_pictLocalPosY), rect.size.width, rect.size.height);
        
        rect = btnPictureAlbum.frame;
        btnPictureAlbum.frame = CGRectMake(rect.origin.x, (btnY + self->_btnPictureAlbumLocalPosY), rect.size.width, rect.size.height);
        
    } completion:^(BOOL finished){
    }];
}

/**
 キーボードが閉じる前に呼ばれる。
 キーボードが出現する事で、キーボードに隠れてほしくないボタンの位置などレイアウトの変更を元に戻す。
 */
-(void)keyboardWillHide:(NSNotification*)note
{
    NSArray* btns = [NSArray arrayWithObjects:btnAddNameField,
                     btnAddDateField,
                     btnAddGeneral1Field,
                     btnAddGeneral2Field,
                     btnAddGeneral3Field,
                     btnDeletePicture, nil];
    
    NSTimeInterval animationDuration = [[[note userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:animationDuration animations:^(void){
        //  各種レイアウト変更
        for( UIButton* btn in btns ){
            if(btn == nil ) break;
            btn.frame = CGRectMake(btn.frame.origin.x, self->_btnDefaultPosY, btn.frame.size.width, btn.frame.size.height);
        }
        
        CGRect rect = textMailBody.frame;
        float height = (self->_btnDefaultPosY - self->_textMailBodyMarginBottom) - rect.origin.y;
        textMailBody.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height);
        
        rect = scviewPictContainer.frame;
        scviewPictContainer.frame = CGRectMake(rect.origin.x, (self->_btnDefaultPosY + self->_pictLocalPosY), rect.size.width, rect.size.height);
        
        rect = btnPictureAlbum.frame;
        btnPictureAlbum.frame = CGRectMake(rect.origin.x, (self->_btnDefaultPosY + self->_btnPictureAlbumLocalPosY), rect.size.width, rect.size.height);
        
    } completion:^(BOOL finished){
    }];
}

#pragma mark Delegate
/**
 textFieldShouldClear
 テキストフィールドのデリゲート
 Returnボタンがタップされた時に呼ばれる
 */
-(BOOL) textFieldShouldReturn:(UITextField*)textField
{
	return YES;
}

/**
 alertView
 アラートのデリゲート
 */
- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch ( alertView.tag )
	{
	case ALERT_TAG_TAKE_PICTURE:
		[self takePictureFunc:buttonIndex];
		break;

	case ALERT_TAG_DELETE_NO_ALERT:
		break;
			
	case ALERT_TAG_DELETE_PICTURE:
			[self selectedPictureDelete:buttonIndex];
		break;

	default:
		[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
		break;
	}
}

/**
 OnSwipeRightView
 @param sender
 @return void
 */
- (void) OnSwipeRightView:(id) sender
{
	[self OnReturnTemplateManage];
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
	NSInteger popupMode = [editor popupMode];

	// ポップオーバーを閉じる
	if ( popOverController != nil )
		[popOverController dismissPopoverAnimated:YES];

	switch ( event )
	{
	case CLICKED_SELECT:
		{
			if ( cellIndex == -1 )
			{
				if ( popupMode == POPUP_MODE_CATEGORY )
				{
					// チェックマークが外されているのでテキストフィールドから文字列を削除する
					textCategory.text = nil;
				}
				else
				{
					// チェックマークが無くなっているのでデータを削除する
					[_dicGeneralFields removeObjectForKey:[[NSNumber numberWithInteger:popupMode] description]];
				}
			}
			else
			{
				if ( popupMode == POPUP_MODE_CATEGORY )
				{
					// カテゴリー名テキストフィールドに文字列を設定する
					textCategory.text = [editor getCellNameFromIndex:cellIndex];
					if ( _strSelectCategory != nil )
					{
						[_strSelectCategory release];
						_strSelectCategory = nil;
					}
					_strSelectCategory = [[NSString alloc] initWithString:textCategory.text];
				}
				else
				{
					// データを更新する
					[_dicGeneralFields setObject:[editor getCellNameFromIndex:cellIndex]
										  forKey:[[NSNumber numberWithInteger:popupMode] description]];
				}
			}
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
			//
			UITextField* textField = [alert textFieldAtIndex:0];
			[textField setPlaceholder:[[editor strKindName] stringByAppendingString:@"を追加してください"]];
			// Blockを追加
			if ( popupMode == POPUP_MODE_CATEGORY )
			{
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
			else
			{
				[alert showWithCallback:^(NSInteger buttonIndex){
					// cancel
					if ( buttonIndex != 0 )
						return;
					
					// 汎用フィールドのタイトルを取得
					NSString* strGenField = [[alert textFieldAtIndex:0] text];
					if ( [strGenField length] == 0 )
					{
						[Common showDialogWithTitle:@"汎用フィールドの追加"
											message:@"汎用フィールド名が入っていません"];
						return;
					}

					// DB取得
					userDbManager* dbMng = [[userDbManager alloc] init];
					if ( dbMng == nil ) return;
					
					// 作成日時
					NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
					
					// 汎用フィールドを追加
					[dbMng insertGeneralField:strGenField Date:date];
					[self loadGeneralFieldName];
					
					// DB解放
					[dbMng release];
				}];
			}
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

				// Blockを追加
				if ( popupMode == POPUP_MODE_CATEGORY )
				{
					// アラートビューの設定
					alert = [[UISpecialAlertView alloc] initWithTitle:[[editor strKindName] stringByAppendingString:@"の削除"]
															  message:[[editor getCellNameFromIndex:cellIndex] stringByAppendingString:@"を削除します"]
															 delegate:self
													cancelButtonTitle:@"削除"
													otherButtonTitles:strCancel, nil ];
					// Block
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
							[self loadCategoryName];
                            isCategoryClear = YES;

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
					}];
				}
				else
				{
					NSString* genFieldId = [editor getCellCommonIDFromIndex:cellIndex];
					NSString* tmplId = (_editMode == TMPL_MODE_CREATE) ? _tmpTemplateId : [_templInfo tmplId];
					BOOL error = NO;

					// 汎用フィールドが他のテンプレートで使用されているかを取得する
					userDbManager* dbMng = [[userDbManager alloc] initWithDbOpen];
					BOOL isUsed = [dbMng isGenFieldUsed:genFieldId TmplId:tmplId Error:&error];
					[dbMng closeDataBase];
					[dbMng release];
					if ( error != YES ) return;

					// 使用してなければ削除できる
					if ( isUsed != YES )
					{
						// アラートビューの設定
						alert = [[UISpecialAlertView alloc] initWithTitle:[[editor strKindName] stringByAppendingString:@"の削除"]
																  message:[[editor getCellNameFromIndex:cellIndex] stringByAppendingString:@"を削除します"]
																 delegate:self
														cancelButtonTitle:@"削除"
														otherButtonTitles:strCancel, nil ];
						// Block
						[alert showWithCallback:^(NSInteger buttonIndex){
							// cancel
							if ( buttonIndex != 0 )
								return;
							
							// DB取得
							userDbManager* dbMng = [[userDbManager alloc] init];
							if ( dbMng == nil ) return;
							
							// DBの削除
							[dbMng deleteGeneralField:[editor getCellCommonIDFromIndex:cellIndex]];
							[self loadGeneralFieldName];
							
							// 削除完了メッセージ
							NSString* msg = [NSString stringWithFormat:@"%@が削除されました", cellName];
							[Common showDialogWithTitle:@"汎用フィールドの削除" message:msg];

							// DB解放
							[dbMng release];
						}];
					}
					else
					{
						// 使用中だったのでエラーアラートを表示する
						[Common showDialogWithTitle:@"汎用フィールドの削除" message:@"この汎用フィールドは\n他のテンプレートで使用中です\n削除できません"];
					}

				}
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
				// アラートビューの設定
				alert = [[UISpecialAlertView alloc] initWithTitle:[[editor strKindName] stringByAppendingString:@"の編集"]
														  message:[[editor getCellNameFromIndex:cellIndex] stringByAppendingString:@"を編集します"]
														 delegate:self
												cancelButtonTitle:@"編集"
												otherButtonTitles:strCancel, nil ];
			
				// アラートビューにテキストフィールド追加
				[alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
				// アラートのテキストフィールドへ文字列追加
				UITextField* textField = [alert textFieldAtIndex:0];
				[textField setText:[editor getCellNameFromIndex:cellIndex]];

				// Blockを追加
				if ( popupMode == POPUP_MODE_CATEGORY )
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

					// Block
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

						
						if ( [newText length] == 0 )
						{
							[Common showDialogWithTitle:@"カテゴリーの追加"
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
					}];
				}
				else
				{
					// Block
					[alert showWithCallback:^(NSInteger buttonIndex){
						// cancel
						if ( buttonIndex != 0 )
							return;
						
						// テキストフィールド
						UITextField* textField = [alert textFieldAtIndex:0];
						NSString* newText = [textField text];
						if ( [newText length] == 0 )
						{
							[Common showDialogWithTitle:@"汎用フィールドの追加"
												message:@"汎用フィールド名が入っていません"];
							return;
						}
						
						// 旧テキストフィールド
						NSString* oldText = [editor getCellNameFromIndex:cellIndex];
						if ( [newText compare:oldText] == NSOrderedSame )
							return;
						
						// DB取得
						userDbManager* dbMng = [[userDbManager alloc] init];
						if ( dbMng == nil ) return;
						
						// 更新日時
						NSTimeInterval date = [[NSDate date] timeIntervalSince1970];

						// DBの編集
						[dbMng updateGeneralField:[editor getCellCommonIDFromIndex:cellIndex]
											 Date:date
										 NewValue:newText];
						[self loadGeneralFieldName];
						
						// DB解放
						[dbMng release];
					}];
				}
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
			// Blockを追加
			if ( popupMode == POPUP_MODE_CATEGORY )
			{
				// アラートビューの設定
				alert = [[UISpecialAlertView alloc] initWithTitle:@"全て削除"
														  message:@"全てのカテゴリーを削除します"
														 delegate:self
												cancelButtonTitle: @"削除"
												otherButtonTitles:strCancel, nil ];
				// Block
				[alert showWithCallback:^(NSInteger buttonIndex){
					// cancel
					if ( buttonIndex != 0 )
						return;
					
					// DB取得
					userDbManager* dbMng = [[userDbManager alloc] init];
					if ( dbMng == nil ) return;
					
					// DBの全て削除
					[dbMng deleteAllCategories];
                     textCategory.text = @"";
                     _strSelectCategory = nil;
                     isCategoryClear = YES;
                    
					// 削除完了メッセージ
					[Common showDialogWithTitle:@"カテゴリーの削除" message:@"全てのカテゴリーが削除されました"];

					// DB解放
					[dbMng release];
                    
				}];
			}
			else
			{
				// アラートビューの設定
				alert = [[UISpecialAlertView alloc] initWithTitle:@"全て削除"
														  message:@"全ての汎用フィールドデータを削除します\n全てのテンプレートに関連付けされている\n汎用フィールドデータが削除される事になります"
														 delegate:self
												cancelButtonTitle:@"削除"
												otherButtonTitles:strCancel, nil ];
				// Block
				[alert showWithCallback:^(NSInteger buttonIndex){
					// cancel
					if ( buttonIndex != 0 )
						return;
					
					// DB取得
					userDbManager* dbMng = [[userDbManager alloc] init];
					if ( dbMng == nil ) return;
					
					// DBの全て削除
					[dbMng deleteAllGeneralFields];
					[self loadGeneralFieldName];
					
					// 削除完了メッセージ
					[Common showDialogWithTitle:@"汎用フィールドの削除" message:@"全ての汎用フィールドが削除されました"];

					// DB解放
					[dbMng release];
				}];
			}
		}
		break;

	default:
		break;
	}

	if ( alert != nil )
	{
		// アラートの表示
		[alert show];
		[alert release];
	}
}

/**
 サムネイル選択イベント
 */
- (void) SelectThumbnail:(NSUInteger)tagID image:(UIImage*)image select:(BOOL)isSelect
{
	NSUInteger idx = 0xffffffff;
	NSUInteger count = 0;

	for ( id aItem in _selectItemOrder )
	{
		NSUInteger tag = (NSUInteger)[((NSString*)aItem) intValue];
		if ( tag == tagID )
		{
			if ( isSelect )
			{
				// 選択時、選択したIDが既に選択サムネイルItemの順序Tableに含まれている場合は何もしない
				return;
			}
			else
			{
				// 選択解除時、選択サムネイルItemの順序Tableより削除
				idx = count;
				break;
			}
		}
		count++;
	}
	
	if ( idx != 0xffffffff )
	{
		// サムネイルItemを取り出す
		OKDThumbnailItemView* item = [self searchThnmbnailItemByTagID:tagID];
		// サムネイルItemの選択番号を非表示にする
		[item setSelectNumber:0];
		// 選択サムネイルItemの順序Tableより削除
		[_selectItemOrder removeObjectAtIndex:idx];
		
		// 他のサムネイルItemの選択番号を更新
		for (u_int i = 0; i < (u_int)[_selectItemOrder count]; i++)
		{
			NSUInteger oIdx = (NSUInteger)[((NSString*)[_selectItemOrder objectAtIndex:i]) intValue];
			OKDThumbnailItemView* oItem = [self searchThnmbnailItemByTagID:oIdx];
			[oItem setSelectNumber:(i+1)];
		}
		
		return;
	}
	
	if ( isSelect )
	{
		// サムネイルItemを取り出す
		OKDThumbnailItemView* item = [self searchThnmbnailItemByTagID:tagID];
		if ( [item isKindOfClass:[VideoThumbnailItemView class]] == YES )
		{
			// 動画は選択できない
			[item setSelect:NO];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"選択出来ません"
															message:@"動画は選択できません"
														   delegate:nil
												  cancelButtonTitle:nil
												  otherButtonTitles:@"OK", nil];
			[alert show];
			[alert release];
			return;
		}
        
		// 選択時、選択サムネイルItemの順序Tableの末尾に追加
		[_selectItemOrder addObject:[NSString stringWithFormat:@"%ld", (long)tagID]];
		
		// サムネイルItemに選択番号を設定にする
		[item setSelectNumber:(u_int)[_selectItemOrder count]];
	}
}

/**
 imagePickerController
 */
- (void) imagePickerController:(UIImagePickerController*) picker didFinishPickingMediaWithInfo:(NSDictionary*) info
{
	// ポップオーバーを非表示にする
	[_imagePopController dismissPopoverAnimated:YES];

	// 動画はNGにしておく
    NSString* mediaType = info[@"UIImagePickerControllerMediaType"];
	if ( [mediaType isEqualToString:@"public.image"] != YES )
		return;
    
	// image
	UIImage *oriImage = info[@"UIImagePickerControllerOriginalImage"];
    
    // 縦と横の倍率でいずれか大きいほうで画像の倍率を求める
    CGFloat widthRatio = oriImage.size.width / CAM_VIEW_PICTURE_WIDTH;
    CGFloat heightRatio = oriImage.size.height / CAM_VIEW_PICTURE_HEIGHT;
    CGFloat raito = (widthRatio >= heightRatio)? widthRatio : heightRatio;
    
    // 倍率より縮小後のサイズを求める
    CGFloat width  = oriImage.size.width / raito;
    CGFloat height = oriImage.size.height / raito;
    
    // グラフィックコンテキストを作成
	UIGraphicsBeginImageContext(CGSizeMake(CAM_VIEW_PICTURE_WIDTH, CAM_VIEW_PICTURE_HEIGHT));
    
    // グラフィックコンテキストに描画
	[oriImage drawInRect:CGRectMake((CAM_VIEW_PICTURE_WIDTH / 2) - (width / 2),
                                    (CAM_VIEW_PICTURE_HEIGHT / 2) - (height / 2), width, height)];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();

	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
    
    // プレビューの表示
    viewPictureAlbum.image = reSizeImage;
    viewPictureAlbum.hidden = NO;
	
    // 保存確認のダイアログ表示
    [self showSaveCheckAlert];
}

/**
 imagePickerControllerDidCancel
 */
- (void) imagePickerControllerDidCancel:(UIImagePickerController*) picker
{
	// ポップオーバーを非表示
    [_imagePopController dismissPopoverAnimated:YES];
}

/**
 popoverControllerDidDismissPopover
 */
- (void) popoverControllerDidDismissPopover:(UIPopoverController*) popoverController
{
	[self afterPopupClose];
}

/**
 UITextViewへの入力チェック
 キーボードからテキストビューへの入力がされた際に呼ばれるデリゲート
 */
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    //  バックスペースが押されるとカーソルの前の文字を比較して置き換え文字({__NAME__}など)の場合一回で消す
    if( self->textMailBody == textView ){
        if( [text isEqualToString:@""] ){
            // カーソル位置取得
            NSRange range = [textMailBody selectedRange];
            // 挿入先
            NSString* text = [textMailBody text];
            if( [text length] < range.location ){
                range.location = [text length];
            }
            
            NSString* strFirstHalf = [text substringToIndex:range.location];
            NSString* strSecondHalf = [text substringFromIndex:range.location];
            // スクロールOFF
            [textMailBody setScrollEnabled:NO];
            NSRange range2 = [strFirstHalf rangeOfString:@"\\{__(NAME|DATE\\+?[0-9]*|DATE\\+YEAR|FIELD1|FIELD2|FIELD3)__\\}$" options:NSRegularExpressionSearch | NSBackwardsSearch];
            if ( (range2.location + range2.length) <= [strFirstHalf length]) {
                strFirstHalf = [strFirstHalf stringByReplacingCharactersInRange:range2 withString:@" "];
            }
            // 文字列の挿入
            [textMailBody setText:[NSString stringWithFormat:@"%@%@", strFirstHalf, strSecondHalf]];
            // 位置更新
            range.location = [strFirstHalf length];
            [textMailBody setSelectedRange:range];
            // スクロールON
            [textMailBody setScrollEnabled:YES];
        }

    }
    
    return YES;
}

#pragma mark ViewFunction
/**
 initWithTemplateInfo
 テンプレート情報で初期化する
 */
- (id) initWithTemplateInfo:(TemplateInfo*) templInfo Delegate:(id)delegate
{
	// 初期化
	self = [self initWithNibName:@"TemplateCreatorViewController" bundle:nil];
	if ( self )
	{
		if ( templInfo != nil )
		{
			// テンプレート情報の保存
			_templInfo = templInfo;
			[_templInfo retain];
			// 編集モードに設定
			[self setEditMode:TMPL_MODE_EDIT];
			// 仮のテンプレートIDはなし
			_tmpTemplateId = nil;
			// 既存のデータを読み込み
			[self loadCategoryData];
			[self loadGeneralFieldData];
		}
		else
		{
			// テンプレート情報なし
			_templInfo = nil;
			// 作成モードに設定
			[self setEditMode:TMPL_MODE_CREATE];
			// 仮のテンプレートIDを入れておく
			_tmpTemplateId = [[NSString alloc] initWithString:[Common getUUID]];
			// 初期値
			[self initCategoryData];
			[self initGeneralFieldData];
		}

		// デリゲートの設定
		_delegate = delegate;
	}
	return self;
}

/**
 setupSwipe
 スワイプの設定
 */
- (BOOL) setupSwipe
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
 setupLongPressed
 長押しの設定
 */
- (BOOL) setupLongPressed
{
	return YES;
}

/**
 setupTextField
 */
- (void) setupTextField
{
	// カテゴリーを設定
	textCategory.text = [_templInfo categoryName];
	// タイトルを設定
	textTitle.text = [_templInfo strTemplateTitle];
	// 本文を設定
	textMailBody.text = [_templInfo strTemplateBody];
    textMailBody.delegate = self;
}

/**
 スクロールビューのピンチ（ズーム）機能の設定
 */
-(void) setupScrollViewZoom
{
	// ピンチ（ズーム）機能の追加:delegate指定
	[scviewPictContainer setDelegate:self];
	
	// スクロールビューの拡大と縮小の範囲設定（これがないとズームしない）
	[scviewPictContainer setMinimumZoomScale:1.0f];
	[scviewPictContainer setMaximumZoomScale:10.0f];
}

/**
 thumbnailSelectedCellRefresh
 サムネイルと選択セルの更新
 */
- (void) thumbnailSelectedCellRefresh
{
	// 画像URLのロード
	[self loadPictUrls];

	// サムネイルリストと取得したユーザ写真リスト（の長さ）が異なれば、再描画する
	if ( [_arrayThumbailItems count] != [_capturePictInfo count] )
	{
		// サムネイルItemリストの作成（写真データの読み込み含む）
		[self thumbnailItemsMake];
		
		// サムネイルItemのレイアウト
		[self thumbnailItemsLayout];
	}
}

/**
 append
 メール本文に置き換え文字列を追加する
 */
-(BOOL) appendStringInMailBodyWithField:(NSString*) strField
{
	// カーソル位置取得
	NSRange range = [textMailBody selectedRange];
	// 挿入先
    NSString* text = [textMailBody text];
    if( [text length] < range.location ){
        range.location = [text length];
    }
	NSString* strFirstHalf = [text substringToIndex:range.location];
	NSString* strSecondHalf = [text substringFromIndex:range.location];
	// スクロールOFF
	[textMailBody setScrollEnabled:NO];

	// 文字列の挿入
	[textMailBody setText:[NSString stringWithFormat:@"%@%@%@", strFirstHalf, strField, strSecondHalf]];
	// 位置更新
	range.location += [strField length];
	[textMailBody setSelectedRange:range];
	// スクロールON
	[textMailBody setScrollEnabled:YES];
	return YES;
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
 汎用フィールド名を取得する
 */
- (void) loadGeneralFieldName
{
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	if ( [_arrayGenFieldStrings count] > 0 )
	{
		// 何かしら文字列が追加されていた場合は一旦破棄する
		[_arrayGenFieldStrings removeAllObjects];
	}
	[usrDbMng loadGeneralFieldName:&_arrayGenFieldStrings];
	[usrDbMng release];
}

/**
 取り込み用画像情報DBのチェック
 */
- (BOOL) checkCapturePictInfo
{
	BOOL stat = YES;
	userDbManager *usrDbMng = [[userDbManager alloc] initWithDbOpen];
	if ( [usrDbMng isExistCapturePictInfo] != YES )
	{
		// ないなら作成しておく
		stat = [usrDbMng createCaptruePictInfoTable];
	}
	[usrDbMng closeDataBase];
	[usrDbMng release];
	return stat;
}


/**
 画像のURLを取得する
 */
- (void) loadPictUrls
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:@"accountIDSave"];
	NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];
	userDbManager *usrDbMng = [[userDbManager alloc] initWithDbOpen];

	// テンプレート編集モード&画像付きの場合のみ画像のファイルチェックする
	if ( [self editMode] == TMPL_MODE_EDIT
	&&   [[_templInfo pictureUrls] count] > 0 )
	{
		// 添付されている画像が端末にあるかチェックする
		NSMutableArray* existPictures = [NSMutableArray array];
		for ( NSArray* array in [_templInfo pictureUrls] )
		{
			NSString* fullPath = (NSString*)[array objectAtIndex:1];
            NSString* fileName = [fullPath lastPathComponent];

			// ファイルの存在チェック
			OKDImageFileManager* imgMng = [[OKDImageFileManager alloc] initWithFolder:folderName];
			// JPGファイルはありますか？
			BOOL exist = [imgMng isExsitFileWithOutPath:fileName isThumbnail:NO];
			if ( exist == NO )
			{
				// サムネイルもチェックする
				exist = [imgMng isExsitFileWithOutPath:fileName isThumbnail:YES];
			}
			if ( exist == NO )
			{
				// 端末に全くないのでサーバーからダウンロードしてセーブする
				UIImage* img = [imgMng getTemplateThumbnailSizeImage:fileName];
				// それでもないんだから、このファイルは無視
				if ( img == nil ) continue;
			}
			// 存在画像リストに追加
			[existPictures addObject:array];
		}

		// 画像取り込み用DBがあるか
		if ( [usrDbMng isExistCapturePictInfo] == YES )
		{
			// DBあり
			for ( NSArray* array in existPictures )
			{
				NSString* pictUrl = (NSString*)[array objectAtIndex:1];

				// DBにあるか検索
				NSMutableArray* pictInfo = [NSMutableArray array];
				[usrDbMng getCapturePictInfo:accID Data:&pictInfo];
				if ( [pictInfo count] == 0 )
				{
					// DBの中になかったので追加しておく
					NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
					[usrDbMng insertCapturePictInfo:accID PictUrl:pictUrl Date:date];
				}
				else
				{
					// DBに本当にあるんかい
					BOOL find = NO;
					for ( NSArray* dbData in pictInfo )
					{
						NSString* url = [dbData objectAtIndex:1];
						if ( [pictUrl isEqualToString:url] == YES )
						{
							// 見つかった
							find = YES;
							break;
						}
					}
					// 結局DBにみつからなかったので追加してやる
					if ( find != YES )
					{
						// DBの中になかったので追加しておく
						NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
						[usrDbMng insertCapturePictInfo:accID PictUrl:pictUrl Date:date];
					}
				}
			}
		}
		else
		{
			// DBないから作成する
			if ( [usrDbMng createCaptruePictInfoTable] != YES )
			{
				// 作成失敗
				[usrDbMng closeDataBase];
				[usrDbMng release];
				return;
			}

			// ファイルが存在する分に関してはDBに追加しておく
			for ( NSArray* exist in existPictures )
			{
				NSString* url = (NSString*)[exist objectAtIndex:1];
				NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
				[usrDbMng insertCapturePictInfo:accID PictUrl:url Date:date];
			}
		}
	}
	
	// データベースから最新の履歴用のユーザ写真リストを取得する
	if ( _capturePictInfo != nil )
	{
		[_capturePictInfo removeAllObjects];
		[_capturePictInfo release];
	}
	_capturePictInfo = [[NSMutableArray alloc] init];
	[usrDbMng getCapturePictInfo:accID Data:&_capturePictInfo];
	[usrDbMng closeDataBase];
	[usrDbMng release];
}

/**
 initCategoryData
 */
- (void) initCategoryData
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	if ( _strSelectCategory != nil )
	{
		[_strSelectCategory release];
		_strSelectCategory = nil;
	}
	NSString* strDefCategory = [defaults stringForKey:CATEGORY_SAVE_KEY];
	if ( strDefCategory != nil )
		_strSelectCategory = [[NSString alloc]initWithString:strDefCategory];
}

/**
 テンプレートから選択しているカテゴリーを読み込んでくる
 */
- (void) loadCategoryData
{
	// テンプレートID
	NSString* tmplId = (_editMode == TMPL_MODE_CREATE) ? _tmpTemplateId : [_templInfo tmplId];
	
	// カテゴリーIDの取得
	userDbManager* userDbMng = [[userDbManager alloc] initWithDbOpen];
	NSString* categoryId = [userDbMng getCategoryIdWithTmplID:tmplId];
	[userDbMng closeDataBase];
	[userDbMng release];

	// カテゴリー名の設定
	if ( categoryId != nil )
	{
		// カテゴリー名をDBから取得する
		userDbMng = [[userDbManager alloc] initWithDbOpen];
		_strSelectCategory = [userDbMng getCategoryTitleAtID:categoryId];
		[userDbMng closeDataBase];
		[userDbMng release];

		// 結局なかったので初期値を設定する
		if ( _strSelectCategory == nil )
			[self initCategoryData];
		else
			[_strSelectCategory retain];
	}
	else
	{
		// 初期値を設定
		[self initCategoryData];
	}
}

/**
 saveCategoryData
 */
- (BOOL) saveCategoryData
{
	if ( _strSelectCategory == nil ) return NO;
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:_strSelectCategory forKey:CATEGORY_SAVE_KEY];
	return YES;
}

/**
 initGeneralFieldData
 */
- (void) initGeneralFieldData
{
	// 無い場合はallocするだけ
	_dicGeneralFields = [[NSMutableDictionary alloc] init];
	// 比較用にコピーしておく
	_dicOldGeneralFields = [[NSMutableDictionary alloc] init];
}

/**
 loadGeneralFieldData
 */
- (void) loadGeneralFieldData
{
	// テンプレートID
	NSString* tmplId = (_editMode == TMPL_MODE_CREATE) ? _tmpTemplateId : [_templInfo tmplId];

	// カテゴリーIDの取得
	userDbManager* userDbMng = [[userDbManager alloc] initWithDbOpen];
	NSDictionary* generalId = [userDbMng getGenFieldIdWithTmplID:tmplId];
	[userDbMng closeDataBase];
	[userDbMng release];

	// とりえあえずallocしておく
	_dicGeneralFields = [[NSMutableDictionary alloc] init];
	if ( generalId != nil )
	{
		NSString* gen1FieldId = (NSString*)[generalId objectForKey:@"1"];
		NSString* gen2FieldId = (NSString*)[generalId objectForKey:@"2"];
		NSString* gen3FieldId = (NSString*)[generalId objectForKey:@"3"];

		// 汎用フィールド名を取得する
		NSString *genField1 = nil, *genField2 = nil, *genField3 = nil;
		userDbManager* userDbMng = [[userDbManager alloc] initWithDbOpen];
		if ( gen1FieldId != nil )
			genField1 = [userDbMng getGenFieldDataByID:gen1FieldId];
		if ( gen2FieldId != nil )
			genField2 = [userDbMng getGenFieldDataByID:gen2FieldId];
		if ( gen3FieldId != nil )
			genField3 = [userDbMng getGenFieldDataByID:gen3FieldId];
		[userDbMng closeDataBase];
		[userDbMng release];
		
		// DBからの値を設定する
		[_dicGeneralFields setObject:((genField1 != nil) ? genField1 : @"") forKey:@"1"];
		[_dicGeneralFields setObject:((genField2 != nil) ? genField2 : @"") forKey:@"2"];
		[_dicGeneralFields setObject:((genField3 != nil) ? genField3 : @"") forKey:@"3"];
	}
	_dicOldGeneralFields = [[NSMutableDictionary alloc] initWithDictionary:_dicGeneralFields];
}

/**
 saveGeneralFieldData
 */
- (BOOL) saveGeneralFieldData
{
	if ( [_dicGeneralFields count] == 0 ) return NO;
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:_dicGeneralFields forKey:GEN_FIELD_SAVE_KEY];
	return YES;
}

/**
 選択されている画像URLを保存する
 */
- (BOOL) saveTemplatePictInfo
{
	// DBオープン
	userDbManager* userDbMng = [[userDbManager alloc] initWithDbOpen];

	// モード別で動作が違う
	if ( [self editMode] == TMPL_MODE_CREATE )
	{
		// 選択されていなければ保存しない
		if ( [_selectItemOrder count] == 0 )
		{
			// DBクローズ
			[userDbMng closeDataBase];
			[userDbMng release];
			return YES;
		}
		
		// 選択されている画像のURLを保存
		for ( NSString* order in _selectItemOrder )
		{
			// 画像の取得
			NSUInteger tag = (NSUInteger)[order integerValue];
			OKDThumbnailItemView* itemView = [self searchThnmbnailItemByTagID:tag];
			if ( itemView == nil ) continue;

			// 取り込み画像DBから取得する
			NSMutableArray* array = [NSMutableArray array];
			[userDbMng getCapturePictInfoByPictId:[itemView imgId] Data:&array];

			// テンプレート用画像DBに登録する
			[userDbMng insertPictureUrl:array TemplateId:(_tmpTemplateId ? _tmpTemplateId : [_templInfo tmplId])];
		}
	}
	else
	{
		// 選択したファイルが変わっていなかったら、そのまま戻る
		if ( [self isSelectedPicturesDirty] == NO )
		{
			// DBクローズ
			[userDbMng closeDataBase];
			[userDbMng release];
			return YES;
		}

		// 選択した画像が変更されたら一旦DBから画像削除しておく
		[userDbMng deleteAllPictureUrls:[_templInfo tmplId]];

		// 現在選択されている画像を追加する
		for ( NSString* order in _selectItemOrder )
		{
			// 画像の取得
			NSUInteger tag = (NSUInteger)[order integerValue];
			OKDThumbnailItemView* itemView = [self searchThnmbnailItemByTagID:tag];
			if ( itemView == nil ) continue;
			
			// 取り込み画像DBから取得する
			NSMutableArray* array = [NSMutableArray array];
			[userDbMng getCapturePictInfoByPictId:[itemView imgId] Data:&array];
			
			// テンプレート用画像DBに登録する
			[userDbMng insertPictureUrl:array TemplateId:[_templInfo tmplId]];
		}

        //
		// 画像ファイルの削除リストがあったら、ファイルを削除する
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString* accID = [defaults stringForKey:@"accountIDSave"];
		NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];
		OKDImageFileManager *imgFileMng = [[OKDImageFileManager alloc] initWithFolder:folderName];
		for ( NSString* fileName in _delPictureList )
		{
			[imgFileMng deleteImageBothByRealSize:fileName];
		}
	}

	// DBクローズ
	[userDbMng closeDataBase];
	[userDbMng release];

	return YES;
}

/**
 setupUIController
 */
- (void) setupUIController
{
	// カテゴリーのテキストフィールドは編集不可
	[textCategory setEnabled:NO];
}

/**
 isExistTextData
 */
- (BOOL) isExistTextData
{
	// どちらか一方がテキストが存在すればYESを返す
	return ([textTitle hasText] || [textMailBody hasText]) ? YES : NO;
}

/**
 isTextFieldDirty
 */
- (BOOL) isTextFieldDirty
{
	if ( _editMode == TMPL_MODE_CREATE )
	{
		// 作成モード時はずっとダーティじゃないにしておく
		return NO;
	}
	else
	{
		// テンプレート作成画面起動時の状態
		NSString* strOldCategory = [_saveOldTextData objectAtIndex:0];
		NSString* strOldTitle = [_saveOldTextData objectAtIndex:1];
		NSString* strOldBody = [_saveOldTextData objectAtIndex:2];
		NSString* oldGen1Field = [_dicOldGeneralFields objectForKey:@"1"];
		NSString* oldGen2Field = [_dicOldGeneralFields objectForKey:@"2"];
		NSString* oldGen3Field = [_dicOldGeneralFields objectForKey:@"3"];

		// 現在の状態
		NSString* strNowCategory = [textCategory text];
		NSString* strNowTitle = [textTitle text];
		NSString* strNowBody = [textMailBody text];
		NSString* gen1Field = [_dicGeneralFields objectForKey:@"1"];
		NSString* gen2Field = [_dicGeneralFields objectForKey:@"2"];
		NSString* gen3Field = [_dicGeneralFields objectForKey:@"3"];

		BOOL cmp = [self cmpStringsWithOld:strOldCategory Now:strNowCategory]
				&& [self cmpStringsWithOld:strOldTitle Now:strNowTitle]
				&& [self cmpStringsWithOld:strOldBody Now:strNowBody]
				&& [self cmpStringsWithOld:oldGen1Field Now:gen1Field]
				&& [self cmpStringsWithOld:oldGen2Field Now:gen2Field]
				&& [self cmpStringsWithOld:oldGen3Field Now:gen3Field];
		return cmp ? NO : YES;
	}
}

/**
 選択したファイルが違っている
 */
- (BOOL) isSelectedPicturesDirty
{
	// 現在の選択されている個数を取得する
	NSInteger selectCount = 0;
	for ( OKDThumbnailItemView* itemView in _arrayThumbailItems )
	{
		if ( [itemView IsSelected] == YES )
			selectCount++;
	}

	// 選択数の比較
	if ( selectCount != [_oldArrayThumbailItems count] )
		return YES;
	
	// 起動時に選択されていたものと現在のが同じか？
	NSInteger find = 0;
	for ( NSArray* selObj in _oldArrayThumbailItems )
	{
		NSString* uuid = [selObj objectAtIndex:1];
		for ( OKDThumbnailItemView* itemView in _arrayThumbailItems )
		{
			if ( [itemView IsSelected] == YES )
			{
				if ( [[itemView imgId] isEqualToString:uuid] == YES )
				{
					// 見つかった
					find++;
					break;
				}
			}
		}
	}

	// 見つかった個数と起動時に選択されていた個数を比較
	return ([_oldArrayThumbailItems count] == find) ? NO : YES;
}

/**
 DBから削除される画像リスト
 */
- (NSArray*) getDeletePictureLists
{
	NSMutableArray* delLists = [NSMutableArray array];
	NSInteger oldCount = [_oldArrayThumbailItems count];
	for ( NSInteger i = 0; i < oldCount; i++ )
	{
		BOOL find = NO;
		NSMutableArray* itemOld = [_oldArrayThumbailItems objectAtIndex:i];
		for ( OKDThumbnailItemView* itemNew in _arrayThumbailItems )
		{
			if ( [[itemNew getFileName] isEqualToString:(NSString*)[itemOld objectAtIndex:0]]
			&&   [[itemNew imgId] isEqualToString:(NSString*)[itemOld objectAtIndex:1]]
			&&   [itemNew IsSelected] == [(NSNumber*)[itemOld objectAtIndex:2] boolValue] )
			{
				// 見つかったのでループを抜ける
				find = YES;
				break;
			}
		}

		// 見つからなかったので削除リストに登録する
		if ( find == NO )
		{
			// アイテムを追加
			NSMutableArray* delObj = [NSMutableArray array];
			[delObj addObject:[itemOld objectAtIndex:0]]; // filename
			[delObj addObject:[itemOld objectAtIndex:3]]; // select uuid
			// 削除リストに登録
			[delLists addObject:delObj];
		}
	}
	return delLists;
}

/**
 旧文字列と現在の文字列を比べる
 */
- (BOOL) cmpStringsWithOld:(NSString*)oldStr Now:(NSString*)nowStr
{
	// nil同士なので同じ
	if ( oldStr == nil && nowStr == nil )
		return YES;

	if ( oldStr == nil && nowStr != nil )
	{
		// 変更されている
		return NO;
	}
	else
	if ( oldStr != nil && nowStr == nil )
	{
		// 変更されている
		return NO;
	}
	else
	{
		NSInteger oldLen = [oldStr length];
		NSInteger nowLen = [nowStr length];
		if ( oldLen == nowLen )
		{
			// 長さ同じだけど内容を比べる
			return [oldStr isEqualToString:nowStr];
		}
		else
		{
			// 変更されている
			return NO;
		}
	}
	return NO;
}

/**
 insertTemplateDatabase
 */
- (BOOL) insertTemplateDatabaseWithCategory:(NSString*) strCategory
								  Gen1Field:(NSString*) strGen1Field
								  Gen2Field:(NSString*) strGen2Field
								  Gen3Field:(NSString*) strGen3Field
{
	userDbManager* userDBMng = [[userDbManager alloc] initWithDbOpen];

	// カテゴリーIDの取得
	NSString* categoryId = [userDBMng getCategoryID:strCategory];

	// 汎用１フィールドIDの取得
	NSString* gen1Field = [userDBMng getGenFieldID:strGen1Field];

	// 汎用２フィールドIDの取得
	NSString* gen2Field = [userDBMng getGenFieldID:strGen2Field];

	// 汎用３フィールドIDの取得
	NSString* gen3Field = [userDBMng getGenFieldID:strGen3Field];

	// 作成日時
	NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
	
	// データをまとめる
	NSMutableArray* arrayTemplateData = [NSMutableArray array];
	[arrayTemplateData addObject:(categoryId != nil) ? categoryId : [NSNull null]];
	[arrayTemplateData addObject:(gen1Field != nil) ? gen1Field : [NSNull null]];
	[arrayTemplateData addObject:(gen2Field != nil) ? gen2Field : [NSNull null]];
	[arrayTemplateData addObject:(gen3Field != nil) ? gen3Field : [NSNull null]];
	[arrayTemplateData addObject:[NSNumber numberWithDouble:date]];
	
	// データベースに挿入
	// 仮のテンプレートIDを使う
	[userDBMng insertTemplateWithID:_tmpTemplateId
							  Title:textTitle.text
							   Body:textMailBody.text
							   Data:arrayTemplateData];
	[userDBMng closeDataBase];
	[userDBMng release];
	return YES;
}

/**
 updateTemplateDatabaseWithGenField
 */
- (BOOL) updateTemplateDatabaseWithGenField:(NSString*) strCategory
								  Gen1Field:(NSString*) strGen1Field
								  Gen2Field:(NSString*) strGen2Field
								  Gen3Field:(NSString*) strGen3Field
{
	userDbManager* userDBMng = [[userDbManager alloc] initWithDbOpen];

	// カテゴリーIDの取得
	NSString* categoryId = [userDBMng getCategoryID:strCategory];
	
	// 汎用１フィールドIDの取得
	NSString* gen1Field = [userDBMng getGenFieldID:strGen1Field];
	
	// 汎用２フィールドIDの取得
	NSString* gen2Field = [userDBMng getGenFieldID:strGen2Field];
	
	// 汎用３フィールドIDの取得
	NSString* gen3Field = [userDBMng getGenFieldID:strGen3Field];
	
	// 作成日時
	NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
	
	// データをまとめる
	NSMutableArray* arrayTemplateData = [NSMutableArray array];
	[arrayTemplateData addObject:(categoryId != nil) ? categoryId : [NSNull null]];
	[arrayTemplateData addObject:(gen1Field != nil) ? gen1Field : [NSNull null]];
	[arrayTemplateData addObject:(gen2Field != nil) ? gen2Field : [NSNull null]];
	[arrayTemplateData addObject:(gen3Field != nil) ? gen3Field : [NSNull null]];
	[arrayTemplateData addObject:[NSNumber numberWithDouble:date]];

	// データベースを更新
	[userDBMng updateTemplateWithID:[_templInfo tmplId]
							  Title:textTitle.text
							   Body:textMailBody.text
							   Data:arrayTemplateData];

	[userDBMng closeDataBase];
	[userDBMng release];
	return YES;
}

/**
 thumbnailItemsMake
 */
- (void) thumbnailItemsMake
{
	// インジケーターON
	[self.view bringSubviewToFront:actIndView];
	[actIndView startAnimating];
	[self.view bringSubviewToFront:actIndView];

	// アイテムが追加されていたら初期化する
	NSMutableArray* arraySelect = [NSMutableArray array];
	if ( [_arrayThumbailItems count] > 0 )
	{
		for ( OKDThumbnailItemView* itemView in _arrayThumbailItems )
		{
			// 選択されていたサムネイルを記憶しておく
			if ( [itemView IsSelected] == YES )
			{
				[arraySelect addObject:[itemView imgId]];
			}
			// ビュー削除
			[itemView removeFromSuperview];
		}
		// アイテム削除
		[_arrayThumbailItems removeAllObjects];
	}

	// 画像URLがあった時
	NSInteger idx = 0;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:@"accountIDSave"];
	NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];

	// 画像の表示
	for ( NSMutableArray* _obj in _capturePictInfo )
	{
		NSString* strPictId = [_obj objectAtIndex:0];
		NSString* strPictUrl = [_obj objectAtIndex:1];
		NSTimeInterval updateTime = [(NSNumber*)[_obj objectAtIndex:2] doubleValue];

		// ファイル名
		NSString* strFileName = [strPictUrl lastPathComponent];

		// サムネイルViewの作成
		OKDThumbnailItemView *thumbnailView = [OKDThumbnailItemView alloc];
		[[thumbnailView initWithFrame: CGRectMake(0.0f, 0.0f, ITEM_WITH, ITEM_HEIGHT)] autorelease];
		[thumbnailView setFileName:strFileName];

		// Imageファイル管理のインスタンスを生成
		OKDImageFileManager* imgFileMng = [[OKDImageFileManager alloc] initWithFolder:folderName];

		// Document以下のファイル名に変換
		NSString* docFileName = [[NSString alloc] initWithString:[strFileName lastPathComponent]];
		docFileName = [docFileName substringToIndex:[docFileName length] - 4];
		[thumbnailView setTitle:docFileName];
		[imgFileMng release];

		// 選択していたものがあったら選択しておく
		if ( [arraySelect count] > 0 )
		{
			thumbnailView.delegate = self;
			thumbnailView.tag = idx;
			[thumbnailView setImgId:strPictId];
			[thumbnailView setUpdateTime:updateTime];
			for ( NSString* imgId in arraySelect )
			{
				if ( [imgId isEqualToString:strPictId] == YES )
				{
					[thumbnailView setIsSelected:YES];
					[arraySelect removeObject:imgId];
					break;
				}
			}
		}
		else
		{
			thumbnailView.delegate = self;
			thumbnailView.tag = idx;
			[thumbnailView setImgId:strPictId];
			[thumbnailView setUpdateTime:updateTime];
		}
		
		// itemをリストに加える
		[_arrayThumbailItems addObject:thumbnailView];

		idx++;
	}

	[_arrayThumbailItems sortUsingComparator:^(id v1, id v2){
		NSString *f1 = [((OKDThumbnailItemView *)v1) getFileName];
		NSString *f2 = [((OKDThumbnailItemView *)v2) getFileName];
		NSComparisonResult result = [f2 compare:f1];
		
		[f1 release];
		[f2 release];
		
		return (result);
	}];

	idx = 0;
	for ( OKDThumbnailItemView *view in _arrayThumbailItems )
	{
		view.tag = idx++;
		[viewPictureConteiner addSubview:view];
	}
	
	// アイテム選択順の初期化
	if ( [_selectItemOrder count] > 0 )
	{
		[_selectItemOrder removeAllObjects];
	}

	// Timerにより別スレッドでImageを描画する
	[NSTimer scheduledTimerWithTimeInterval:0.1f
									 target:self
								   selector:@selector(OnImageWrite:)
								   userInfo:nil
									repeats:NO];
}

/**
 Imageの描画：Timerスレッド
 */
-(void) OnImageWrite:(NSTimer*)timer
{
	// Imageファイル管理のインスタンスを生成
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:@"accountIDSave"];
	NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];
	OKDImageFileManager* imgFileMng = [[OKDImageFileManager alloc] initWithFolder:folderName];
	for ( int i = 0; i < [_arrayThumbailItems count]; i++ )
	{
		OKDThumbnailItemView *view = (OKDThumbnailItemView*)_arrayThumbailItems[i];
		[view writeToTemplateThumbnail:imgFileMng];
		[view drawRect:view.bounds];
	}
	// インジケーターOFF
	[actIndView stopAnimating];
	[imgFileMng release];
}

/**
 フルパスのファイル名からサムネイルのタイトル［yy年mm月dd日 HH時MM分］を取得する
 */
- (NSString*) makeThumbNailTitle:(NSString*)fullPath
{
	// フルパスからファイル名だけを取り出す->yyMMdd_HHmmss.jpg
	NSString* fileName = [fullPath lastPathComponent];
	
	// 文字列から日付を取り出す
	NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
	[formatter setDateFormat:@"yyMMdd_HHmmss"];
	NSDate* date = [formatter dateFromString:[fileName substringToIndex:13]]; // 先頭から13文字を取得
	
	// サムネイルタイトルの書式にする
	NSDateFormatter* formatter2 = [[[NSDateFormatter alloc] init] autorelease];
    [formatter2 setLocale:[NSLocale systemLocale]];
    [formatter2 setTimeZone:[NSTimeZone systemTimeZone]];
	[formatter2 setDateFormat:@"20yy年MM月dd日 HH時mm分"];
	
	return ([formatter2 stringFromDate:date]);
}

/**
 サムネイルItemのレイアウト
 */
-(void) thumbnailItemsLayout
{
	// 横方向の数
	CGFloat xNums = (scviewPictContainer.bounds.size.width == TMPL_THUBNAIL_CONTEINER_WIDTH)? ITEM_X_NUMS : ITEM_X_NUMS_LS;
	// 縦方向の数  height = THUBNAIL_CONTEINER_HEIHT:通常 // THUBNAIL_CONTEINER_HEIGHT_LOCK:画面ロック
	CGFloat yNums = (scviewPictContainer.bounds.size.height == TMPL_THUBNAIL_CONTEINER_HEIGHT)? ITEM_Y_NUMS : ITEM_Y_NUMS_WIN_LOCK;
	// 横マージン
	CGFloat wm = (scviewPictContainer.bounds.size.width - (ITEM_WITH * xNums) ) / (xNums + 1);
	// 縦マージン
	CGFloat hm = (scviewPictContainer.bounds.size.height - (ITEM_HEIGHT * yNums) ) / (yNums + 1);
	
	// コンテナViewのサイズ
	NSInteger itemCount = [_arrayThumbailItems count];
	NSInteger ih = itemCount / (NSInteger)xNums;
	if ( ih < (NSInteger)yNums )
		ih = (NSInteger)yNums;
	else if ( (itemCount % (NSInteger)xNums) != 0)
		ih++;
	CGFloat cHeight = (CGFloat)((hm * (ih + 1)) + (ITEM_HEIGHT * ih));
	[viewPictureConteiner setFrame:CGRectMake(0.0f, 0.0f, scviewPictContainer.bounds.size.width, cHeight)];
	
	// Scrollの設定
	[scviewPictContainer setContentSize: viewPictureConteiner.frame.size];
	
	// 各Itemの通し番号:0〜 _arrayThumbailItemsのcount
	int idx = 0;
	for ( id thumbnailView in _arrayThumbailItems )
	{
		// 列数番号：0 〜 (xNums - 1)
		NSInteger ix = idx % (NSInteger)xNums;
		// 行数番号：0 〜
		NSInteger iy = idx / (NSInteger)xNums;
		// 位置設定
		CGFloat posX = (wm * (ix + 1)) + (ITEM_WITH * ix);
		CGFloat posY = (hm * (iy + 1)) + (ITEM_HEIGHT * iy);
		[thumbnailView setFrame:CGRectMake(posX, posY, ITEM_WITH, ITEM_HEIGHT)];
		idx++;
	}
}

/**
 起動時にサムネイルを選択する
 */
- (void) initSelectThumbnailItems
{
	// テンプレート作成モード時は選択しなくてよい
	if ( [self editMode] == TMPL_MODE_CREATE )
		return;

	// テンプレート添付の画像なし
	if ( [[_templInfo pictureUrls] count] == 0 )
		return;

	// サムネイル
	for ( OKDThumbnailItemView* itemView in _arrayThumbailItems )
	{
		// リストの中にサムネイルの名前があるか
		for ( NSArray* array in [_templInfo pictureUrls] )
		{
			NSString* fullPath = (NSString*)[array objectAtIndex:1];
			NSString* pictName = [fullPath lastPathComponent];
			NSString* itemName = [itemView getFileName];
			if ( [pictName isEqualToString:itemName] == YES )
			{
				// 見つかったので選択しておく
				[itemView setSelect:YES];
				[itemView setSelectImgId:[array objectAtIndex:0]];
				break;
			}
		}
	}

	// 起動時の状態をコピーしておく
	_oldArrayThumbailItems = [[NSMutableArray alloc] init];
	for ( OKDThumbnailItemView* itemView in _arrayThumbailItems )
	{
		if ( [itemView IsSelected] == YES )
		{
			NSMutableArray* obj = [[[NSMutableArray alloc] init] autorelease];
			[obj addObject:[itemView getFileName]];
			[obj addObject:[itemView imgId]];
			[obj addObject:[NSNumber numberWithBool:[itemView IsSelected]]];
			[obj addObject:[itemView selectImgId]];
			[_oldArrayThumbailItems addObject:obj];
		}
	}
	_oldSelectItemOrder = [[NSMutableArray alloc] initWithArray:_selectItemOrder copyItems:YES];
}


/**
 起動時にサムネイルを選択する
 */
- (void) selectThumbnailItems
{
	// サムネイル
	for ( OKDThumbnailItemView* itemView in _arrayThumbailItems )
	{
		// URLが見つかった
		if ( [itemView IsSelected] == YES )
		{
			// 一旦NOにしないとダメらしい
			[itemView setIsSelected:NO];
			// 見つかったので選択しておく
			[itemView setSelect:YES];
		}
	}

	// Timerにより別スレッドでImageを描画する
	[NSTimer scheduledTimerWithTimeInterval:0.1f
									 target:self
								   selector:@selector(OnImageWrite:)
								   userInfo:nil
									repeats:NO];
}

/**
 サムネイルの更新
 */
- (void) refreshThumbnail
{
	// サムネイルItemリストの作成（写真データの読み込み含む）
	[self thumbnailItemsMake];
	
	// サムネイルItemのレイアウト
	[self thumbnailItemsLayout];
	
	// 再描画を行わない
	_isThumbnailRedraw = NO;
}

/**
 tagIDによりサムネイルItemを取り出す
 */
- (OKDThumbnailItemView*) searchThnmbnailItemByTagID:(NSUInteger)tagID
{
	// サムネイルItemを取り出す
	OKDThumbnailItemView* item = nil;
	for ( id iv in _arrayThumbailItems )
	{
		item = (OKDThumbnailItemView*)iv;
		if ( item.tag == tagID)
			break;
	}
	return(item);
}

/**
 サムネイルの選択個数を取得
 */
- (NSInteger) selectThubnailItemNums
{
	// 選択個数を確認
	NSInteger sel = 0;
	for ( id item in _arrayThumbailItems )
	{
		if (((OKDThumbnailItemView*)item).IsSelected)
		{
			sel++;
		}
	}
	return (sel);
}

/**
 保存確認のダイアログ表示
 */
- (void) showSaveCheckAlert
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"写真アルバムの取り込み"
												   message:@"この画像を取り込みますか？"
												  delegate:self
										 cancelButtonTitle:@"はい"
										 otherButtonTitles:@"いいえ" ,nil];
    alert.tag = ALERT_TAG_TAKE_PICTURE;
    [alert show];
    [alert release];
}

/**
 画像の取得
 */
- (void) takePictureFunc:(NSInteger) buttonIndex
{
	if ( buttonIndex != 0 )
	{
		// キャンセル
		viewPictureAlbum.image = nil;
		viewPictureAlbum.hidden = YES;
		return;
	}

	// 画像を保存する
	if ( [self saveImageFile:viewPictureAlbum.image] == YES )
	{
		// シャッター音を鳴らす
		[Common playSoundWithResouceName:@"shutterSound" ofType:@"mp3"];
		[self thumbnailSelectedCellRefresh];
	}
	else
	{
		[Common showDialogWithTitle:@"写真アルバムの取り込み"
							message:@"写真の取り込みに失敗しました\n(誠に恐れ入りますが\n再度操作をお願いいたします)"];
	}

	viewPictureAlbum.image = nil;
	viewPictureAlbum.hidden = YES;
}

/**
 画像の保存
 */
- (bool) saveImageFile:(UIImage*)cameraImage
{
	UIImage *image = cameraImage;
    
	// Imageファイル管理を選択ユーザIDで作成する
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:@"accountIDSave"];
	NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];
	OKDImageFileManager* imgFileMng = [[OKDImageFileManager alloc] initWithFolder:folderName];
	
	// Imageの保存：実サイズ版と縮小版の保存
	//	  ileName：パスなしの実サイズ版のファイル名
	NSString* fileName = [imgFileMng saveImage:image];
	if (! fileName)
	{
        // 保存に失敗
		[ imgFileMng release];
		return (NO);
	}
	
	NSLog(@"save photo album's file: => %@", fileName);
	
	// データベース内の写真urlはDocumentフォルダ以下で設定 -> TODO:変更必要
	NSString* docPictUrl = [NSString stringWithFormat:@"Documents/%@/%@", folderName, fileName];

	// 作成日時
	NSTimeInterval date = [[NSDate date] timeIntervalSince1970];
	
	// 保存したファイル名（パスなしの実サイズ版）でデータベースの履歴用のユーザ写真を追加
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	bool stat = [usrDbMng insertCapturePictInfo:accID PictUrl:docPictUrl Date:date];
	
	[usrDbMng release];
	[ imgFileMng release];
	
	return (stat);
}

// サムネイルの選択個数を取得
- (NSInteger) selectThumbnailItemNums
{
	// 選択個数を確認
	NSInteger nCount = 0;
	for ( OKDThumbnailItemView* item in _arrayThumbailItems)
	{
		if ( [item IsSelected] )
			nCount++;
	}
	return nCount;
}

/**
 アラートの初期化
 */
- (void) initAlertDialog
{
	// 削除なしAlertダイアログ
	deleteNoAlert = [[UIAlertView alloc] init];
	deleteNoAlert.title = @"選択画像を削除";
	deleteNoAlert.message = @"画像が選択されていません";
	deleteNoAlert.delegate = self;
	deleteNoAlert.tag = ALERT_TAG_DELETE_NO_ALERT;
	[deleteNoAlert addButtonWithTitle:@"OK"];

	// 削除確認Alertダイアログ
	deleteCheckAlert = [[UIAlertView alloc] init];
	deleteCheckAlert.title = @"選択画像を削除";
	deleteCheckAlert.message = @"選択されている画像を\n削除してよろしいですか？";
	deleteCheckAlert.delegate = self;
	deleteCheckAlert.tag = ALERT_TAG_DELETE_PICTURE;
	[deleteCheckAlert addButtonWithTitle:@"は　い"];
	[deleteCheckAlert addButtonWithTitle:@"いいえ"];
}

/**
 選択画像の削除
 */
- (void) selectedPictureDelete:(NSInteger)buttonIndex
{
    if( buttonIndex != 0 ){
        return;
    }
    
    // 削除用リスト
	NSMutableArray *deleteItems = [[NSMutableArray alloc] init];
	NSMutableArray *deleteTags = [[NSMutableArray alloc] init];
	NSMutableArray *delPictUrls = [[NSMutableArray alloc] init];
	userDbManager *usrDbMng = [[userDbManager alloc] init];

    // Imageファイル管理のインスタンスを生成
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:@"accountIDSave"];
	NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];
	OKDImageFileManager *imgFileMng = [[OKDImageFileManager alloc] initWithFolder:folderName];

	// テンプレートID
	NSString* tmplID = ([self editMode] == TMPL_MODE_CREATE) ? _tmpTemplateId : [_templInfo tmplId];
	
    for ( id item in _arrayThumbailItems )
    {
        OKDThumbnailItemView *thItem = (OKDThumbnailItemView*)item;
        if ( ![thItem IsSelected] ) continue;

		// URLを取得
		NSMutableArray* arrayData = [NSMutableArray array];
		[usrDbMng getCapturePictInfoByPictId:[thItem imgId] Data:&arrayData];
		NSString* pictUrl = (NSString*)[arrayData objectAtIndex:0];

		// 他のテンプレートで使用されているかチェックする
		BOOL error = NO;
		if ( [usrDbMng isTemplatePictureUsed:pictUrl TmplId:tmplID Error:&error] == YES )
		{
			// 使われていたので、このファイルの削除はしない
			NSString* msg = [NSString stringWithFormat:@"%@は\n他のテンプレートで使用されています\n削除できません", [thItem getFileName]];
			[Common showDialogWithTitle:@"画像削除" message:msg];
			continue;
		}

		// Pict Urlを削除リストに追加
		[delPictUrls addObject:pictUrl];
		
        // とりあえず親Viewより削除
        [thItem removeFromSuperview];
        
        // ファイル名の取得：パスを除くファイル名
        NSString *fileName = [thItem getFileName];

        // 削除用リストに加える
        [deleteItems addObject:thItem];
        
        for ( NSUInteger i = 0; i < [_selectItemOrder count]; i++ )
        {
            NSUInteger tag = (NSUInteger)[((NSString*)([_selectItemOrder objectAtIndex:i])) intValue];
            if (tag == ((OKDThumbnailItemView*)item).tag)
            {
                [deleteTags addObject:[_selectItemOrder objectAtIndex:i]];
                break;
            }
        }
        
		// データベースの履歴用ユーザ写真を削除:写真urlをキーとして削除
		[usrDbMng openDataBase];
		[usrDbMng deleteCapturePictInfo:[thItem imgId]];
		[usrDbMng closeDataBase];
        
		// ファイルの削除  DB更新後に削除する：ver130
		[_delPictureList addObject:fileName];
//		[imgFileMng deleteImageBothByRealSize:fileName];
//		[fileName release];
    }
    
    // サムネイルItemリストより削除
    for ( id delItem in deleteItems )
	{
        [_arrayThumbailItems removeObject:delItem];
    }
    
    // 選択サムネイルItemの順序Tableより削除
    for ( id delTag in deleteTags )
	{
        [_selectItemOrder removeObject:delTag];
    }

	// _templInfoのpictureUrlから削除
	for ( NSString* delUrl in delPictUrls )
	{
		[_templInfo removePictUrlByUrl:delUrl];
	}
	
    // データベースから最新の履歴用のユーザ写真リストを取得する
	[self loadPictUrls];
    
	// リリース
    [imgFileMng release];
    [deleteTags release];
    [deleteItems release];
	[delPictUrls release];

	// DBクローズ
    [usrDbMng release];
	
    // サムネイルItemリストの作成（写真データの読み込み含む）
	[self thumbnailItemsMake];
	
	// Itemを再度レイアウトする
	[self thumbnailItemsLayout];

	// 選択できるサムネイルがあったら選択する
	[self selectThumbnailItems];
	
	_isThumbnailRedraw = NO;
}

/**
 比較用のテキストデータの保存
 */
- (void) saveOldTextData
{
	NSString* strCategory = [textCategory text];
	NSString* strTitle = [textTitle text];
	NSString* strBody = [textMailBody text];

	if ( _saveOldTextData != nil )
	{
		[_saveOldTextData removeAllObjects];
		[_saveOldTextData release];
		_saveOldTextData = nil;
	}
	_saveOldTextData = [[NSMutableArray alloc] init];
	[_saveOldTextData addObject:((strCategory != nil) ? strCategory : @"")];
	[_saveOldTextData addObject:((strTitle != nil) ? strTitle : @"")];
	[_saveOldTextData addObject:((strBody != nil) ? strBody : @"")];
}

/**
 汎用フィールドが選択されているか
 */
- (BOOL) isGenFieldSelected:(NSInteger)genField
{
	NSNumber* selected = [NSNumber numberWithInteger:genField];
	NSString* str = [_dicGeneralFields objectForKey:[selected description]];
	return  (str != nil && [str length] > 0) ? YES : NO;
}

// 項目編集ポップアップの表示
- (void) dispItemEditerPopupWithEditKind:(ITEM_EDIT_KIND)editKind
{
	// メモ入力のためキーボードが表示されている場合は、ここで閉じる
	[textTitle resignFirstResponder];
	[textMailBody resignFirstResponder];
    
//    btnFreeMemoKbHider.hidden = YES;
	
	if (_popoverCntlWorkItemSet)
	{
		[_popoverCntlWorkItemSet release];
		_popoverCntlWorkItemSet = nil;
	}
	
	UITextView *tv = textMailBody;
    
    NSString *itemEditorPopupTitle = @"";
    UIView *btnView;
    switch (editKind) {
        case ITEM_EDIT_DATE:
            btnView = btnAddDateField;
            itemEditorPopupTitle = @"本文に入れたい日付を選択してください。（送信日より○日後）";
            break;
        case ITEM_EDIT_GENERAL1:
            btnView = btnAddGeneral1Field;
            itemEditorPopupTitle = @"テンプレートに挿入する文字を選択してください。";
            break;
        case ITEM_EDIT_GENERAL2:
            btnView = btnAddGeneral2Field;
            itemEditorPopupTitle = @"テンプレートに挿入する文字を選択してください。";
            break;
        case ITEM_EDIT_GENERAL3:
            btnView = btnAddGeneral3Field;
            itemEditorPopupTitle = @"テンプレートに挿入する文字を選択してください。";
            break;
        default:
            return;
    }
	
	//施術内容の設定ポップアップViewControllerのインスタンス生成
	itemEditerPopup *vcItemEditer
    = [[itemEditerPopup alloc] initWithHistID:0x7200
                                 itemEditKind:editKind
                               itemListString:tv.text
                            popOverController:nil
                                     callBack:self];
#ifndef CALULU_IPHONE
	// ポップアップViewの表示
	_popoverCntlWorkItemSet = [[UIPopoverController alloc]
                               initWithContentViewController:vcItemEditer];
	vcItemEditer.popoverController = _popoverCntlWorkItemSet;
	_popoverCntlWorkItemSet.delegate = self;	// ポップアップクローズ処理を行うため
	[_popoverCntlWorkItemSet presentPopoverFromRect:btnView.bounds
											inView:btnView
						  permittedArrowDirections:UIPopoverArrowDirectionDown
										  animated:YES];
    [_popoverCntlWorkItemSet setPopoverContentSize:CGSizeMake(560.0f, 280.0f)];
#else
    // 下表示modalDialogの表示
    [MainViewController showBottomModalDialog:vcItemEditer];
#endif
	// ポップアップタイトルの設定
    [vcItemEditer setPopupTitle:itemEditorPopupTitle];
	
	[vcItemEditer release];
    
	// ポップアップを開いた時は回転禁止にする
    iPadCameraAppDelegate *app = [[UIApplication sharedApplication]delegate];
    app.navigationController.enableRotate = NO;
}

// 項目をクリックした時のイベント
/**
 メソッドの引数についてはmemo設定に準じています
 selectedsには選択されたボタンが表示する文字列が１つくるだけです。
 editKindは使用していません。
 */
- (void)OnItemSetWithSelecteds:(NSArray*)selecteds itemEditKind:(ITEM_EDIT_KIND)editKind
{
	// カーソル位置取得
	NSRange range = [textMailBody selectedRange];
	// 挿入先
    NSString* text = [textMailBody text];
    if( [text length] < range.location ){
        range.location = [text length];
    }
	NSString* strFirstHalf = [text substringToIndex:range.location];
	NSString* strSecondHalf = [text substringFromIndex:range.location];
	// スクロールOFF
	[textMailBody setScrollEnabled:NO];
    
	// 施術内容の文字列の更新
	NSMutableString *strField = [NSMutableString string];
	for (id name in selecteds)
	{
		// 施術マスタテーブルよりIDにて内容（文字列）を取り出す
		[strField appendString:name];
	}
    
	// 文字列の挿入
	[textMailBody setText:[NSString stringWithFormat:@"%@%@%@", strFirstHalf, strField, strSecondHalf]];
	// 位置更新
	range.location += [strField length];
	[textMailBody setSelectedRange:range];
	// スクロールON
	[textMailBody setScrollEnabled:YES];
}

// ポップアップを閉じる時に、回転許可を戻す
- (void)afterPopupClose
{
    iPadCameraAppDelegate *app = [[UIApplication sharedApplication]delegate];
    app.navigationController.enableRotate = YES;
}

#pragma mark Handler
/**
 OnReturnTemplateManage
 */
- (IBAction) OnReturnTemplateManage
{
	MainViewController* mainVC = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	[mainVC closePopupWindow:self];
}

/**
 OnCategoryEditor
 */
- (IBAction) OnCategoryEditor:(id)sender
{
	if ( popOverController != nil )
	{
		[popOverController release];
		popOverController = nil;
	}
    
    [self.view endEditing: YES];
	
	// ポップオーバーの表示
	EditorPopup* editorPopup = [[EditorPopup alloc] initWithCategory:_arrayCategoryStrings
															   title:@"カテゴリー編集"
														selectString:textCategory.text
															delegate:self
															 popOver:nil];
	if ( editorPopup != nil )
	{
		popOverController = [[UIPopoverController alloc] initWithContentViewController:editorPopup];
		[editorPopup setPopOverController: popOverController];
		[popOverController presentPopoverFromRect:btnCategoryEditor.bounds
											 inView:btnCategoryEditor
						   permittedArrowDirections:UIPopoverArrowDirectionAny
										   animated:YES];
        [popOverController setPopoverContentSize:CGSizeMake(420.0f, 513.0f)];
	}
	[editorPopup release];
}

/**
 OnAddNameField
 */
- (IBAction) OnAddNameField:(id)sender
{
	// 名前フィールドをメール本文に追加
	[self appendStringInMailBodyWithField: NAME_FIELD];
}

/**
 OnAddDateField
 */
- (IBAction) OnAddDateField:(id)sender
{
	// 日付フィールドをメール本文に追加
//	[self appendStringInMailBodyWithField: DATE_FIELD];
    [self dispItemEditerPopupWithEditKind:ITEM_EDIT_DATE];

}

/**
 OnAddGeneral1Field
 */
- (IBAction) OnAddGeneral1Field:(id)sender
{
    [self dispItemEditerPopupWithEditKind:ITEM_EDIT_GENERAL1];
}

/**
 OnAddGeneral2Field
 */
- (IBAction) OnAddGeneral2Field:(id)sender
{
    [self dispItemEditerPopupWithEditKind:ITEM_EDIT_GENERAL2];
}

/**
 OnAddGeneral3Field
 */
- (IBAction) OnAddGeneral3Field:(id)sender
{
    [self dispItemEditerPopupWithEditKind:ITEM_EDIT_GENERAL3];
}

/**
 画像を削除する
 */
- (IBAction) OnDeletePicture:(id)sender
{
	if ( [self selectThumbnailItemNums] < 1 )
	{
		// 選択なし
		deleteNoAlert.title = @"選択画像を削除";
		deleteNoAlert.message = @"画像が選択されていません";
		[deleteNoAlert show];
		return;
	}

	// 削除ダイアログの表示
	[deleteCheckAlert show];
}


/**
 画像をアルバムから追加する
 */
- (IBAction) OnPhotoAlbum:(id)sender
{
    // アプリケーション使用容量設定値の自動設定を行う
    APCValueEnable valEnable = [appCapacityManager setAutoAppUsingCapacity];
    if (valEnable.freeDevSpace < 100.0f) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ご注意"
														message:@"空き容量が100MB未満になった為、\n画像・動画の撮影を中止します\niPad内の不要なコンテンツ等を\n削除し容量を確保して下さい"
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
		
        return;
    } else if (valEnable.freeDevSpace < 500.0f) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ご注意"
														message:@"空き容量が500MB未満になりました\n不要なコンテンツ等を削除し、\n容量を確保して下さい\n空き容量が100MB未満になると、\nデータ保護の為に画像・動画の撮影が\n出来なくなります"
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
//        // 空き容量がないので、この画面を閉じて前画面に戻る
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC);
//        dispatch_after(popTime, dispatch_get_main_queue(),
//			^{
//				[Common showDialogWithTitle:@"ご注意"
//									message:@"お使いのiPadには\n空き容量がありません\n\n不要なコンテンツなどを\n削除して空き容量を\n確保してください"];
//			});
//        return;
    }

	// アラートの表示
    if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO )
	{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"写真アルバムから取り込み"
                                                            message:@"写真アルバムが開けませんでした。\n(誠に恐れ入りますが\n再度操作をお願いいたします"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        return;
    };
	
	// イメージピッカーの作成
    UIImagePickerController *imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imgPicker.mediaTypes = @[(NSString*)kUTTypeImage];
    imgPicker.delegate = self;

	// イメージピッカー表示用ポップコントローラーの作成
	if ( _imagePopController != nil )
	{
		[_imagePopController release];
		_imagePopController = nil;
	}

	// ポップオーバー表示
	_imagePopController = [[UIPopoverController alloc] initWithContentViewController:imgPicker];
	_imagePopController.delegate = self;
    [_imagePopController presentPopoverFromRect:btnPictureAlbum.bounds
										 inView:btnPictureAlbum
					   permittedArrowDirections:UIPopoverArrowDirectionAny
									   animated:YES];
    [imgPicker release];
}

@end

/*
 UISpecialAlertView
 */
@implementation UISpecialAlertView

#pragma mark UISpecialAlertView_iOSFramework
/**
 dealloc
 */
- (void) dealloc
{
	[Callback release];
	[super dealloc];
}

#pragma mark UISpecialAlertView_Method
/**
 showWithCallback
 */
- (void) showWithCallback:(void (^)(NSInteger))callback
{
	Callback = [callback copy];
	[self show];
}

/**
 dismissWithClickedButtonIndex
 */
- (void) dismissWithClickedButtonIndex:(NSInteger) buttonIndex animated:(BOOL) animated
{
	[super dismissWithClickedButtonIndex:buttonIndex animated:animated];
	if ( Callback != nil ) Callback( buttonIndex );
	[Callback release];
	Callback = nil;
}

@end
