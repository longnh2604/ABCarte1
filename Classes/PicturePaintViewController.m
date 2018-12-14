    //
//  PicturePaintViewController.m
//  iPadCamera
//
//  Created by MacBook on 11/03/03.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "iPadCameraAppDelegate.h"
#import "MainViewController.h"

#import "PicturePaintViewController.h"
#import "PictureCompViewController.h"
#import "HistDetailViewController.h"
#import "HistListViewController.h"

#import "PicturePaintCommon.h"
#import "PicturePaintManagerView.h"
#import "PicturePaintPalletView.h"

#import "UtilHardCopySupport.h"

#import "userDbManager.h"
#import "OKDImageFileManager.h"

#import "AccountManager.h"
#import "UserInfoListViewController.h"
#import "DevStatusCheck.h"

@implementation PicturePaintViewController

@synthesize IsNavigationCall;
@synthesize IsCompViewSkipped;
@synthesize IsCompViewDirty;
@synthesize IsUpdown;

#pragma mark local_methods

// Viewの角を丸くする
- (void) setCornerRadius:(UIView*)radView
{
	CALayer *layer = [radView layer];
	[layer setMasksToBounds:YES];
	[layer setCornerRadius:12.0f];
}

// 画像合成画面に画像描画画面からの戻りであることを通知する
- (void) notifyFromPaintView2CompView
{
	// MainViewControllerの取得
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	UIViewController *vc
		= [ mainVC getVC4NaviCtrlWithClass:[PictureCompViewController class]];
	if (vc)
	{
		// 画像描画画面からの戻りであることを通知する
		[(PictureCompViewController*)vc backFromPicturePaintView];
		
		((PictureCompViewController*)vc).IsRotated = _isRotated;
			((PictureCompViewController*)vc).IsSetLayout = NO;
		}
	}

// 前画面に戻る（MainViewControllerにて遷移した時は呼び出されない）
- (void)OnBackView
{
	// if (! _isSaved)
	if ((self.IsCompViewDirty) || (vwPaintManager.IsDirty) )
	{
		// 合成画像が保存されていなければ、alertを表示して画面遷移しない
        [self showAlert];
		
		// ダイアログの応答待機
		NSInteger wait;
		while ((wait = _modifyCheckAlertWait) < 0)
		{
			[[NSRunLoop currentRunLoop]
				runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
		}
		
		// はいが押された
		if (wait == 1)
		{ return; }
	}

	if (! self.IsCompViewSkipped) 
	{
		// 画像合成画面を取得する
		NSArray *array = self.navigationController.viewControllers;
		PictureCompViewController* pictureCompVC = 
		(PictureCompViewController*)[array objectAtIndex:[array count] - 2];

		// 画像描画画面からの戻りであることを通知する
		[pictureCompVC backFromPicturePaintView];

			pictureCompVC.IsSetLayout = NO;
		pictureCompVC.IsRotated = _isRotated;
	}

	[self.navigationController popViewControllerAnimated:YES];
}

#ifdef CALULU_IPHONE

// タイトル、ロックボタンのの位置調整
- (void) _titelButtonLayout:(BOOL)isPortrait
{
    // 縦表示：タイトルとボタン２段表示
    if (isPortrait)
    {
        // 施術日：横サイズを縮小
        viewWorkDateBack.frame = CGRectMake(  5.0f,  4.0f, 135.0f, 24.0f);
        btnLockMode.frame = CGRectMake(  4.0f, 30.0f,  38.0f, 38.0f);
    }
    // 横表示：タイトルとボタン１段表示
    else
    {
        // 施術日：横サイズを大きくして「施術日」のDimを表示
        viewWorkDateBack.frame = CGRectMake(125.0f,  4.0f, 175.0f, 24.0f);
        btnLockMode.frame = CGRectMake(  4.0f,  4.0f,  38.0f, 38.0f);
    }
}

#endif

// 縦横の切り替え
- (void) changeToPortrait:(BOOL)isPortrait
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    float uiOffset = (iOSVersion<7.0f || !IsNavigationCall)? 0.0f : 20.0f;

	// 縦横の切り替え時に表示がおかしくなるので、一旦１倍に戻す
	myScrollView.zoomScale = 1.0f;
	
	// スクロールのコンテナViewの位置設定
#ifdef CALULU_IPHONE
	CGFloat posX = (isPortrait)?   0.0f : 80.0f;
	CGFloat posY = (isPortrait)? 100.0f : 44.0f;
    // 縦と横はPortraitとRandscapeで共通とする：またこれらはInterfaceBuilderで設定されていること
    // CGFloat width = (isPortrait)? VIEW_WIDTH : 400.0f; 
    // CGFloat height = (isPortrait)? VIEW_HEIGHT : 300.0f;
	CGFloat addHeight = (isPortrait)? 120.0f : 80.0f;	// 拡大したときに画像の下までスクロールしないため
#else
    CGFloat posX = (isPortrait)? 20.0f : 148.0f;
	CGFloat posY = (isPortrait)? 254.0f : 70.0f;
    // CGFloat width = VIEW_WIDTH;
    // CGFloat height = VIEW_HEIGHT;
	CGFloat addHeight = (isPortrait)? 120.0f : 80.0f;	// 拡大したときに画像の下までスクロールしないため
#endif
    if (self.IsUpdown){
        if (!isPortrait) posY += 30;
        [vwScrollConteiner setFrame:CGRectMake(posX, posY-50.0f, VIEW_WIDTH, 696.0f)];
        [imgvwPicture setFrame:CGRectMake(0.0f, 0.0f, VIEW_WIDTH, 696.0f)];
    }else{
        [vwScrollConteiner setFrame:CGRectMake(posX, posY, VIEW_WIDTH, VIEW_HEIGHT + addHeight)];
        [imgvwPicture setFrame:CGRectMake(0.0f, 0.0f, VIEW_WIDTH, VIEW_HEIGHT)];
    }
	
	// スクロール範囲の設定（これがないとスクロールしない）
	[myScrollView setContentSize:vwScrollConteiner.frame.size];
		
	//　パレットの位置調整
    if (IsNavigationCall && iOSVersion>=7.0f) {
        vwPaintPallet.uiOffset = 20.0f;
    }
	CGPoint origin = (isPortrait)?
#ifdef CALULU_IPHONE
		CGPointMake(4.0f, 414.0f) : CGPointMake(72.0f, 254.0f);
#else
		CGPointMake(20.0f, 924.0f + uiOffset) : CGPointMake(12.0f, 150.0f + uiOffset);
#endif
    // 描画ツールのボタンレイアウト(動画編集と同じものを呼ぶ:区分線なし)
    [vwPaintPallet setVideoEditPositionWithRotate:origin isPortrate:isPortrait];
    
    vwPaintPallet.uiOffset = 0.0f;
    
#ifdef CALULU_IPHONE
    // タイトル、ロックボタンの位置調整
    [self _titelButtonLayout:isPortrait];
#endif
	//　ロックボタンの位置調整
    [btnLockMode setFrame: (isPortrait)?
     CGRectMake(20.0f, 10.0f + uiOffset, 54.0f, 54.0f) :
     CGRectMake(20.0f, 10.0f + uiOffset, 54.0f, 54.0f) ];
	
    // ユーザ名
    [viewUserNameBack setFrame: (isPortrait)?
     CGRectMake(461.0f, 12.0f + uiOffset, 287.0f, 30.0f) :
     CGRectMake(461.0f + 256.0f, 12.0f + uiOffset, 287.0f, 30.0f) ];
    
    // 施術日
    [viewWorkDateBack setFrame: (isPortrait)?
     CGRectMake(124.0f, 12.0f + uiOffset, 310.0f, 30.0f) :
     CGRectMake(124.0f + 256.0f, 12.0f + uiOffset, 310.0f, 30.0f) ];

	// 印刷ボタンの位置調整
	if (! btnHardCopyPrint.hidden)
	{
		[btnHardCopyPrint setFrame: (isPortrait)?
#ifdef CALULU_IPHONE
			CGRectMake(278.0f, 30.0f, 38.0f, 38.0f) :
			CGRectMake( 84.0f,  4.0f, 38.0f, 38.0f) ];
#else
            CGRectMake(82.0f, 75.0f + uiOffset, 54.0f, 54.0f) :
            CGRectMake(82.0f, 75.0f + uiOffset, 54.0f, 54.0f) ];
#endif
	}
	
	// 画像保存ボタンの位置調整
	if (! btnSave.hidden)
	{
		[btnSave setFrame: (isPortrait)?
#ifdef CALULU_IPHONE
            CGRectMake( 44.0f, 30.0f, 38.0f, 38.0f) :
            CGRectMake( 44.0f,  4.0f, 38.0f, 38.0f) ];
#else
			CGRectMake(23.0f, 75.0f + uiOffset, 54.0f, 54.0f) :
			CGRectMake(23.0f, 75.0f + uiOffset, 54.0f, 54.0f) ];
