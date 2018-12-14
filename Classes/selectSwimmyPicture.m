//
//  selectSwimmyPicture.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/04/18.
//
//

#import "selectSwimmyPicture.h"

#import "ThumbnailViewController.h"
#import "OKDImageFileManager.h"
#import "userDbManager.h"

#import "VideoThumbnailItemView.h"
#import "MovieResource.h"

#define POP_WIN_WIDTH   750 - 143
#define POP_WIN_HEIGHT  512
#define SCR_VIEW_WIDTH  730 - 143
#define SCR_VIEW_HEIGHT 402

@interface selectSwimmyPicture ()

@end

@implementation selectSwimmyPicture

@synthesize myDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		// メンバの初期化
		tumbnailItems = nil;
		_scrollView = nil;
		_drawView = nil;
    }
    return self;
}

- (id) initWithSwimmyPicture:(NSUInteger)popUpID
           popOverController:(UIPopoverController *)controller
                    callBack:(id)callBackDelegate
                selectUserID:(USERID_INT)userID
                       title:(NSString *)lblString
{
    if (self = [super initWithPopUpViewContoller:popUpID popOverController:controller callBack:callBackDelegate]) {
        self.contentSizeForViewInPopover = CGSizeMake(POP_WIN_WIDTH, POP_WIN_HEIGHT);
        
        _selectedUserID = userID;
        _lblText = lblString;
        delegate = callBackDelegate;
        myDelegate = callBackDelegate;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [btnSet setBackgroundColor:[UIColor whiteColor]];
    [[btnSet layer] setCornerRadius:6.0];
    [btnSet setClipsToBounds:YES];
    [[btnSet layer] setBorderColor:[[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] CGColor]];
    [[btnSet layer] setBorderWidth:1.0];

    [btnCancel setBackgroundColor:[UIColor whiteColor]];
    [[btnCancel layer] setCornerRadius:6.0];
    [btnCancel setClipsToBounds:YES];
    [[btnCancel layer] setBorderColor:[[UIColor redColor] CGColor]];
    [[btnCancel layer] setBorderWidth:1.0];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    lblTitle.text = _lblText;

    // サムネイルの更新
    [self refreshThumbNail];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [btnSet release];
    [btnCancel release];
    [lblTitle release];
    [super dealloc];
}
- (void)viewDidUnload {
    [btnSet release];
    btnSet = nil;
    [btnCancel release];
    btnCancel = nil;
    [lblTitle release];
    lblTitle = nil;
    [super viewDidUnload];
}

#pragma mark 情報設定関連
// 選択ユーザIDの設定:サムネイルも再描画を行うかも判定する
- (void) setSelectedUserID:(USERID_INT)userID
{
		// ここで、選択ユーザIDを保存する
		_selectedUserID = userID;
}

// 選択OKの場合
- (IBAction)OnSelectOK:(id)sender {
    // 画像選択されていない場合
    if ([selectItemOrder count]<1) {
        return;
    }

    if([self.myDelegate respondsToSelector:@selector(OnSelectComparePictureSet:)])
        [self.myDelegate OnSelectComparePictureSet:[self getOrderdTumbnailItems]];

    [self closeByPopoverContoller];
}

// 選択キャンセルの場合
- (IBAction)OnSelectCancel:(id)sender {
    if([self.myDelegate respondsToSelector:@selector(OnSelectComparePictureCancel)])
        [self.myDelegate OnSelectComparePictureCancel];
    
    [self closeByPopoverContoller];
}

#pragma mark 画面描画関連
// ScrollViewと描画Viewの作成
- (void) makeScrDrawView
{
	// 画面サイズの取得
    CGFloat scrWidth = SCR_VIEW_WIDTH;
	CGFloat scrHeigth = SCR_VIEW_HEIGHT;

	// scroll viewの作成
	if (! _scrollView) {
		_scrollView = [[UIScrollView alloc]
                       initWithFrame:CGRectMake(10.0f, 55.0f, scrWidth, scrHeigth)];
		
		// 本（base）viewにスクロールビューを追加
		[self.view addSubview:_scrollView];
        
	}
	else {
		_scrollView .frame
        = CGRectMake(10.0f, 55.0f, scrWidth, scrHeigth);
		[_scrollView setZoomScale:1.0f];
	}
    
	
	// 描画Viewの作成 : 高さは横向きでの値（自動伸縮しないので仮設定）
	if (! _drawView) {
		_drawView = [[UIView alloc]
					 initWithFrame:CGRectMake(0.0f, 0.0f, scrWidth, scrHeigth+100)];
		
		// スクロールビューに対象viewを追加
		[_scrollView addSubview:_drawView];
	}
	else {
		_drawView.frame = CGRectMake(0.0f, 0.0f, scrWidth, scrHeigth);
		
		// 一旦、subViewとなるサムネイルItemを全て削除する
		for ( id vw in _drawView.subviews)
		{
			[((UIView*)vw) removeFromSuperview];
		}
	}
	
	// スクロール範囲の設定（これがないとスクロールしない）
	[_scrollView setContentSize:_drawView.frame.size];
    
	// ピンチ（ズーム）機能の追加:delegate指定
//	[_scrollView setDelegate:self];
	
	// スクロールビューの拡大と縮小の範囲設定（これがないとズームしない）
	[_scrollView setMinimumZoomScale:1.0];
	[_scrollView setMaximumZoomScale:3.0];
    
    _drawView.backgroundColor = [UIColor grayColor];
	
	// サムネイルItemを描画Viewに加える
	for ( id item in tumbnailItems)
	{
        // レイアウトはthumbnailItemsLayoutで行う
		[_drawView addSubview:(OKDThumbnailItemView*)item];
	}
}

// サムネイルItemのレイアウト isPortrait=縦向き(isPortrait)でTRUE
- (void) thumbnailItemsLayout:(BOOL)isPortrait
{
	// サムネイルItemのリストの個数
	NSUInteger count = [tumbnailItems count];
	
	// 横に何個並ぶか？
    NSUInteger wn = 4;		// 横画面＝ 7 縦画面＝5
	
	// 縦に何個並ぶか？
	NSUInteger hn = ((count % wn) == 0)? (count / wn) : ((count /wn) + 1);
	
	// 横マージン
    CGFloat wm = (isPortrait)?  15.0f : 15.0f;
    
	// 縦横間隔マージン（縦マージン）
   	CGFloat im = 15.0f;
	
	CGFloat sW;
	CGFloat sH;
	// 描画ViewとScrollViewもリサイズする
    CGFloat scrWidth  = POP_WIN_WIDTH;
	CGFloat scrHeight = POP_WIN_HEIGHT;
    
    [self.view setFrame:CGRectMake(0, 0, scrWidth, scrHeight)];
    
	if (isPortrait)
	{
   		sW = SCR_VIEW_WIDTH;
		// 縦の場合は高さを調節
		sH = ( (ITEM_HEIGHT * hn) + (im * (hn + 1) ));
	}
	else
	{
   		sW = SCR_VIEW_WIDTH;
        		// 横の場合も高さを調節
		sH = ( (ITEM_HEIGHT * hn) + (im * (hn + 1) ));
		
	}
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = (iOSVersion<7.0f)? 0.0f : 0.0f;

    [_drawView setFrame:CGRectMake(0.0f, 0.0f, sW, sH)];
    [_scrollView setFrame:CGRectMake(10.0f - uiOffset, 55.0f, SCR_VIEW_WIDTH, SCR_VIEW_HEIGHT)];
    
	// スクロール範囲の設定（これがないとスクロールしない）
	[_scrollView setContentSize:_drawView.frame.size];
	
    //2012 6/26 sHの比較対象をscrHeightから(scrHeight - 88.0f)に変更
	if ( (sW > scrWidth) || (sH > scrHeight - 88.0f) )
	{
		[_scrollView setContentSize:_drawView.frame.size];
	}
    
	// itemを縦横にレイアウト
	for (NSUInteger y = 0; y < hn; y++)
	{
		for (NSUInteger x = 0; x < wn; x++)
		{
			NSUInteger idx = x + (y * wn);
			
			if (idx >= count)
			{	break; }
			
			// itemの取り出し
			OKDThumbnailItemView *item
            = (OKDThumbnailItemView*)[tumbnailItems objectAtIndex:idx];
			
			// x位置：横マージン＋（縦横間隔マージン＋item幅）× x
			CGFloat xp = wm + (im + ITEM_WITH) * x;
			// y位置：縦マージン＋（縦横間隔マージン＋item高さ）× y
			CGFloat yp = im + (im + ITEM_HEIGHT) * y;
			[item setFrame:CGRectMake(xp, yp, ITEM_WITH, ITEM_HEIGHT)];
		}
	}
}

// サムネイルの選択個数を取得
- (NSInteger) selectThubnailItemNums
{
	// 選択個数を確認
	NSInteger sel = 0;
	for ( id item in tumbnailItems)
	{
		if (((OKDThumbnailItemView*)item).IsSelected)
		{
			sel++;
		}
	}
	
	return (sel);
}
// tagIDによりサムネイルItemを取り出す
- (OKDThumbnailItemView*) searchThnmbnailItemByTagID:(NSUInteger)tagID
{
	// サムネイルItemを取り出す
	OKDThumbnailItemView *item = nil;
	for (id iv in tumbnailItems)
	{
		item = (OKDThumbnailItemView*)iv;
		if ( item.tag == tagID)
		{
			break;
		}
	}
	
	return(item);
}

#pragma mark サムネイル関連
// サムネイルItemリストの作成
- (BOOL) tumbnailItemsMake
{
    
	// このユーザのDocumentsとCachesフォルダの写真ファイル一覧の取得
    NSArray *fileNames = [self _getPictureFiles];
    
	// 更新の必要性を確認:サムネイルItemリストとファイル一覧が同数であれば更新不要とする
	if ((tumbnailItems) &&
		([tumbnailItems count] == [fileNames count] ) )
	{	return (NO); }
    
//	[self.view bringSubviewToFront:actIndView];
//	[actIndView startAnimating];
//	[self.view bringSubviewToFront:actIndView];
	
	if (tumbnailItems != nil)
	{
		// リストをクリアする
		[tumbnailItems removeAllObjects];
	}
	else
	{
		// リストを空で作成
		tumbnailItems = [ [NSMutableArray alloc] init];
	}
    
    //データベースからタイトルを読み出す
    userDbManager *usrDbMng = [[userDbManager alloc] init];
    // Imageファイル管理のインスタンスを生成
    OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID:_selectedUserID];
    
	// ファイル一覧よりthumbnailのitemを作成
	// for (int idx = 0; idx < [fileNames count]; idx++) -> 昇順
    int tagnum = 1;
	for (NSInteger idx = ([fileNames count] -1); idx >= 0; idx--) // -> 降順
	{
		// ファイルのフルパス
		NSString *fileName
        = [NSString stringWithString:[fileNames objectAtIndex:idx]];
		
        // fukui　tmbのみしかない場合に対応
        if (! [fileName hasSuffix:THUMBNAIL_SIZE_EXT])
		{	continue; }
        MovieResource *movieResource = [[MovieResource alloc] initWithUserId:_selectedUserID fileName:fileName];
#ifdef DEBUG
        NSLog(@"Movie Resource : %@",movieResource.path);
#endif
		// サムネイルViewの作成
		OKDThumbnailItemView *thumbnailView;
        if (!movieResource.isMovie) {
            thumbnailView = [[OKDThumbnailItemView alloc] initWithFrame:
                             CGRectMake(0.0f, 0.0f, ITEM_WITH, ITEM_HEIGHT)];	// autorelease
            [thumbnailView setFileName:fileName];
        } else {
            continue; // 動画は必要ないので飛ばす
            thumbnailView = [[VideoThumbnailItemView alloc] initWithFrame:
                             CGRectMake(0.0f, 0.0f, ITEM_WITH, ITEM_HEIGHT)];	// autorelease
            [thumbnailView setFileName:movieResource.thumbnailPath];
        }
        
        //データベースからタイトルを読み出す
        [thumbnailView setTitle:[self makeThumbNailTitle:fileName]];

		thumbnailView.delegate = self;

        // ファイル総数よりサムネイル画像のtag番号を割り振っているため、jpg/mp4を
        // クラウドよりダウンロードするとファイル総数が変わりtag番号も変わってしまっていた
        // tag番号が固定になるように修正
		thumbnailView.tag = tagnum++;
		
        // userから送られたファイルの場合ファイル名は..._u.jpgになっている
//        if ([thumbnailView isKindOfClass:[OKDThumbnailItemView class]]) {
//            if ([fileName hasSuffix:@"u.tmb"] || [fileName hasSuffix:@"u.jpg"]) {
//                [(OKDThumbnailItemView *)thumbnailView setUser:YES];
//            } else {
//                [(OKDThumbnailItemView *)thumbnailView setUser:NO];
//            }
//        }
		// itemをリストに加える
		[tumbnailItems addObject:thumbnailView];
        [movieResource release];
		[thumbnailView release];
	}
    [usrDbMng release];
    [imgFileMng release];
	// Timerにより別スレッドでImageを描画する
	[NSTimer scheduledTimerWithTimeInterval:0.1f
									 target:self
								   selector:@selector(OnImageWrite:)
								   userInfo:nil
									repeats:NO];
#ifdef DEBUG
	NSLog(@"fire imageWrite timer");
#endif
	return (YES);
}

