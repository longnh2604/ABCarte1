//
//  QRCodeViewController.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/04/18.
//
//

/*
 IMPORT
 */
#import "QRCodeViewController.h"
#import "Common.h"
#import "MainViewController.h"
#import "MailSendPopUp.h"

/*
 INTERFACE
 */
@interface QRCodeViewController ()
{
	IBOutlet UINavigationBar* naviBar;
	IBOutlet UIView* viewBasePanel;
	IBOutlet UIImageView* imageBackground;
	IBOutlet UIImageView* imageQRDefault;
	IBOutlet UIImageView* imageQRCodeSmartPhone;
	IBOutlet UIImageView* imageQRCodeDocomo;
	IBOutlet UIImageView* imageQRCodeAuSoftbank;
	IBOutlet UITextView* textView;
	IBOutlet UIBarButtonItem* btnQRcodeReturn;
	IBOutlet UISegmentedControl* segmentCarrier;

	NSInteger _userId;
	NSString* _accID;
	id<QRCodeViewControllerDelegate> _delegate;
	NSInteger _carrier;
}
@end

/*
 IMPLEMENTATION
 */
@implementation QRCodeViewController

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
		_carrier = QR_CARRIER_DEFAULT;
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

	// セグメントの選択 - デフォルトはスマートフォンで
	[segmentCarrier setSelectedSegmentIndex:0];

	// 背景色の変更
	viewBasePanel.backgroundColor = [Common getScrollViewBackColor];
	
	// テキストビューに枠線の描画
	[[textView layer] setBorderWidth:2];
	[[textView layer] setBorderColor:[[UIColor blackColor] CGColor]];

	// QRコードの表示
	imageQRDefault.hidden = NO;
	imageQRCodeSmartPhone.hidden = YES;
	imageQRCodeDocomo.hidden = YES;
	imageQRCodeAuSoftbank.hidden = YES;
}

/**
 willRotateToInterfaceOrientation
 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
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
	[super viewWillAppear:animated];
}

/**
 dealloc
 */
- (void) dealloc
{
	// UIパーツ
	[imageBackground release];
	[imageQRCodeSmartPhone release];
	[textView release];
	[btnQRcodeReturn release];
	[segmentCarrier release];
	
	[super dealloc];
}


#pragma mark LocalMethod
/*
 QRコードの作成
 */
- (UIImage*) createQRCodeWithCarrier:(NSInteger)carrier
							MailAddr:(NSString*)mailAddr
							UserData:(NSString*)userData
							CheckSum:(NSString*)checkSum
						   ImageSize:(CGSize)imgSize
						   ImageView:(UIImageView*)imgView
							   hints:(ZXEncodeHints*)hints
{
	NSString* strMail = [self createQRString:carrier
									MailAddr:mailAddr
									UserData:userData
									CheckSum:checkSum];
	
	CGImageRef qrSmartPhoneImage = [self createQRImage:strMail ImageSize:imgSize ImageView:imgView hints:hints];
	return [self correctBlurImage:[UIImage imageWithCGImage:qrSmartPhoneImage] ImageSize:imgSize];
}


/**
 QRコードイメージの作成
 */
- (CGImageRef) createQRImage:(NSString*)strQRCode ImageSize:(CGSize)imgSize ImageView:(UIImageView*)imgView hints:(ZXEncodeHints*)hints
{
	if ( strQRCode == nil || [strQRCode length] == 0 )
		return nil;

	// QRコードの作成
	ZXMultiFormatWriter* writer = [[ZXMultiFormatWriter alloc] init];
	CGSize imageSize = imgSize;
	ZXBitMatrix* result = nil;
	if ( hints == nil )
	{
		result = [writer encode:strQRCode
						 format:kBarcodeFormatQRCode
						  width:imageSize.width
						 height:imageSize.height
						  error:nil];
	}
	else
	{
		result = [self encodeQRWithText:strQRCode
							  ImageSize:imgSize
								  Scale:4
							  ImageView:imgView
								  Hints:hints
								ecLevel:hints.errorCorrectionLevel
								  error:nil];
	}

	[writer release];
	if ( result == nil )
	{
		// 出てこなかった
		return nil;
	}

	// イメージの取得
	CGImageRef rqImage = [[ZXImage imageWithMatrix:result] cgimage];
	return rqImage;
}

