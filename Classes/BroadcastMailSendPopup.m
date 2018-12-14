//
//  BroadcastMailSendPopup.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/05/15.
//
//

/*
 IMPORT
 */
#import "defines.h"
#import "BroadcastMailSendPopup.h"
#import "OKDImageFileManager.h"
#import "OKDThumbnailItemView.h"

/*
 INTERFACE
 */
@interface BroadcastMailSendPopup ()
{
	// UIパーツ
	IBOutlet UITextField* mailTitle;
	IBOutlet UITextView* mailBody;
	IBOutlet UIScrollView* scviewThumbnails;
	IBOutlet UIToolbar* toolBar;
	IBOutlet UIBarButtonItem* btnSendMail;
	IBOutlet UIBarButtonItem* btnCancel;
	IBOutlet UILabel* labelAttachPict;

	// データ
	NSMutableDictionary* _dicMailData;
	NSString* _tmplId;
	BOOL _isMailSend;
    id<BroadcastMailSendPopupDelegate> broadcastMailSendPopDelegate;
}
@end

/*
 IMPLEMENTATION
 */
@implementation BroadcastMailSendPopup

#pragma mark iOS_Framework
/**
 viewDidLoad
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	// 件名
	mailTitle.backgroundColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.956 alpha:1.0];
	mailTitle.layer.cornerRadius = 8;
	mailTitle.layer.borderWidth = 0.5f;
	mailTitle.layer.borderColor = [[UIColor darkGrayColor] CGColor];
	NSString* title = [_dicMailData objectForKey:@"title"];
	[mailTitle setText:title];

	// テンプレート本文
	mailBody.backgroundColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.956 alpha:1.0];
	mailBody.layer.cornerRadius = 8;
	mailBody.layer.borderWidth = 0.5f;
	mailBody.layer.borderColor = [[UIColor darkGrayColor] CGColor];
	NSString* body = [self makePreviewText:[_dicMailData objectForKey:@"body"]];
	[mailBody setText:body];

	// サムネイル画像
	if ( [self isExistTemplatePict] == YES )
	{
		// あり
		[labelAttachPict setText:@"添付画像"];
		// 添付画像ビューを変更する
		scviewThumbnails.backgroundColor = [UIColor colorWithRed:0.937 green:0.937 blue:0.956 alpha:1.0];
		scviewThumbnails.layer.cornerRadius = 8;
		scviewThumbnails.layer.borderWidth = 0.5f;
		scviewThumbnails.layer.borderColor = [[UIColor darkGrayColor] CGColor];
		// 添付画像を表示する
		[self createThumbnails];
	}
	else
	{
		// なし
		[labelAttachPict setText:@"添付画像なし"];
		// 画像ビューを非表示に
		[scviewThumbnails setHidden:YES];
		// ウィンドウサイズの変更
		NSInteger height = 211 + 17;
		self.contentSizeForViewInPopover = CGSizeMake(580, 640 - height);
	}
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
	// UIパーツのリリース
	[mailTitle release];
	[mailBody release];
	[scviewThumbnails release];
	[toolBar release];
	[btnSendMail release];
	[btnCancel release];
	[labelAttachPict release];

	// データのリリース
	[_dicMailData release];
	[_tmplId release];

	[super dealloc];
}


#pragma mark local_method

/**
 プレビュー用にテンプレート本文を作成する
 */
- (NSString*) makePreviewText:(NSString*)body
{
	// まずは本文をコピー
	NSString* preview = [NSString stringWithString:body];

	// 選択されている先頭ユーザーの取得
	NSMutableArray* users = [_dicMailData objectForKey:@"users"];
	NSMutableDictionary* userDic = [users objectAtIndex:0]; // top
	NSMutableDictionary* replaceValue = [userDic objectForKey:@"replace_values"];

	// 名前
	NSString* replaceName = [replaceValue objectForKey:@"NAME"];

	// 日付
	NSString* replaceDate = [replaceValue objectForKey:@"DATE"];
	
	// 汎用フィールド
	NSString* replaceGen1Field = [replaceValue objectForKey:@"FIELD1"];
	NSString* replaceGen2Field = [replaceValue objectForKey:@"FIELD2"];
	NSString* replaceGen3Field = [replaceValue objectForKey:@"FIELD3"];

	// 文字列を置き換える
	preview = [preview stringByReplacingOccurrencesOfString:@"{__NAME__}" withString:replaceName];
	preview = [preview stringByReplacingOccurrencesOfString:@"{__DATE__}" withString:replaceDate];
	preview = [preview stringByReplacingOccurrencesOfString:@"{__FIELD1__}" withString:replaceGen1Field];
	preview = [preview stringByReplacingOccurrencesOfString:@"{__FIELD2__}" withString:replaceGen2Field];
	preview = [preview stringByReplacingOccurrencesOfString:@"{__FIELD3__}" withString:replaceGen3Field];
	
	return preview;
}

/**
 テンプレート画像が存在するか
 */
- (BOOL) isExistTemplatePict
{
	NSMutableArray* picts = [_dicMailData objectForKey:@"picture_urls"];
	return ([picts count] > 0) ? YES : NO;
}

/**
 テンプレート画像のサムネイルを作成／表示する
 */