#endif
	}
    
    //メール画面呼び出しボタンの位置調整
    if (! btnMail.hidden)
    {
        [btnMail setFrame:(isPortrait)?
         CGRectMake(23.0f, 134.0f + uiOffset, 54.0f, 54.0f) :
         CGRectMake(82.0f, 10.0f + uiOffset, 54.0f, 54.0f)];
    }
    
    //メールポップアップ再表示
    [self reloadMailPopup];
}

// 印刷の設定確認
- (void) priterSetting
{
	// 設定ファイル管理インスタンスを取得
	NSUserDefaults *defaluts = [NSUserDefaults standardUserDefaults];
	
	// 印刷の有効／無効を設定ファイルから取得
	BOOL stat = NO;
	if (! [defaluts objectForKey:@"printer_enable"])
	{
		// 初回取得
		// ここで書き込みを行う
		[defaluts setBool:stat forKey:@"printer_enable"];
	}
	else {
		stat = [defaluts boolForKey:@"printer_enable"];
	}
	
	// 印刷ボタンの有効／無効を行う
	btnHardCopyPrint.hidden = ! stat;
}

// mail送信ボタンの有効／無効設定
- (void) setMailSendButonEnable:(BOOL)isEnable
{
#if WEB_MAIL_FUNC || MAIL_FUNC
    if (isEnable)
	{
		btnMail.enabled = YES;
		[btnMail setBackgroundImage: [UIImage imageNamed:@"mailIcon_selected"]
                               forState:UIControlStateNormal];
	}
	else
	{
		btnMail.enabled = NO;
		[btnMail setBackgroundImage: [UIImage imageNamed:@"mailIcon_selected"]
                               forState:UIControlStateNormal];
	}
#else
    btnMail.hidden = YES;
#endif
}

// 遷移元のVCに対して更新処理を行う
- (void) refresh2OwnerTransitionVC
{
	// MainViewControllerの取得
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	
	// 他の画面に保存済み画像を表示する
	// 画面遷移の経路によって、通知先画面を変更する
	if (self.IsNavigationCall)
	{
		// 写真一覧（サムネイル）画面へ通知
		
		// NavigationControllerよりthumbNailクラスのVCを取得
		UIViewController *vc
			= [ mainVC getVC4NaviCtrlWithClass:[ThumbnailViewController class]];
		if (vc)
		{
			// サムネイルの更新(画像一覧のTAG変更含む)
            [(ThumbnailViewController*)vc refreshThumbNail:true];
		}
		
		// ViewContllerのリストより履歴一覧クラスのVCを取得
		vc = [ mainVC getVC4ViewControllersWithClass:[HistListViewController class] ];
		if (vc)
		{
			// Viewの日付による更新
			[ (HistListViewController*)vc refrshViewWithDate:[NSDate date]];
		}

	}
	else 
	{
		// 履歴詳細VC(2つ前のVC)を取得して、サムネイルを更新
		UIViewController *vc = [mainVC getViewControllerFromCurrentView:self pageTo:-3];
		if ((vc) 
			&& ([vc isKindOfClass:[HistDetailViewController class]]) )
		{
			// 当日の場合のみ、サムネイルと選択セルを更新する
			if ( ((HistDetailViewController*)vc).isWorkDateToday)				   
			{ [(HistDetailViewController*)vc thumbnailSelectedCellRefresh]; }
			
			// ユーザ情報Viewの更新
			[(HistDetailViewController*)vc refreshUserInfoView];
		}
		
		// 履歴一覧VC（３つ前のVC）を取得して、一覧を更新
		vc = [mainVC getViewControllerFromCurrentView:self pageTo:-4];
		if ((vc) 
			&& ([vc isKindOfClass:[HistListViewController class]]) )
		{
			// Viewの日付による更新
			[ (HistListViewController*)vc refrshViewWithDate:[NSDate date]];
		}	
	}
}