/*
 */
- (NSString*) createUserData
{
	// ユーザーデータの作成
	NSMutableDictionary* dicUserData = [NSMutableDictionary dictionary];

	// ユーザーID
	NSNumber* userId = [NSNumber numberWithInteger:_userId];
	[dicUserData setObject:userId forKey:@"user_id"];
	// アカウントID
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString* accID = [defaults stringForKey:@"accountIDSave"];
	[dicUserData setObject:accID forKey:@"account_id"];
	// 日付
	NSDate* today = [NSDate date];
	NSDateFormatter* fm = [[NSDateFormatter alloc] init];
	[fm setLocale:[NSLocale systemLocale]];
	[fm setTimeZone:[NSTimeZone systemTimeZone]];
	[fm setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString* strDate = [fm stringFromDate:today];
	[dicUserData setObject:strDate forKey:@"date"];

	// JSONに変換
	NSData* jsonData = nil;
	NSError* error = nil;
	NSString* strBase64 = nil;
	if ( [NSJSONSerialization isValidJSONObject:dicUserData] == YES )
	{
		// to JSON
		jsonData = [NSJSONSerialization dataWithJSONObject:dicUserData
												   options:NSJSONWritingPrettyPrinted
													 error:&error];

		// base64にエンコード
		if ( [jsonData respondsToSelector:@selector(base64EncodedStringWithOptions:)] )
		{
			// iOS7 and later
			strBase64 = [jsonData base64EncodedStringWithOptions:kNilOptions];
		}
		else
		{
			// iOS6 and prior
			strBase64 = [jsonData base64Encoding];
		}
	}
    
    [fm release];
	return strBase64;
}

/*
 QRコードに入力する文字列の作成
 */
- (NSString*) createQRString:(NSInteger)carrier
					MailAddr:(NSString*)mailAddr
					UserData:(NSString*)userData
					CheckSum:(NSString*)checkSum
{
	NSMutableString* mailto = [NSMutableString string];

	switch ( carrier )
	{
		case QR_CARRIER_DEFAULT:
			{
				/*
				 デフォルト設定
				 */

				// URL
				//
				//  http://abcarte.net/registuser.html?data=userData&checksum=checkSum
				//
				[mailto appendFormat:@"http://abcarte.net/registuser.php?data=%@&checksum=%@", userData, checkSum];
			}
			break;

		case QR_CARRIER_SMARTPHONE:
			{
				/*
				 スマートフォン向け
				 */
				NSString* strSubject = [self urlEncode:@"メールアドレスの登録" Encoding:kCFStringEncodingUTF8];
				[mailto appendFormat:@"mailto:%@?", mailAddr];						// メールアドレス
				[mailto appendFormat:@"subject=%@&", strSubject];					// 件名
				[mailto appendFormat:@"body=DATA:%@%%26%@", userData, checkSum];	// 本文
			}
			break;

		case QR_CARRIER_DOCOMO:
			{
				/*
				 docomo
				 MATMSG:TO:hogehoge@foo.com;SUB:参加表明;BODY:オレオレ;;
				 */
				[mailto appendFormat:@"MATMSG:TO:%@;", mailAddr];					// メールアドレス
				[mailto appendString:@"SUB:メールアドレスの登録;"];						// 件名
				[mailto appendFormat:@"BODY:DATA:%@&%@;;", userData, checkSum];		// 本文
			}
			break;
			
		case QR_CARRIER_AU:
		case QR_CARRIER_SOFTBANK:
			{
				/*
				 softbank, au
				 MAILTO:hogehoge@foo.com
				 SUBJECT:参加表明
				 BODY:オレオレ
				 */
				[mailto appendFormat:@"MAILTO:%@\n\r", mailAddr];						// メールアドレス
				[mailto appendString:@"SUBJECT:メールアドレスの登録\n\r"];				// 件名
				[mailto appendFormat:@"BODY:DATA:%@%%26%@\n\r", userData, checkSum];	// 本文
			}
			break;

		default:
			break;
	}

	return mailto;
}

/**
 URLエンコード
 */
- (NSString*) urlEncode:(NSString*)data Encoding:(CFStringEncoding)encoding
{
	NSString* escapedString = (NSString*)CFURLCreateStringByAddingPercentEscapes(
		kCFAllocatorDefault,
		(CFStringRef)data,
		NULL,
		(CFStringRef)@"!*'();:@&=+$,/?%#[]",
		encoding
	);
	NSString* retString = [NSString stringWithString:escapedString];
	[escapedString release];
	return retString;
}

/**
 ぼやけたイメージを補正する
 */
- (UIImage*) correctBlurImage:(UIImage*)blurImage ImageSize:(CGSize)imgSize
{
	UIGraphicsBeginImageContext( imgSize );
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetInterpolationQuality( context, kCGInterpolationNone );	// 補間なし設定
	[blurImage drawInRect:CGRectMake( 0, 0, imgSize.width, imgSize.height )];
	blurImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return blurImage;
}

/**
 携帯端末用にQRコードを作成
 */
int const QUIET_ZONE_SIZE = 4;
- (ZXBitMatrix*) encodeQRWithText:(NSString*)strQRCode
						ImageSize:(CGSize)imgSize
							Scale:(NSInteger)scale
						ImageView:(UIImageView*)imgView
							Hints:(ZXEncodeHints*)hints
						  ecLevel:(ZXErrorCorrectionLevel *)ecLevel
							error:(NSError **)error
{
	if ( strQRCode == nil || [strQRCode length] == 0 )
		return nil;
	
	if ( imgSize.width <= 0 || imgSize.height <= 0 )
		return nil;

	int quietZone = QUIET_ZONE_SIZE;
	NSStringEncoding encoding = hints.encoding; // Mac用ShiftJIS

	ZXMode* mode = [ZXMode byteMode];
	/*
	 Header
	 */
	ZXBitArray *headerBits = [[ZXBitArray alloc] init];

	// ECI
    ZXCharacterSetECI *eci = [ZXCharacterSetECI characterSetECIByEncoding:encoding];
    if (eci != nil) [self appendECI:eci bits:headerBits];

	// mode
	[headerBits appendBits:[mode bits] numBits:4];
	
	/*
	 Data
	 */
	ZXBitArray *dataBits = [[ZXBitArray alloc] init];
	[self append8BitBytes:strQRCode bits:dataBits encoding:encoding];

	int provisionalBitsNeeded = headerBits.size
    + [mode characterCountBits:[ZXQRCodeVersion versionForNumber:1]]
    + dataBits.size;
	ZXQRCodeVersion *provisionalVersion = [self chooseVersion:provisionalBitsNeeded ecLevel:ecLevel error:error];
	if (!provisionalVersion) {
        [headerBits release];
        [dataBits release];
        return nil;
    }
	
	int bitsNeeded = headerBits.size
    + [mode characterCountBits:provisionalVersion]
    + dataBits.size;
	ZXQRCodeVersion *version = [self chooseVersion:bitsNeeded ecLevel:ecLevel error:error];
	if (!version) {
        [headerBits release];
        [dataBits release];
        return nil;
    }
	
	ZXBitArray *headerAndDataBits = [[ZXBitArray alloc] init];
	[headerAndDataBits appendBitArray:headerBits];
	// Find "length" of main segment and write it
	int numLetters = [dataBits sizeInBytes];
	if (![ZXEncoder appendLengthInfo:numLetters version:version mode:mode bits:headerAndDataBits error:error]) {
        [headerBits release];
        [dataBits release];
        [headerAndDataBits release];
		return nil;
	}
	// Put data together into the overall payload
	[headerAndDataBits appendBitArray:dataBits];

	ZXQRCodeECBlocks *ecBlocks = [version ecBlocksForLevel:ecLevel];
	int numDataBytes = version.totalCodewords - ecBlocks.totalECCodewords;
	
	// Terminate the bits properly.
	if (![ZXEncoder terminateBits:numDataBytes bits:headerAndDataBits error:error]) {
        [headerBits release];
        [dataBits release];
        [headerAndDataBits release];
		return nil;
	}
	
	// Interleave data bits with error correction code.
	ZXBitArray *finalBits = [ZXEncoder interleaveWithECBytes:headerAndDataBits
											   numTotalBytes:version.totalCodewords
												numDataBytes:numDataBytes
												 numRSBlocks:ecBlocks.numBlocks error:error];
	if (!finalBits) {
        [headerBits release];
        [dataBits release];
        [headerAndDataBits release];
		return nil;
	}
	
	ZXQRCode *qrCode = [[ZXQRCode alloc] init];
	qrCode.ecLevel = ecLevel;
	qrCode.mode = mode;
	qrCode.version = version;
	
	// Choose the mask pattern and set to "qrCode".
	int dimension = version.dimensionForVersion;
	ZXByteMatrix *matrix = [[ZXByteMatrix alloc] initWithWidth:dimension height:dimension];
	int maskPattern = [self chooseMaskPattern:finalBits ecLevel:[qrCode ecLevel] version:[qrCode version] matrix:matrix error:error];
	if (maskPattern == -1) {
        [headerBits release];
        [dataBits release];
        [headerAndDataBits release];
        [matrix release];
        [qrCode release];
		return nil;
	}
	[qrCode setMaskPattern:maskPattern];
	
	// Build the matrix and set it to "qrCode".
	if (![ZXMatrixUtil buildMatrix:finalBits ecLevel:ecLevel version:version maskPattern:maskPattern matrix:matrix error:error]) {
        [headerBits release];
        [dataBits release];
        [headerAndDataBits release];
        [matrix release];
        [qrCode release];
		return nil;
	}
	[qrCode setMatrix:matrix];

	ZXBitMatrix* writeMatrix = nil;
	if ( scale != -1 && imgView != nil )
	{
		// スケーリング版
		writeMatrix = [self renderToScaleResult:qrCode
                                          width:imgSize.width
                                         height:imgSize.height
                                      quietZone:quietZone
                                          scale:(int)scale
                                      imageView:imgView];
	}
	else
	{
		// Not スケーリング版
		writeMatrix = [self renderResult:qrCode width:imgSize.width height:imgSize.height quietZone:quietZone];
	}
    [headerBits release];
    [dataBits release];
    [headerAndDataBits release];
    [matrix release];
    [qrCode release];

	return writeMatrix;
}

- (void)appendECI:(ZXECI *)eci bits:(ZXBitArray *)bits
{
	[bits appendBits:[[ZXMode eciMode] bits] numBits:4];
	[bits appendBits:[eci value] numBits:8];
}

- (void)append8BitBytes:(NSString *)content bits:(ZXBitArray *)bits encoding:(NSStringEncoding)encoding
{
	NSData *data = [content dataUsingEncoding:encoding];
	int8_t *bytes = (int8_t *)[data bytes];
	
	for (int i = 0; i < [data length]; ++i) {
		[bits appendBits:bytes[i] numBits:8];
	}
}

- (BOOL)appendKanjiBytes:(NSString *)content bits:(ZXBitArray *)bits error:(NSError **)error
{
	NSData *data = [content dataUsingEncoding:NSShiftJISStringEncoding];
	int8_t *bytes = (int8_t *)[data bytes];
	for (int i = 0; i < [data length]; i += 2) {
		int byte1 = bytes[i] & 0xFF;
		int byte2 = bytes[i + 1] & 0xFF;
		int code = (byte1 << 8) | byte2;
		int subtracted = -1;
		if (code >= 0x8140 && code <= 0x9ffc) {
			subtracted = code - 0x8140;
		} else if (code >= 0xe040 && code <= 0xebbf) {
			subtracted = code - 0xc140;
		}
		if (subtracted == -1) {
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Invalid byte sequence"};
			
			if (error) *error = [[NSError alloc] initWithDomain:ZXErrorDomain code:ZXWriterError userInfo:userInfo];
			return NO;
		}
		int encoded = ((subtracted >> 8) * 0xc0) + (subtracted & 0xff);
		[bits appendBits:encoded numBits:13];
	}
	return YES;
}

- (ZXQRCodeVersion *)chooseVersion:(int)numInputBits ecLevel:(ZXErrorCorrectionLevel *)ecLevel error:(NSError **)error
{
	// In the following comments, we use numbers of Version 7-H.
	for (int versionNum = 1; versionNum <= 40; versionNum++) {
		ZXQRCodeVersion *version = [ZXQRCodeVersion versionForNumber:versionNum];
		// numBytes = 196
		int numBytes = version.totalCodewords;
		// getNumECBytes = 130
		ZXQRCodeECBlocks *ecBlocks = [version ecBlocksForLevel:ecLevel];
		int numEcBytes = ecBlocks.totalECCodewords;
		// getNumDataBytes = 196 - 130 = 66
		int numDataBytes = numBytes - numEcBytes;
		int totalInputBytes = (numInputBits + 7) / 8;
		if (numDataBytes >= totalInputBytes) {
			return version;
		}
	}
	
	NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Data too big"};
	if (error) *error = [[NSError alloc] initWithDomain:ZXErrorDomain code:ZXWriterError userInfo:userInfo];
	return nil;
}

- (int)chooseMaskPattern:(ZXBitArray *)bits ecLevel:(ZXErrorCorrectionLevel *)ecLevel version:(ZXQRCodeVersion *)version matrix:(ZXByteMatrix *)matrix error:(NSError **)error
{
	int minPenalty = INT_MAX;
	int bestMaskPattern = -1;
	
	for (int maskPattern = 0; maskPattern < NUM_MASK_PATTERNS; maskPattern++) {
		if (![ZXMatrixUtil buildMatrix:bits ecLevel:ecLevel version:version maskPattern:maskPattern matrix:matrix error:error]) {
			return -1;
		}
		int penalty = [self calculateMaskPenalty:matrix];
		if (penalty < minPenalty) {
			minPenalty = penalty;
			bestMaskPattern = maskPattern;
		}
	}
	return bestMaskPattern;
}

- (int)calculateMaskPenalty:(ZXByteMatrix *)matrix
{
	return [ZXMaskUtil applyMaskPenaltyRule1:matrix]
    + [ZXMaskUtil applyMaskPenaltyRule2:matrix]
    + [ZXMaskUtil applyMaskPenaltyRule3:matrix]
    + [ZXMaskUtil applyMaskPenaltyRule4:matrix];
}


- (ZXBitMatrix *)renderResult:(ZXQRCode *)code width:(int)width height:(int)height quietZone:(int)quietZone
{
	ZXByteMatrix *input = code.matrix;
	if (input == nil) {
		return nil;
	}
	int inputWidth = input.width;
	int inputHeight = input.height;
	int qrWidth = inputWidth + (quietZone << 1);
	int qrHeight = inputHeight + (quietZone << 1);
	int outputWidth = MAX(width, qrWidth);
	int outputHeight = MAX(height, qrHeight);
	
	int multiple = MIN(outputWidth / qrWidth, outputHeight / qrHeight);
	// Padding includes both the quiet zone and the extra white pixels to accommodate the requested
	// dimensions. For example, if input is 25x25 the QR will be 33x33 including the quiet zone.
	// If the requested size is 200x160, the multiple will be 4, for a QR of 132x132. These will
	// handle all the padding from 100x100 (the actual QR) up to 200x160.
	int leftPadding = (outputWidth - (inputWidth * multiple)) / 2;
	int topPadding = (outputHeight - (inputHeight * multiple)) / 2;
	
	ZXBitMatrix *output = [[ZXBitMatrix alloc] initWithWidth:outputWidth height:outputHeight];
	
	for (int inputY = 0, outputY = topPadding; inputY < inputHeight; inputY++, outputY += multiple) {
		for (int inputX = 0, outputX = leftPadding; inputX < inputWidth; inputX++, outputX += multiple) {
			if ([input getX:inputX y:inputY] == 1) {
				[output setRegionAtLeft:outputX top:outputY width:multiple height:multiple];
			}
		}
	}
	
	return output;
}

- (ZXBitMatrix *)renderToScaleResult:(ZXQRCode *)code width:(int)width height:(int)height quietZone:(int)quietZone scale:(int)scale imageView:(UIImageView*)imgView
{
	ZXByteMatrix *input = code.matrix;
	if (input == nil) {
		return nil;
	}
	int inputWidth = input.width;
	int inputHeight = input.height;
	int qrWidth = inputWidth + (quietZone << 1);
	int qrHeight = inputHeight + (quietZone << 1);
	int outputWidth = qrWidth * scale;
	int outputHeight = qrHeight * scale;

	// positioning image view
	CGRect rcFrame = imgView.frame;
	CGFloat posX = rcFrame.origin.x - ((outputWidth - width) / 2);
	CGFloat posY = rcFrame.origin.y - ((outputHeight - height) / 2);
	[imgView setFrame:CGRectMake(posX, posY, outputWidth, outputHeight)];
	
	int multiple = scale;
	// Padding includes both the quiet zone and the extra white pixels to accommodate the requested
	// dimensions. For example, if input is 25x25 the QR will be 33x33 including the quiet zone.
	// If the requested size is 200x160, the multiple will be 4, for a QR of 132x132. These will
	// handle all the padding from 100x100 (the actual QR) up to 200x160.
	int leftPadding = (outputWidth - (inputWidth * multiple)) / 2;
	int topPadding = (outputHeight - (inputHeight * multiple)) / 2;
	
	ZXBitMatrix *output = [[ZXBitMatrix alloc] initWithWidth:outputWidth height:outputHeight];
	
	for (int inputY = 0, outputY = topPadding; inputY < inputHeight; inputY++, outputY += multiple) {
		for (int inputX = 0, outputX = leftPadding; inputX < inputWidth; inputX++, outputX += multiple) {
			if ([input getX:inputX y:inputY] == 1) {
				[output setRegionAtLeft:outputX top:outputY width:multiple height:multiple];
			}
		}
	}
	
	return output;
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

	CGRect rcQRCode = [imageQRDefault frame];
	
	// パネルの設定
	if ( isPortrait )
	{
		// 縦画面
        self.view.frame = CGRectMake(20.0f, 220.0f, 728.0f, 768.0f);
		[naviBar setFrame:CGRectMake(0, 0, 728.0f, 44.0f)];
		[viewBasePanel setFrame:CGRectMake(0, 44.0f, 728.0f, 724.0f)];
		//image View
		[imageQRDefault setFrame:CGRectMake(244.0f, 190.0f, rcQRCode.size.width, rcQRCode.size.height)];
		// text view
        CGFloat tbHsize  = 35.0f;
        CGFloat tbHeight = 149.0 + tbHsize;
        CGFloat tbHpos   = 555.0 - tbHsize;
		[textView setFrame:CGRectMake(20.0f, tbHpos, 688.0f, tbHeight)];
        
        NSAttributedString *str1
        = [[NSAttributedString alloc] initWithString:@"\t\t\t・スマートフォンをお持ちの方は、QRコードアプリを\n\t\t\t　ダウンロードして頂く必要がございます。\n"
                                          attributes:@{
                                                       NSForegroundColorAttributeName:[UIColor redColor],
                                                       NSFontAttributeName:[UIFont systemFontOfSize:16]
                                                       }
           ];
        NSAttributedString *str2
        = [[NSAttributedString alloc] initWithString:@"\t\t\t・「＠abcarte.jp」からのドメインブロックを解除して下さい。\n"
                                          attributes:@{
                                                       NSFontAttributeName:[UIFont systemFontOfSize:16]
                                                       }];
        NSAttributedString *str3
        = [[NSAttributedString alloc] initWithString:@"\t\t\t・3日以内に返信メールが届かなかった場合は、店舗へご連絡下さい。\n\n"
                                          attributes:@{
                                                       NSFontAttributeName:[UIFont systemFontOfSize:16]
                                                       }];
        NSAttributedString *str4
        = [[NSAttributedString alloc] initWithString:@"\t\t\t【スタッフ様へ・このQRコードの有効期限は48時間です。\n\t\t\t　48時間を過ぎた場合は、再度QRコードの作成をして下さい】"
                                          attributes:@{
                                                       NSFontAttributeName:[UIFont systemFontOfSize:16]
                                                       }];
        
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:str1];
        [str appendAttributedString:str2];
        [str appendAttributedString:str3];
        [str appendAttributedString:str4];
        
        textView.attributedText = str;
    }
	else
	{
		// 横画面
        self.view.frame = CGRectMake(20.0f, 220.0f, 984.0f, 512.0f);
		[naviBar setFrame:CGRectMake(0, 0, 984.0f, 44.0f)];
		[viewBasePanel setFrame:CGRectMake(0, 44.0, 984.0f, 468.0f)];
		//image View
		CGFloat posX = (984.0f - rcQRCode.size.width) / 2;
		CGFloat posText = 468.0f - 20.0f - 159.0f;
		CGFloat poxImg = (posText - rcQRCode.size.height) / 2;
		[imageQRDefault setFrame:CGRectMake(posX, poxImg, rcQRCode.size.width, rcQRCode.size.height)];
		// text view
		[textView setFrame:CGRectMake(20.0f, posText, 944.0f, 159.0f)];

        
        NSAttributedString *str1
        = [[NSAttributedString alloc] initWithString:@"\t\t・スマートフォンをお持ちの方は、QRコードアプリをダウンロードして頂く必要がございます。\n"
                                          attributes:@{
                                                       NSForegroundColorAttributeName:[UIColor redColor],
                                                       NSFontAttributeName:[UIFont systemFontOfSize:16]
                                                       }
           ];
        NSAttributedString *str2
        = [[NSAttributedString alloc] initWithString:@"\t\t・「＠abcarte.jp」からのドメインブロックを解除して下さい。\n"
                                          attributes:@{
                                                       NSFontAttributeName:[UIFont systemFontOfSize:16]
                                                       }];
        NSAttributedString *str3
        = [[NSAttributedString alloc] initWithString:@"\t\t・3日以内に返信メールが届かなかった場合は、店舗へご連絡下さい。\n\n"
                                          attributes:@{
                                                       NSFontAttributeName:[UIFont systemFontOfSize:16]
                                                       }];
        NSAttributedString *str4
        = [[NSAttributedString alloc] initWithString:@"\t【スタッフ様へ・このQRコードの有効期限は48時間です。48時間を過ぎた場合は、再度QRコードの作成をして下さい】"
                                          attributes:@{
                                                       NSFontAttributeName:[UIFont systemFontOfSize:16]
                                                       }];
        
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:str1];
        [str appendAttributedString:str2];
        [str appendAttributedString:str3];
        [str appendAttributedString:str4];
        
        textView.attributedText = str;
    }
}