// Imageの描画：Timerスレッド
-(void) OnImageWrite:(NSTimer*)timer
{
#ifdef DEBUG
	NSLog(@"reise imageWrite timer");
#endif
	
	// Imageファイル管理のインスタンスを生成
	OKDImageFileManager *imgFileMng
    = [[OKDImageFileManager alloc]initWithUserID:_selectedUserID];
	
	for (id item in tumbnailItems)
	{
		// [ ((OKDThumbnailItemView*)item) writeToImage];
		[ ((OKDThumbnailItemView*)item) writeToThumbnail:imgFileMng];
		OKDThumbnailItemView *view = (OKDThumbnailItemView*)item;
		[view drawRect:view.bounds];
		// NSLog(@"imageWrite done on %d", ((OKDThumbnailItemView*)item).tag);
	}
	
//	[actIndView stopAnimating];
	
	[imgFileMng release];
#ifdef DEBUG
	NSLog(@"complite imageWrite timer");
#endif
}

// フルパスのファイル名からサムネイルのタイトル［yy年mm月dd日 HH時MM分］を取得する
- (NSString*) makeThumbNailTitle:(NSString*)fullPath
{
	// フルパスからファイル名だけを取り出す->yyMMdd_HHmmss.jpg
	NSString *fileName = [fullPath lastPathComponent];
	
	// 文字列から日付を取り出す
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setLocale:[NSLocale systemLocale]];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
	[formatter setDateFormat:@"yyMMdd_HHmmss"];
	NSDate *date
    = [formatter dateFromString:[fileName substringToIndex:13]]; // 先頭から13文字を取得
	
	// サムネイルタイトルの書式にする
	NSDateFormatter *formatter2 = [[[NSDateFormatter alloc] init] autorelease];
    [formatter2 setLocale:[NSLocale systemLocale]];
    [formatter2 setTimeZone:[NSTimeZone systemTimeZone]];
	[formatter2 setDateFormat:@"yyyy年MM月dd日 HH時mm分"];
	
	return ([formatter2 stringFromDate:date]);
}