// Imageの保存
- (bool)saveImageFile:(UIImage*)image
{
	// 履歴IDをデータベースよりユーザIDと当日で取得する:当日の履歴がない場合は作成する
	HISTID_INT histID;
	userDbManager *usrDbMng = [[userDbManager alloc] init];
	if ( (histID = [usrDbMng getHistIDWithDateUserID:_userID 
										 workDate:[NSDate date]
								   isMakeNoRecord:YES] ) < 0)
	{
		NSLog(@"getHistIDWithDateUserID error on PicturePaintViewController!");
        [usrDbMng release];
		return NO;
	}
	
	// Imageファイル管理を選択ユーザIDで作成する
	OKDImageFileManager *imgFileMng 
		= [[OKDImageFileManager alloc] initWithUserID:_userID];
	
	// Imageの保存：実サイズ版と縮小版の保存
	//		fileName：パスなしの実サイズ版のファイル名
	NSString *fileName = [imgFileMng saveImage:image];
	
	if (! fileName)
	{
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:@"写真保存エラー"
								  message:@"写真の保存に失敗しました\n(誠に恐れ入りますが\n再度操作をお願いいたします)"
								  delegate:nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil
								  ];
		[alertView show];
		[alertView release];
		[usrDbMng release];
		[ imgFileMng release];
		
		return (NO);
	}
    lastSavedFilename = [NSMutableString stringWithString:fileName];// 最後に保存したファイル名の保存
    [lastSavedFilename retain];
	NSLog(@"PictureCompViewController - Save image file. userID:%d fileName => %@", _userID, fileName);
	
	// データベース内の写真urlはDocumentフォルダ以下で設定 -> TODO:変更必要
	NSString *docPictUrl =
		[NSString stringWithFormat:@"Documents/User%08d/%@", _userID, fileName];
	
	// 保存したファイル名（パスなしの実サイズ版）でデータベースの履歴用のユーザ写真を追加
	bool stat = [usrDbMng insertHistUserPicture:histID 
									 pictureURL:docPictUrl];	// docPictUrl -> fileName
	
	// 保存したファイル名（パスなしの実サイズ版でデータベースの履歴テーブルの代表画像の更新:既設の場合は何もしない
	stat |= [usrDbMng updateHistHeadPicture:histID pictureURL:docPictUrl	// docPictUrl -> fileName
							isEnforceUpdate:NO];
	
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@""
                              message:@"画像を保存しました"
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil
                              ];
    [alertView show];
    [alertView release];
    
    AudioServicesPlayAlertSound(1105);
    
	[usrDbMng release];
	[imgFileMng release];
	
	// 合成画像保存済みフラグ更新
	_isSaved = YES; // DELC SASAGE CHECK
	
	// 遷移元のVCに対して更新処理を行う
	[self refresh2OwnerTransitionVC];
	
	return (stat);
}

// Imageの合成
- (void)makeCombinedImage
{
	UIImage* imgOrigin = imgvwPicture.image;
	UIImage* imgCanvas = [vwPaintManager getCanvasImage];

	// 描画画像を上下反転
	CGRect rect = CGRectMake(0.0, 0.0, imgCanvas.size.width, imgCanvas.size.height);
	UIGraphicsBeginImageContext(rect.size);	
	CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0, rect.size.height);
	CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
	[imgCanvas drawInRect:rect];
	UIImage* imgCanvasReversed = UIGraphicsGetImageFromCurrentImageContext();	
	UIGraphicsEndImageContext();
	
	// 合成画像の作成
	if (_pictImageMixed) {
        [_pictImageMixed release];
		_pictImageMixed = nil;
	}

    // 画像が拡大されて640x480以下の画素サイズになっていた場合、書き足した線・スタンプが
    // ぼけてしまうため、縦480のサイズに強制的に拡大する
    CGSize size = imgOrigin.size;
    if (size.height < 480) {
        size.height = 480;
        size.width  = (480*imgOrigin.size.width)/imgOrigin.size.height;
        size.width  = (size.width>640)? 640 : size.width;
    }
    
    rect = CGRectMake(0.0, 0.0, size.width, size.height);
	UIGraphicsBeginImageContext(rect.size);

    CGContextRef context = UIGraphicsGetCurrentContext();  // コンテキストを取得
    CGContextStrokeRect(context, rect);  // 四角形の描画
    CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 1.0);  // 塗りつぶしの色を指定
    CGContextFillRect(context, rect);  // 四角形を塗りつぶす
    
	[imgOrigin drawInRect:rect];
    // ポートレートサイズ画像の場合、描画データのアスペクト比が崩れて合成されてしまうため
    // 合成領域を調整する
    rect = [self adjustAspect:rect adjustImage:imgCanvas];
	[imgCanvasReversed drawInRect:rect];
	_pictImageMixed = UIGraphicsGetImageFromCurrentImageContext();
    [_pictImageMixed retain];
	UIGraphicsEndImageContext();

}

/**
 * 画像のアスペクト比が正しくなるように調整
 * @param (CGRect)baseFrame     画像を表示するフレーム
 * @param (UIImage *)adjustImg  調整対象のイメージ
 */
- (CGRect)adjustAspect:(CGRect)baseFrame adjustImage:(UIImage *)adjustImg
{
    CGRect rect;
    CGSize tmpSize = CGSizeMake(adjustImg.size.width, adjustImg.size.height);
    CGFloat width  = baseFrame.size.width;
    CGFloat height = baseFrame.size.height;
    CGFloat tmpY   = baseFrame.origin.y;
    
    if (width < height) {   // ポートレートに対して調整する場合
        
        if (adjustImg.size.width > adjustImg.size.height)
        {   // 横長画像の場合(縦をフィットさせて、左右をクリップ)
            CGFloat tmpWidth = tmpSize.width * height / tmpSize.height;
            CGFloat tmpX     = (tmpWidth - width) / 2 * -1;
            rect = CGRectMake(tmpX, 0.0f, tmpWidth, height);
        }
        else
        {   // 縦長画像の場合
            rect = CGRectMake(0.0f, 0.0f, width, height);
        }
    } else {                // ランドスケープに対して調整する場合
        
        if (adjustImg.size.width < adjustImg.size.height)
        {   // 縦長画像の場合(縦をフィットさせて、左右はスペース)
            CGFloat tmpWidth = tmpSize.width * height / tmpSize.height;
            CGFloat tmpX     = (width - tmpWidth) / 2;
            rect = CGRectMake(tmpX, tmpY, tmpWidth, height);
        } else {
            rect = CGRectMake(0.0f, tmpY, width, height);
        }
    }
    
    return rect;
}