- (void) createThumbnails
{
	// フォルダ名
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:@"accountIDSave"];
	NSString* folderName = [NSString stringWithFormat:FOLDER_NAME_TEMPLATE_ID, accID];

	NSMutableArray* arrayThumbnails = [[NSMutableArray alloc] init];
	NSInteger imgCount = 0;
	NSInteger imgHeight = 0;
	NSInteger contentsHeight = 0;

	NSMutableArray* picts = [_dicMailData objectForKey:@"picture_urls"];
	for ( NSString* pictUrl in picts )
	{
		// ファイル名
		NSString* fileName = [pictUrl lastPathComponent];

		// イメージの取得
		OKDImageFileManager* fileMng = [[OKDImageFileManager alloc] initWithFolder:folderName];
		UIImage* realImg = [fileMng getTemplateRealSizeImage:fileName];
		UIImage* resizeImg = [self resizePicture:realImg Resize:100];
		CGSize imgSize = resizeImg.size;
		imgHeight = resizeImg.size.height;

		// サムネイルの追加
		CGFloat posX = ((imgCount%3) * imgSize.width) + (((imgCount%3) + 1) * 10);
		CGFloat posY = ((imgCount/3) * imgSize.height) + (5 * ((imgCount/3) + 1));
		UIImageView* imgView = [[UIImageView alloc] initWithFrame:CGRectMake(posX, posY, imgSize.width, imgSize.height)];
		[imgView setBackgroundColor:[UIColor darkGrayColor]];
		[imgView setImage:resizeImg];
		[scviewThumbnails addSubview:imgView];
		
		imgCount++;
	}

	// スクロールビューの設定
	scviewThumbnails.scrollEnabled = YES;
	NSInteger hCount = (NSInteger)ceil((double)imgCount / 3.0f);
	contentsHeight = (imgHeight * hCount) + ((hCount + 1) * 5);
	if ( contentsHeight < 211 ) contentsHeight = 211;
	scviewThumbnails.contentSize = CGSizeMake(540, contentsHeight);
	
	[arrayThumbnails release];
}

/**
 */
- (UIImage*) resizePicture:(UIImage*)srcImg Resize:(CGFloat)resizeHeight
{
	// サイズを求める
	CGFloat witdh = srcImg.size.width;
	CGFloat height = srcImg.size.height;
	CGFloat aspect = witdh / height;
	CGFloat resizeWidth = aspect * resizeHeight;
	CGSize resized = CGSizeMake(resizeWidth, resizeHeight);

	// リサイジングする
	UIGraphicsBeginImageContext(resized);
    [srcImg drawInRect:CGRectMake(0, 0, resized.width, resized.height)];
    UIImage* resizedImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	return resizedImg;
}

#pragma mark instance_method

/**
 初期化する
 */
- (id) initWithMailData:(NSMutableDictionary*)dic
			 TemplateId:(NSString*)tmplId
				PopupId:(NSInteger)popupId
			   Callback:(id)callback
{
    broadcastMailSendPopDelegate = callback;
    
	self = [super initWithPopUpViewContoller:popupId
						   popOverController:nil
									callBack:callback
									 nibName:@"BroadcastMailSendPopup"];
	if ( self )
	{
		// サイズ変更
		self.contentSizeForViewInPopover = CGSizeMake(580, 640);
		// メールデータ
		_dicMailData = dic;
		[_dicMailData retain];
		// テンプレートID
		_tmplId = tmplId;
		[_tmplId retain];
		// メール送信フラグ
		_isMailSend = NO;
	}
	return self;
}

#pragma mark event_handler

/**
 キャンセルボタン
 */
- (IBAction) OnCancel:(id)sender
{
	if ( delegate != nil )
	{
		[delegate OnPopUpViewSet:-1 setObject:nil];
	}
    if( self->_dicMailData != nil ){
        [self->_dicMailData release];
    }
	[self closeByPopoverContoller];
}

/**
 送信ボタン
 */
- (IBAction) OnSendMail:(id)sender
{
//2016/1/5 TMS ストア・デモ版統合対応 デモ版のみ一斉メール送信スルー
#ifndef FOR_SALES
	if ( _isMailSend )
		return;

	_isMailSend = YES;
    [broadcastMailSendPopDelegate SendButtonCallBack:self->_dicMailData];
    
    if( self->_dicMailData != nil ){
        [self->_dicMailData release];
    }
    if ( delegate != nil ){
		[delegate OnPopUpViewSet:-1 setObject:nil];
	}
	[self closeByPopoverContoller];
#endif
}

/**
 popoverviewが閉じる前に呼ばれる。
 プロトコルで定義されている。
 　※ dismissPopoverAnimated を使って明示的に閉じたときには呼ばれない。
 return YES :ウインドウが閉じる。
 return NO  :ウインドウが閉じない。
 */
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    if( self->_dicMailData != nil ){
        [self->_dicMailData release];
    }
    if ( delegate != nil ){
		[delegate OnPopUpViewSet:-1 setObject:nil];
	}
    return YES;
}

/**
 popoverviewが閉じた後に呼ばれる。
 プロトコルで定義されている。
 　※ dismissPopoverAnimated を使って明示的に閉じたときには呼ばれない。
 */
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    
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

@end