// サムネイルの更新
- (void) refreshThumbNail
{
	// サムネイルItemリストの作成
	if (! [self tumbnailItemsMake])
	{	return; }		// 更新の必要なし
	
	// ScrollViewと描画Viewの作成
	[ self makeScrDrawView];
	
	// 選択サムネイルItemの順序Tableの初期化
	if (selectItemOrder == nil)
	{ selectItemOrder = [[NSMutableArray alloc] init];}
	
	// サムネイルItemのレイアウト
	UIScreen *screen = [UIScreen mainScreen];
	[self thumbnailItemsLayout:(screen.applicationFrame.size.width == 768.0f)];

    // 選択されているサムネイルの選択枠再描画
    for (int i = 0; i < (int)[selectItemOrder count]; i++)
    {
        NSUInteger oIdx
        = (NSUInteger)[((NSString*)[selectItemOrder objectAtIndex:i]) intValue];
        OKDThumbnailItemView *oItem = [self searchThnmbnailItemByTagID:oIdx];
        [oItem setSelectNumber:i+1];
        [oItem setSelect:YES];
    }
}

// 選択された画像の tagID
- (void)SelectThumbnail:(NSUInteger)tagID image:(UIImage*)image select:(BOOL)isSelect
{
#ifdef DEBUG
    NSLog (@"selected tag ID = %ld", (long)tagID);
#endif
	NSUInteger idx = 0xffffffff;
	NSUInteger count = 0;
	for (id aItem in selectItemOrder)
	{
		NSUInteger tag = (NSUInteger)[((NSString*)aItem) intValue];
		if ( tag == tagID)
		{
			// 選択時、選択したIDが既に選択サムネイルItemの順序Tableに含まれている場合は何もしない
			if (isSelect)
			{ return; }
			// 選択解除時、選択サムネイルItemの順序Tableより削除
			else
			{
				idx = count;
				break;
			}
		}
		
		count++;
		
		// NSLog(@"selectItemOrder item %u", (NSUInteger)((NSNumber*)aItem) )
	}
	
	if (idx != 0xffffffff)
	{
		// サムネイルItemを取り出す
		OKDThumbnailItemView *item = [self searchThnmbnailItemByTagID:tagID];
		// サムネイルItemの選択番号を非表示にする
		[item setSelectNumber:0];
		// 選択サムネイルItemの順序Tableより削除
		[selectItemOrder removeObjectAtIndex:idx];
		
		// 他のサムネイルItemの選択番号を更新
		for (int i = 0; i < (int)[selectItemOrder count]; i++)
		{
			NSUInteger oIdx
			= (NSUInteger)[((NSString*)[selectItemOrder objectAtIndex:i]) intValue];
			OKDThumbnailItemView *oItem = [self searchThnmbnailItemByTagID:oIdx];
			[oItem setSelectNumber:(i+1)];
		}
		
		return;
	}
	
	if (isSelect)
	{
		// サムネイルItemを取り出す
		OKDThumbnailItemView *item = [self searchThnmbnailItemByTagID:tagID];
        if (selectItemOrder.count > 0){
            NSUInteger oIdx
            = (NSUInteger)[((NSString*)[selectItemOrder objectAtIndex:0]) intValue];
            OKDThumbnailItemView *oItem = [self searchThnmbnailItemByTagID:oIdx];
            if ([oItem isKindOfClass:[VideoThumbnailItemView class]] !=
                [item isKindOfClass:[VideoThumbnailItemView class]]){
                // 動画と画像のサムネイルを両方選択することはできない。
                [item setSelect:NO];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"選択出来ません"
                                                                message:@"動画と静止画を同時に選択できません"
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil];
                [alert show];
                [alert release];
                return;
            }
        }
        // ２枚目を選択しようとしたとき
        if ([selectItemOrder count]>0) {
            // ２枚目選択されたサムネイルを元に戻す
            [[tumbnailItems objectAtIndex:tagID-1] setSelect:NO];

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"選択出来ません"
                                                            message:@"２枚以上選択できません"
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
            [alert show];
            [alert release];
            return;
        }
        
		// 選択時、選択サムネイルItemの順序Tableの末尾に追加
		[selectItemOrder addObject:[NSString stringWithFormat:@"%ld", (long)tagID]];
		
		// サムネイルItemに選択番号を設定にする
		[item setSelectNumber:(int)[selectItemOrder count]];
	}
    
}