// スワイプのセットアップ
- (void) setupSwipSupportWithAddFlag:(BOOL)isAdd
{
	if (isAdd)
	{
		// 右方向スワイプを追加する
		UISwipeGestureRecognizer *swipeGestue = [[UISwipeGestureRecognizer alloc]
												 initWithTarget:self action:@selector(OnSwipeRightView:)];
		swipeGestue.direction = UISwipeGestureRecognizerDirectionRight;
		swipeGestue.numberOfTouchesRequired = 1;
		[self.view addGestureRecognizer:swipeGestue];
		
		[swipeGestue release];
	}
	else {
		// スワイプを全て削除
		// remarks:gestureRecognizersプロパティはcopyのためイテレート中の削除もOK
		for (id swipeGestue in self.view.gestureRecognizers)
		{	[self.view removeGestureRecognizer:swipeGestue]; }
	}
}

// 描画領域のクリアなど終了処理
- (void) onDestoryView
{
	// 描画領域のAll Clear
	[vwPaintManager allClearCanvas:YES];
	
	// 区分線の削除
	[vwPaintManager deleteSeparate];
	
	// １倍に戻す
	myScrollView.zoomScale = 1.0f;
	
	// MaibViewにスクロールロックを強制解除
	MainViewController *mainVC 
		= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
	[mainVC viewScrollLock:NO];
	
	// PictureCompViewControllerの取得(1つ前のView)
	PictureCompViewController *pictureCompVC = 
	(PictureCompViewController*)[mainVC getViewControllerFromCurrentView:self pageTo:-1];
	[pictureCompVC backFromPicturePaintView];
		pictureCompVC.IsSetLayout = NO;
	pictureCompVC.IsRotated = _isRotated;
    
    // Imageのクリア
//    [imgvwPicture setImage:nil];
    
    // ユーザ名、施術日のクリア
    lblUserName.text = @"";
    lblWorkDate.text = @"";
	
}


#pragma mark public_methods

// ユーザー情報の設定
- (void)setUser:(USERID_INT)userID
{
	_userID = userID;
}
// 施術情報の設定（画像合成ビューで必要）
- (void)setWorkItemInfo:(USERID_INT)userID workItemHistID:(HISTID_INT)histID
{
	_userID = userID;
	_histID = histID;
}
// 画像合成画面に新しいスタンプを置く //DELC SASAGE
- (void) setStampFromImage:(UIImage *)image{
    Stamp *stamp = [[Stamp alloc] initWithImage:image];
    [vwPaintManager setSelectedStamp:stamp];
}
//スタンプ選択画面のスタンプを全て、未選択状態に
- (void)setStampsUnselected{
    [vwPaintPallet setStampsUnselected];
}

#pragma mark life_cycle

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// 初期化
//	picture:写真Image  userName:対象ユーザ名  nameColor:ユーザ名の色 workDate:施術日（nil可：その場合は表示されない）
- (void)initWithPicture:(UIImage*)picture userName:(NSString*)name nameColor:(UIColor*)color workDate:(NSString*)date
{
    memWarning = NO;
    
	[imgvwPicture setImage:picture];
    width = picture.size.width;
    height = picture.size.height;
//    [picture release];
#ifdef DEBUG
    NSLog(@"pcount[%ld]", (long)[picture retainCount]);
#endif
	
	lblUserName.text = name;
	lblUserName.textColor = color;
	if (date)
	{
		lblWorkDate.text = date;
		
		lblWorkDate.hidden = NO;
		lblWorkDateTitle.hidden = NO;
		viewWorkDateBack.hidden = NO;
	}
	
	// メンバの初期化
	_isSaved = NO;
	self.IsCompViewSkipped = NO;
	
	if (_pictImageMixed)
	{
		// 合成画像破棄
		_pictImageMixed = nil;
	}
    // lastSavedFilename = [NSMutableString string]; //最後に保存したファイル名 初期化 DELC SASAGE
    lastSavedFilename = nil;
    
    [self setMailSendButonEnable:NO];
    [vwPaintManager resizeFrame:self.IsUpdown];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    // 背景色の変更 RGB:D8BFD8
//    [self.view setBackgroundColor:[UIColor colorWithRed:0.847 green:0.749 blue:0.847 alpha:1.0]];
    self.view.backgroundColor = [UIColor colorWithRed:204/255.0f green:149/255.0f blue:187/255.0f alpha:1.0f];
	// ロックモードの初期設定
	_isModeLock = NO;
    
	// 回転されたか
	_isRotated = NO;
	
	// 管理Viewとフリックボタンのhidden設定
	// vwPaintManager.hidden = YES;
	btnFlick.hidden = NO;
	
	// フリックボタンの初期化
	// [btnFlick initialize:self];
	// btnFlick.tag = FLICK_NEXT_PREV_VIEW;
	btnFlick.hidden = YES;
	
	// スクロール範囲の設定（これがないとスクロールしない）		   
	[myScrollView setContentSize:vwScrollConteiner.frame.size];
    
	// 背景Viewの角を丸くする
	[self setCornerRadius:viewUserNameBack];
	[self setCornerRadius:viewWorkDateBack];
	
	// パレットの初期化
	vwPaintPallet = [[PicturePaintPalletView alloc] initWithEventListner:vwPaintManager];
    [vwPaintPallet displayRotationBtn];
	[self.view addSubview:vwPaintPallet];
	vwPaintPallet.backgroundColor = viewUserNameBack.backgroundColor;
	// vwPaintPallet.alpha = 0.45f;
#ifdef VARIABLE_PICTURE_PAINT_PALLET
    // 動的パレットの初期化
    [vwPaintPallet initVariablePallet:self.view];
#endif

// #ifdef PICTURE_PAINT_PALLET_POPUP
    [vwPaintPallet setupPalletPopup];
// #endif
	
	// 写真描画の管理クラスの初期設定
	vwPaintManager.scrollViewParent = myScrollView;
	vwPaintManager.vwSaparete = vwSaparete;
	vwPaintManager.vwGrayOut1 = vwGrayOut1;
	vwPaintManager.vwGrayOut2 = vwGrayOut2;
	vwPaintManager.vwPallet = vwPaintPallet;

    vwPaintManager.vwStampE = vwStampE;
    vwPaintManager.imgvwStamp = imgvwStamp;
    
    vwPaintManager.ppvController = self;
    
    angle = 0;

    //    [self.view bringSubviewToFront:vwStampE];
    
    [vwPaintManager initLocal];

	
//	// 縦横切り替え
//	UIScreen *screen = [UIScreen mainScreen];
//#ifdef CALULU_IPHONE
//	[self changeToPortrait:(screen.applicationFrame.size.width == 320.0f)];
//#else
//    [self changeToPortrait:(screen.applicationFrame.size.width == 768.0f)];
//#endif
	
	// 印刷の設定確認
	[self priterSetting];

    // mailの利用が可能かを確認する(ログイン済みかつAppStore購入で無い場合)
    [self setMailEnableIsFlag:([AccountManager isLogined] && ![AccountManager isAppleStore])];
    
    // Alertダイアログの初期化
    modifyCheckAlert = nil;
	
	// NavigationCallによる画面遷移の場合
	if (self.IsNavigationCall)
	{	
		// スワイプをセットアップする
		[self setupSwipSupportWithAddFlag:YES]; 
	}
	
	// 画像保存時のflashViewの作成(インスタンスの作成のみ)
	flashView = [[UIView alloc] initWithFrame:self.view.frame];
	flashView.hidden =YES;
	[self.view addSubview:flashView];
	
	// 合成画像の編集フラグをリセット
	self.IsCompViewDirty = NO;
	
	// シャッター音のIDの初期化
	_shutterSoundID = (UInt32)0;
    
    //メールポップアップ再表示受信
    NSNotificationCenter *notif = [NSNotificationCenter defaultCenter];
    [notif addObserver:self selector:@selector(reloadMailPopup) name:@"reloadMailPopup" object:nil];
    //現在表示されている画像が保存済みかを監視
    int opt = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
    [self addObserver:self forKeyPath:@"IsCompViewDirty" options:opt context:NULL];
    [vwPaintManager addObserver:self forKeyPath:@"IsDirty" options:opt context:NULL];
    
    vcMailSend = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    // 縦横切り替え
	UIScreen *screen = [UIScreen mainScreen];
#ifdef CALULU_IPHONE
	[self changeToPortrait:(screen.applicationFrame.size.width == 320.0f)];
#else
    [self changeToPortrait:(screen.applicationFrame.size.width == 768.0f)];
#endif
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.IsCompViewDirty || vwPaintManager.IsDirty || !_isSaved){
        [self setMailSendButonEnable:NO];
    } else{
#ifdef AIKI_CUSTOM
        [self setMailSendButonEnable:YES];
#else
        if([AccountManager isWebMail]) // WebMail契約のある人のみ
            [self setMailSendButonEnable:YES];
#endif
    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

// 縦横切り替え後のイベント
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{	
	BOOL isPortrait;
	
	switch (toInterfaceOrientation) {
		case UIInterfaceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
			isPortrait = YES;
			break;
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			isPortrait = NO;
			break;
		default:
			isPortrait = NO;
			break;
	}

	// iOS7の場合、処理を分けないと配置がおかしくなるため
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self changeToPortrait:isPortrait];
    });
	
	// 回転されたか
	if (self.IsNavigationCall) 
	{
        _isRotated = YES;
    }	
}	

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
    if (!memWarning) {
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        if ([[mainVC getNowCurrentViewController] isKindOfClass:[PicturePaintViewController class]]) {
#ifdef DEBUG
            UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:@"ご注意"
                                       message:[NSString stringWithFormat:@"空きメモリ容量が少ない為、\niPad内の不要なアプリケーションを\n終了して下さい\n[%d]",
                                                [DevStatusCheck getFreeMemory]]
                                      delegate:nil
                             cancelButtonTitle:nil
                             otherButtonTitles:@"OK", nil];
#else
            UIAlertView *alert =
            [[UIAlertView alloc] initWithTitle:@"ご注意"
                                       message:@"空きメモリ容量が少ない為、\niPad内の不要なアプリケーションを\n終了して下さい"
                                      delegate:nil
                             cancelButtonTitle:nil
                             otherButtonTitles:@"OK", nil];
#endif
            [alert show];
            [alert release];
        }
    }
    memWarning = YES;
}