#pragma mark ClassMethod
/**
 初期化
 */
- (id) initWithUserId:(NSInteger)userId Delegate:(id)delegate
{
	self = [self initWithNibName:@"QRCodeViewController" bundle:nil];
	if ( self )
	{
		_userId = -1;
		_delegate = delegate;
	}
	return self;
}

/**
 QRコード作成
 */
- (BOOL) createQRCodeWithUserId:(NSInteger)userId Delegate:(id)delegate
{
	if ( userId < 0 )
		return NO;

	// データ設定
	_userId = userId;
	_delegate = delegate;

	// アカウントID
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	_accID = [defaults stringForKey:@"accountIDSave"];
	
	// ユーザーデータを暗号化
	NSString* userData = [self createUserData];
	
	// チェックサム
	NSInteger checkSum = [Common getCheckSumWithText:userData];
	NSString* strCheckSum = [NSString stringWithFormat:@"%ld", (long)checkSum];

	// デフォルト設定
	ZXEncodeHints* defaultHints = [[ZXEncodeHints alloc] init];
	[defaultHints setEncoding:-2147483647];
	[defaultHints setErrorCorrectionLevel:[ZXErrorCorrectionLevel errorCorrectionLevelL]];
	imageQRDefault.image = [self createQRCodeWithCarrier:QR_CARRIER_DEFAULT
												MailAddr:MAIL_ADDRESS
												UserData:userData
												CheckSum:strCheckSum
											   ImageSize:imageQRDefault.frame.size
											   ImageView:imageQRDefault
												   hints:defaultHints];
	
	// スマートフォン用を作成
	ZXEncodeHints* smartphoneHints = [[ZXEncodeHints alloc] init];
	[smartphoneHints setEncoding:-2147483647];
	[smartphoneHints setErrorCorrectionLevel:[ZXErrorCorrectionLevel errorCorrectionLevelL]];
	imageQRCodeSmartPhone.image = [self createQRCodeWithCarrier:QR_CARRIER_SMARTPHONE
													   MailAddr:MAIL_ADDRESS
													   UserData:userData
													   CheckSum:strCheckSum
													  ImageSize:imageQRCodeSmartPhone.frame.size
													  ImageView:imageQRCodeSmartPhone
														  hints:smartphoneHints];
	
	// docomo用を作成
	ZXEncodeHints* docomoHints = [[ZXEncodeHints alloc] init];
	[docomoHints setEncoding:-2147483647];
	[docomoHints setErrorCorrectionLevel:[ZXErrorCorrectionLevel errorCorrectionLevelL]];
	imageQRCodeDocomo.image = [self createQRCodeWithCarrier:QR_CARRIER_DOCOMO
												   MailAddr:MAIL_ADDRESS
												   UserData:userData
												   CheckSum:strCheckSum
												  ImageSize:imageQRCodeDocomo.frame.size
												  ImageView:imageQRCodeDocomo
													  hints:docomoHints];

	// au, softbank用を作成
	ZXEncodeHints* auSoftbankHints = [[ZXEncodeHints alloc] init];
	[auSoftbankHints setEncoding:-2147483647];
	[auSoftbankHints setErrorCorrectionLevel:[ZXErrorCorrectionLevel errorCorrectionLevelL]];
	imageQRCodeAuSoftbank.image = [self createQRCodeWithCarrier:QR_CARRIER_AU
													   MailAddr:MAIL_ADDRESS
													   UserData:userData
													   CheckSum:strCheckSum
													  ImageSize:imageQRCodeAuSoftbank.frame.size
													  ImageView:imageQRCodeAuSoftbank
														  hints:auSoftbankHints];
	
	// デフォルトの非表示の設定
	imageQRCodeSmartPhone.hidden = YES;
	imageQRCodeDocomo.hidden = YES;
	imageQRCodeAuSoftbank.hidden = YES;

	// セグメントの選択 - デフォルトはスマートフォンで
	[segmentCarrier setSelectedSegmentIndex:0];

	// フレームサイズの変更
	BOOL isPortrait = [MainViewController isNowDeviceOrientationPortrate];
	[self rotateSubView:isPortrait];
    
    [defaultHints release];
    [smartphoneHints release];
    [docomoHints release];
    [auSoftbankHints release];
	
	return YES;
}


#pragma mark EventHandler
/**
 QRコードを非表示にする
 */
- (IBAction) OnQRCodeReturn:(id)sender
{
	self.view.hidden = YES;
	if ( _delegate != nil )
	{
		// 終了通知
		[_delegate OnQRCodeFinished:self UserId:_userId];
	}
}

/**
 キャリアを選択する
 */
- (IBAction) OnSelectCarrier:(id)sender
{
	// 表示の設定
	NSInteger selIndex = [segmentCarrier selectedSegmentIndex];
	if ( selIndex == 0 )
	{
		// スマートフォンを表示
		imageQRCodeSmartPhone.hidden = NO;
		imageQRCodeDocomo.hidden = YES;
		imageQRCodeAuSoftbank.hidden = YES;
	}
	else
	if ( selIndex == 1 )
	{
		// docomoを表示
		imageQRCodeSmartPhone.hidden = YES;
		imageQRCodeDocomo.hidden = NO;
		imageQRCodeAuSoftbank.hidden = YES;
	}
	else
	{
		// au, softbankを表示
		imageQRCodeSmartPhone.hidden = YES;
		imageQRCodeDocomo.hidden = YES;
		imageQRCodeAuSoftbank.hidden = NO;
	}
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