// このユーザのDocumentsとCachesフォルダの写真ファイル一覧の取得
- (NSArray*) _getPictureFiles
{
    NSMutableArray *pictFiles = [NSMutableArray array];
    
    // 最初にCachesフォルダから取得
    NSMutableString *cFolder = [NSMutableString string];
    [cFolder appendFormat:@"%@/%@/", NSHomeDirectory(), DOWNLOAD_PICTURE_CACHES_FOLDER];
    [cFolder appendFormat:FOLDER_NAME_USER_ID, _selectedUserID];
    NSArray *cFiles
    = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cFolder error:NULL];
    for (NSString* aFile in cFiles)
    {   [ pictFiles addObject:aFile];}
    
    // 次にDocumentsフォルダから取得
    NSArray *dFiles
    = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:
       [NSString stringWithFormat:PICTURE_FOLDER, NSHomeDirectory(), _selectedUserID]
                                                          error:NULL];
    
    for (NSString* aFile in dFiles)
    {   [ pictFiles addObject:aFile];}
    
    return (pictFiles);
}

// 選択された画像の配列を作成する
- (NSMutableArray *)getOrderdTumbnailItems{

    NSMutableArray *orderdTumbnailItems = [NSMutableArray array];
	for ( id item in selectItemOrder)
	{
		NSUInteger idx = (NSUInteger)[((NSString*)item) intValue];
		for (id iv in tumbnailItems)
		{
			if ( ((OKDThumbnailItemView*)iv).tag == idx)
			{
				// サムネイルファイルはここで実サイズ版のファイル名に変える
                NSString *aFile = [((OKDThumbnailItemView*)iv) getFileName];
                NSString *realFile = ([ aFile hasSuffix:THUMBNAIL_SIZE_EXT])?
                [aFile stringByReplacingOccurrencesOfString:THUMBNAIL_SIZE_EXT
                                                 withString:REAL_SIZE_EXT] : aFile;
                [((OKDThumbnailItemView*)iv) setFileName:realFile];

                [orderdTumbnailItems addObject:iv];
			}
		}
	}
    return orderdTumbnailItems;
}

@end