// アプリがスリープされた時に、一旦メモりワーニングフラグをクリアする
- (void)willResignActive {
    memWarning = NO;
}

- (void)viewDidUnload {
    [vwStampE release];
    vwStampE = nil;
    [imgvwStamp release];
    imgvwStamp = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s",__func__);
#endif
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reloadMailPopup" object:nil];

    if (_pictImageMixed) {
        [_pictImageMixed release];
    }
    
	if (flashView)
	{
        [flashView removeFromSuperview];
		[flashView release];
		flashView = nil;
	}

    [lblUserName release];
    [lblWorkDate release];
    [lblWorkDateTitle release];
    [viewUserNameBack release];
    [viewWorkDateBack release];
    [btnLockMode release];
    [btnHardCopyPrint release];
    [myScrollView release];
    myScrollView.delegate = nil;
    [vwScrollConteiner release];
    [btnFlick release];
    [vwSaparete release];
    [vwGrayOut1 release];
    [vwGrayOut2 release];
    [imgvwPicture setImage:nil];
    [imgvwPicture release];
    [btnSave release];
    [btnMail release];
    [vwStampE release];
    [imgvwStamp release];

    [vwPaintPallet removeFromSuperview];
	[vwPaintPallet release];
    vwPaintPallet.delegate = nil;
	
    [lastSavedFilename release];
    
    vwPaintManager.scrollViewParent = nil;
    vwPaintManager.vwSaparete = nil;
    vwPaintManager.vwGrayOut1 = nil;
    vwPaintManager.vwGrayOut2 = nil;
    vwPaintManager.vwPallet = nil;
    vwPaintManager.vwStampE = nil;
    vwPaintManager.imgvwStamp = nil;
    [vwPaintManager removeObserver:self forKeyPath:@"IsDirty"];
    [vwPaintManager release];

    [self removeObserver:self forKeyPath:@"IsCompViewDirty"];

    for (UIGestureRecognizer *gesture in [self.view gestureRecognizers]) {
        if ([gesture isKindOfClass:[UISwipeGestureRecognizer class]]) {
            [self.view removeGestureRecognizer:gesture];
        }
    }

    [super dealloc];
}

#pragma mark MainViewControllerDelegate

// 画面終了の通知（本画面がnavigationControllerよりコールされた場合は呼び出されない）
- (BOOL) OnUnloadView:(id)sender
{
	// if (! _isSaved)
	if ((self.IsCompViewDirty) || (vwPaintManager.IsDirty) ) 
	{
		// 合成画像が保存されていなければ、alertを表示して画面遷移しない
        [self showAlert];
		
		// NavigationCallによるもの
		if (sender == self)
		{
			_modifyCheckAlertWait = -1;
		 
			// ダイアログの応答待機
			NSInteger wait;
			while ((wait = _modifyCheckAlertWait) < 0)
			{
				[[NSRunLoop currentRunLoop]
				 runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5f]];
			}
			
			// はいが押された
			if (wait == 1)
			{ return (NO); }
		}
		// MainVCによるもの
		else {
			_modifyCheckAlertWait = 0;
			
			return (NO);
		}

	}
	
	// 描画領域のクリアなど終了処理
	[self onDestoryView];
		
	return (YES);		// 画面遷移する
}

/**
 * 画像描画の未保存時のアラート表示(iOS8対応含む)
 */
- (void)showAlert
{
    float iOSVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (iOSVersion<8.0) {
        // Alertダイアログの初期化
        if (modifyCheckAlert) {
            [modifyCheckAlert release];
        }
        modifyCheckAlert = [[UIAlertView alloc] init];
        modifyCheckAlert.title = @"画像描画";
        modifyCheckAlert.message = @"編集した画像を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集内容は\n破棄されます）";
        modifyCheckAlert.delegate = self;
        [modifyCheckAlert addButtonWithTitle:@"は　い"];
        [modifyCheckAlert addButtonWithTitle:@"いいえ"];
        
        [modifyCheckAlert show];
    } else {
#ifdef SUPPORT_IOS8
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"画像描画"
                                                                       message:@"編集した画像を破棄します\nよろしいですか？\n（「は　い」を選ぶと編集内容は\n破棄されます）"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"は　い"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    // MainVCによる場合で「はい」がタップされた場合
                                                    if (_modifyCheckAlertWait == 0)
                                                    {
                                                        // MainViewControllerの取得
                                                        MainViewController *mainVC
                                                        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
                                                        
                                                        // 前画面に戻る
                                                        [mainVC backBeforePage];
                                                    }
                                                    
                                                    // 押されたボタンを保存
                                                    _modifyCheckAlertWait = 0;
                                                    
                                                    // 合成と画像編集の編集フラグをクリア
                                                    self.IsCompViewDirty = vwPaintManager.IsDirty = NO;
                                                    _isSaved = YES;
                                                }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"いいえ"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    // 押されたボタンを保存
                                                    _modifyCheckAlertWait = 1;
                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
#endif
    }
}

// 画面が表示される都度callされる:viewDidAppear
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear : animated];
	
	// 管理Viewのtouchを無効にする
	vwPaintManager.userInteractionEnabled = NO;
	
	// 描画領域のAll Clear
	[vwPaintManager allClearCanvas:YES];
	
	// 区分線の削除
	[vwPaintManager deleteSeparate];
    
    // Mailボタンの初期化
#ifdef AIKI_CUSTOM
    [self setMailSendButonEnable:YES];
#else
    if([AccountManager isWebMail])
        [self setMailSendButonEnable:YES];
    else
        [self setMailSendButonEnable:NO];
#endif
	
	// 回転されたか
	_isRotated = NO;
	
	// 編集フラグをリセット
	vwPaintManager.IsDirty = NO;
	
	_modifyCheckAlertWait = -1;
    
    //mainVCのスクロールビューの幅設定　2012 6/22 伊藤
    MainViewController *mainVC 
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
    [mainVC setScrollViewWidth:YES];
    
    // 描画オブジェクトの初期化
    [vwPaintManager initDrawObject];
    
    myScrollView.userInteractionEnabled = NO;
}

// ロック画面への遷移確認:実装しない場合は遷移可とみなす
- (BOOL) OnDisplayChangeEnable:(id)sender disableReason:(NSMutableString*) message
{
	BOOL stat;
	
	// 編集中の場合は、遷移不可とする
	if ((! self.IsCompViewDirty) && (! vwPaintManager.IsDirty) )
	{	
		stat = YES; 
		
		MainViewController* mainVC = (MainViewController*)sender;
		// 前ページのView(画像合成)を強制スキップする
		[mainVC skipBeforePage: YES];
		// 前ページへ戻る：選択画像一覧画面
		[mainVC backBeforePage];

        if (vcMailSend) {
            [vcMailSend OnCancelButton:nil];
        }
	}
	else 
	{
		stat = NO;
		[message appendString:@"(先に保存をしてください)"];
	}
	
	return (stat);
}

// スクロール実施の確認 : NOを返すとスクロールをキャンセル
- (BOOL) OnCheckScrollPerformed:(id)sender touchView:(UIView*)view
{
    BOOL isPerformed = ! _isModeLock;
    
    return (isPerformed);
}

#pragma mark control_events

// ロックモード切り替えボタン
- (IBAction) OnBtnLockMode:(id)sender
{
	// 最初にロックモードを切り替える
	_isModeLock = ! _isModeLock;
	
	// ロックモードによりスクロールViewも動作しないようにする
	myScrollView.scrollEnabled = !_isModeLock;
    myScrollView.userInteractionEnabled = _isModeLock;
	
	// ボタンのimage変更
	[((UIButton*)sender) setImage:(_isModeLock)? 
							[UIImage imageNamed:@"lockIcon.png"] : [UIImage imageNamed:@"unlockIcon.png"]
						 forState: UIControlStateNormal];
	
	// 管理Viewとフリックボタンのhidden設定
	vwPaintManager.userInteractionEnabled = _isModeLock;
	// vwPaintManager.hidden = !(_isModeLock);
	// btnFlick.hidden = _isModeLock;
	
	// MaibViewにスクロールロックを依頼
	if (! self.IsNavigationCall)
	{
		MainViewController *mainVC 
			= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
		[mainVC viewScrollLock:_isModeLock];
	}
	else
	{
		// Lockの場合は、一旦スワイプを解除する
		/*	->	右方向スワイプにより、touchesCancelledイベントが発生するため
				PicturePaintManagerViewクラスにて、左->右方向での直線が切れる*/
        [self setupSwipSupportWithAddFlag:! _isModeLock];
	}

	
	// パレットに通知
	[vwPaintPallet setLockState:_isModeLock];
	
	// 写真描画の管理クラスに通知
	[vwPaintManager changeLockMode:_isModeLock];
}

// mail機能の有効
- (void) setMailEnableIsFlag:(BOOL)isEnable
{
    BOOL isHidden = ! isEnable;
    
    btnMail.hidden = isHidden;
    
    [self setMailSendButonEnable:isEnable];
}


// ハードコピー
- (IBAction)OnHardCopyPrint
{
	btnHardCopyPrint.enabled = NO;
	
	// 完了時のハンドラ
	UIPrintInteractionCompletionHandler completionHandler
		= ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) 
	{
		btnHardCopyPrint.enabled = YES;
		
		if(completed)
		{	/*btnHardCopyPrint.enabled = YES;*/}
		
		if (error)
		{
			NSLog(@"FAILED! due to error in domain %@ with error code %ld",
				  error.domain, (long)error.code);
			
			UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:@"画面印刷"
									  message:@"印刷できませんでした"
									  delegate:nil
									  cancelButtonTitle:@"OK"
									  otherButtonTitles:nil
									  ];
			[alertView show];
			[alertView release];	
		}
	};
	
	
	[UtilHardCopySupport startHardCopy:btnHardCopyPrint.bounds inView:btnHardCopyPrint
					 completionHandler:completionHandler];
}

// 画像保存ボタン
- (IBAction)OnSaveImage:(id)sender
{
	btnSave.enabled = NO;
	
	// 画面をフラッシュする
	[Common flashViewWindowWithParentView:self.view flashView:flashView];
	
	// シャッター音を鳴らす
//    [self performSelector:@selector(shutterSoundDelay) 
//               withObject:nil afterDelay:0.5f];
	
	// 写真描画の管理クラスに通知
	[vwPaintManager sendMailMode];
	// 合成画像作成
	[self makeCombinedImage];
		
	// 合成画像のファイル保存とDB更新
	[self saveImageFile:_pictImageMixed];
	
	_isSaved = YES;
	
	// 合成と画像編集の編集フラグをクリア
	self.IsCompViewDirty = vwPaintManager.IsDirty = NO;
	
    btnSave.enabled = YES;
#ifdef AIKI_CUSTOM
    [self setMailSendButonEnable:YES]; // 保存後、メールが送られるようになる。
#else
    if([AccountManager isWebMail]) // WebMail契約のある人のみ
        [self setMailSendButonEnable:YES]; // 保存後、メールが送られるようになる。
#endif
}

//メール送信ボタンイベント
- (IBAction)OnImageMail:(id)sender
{
    // ロックモードでなければ画面をロックする
    if (!_isModeLock) {
        [self OnBtnLockMode:btnLockMode];
    }
    
	// 写真描画の管理クラスに通知
	[vwPaintManager sendMailMode];

    //画像添付用配列
    NSMutableArray *pictImageItems = [NSMutableArray array];
    
    if (lastSavedFilename) {
        OKDThumbnailItemView *thumbnailView
            = [[[OKDThumbnailItemView alloc] initWithFrame:
            CGRectMake(0.0f, 0.0f, ITEM_WITH, ITEM_HEIGHT)] autorelease];
        [thumbnailView setFileName:lastSavedFilename];
        [pictImageItems addObject:thumbnailView];
    }
    
#ifndef WEB_MAIL_FUNC
    //smtpの設定がされているかチェック
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    NSMutableArray *infoBeanArray = [manager selectMailSmtpInfo:1];
    if([infoBeanArray count] != 0){
#endif
        //smtpを設定済み
        vcMailSend
        = [[MailSendPopUp alloc] initWithMailSetting:pictImageItems
                                        selectUserID:_userID
                                        selectHistID:_histID
                                           pictIndex:0
                                             popUpID:POPUP_EDIT_IMAGE_PROFILE
                                            callBack:self];
        // MainViewControllerの取得
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        [mainVC viewScrollLock:YES];
        self.view.userInteractionEnabled = YES;
        
        //メール送信画面を表示
        popoverCntlMailSend =
        [[UIPopoverController alloc] initWithContentViewController:vcMailSend];
        vcMailSend.popoverController = popoverCntlMailSend;
        [popoverCntlMailSend presentPopoverFromRect:btnMail.bounds
                                             inView:btnMail
                           permittedArrowDirections:UIPopoverArrowDirectionLeft
                                           animated:YES];
        [popoverCntlMailSend setPopoverContentSize:CGSizeMake(588.0f, 553.0f)];
        
        //画面外をタップしてもポップアップが閉じないようにする処理
        NSMutableArray *viewCof = [[NSMutableArray alloc]init];
        [viewCof addObject:mainVC.view];
        [viewCof addObject:self.view];
        popoverCntlMailSend.passthroughViews = viewCof;
        [viewCof release];
        [vcMailSend release];
#ifndef WEB_MAIL_FUNC
    }else{
        //smtpを未設定
        // ユーザ情報編集のViewControllerのインスタンス生成
        SetUpSmtpPopUp *setupSmtpViewController = [[SetUpSmtpPopUp alloc]initWithSmtpSetting:0x8010
                                                                                    callBack:self];
        
        // MainViewControllerの取得
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        [mainVC viewScrollLock:YES];
        self.view.userInteractionEnabled = NO;
        
        //Smtp設定画面表示
        popoverCntlMailSend =
        [[UIPopoverController alloc] initWithContentViewController:setupSmtpViewController];
        setupSmtpViewController.popoverController = popoverCntlMailSend;
        [popoverCntlMailSend presentPopoverFromRect:btnMail.bounds
                                             inView:btnMail
                           permittedArrowDirections:UIPopoverArrowDirectionAny
                                           animated:YES];
        
        //画面外をタップしてもポップアップが閉じないようにする処理
        NSMutableArray *viewCof = [[NSMutableArray alloc]init];
        [viewCof addObject:mainVC.view];
        [viewCof addObject:self.view];
        popoverCntlMailSend.passthroughViews = viewCof;
        [viewCof release];
    }
#endif
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    return NO;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    
}

#pragma mark MailSendPopUp Delegate
//メールポップアップデリゲート
- (void) OnPopUpViewSet:(NSUInteger)popUpID setObject:(id)object
{
    self.view.userInteractionEnabled = YES;
    
    if(!_isModeLock) {
        MainViewController *mainVC
        = ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
        [mainVC viewScrollLock:NO];
    }
    
    if (popUpID==MAILSEND_POPUP_ID) {
        // 個別メール送信時に、既読情報を取りに行く
        GetWebMailUserStatus *getStatus = [[GetWebMailUserStatus alloc] initWithDelegate:self];
        [getStatus getStatus:_userID];
        [getStatus release];
    }
    
    [popoverCntlMailSend release];
    popoverCntlMailSend = nil;
    vcMailSend = nil;
}

/**
 * 個別メール送信終了時、即座にメールステータスを反映させる
 */
- (void)finishedGetWebMailUserStatus:(USERID_INT)_userId
							  unread:(NSInteger)unread
						  userUnread:(NSInteger)userUnread
							   check:(NSInteger)check
				  notification_error:(NSInteger)notification_error
						   exception:(NSException *)exception
{
    if (exception == nil) {
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
        
    }
}

//メールポップアップの再表示
- (void) reloadMailPopup
{
    //メールポップアップを表示中なら一旦消して再表示する
    if (popoverCntlMailSend != nil) {
        MailSendPopUp *mailSendPopUp = (MailSendPopUp*)popoverCntlMailSend.contentViewController;
        //メール送信処理中ならfalseが帰ってくる
        BOOL noMailflag = [mailSendPopUp onceSaveMailData];
        if (noMailflag) {
            //処理中でないなら再表示処理を実行する
            [popoverCntlMailSend dismissPopoverAnimated:YES];
            [popoverCntlMailSend release];
            popoverCntlMailSend = nil;
            
            [self OnImageMail:nil];
        }
    }
}

- (void) shutterSoundDelay
{
    [Common playSoundWithResouceName:@"shutterSound" ofType:@"mp3"];
	// [Common playSoundWithResouceName:@"CameraShutter" ofType:@"caf"];
	
	// [Common playSystemSoundWithResouceName:@"CameraShutter" ofType:@"caf" soundID:&_shutterSoundID];
	
	btnSave.enabled = YES;
}

#pragma mark UIScrollViewDelegate

// ピンチ（ズーム）機能：これがないとピンチしない
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	// このviewがscroll対象のviewとなる
	UIView *view = nil;
    NSLog(@"scrollview %@", scrollView);
	if (myScrollView == scrollView)
	{
        //prevent scrolling inside scrollview
		// scroll対象をスクロールのコンテナViewとする
        view = vwScrollConteiner;
	}
	
	return (view);
}

#pragma mark swipe_events

// 右方向のスワイプイベント
- (void)OnSwipeRightView:(id)sender
{
	// ロックモードの時は何もしない
	if (_isModeLock)
	{	return; }
	
	// とりあえず１倍に戻す
	myScrollView.zoomScale = 1.0f;
	
	// 前画面に戻る確認をする
	if ( ([self OnUnloadView:self]) && (self.IsNavigationCall))
	{
		// 画像合成画面に画像描画画面からの戻りであることを通知する
		[self notifyFromPaintView2CompView];
		
		// 現時点で最上位のViewController(=self)を削除する
		[self.navigationController popViewControllerAnimated:YES];
	}
}

#pragma mark UIFlickerButtonDelegate
// フリックイベント
- (void)OnFlicked:(id)sender flickState:(FLICK_STATE)state
{
	switch (((UIFlickerButton*)sender).tag) 
	{
		case FLICK_NEXT_PREV_VIEW:
			// 画面遷移
			switch (state) {
				case FLICK_RIGHT:
					//　前画面に戻る
					[self OnBackView];
					break;
				default:
					break;
			} 
			break;
		default:
			break;
	}
}

// ダブルタップイベント
- (void)OnDoubleTap:(id)sender
{
	switch (((UIFlickerButton*)sender).tag)  
	{
		case FLICK_NEXT_PREV_VIEW:
			//　前画面に戻る
			// [self OnSelectPictView];
			
			// １倍に戻す
			myScrollView.zoomScale = 1.0f;
			break;
		default:
			break;
	}
}

#pragma mark UIAlertViewDelegate

// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// 合成画像保存確認の場合
	if (alertView == modifyCheckAlert)
	{	
		// MainVCによる場合で「はい」がタップされた場合
		if ( (_modifyCheckAlertWait == 0) && (buttonIndex == 0))
		{
			// MainViewControllerの取得
			MainViewController *mainVC 
				= ((iPadCameraAppDelegate*)[[UIApplication sharedApplication]delegate]).viewController;
			
			// 前画面に戻る
			[mainVC backBeforePage];
		}
		
		// 押されたボタンを保存
		_modifyCheckAlertWait = buttonIndex;
					
		// 合成と画像編集の編集フラグをクリア
        if(buttonIndex == 0) {
            self.IsCompViewDirty = vwPaintManager.IsDirty = NO;
            
            _isSaved = YES;
        }
	}
	
	// alertの表示を消す
	[alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
	
	// 描画領域のクリアなど終了処理
	// [self onDestoryView];
	
}

- (void)rotateImage{
    UIImage *image = imgvwPicture.image;

    angle = angle - 90;
    
    if(width > height){
        CGContextRef context;
        float radian;
        switch (angle) {
            case 0:
                UIGraphicsBeginImageContext(CGSizeMake(width, height));
                context = UIGraphicsGetCurrentContext();
                CGContextTranslateCTM(context, width, height);
                CGContextScaleCTM(context, 1.0, -1.0);
                
                radian = -90 * M_PI / 180;
                CGContextRotateCTM(context, radian);
                CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
                
                imgvwPicture.image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                break;
            case -90:
                UIGraphicsBeginImageContext(CGSizeMake(height, width));
                context = UIGraphicsGetCurrentContext();
                CGContextTranslateCTM(context, image.size.height/2, image.size.width/2);
                CGContextScaleCTM(context, 1.0, -1.0);
                
                radian = -90 * M_PI / 180;
                CGContextRotateCTM(context, radian);
                CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(-image.size.width/2, -image.size.height/2, image.size.width, image.size.height), image.CGImage);
                
                imgvwPicture.image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                break;
            case -180:
                UIGraphicsBeginImageContext(CGSizeMake(width, height));
                context = UIGraphicsGetCurrentContext();
                CGContextTranslateCTM(context, image.size.height/2, image.size.width/2);
                CGContextScaleCTM(context, 1.0, -1.0);
                
                radian = -90 * M_PI / 180;
                CGContextRotateCTM(context, radian);
                CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(-image.size.width/2, -image.size.height/2, image.size.width, image.size.height), image.CGImage);
                
                imgvwPicture.image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                break;
            case -270:
                UIGraphicsBeginImageContext(CGSizeMake(height, width));
                context = UIGraphicsGetCurrentContext();
                CGContextTranslateCTM(context, image.size.height/2, image.size.width/2);
                CGContextScaleCTM(context, 1.0, -1.0);
                
                radian = -90 * M_PI / 180;
                CGContextRotateCTM(context, radian);
                CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(-image.size.width/2, -image.size.height/2, image.size.width, image.size.height), image.CGImage);
                
                imgvwPicture.image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                angle = -90;
                break;
        }
    }else{        
        CGContextRef context;
        float radian;
        UIGraphicsBeginImageContext(CGSizeMake(height, height));
        context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, image.size.height/2, image.size.height/2);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        radian = -90 * M_PI / 180;
        CGContextRotateCTM(context, radian);
        CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(-image.size.width/2, -image.size.height/2, image.size.width, image.size.height), image.CGImage);
        
        imgvwPicture.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
}

@end
