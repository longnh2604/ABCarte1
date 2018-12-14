//
//  VideoSaveViewController.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/11/25.
//
//

#import "VideoSaveViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "userDbManagerVideo.h"
#import "VideoSyncManager.h"
#import "UIAlertView+Blocks.h"
#import "MicUtil.h"

#import "userDbManager.h"
#import "Common.h"

#import "defines.h"

const NSInteger MAX_TOTAL_FRAMES = 50;
@interface VideoSaveViewController ()

@end

@implementation VideoSaveViewController
@synthesize overlayImage;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        isAllDisplay = NO;
        startIndex = -1;
        representativeIndex = -1;
        duration = 0.0f;
        frameDuration = 0.0f;
        thumbWidth = 0;
        thumbHeight = 0;
        thumbCols = 0;
        overlayImage = nil;
        NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
        maxDuration = [df floatForKey:@"video_max_duration"];
        maxRecTime  = [df floatForKey:@"video_max_rectime"];
        // 未設定の場合、0.00になる
        if (maxDuration <= 0) {
            maxDuration = 10.0f;
            [df setFloat:maxDuration forKey:@"video_max_duration"]; // 初期値は10秒
            [df synchronize];
        }
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRotate:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    mainView.layer.cornerRadius = 12.0f;
    mainView.layer.shadowOffset = CGSizeMake(4.0f, 4.0f);
    mainView.layer.shadowColor = [UIColor colorWithWhite:0.0f alpha:1.0f].CGColor;
    
    lblMaxDuration.text = [NSString stringWithFormat:@"%.2f[秒]",maxRecTime];
    indicator.hidden = NO;
    [indicator startAnimating];
    // [UIApplication sharedApplication].statusBarOrientation にすると確実に縦横が判定できる。
    [self willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    btnClear.enabled = NO;
    btnCut.enabled = NO;
    btnDontSave.enabled = NO;
    btnSave.enabled = NO;
    
}
- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window == nil) {
        window = [[UIApplication sharedApplication].windows objectAtIndex:0];
    }
    [window.rootViewController.view addSubview:self.view];
}
- (void)setVideoUrl:(NSURL *)_url movie:(MovieResource *)_movie histId:(HISTID_INT)_histId
{
    histId = _histId;
    movie = _movie;
    url = _url;
    [movie retain];
    //video
    asset = [[[AVURLAsset alloc] initWithURL:url
                                     options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil]] retain];
    if (overlayImage == nil) {
        [self showThumbnails];
    } else {
        [self mix:asset image:overlayImage];
    }
}
- (void)showThumbnails
{
    self.imageGenerator = [[[AVAssetImageGenerator alloc] initWithAsset:asset] autorelease];
    self.imageGenerator.appliesPreferredTrackTransform = YES; // if I omit this, the frames are rotated 90° (didn't try in landscape)
    
    AVVideoComposition * composition = [AVVideoComposition videoCompositionWithPropertiesOfAsset:asset];
    
    // Retrieving the video properties
    CGSize naturalSize = [VideoSaveViewController getNaturalSizeOfAsset:asset];
    if (naturalSize.width <  naturalSize.height) {
        // 縦長
        thumbCols = 5;
        thumbWidth = 96;
        thumbHeight = naturalSize.height / naturalSize.width * thumbWidth;
    } else {
        // 横長
        thumbCols = 4;
        thumbWidth = 122;
        thumbHeight = naturalSize.height / naturalSize.width * thumbWidth;
    }
    duration = CMTimeGetSeconds(asset.duration);          // 動画の全長
    frameDuration = CMTimeGetSeconds(composition.frameDuration);   // 1フレームの長さ
    
    if (duration <= maxDuration){
        // btnCut.hidden = btnClear.hidden = YES;
        btnClear.hidden = YES;
        startIndex = 10000;
        lblDescription.text = @"サムネイル画像を選択して下さい";
    }
    CGSize renderSize = CGSizeMake(thumbWidth, thumbHeight);
    CGFloat totalFrames = round(duration/frameDuration);
    if (totalFrames > MAX_TOTAL_FRAMES) {
        totalFrames = MAX_TOTAL_FRAMES;
        frameDuration = duration / totalFrames;
    }
    // Selecting each frame we want to extract : all of them.
    NSMutableArray * times = [NSMutableArray arrayWithCapacity:round(duration/frameDuration)];
    for (int i=0; i<totalFrames; i++) {
        NSValue *time = [NSValue valueWithCMTime:CMTimeMakeWithSeconds(i*frameDuration, composition.frameDuration.timescale)];
        [times addObject:time];
    }
    // scrollview contain size
    lblVideoDuration.text = [NSString stringWithFormat:@"%.1f0[秒]",duration];
    scrollView.contentSize = CGSizeMake(514,MAX(461,  5 + (times.count / thumbCols + 1) * (thumbHeight + 4)));
    buttons = [[NSMutableArray arrayWithCapacity:round(duration/frameDuration)] retain];
    // http://stackoverflow.com/questions/15092211/ios-video-frame-processing-optimization
    __block int i = 0;
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result == AVAssetImageGeneratorSucceeded) {
            NSLog(@"AVAssetImageGeneratorSucceeded %d", i);
            int x = round(CMTimeGetSeconds(requestedTime)/frameDuration);
            NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:x],@"x",
                                 [UIImage imageWithCGImage:im],@"image", nil];
            
            [self performSelectorOnMainThread:@selector(addButton:) withObject:dic waitUntilDone:NO];
        }
        else
            NSLog(@"Ouch: %@", error.description);
        i++;
        //[self performSelectorOnMainThread:@selector(setProgressValue:) withObject:[NSNumber numberWithFloat:i/totalFrames] waitUntilDone:NO];
        if(i == totalFrames) {
            NSLog(@"finish");
            isAllDisplay = YES;
            [self performSelectorOnMainThread:@selector(initRepresentative) withObject:nil waitUntilDone:NO];
            //[self performSelectorOnMainThread:@selector(performVideoDidFinish) withObject:nil waitUntilDone:NO];
        }
    };
    
    self.imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    self.imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    self.imageGenerator.maximumSize = renderSize;
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:handler];
}
- (void)addButton:(id)dic {
    NSDictionary *dictionary = (NSDictionary *)dic;
    NSInteger x = [[dictionary objectForKey:@"x"] integerValue];
    UIImage *image = (UIImage *)[dictionary objectForKey:@"image"];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    button.frame = CGRectMake(7 + (thumbWidth + 4) * (x % thumbCols),
                              5 + (thumbHeight + 4) * (x / thumbCols), thumbWidth, thumbHeight);
    button.tag = x;
    button.layer.cornerRadius = 4.0f;
    button.layer.masksToBounds = YES;
    button.layer.borderColor = [UIColor blueColor].CGColor;
    button.layer.borderWidth = 0.0f;
    button.userInteractionEnabled = NO;
    if (duration > maxRecTime) {
        [button addTarget:self action:@selector(singleTap:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(doubleTap:) forControlEvents:UIControlEventTouchDownRepeat];
    } else {
        // 規定秒数内であれば、代表画像設定のみ
        //[button addTarget:self action:@selector(setRepresentative:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(setRepresentative:) forControlEvents:UIControlEventTouchDownRepeat];
    }
    [buttons insertObject:button atIndex:x];

    //[scrollView addSubview:button];
    [scrollView insertSubview:button belowSubview:indicator];
}
- (void)setFirstFrame:(id)sender {
    if (!isAllDisplay) {
        return;
    }
    UIButton *button = (UIButton *)sender;
    startIndex = button.tag;
    NSInteger endIndex = startIndex + (int)(maxRecTime / frameDuration) + 1;
    //lblVideoDuration.text = [NSString stringWithFormat:@"%.2f[秒]",duration - startIndex * frameDuration];
    if (startIndex * frameDuration + maxRecTime > duration){
        // 残り時間が規定時間より短いため、後ろを優先して選択
        startIndex = (buttons.count - ceil(maxRecTime / frameDuration));
        if (startIndex < 0) {
            startIndex = 0;
        }
    }
    /*
    // 代表画像が範囲外ならば範囲内に変更
    if (representativeIndex < startIndex){
        [self setRepresentative:buttons[startIndex]];
    }
    if (endIndex < representativeIndex) {
        [self setRepresentative:buttons[endIndex]];
    }
    */
    // 必ず先頭コマに
    [self setRepresentative:buttons[startIndex]];
    for (int i = 0; i < buttons.count; i++) {
        if (i == representativeIndex) {
            ((UIButton *)buttons[i]).layer.borderColor = [UIColor redColor].CGColor;
        } else if ( i < startIndex || endIndex < i) {
            ((UIButton *)buttons[i]).layer.borderWidth = 0.0f;
        } else {
            ((UIButton *)buttons[i]).layer.borderWidth = 3.0f;
            ((UIButton *)buttons[i]).layer.borderColor = [UIColor blueColor].CGColor;
        }
    }
}
- (void)initRepresentative {
    [indicator stopAnimating];
    indicator.hidden = YES;
    if (buttons.count > 0) {
        [self setRepresentative:buttons[0]];
    }
    if (duration > maxDuration){
        [self OnCut];
        [self setRepresentative:buttons[startIndex]];
        btnClear.enabled = YES;
        btnCut.enabled = YES;
    }
    btnDontSave.enabled = YES;
    btnSave.enabled = YES;
    for (UIButton *button in buttons) {
        button.userInteractionEnabled = YES;
    }
}
- (void)setRepresentative:(id)sender {
    if (!isAllDisplay) {
        return;
    }
    UIButton *button = (UIButton *)sender;
    if (duration > maxDuration){
        NSInteger endIndex = startIndex + (int)(maxDuration / frameDuration) + 1;
        if (button.tag < startIndex || endIndex < button.tag) {
            // 保存範囲外ならば動作しない。
            return;
        }
    }
    if (representativeIndex >= 0) {
        UIButton *prevRepresentative = (UIButton *)buttons[representativeIndex];
        prevRepresentative.layer.borderColor = [UIColor blueColor].CGColor;
        if (representativeIndex < startIndex || startIndex < 0) {
            prevRepresentative.layer.borderWidth = 0.0f;
        }
    }
    representativeIndex = button.tag;
    button.layer.borderWidth = 3.0f;
    button.layer.borderColor = [UIColor redColor].CGColor;
}
// https://www.cocoanetics.com/2009/12/double-tapping-on-buttons/
- (void)singleTap:(id)sender {
    // NSLog(@"%s",__func__);
    if (!isAllDisplay) {
        return;
    }
	[self performSelector:@selector(setFirstFrame:) withObject:sender afterDelay:0.2f]; //ダブル・タップの可能性があるのでdelay
}
- (void)doubleTap:(id)sender {
    // NSLog(@"%s",__func__);
    if (!isAllDisplay) {
        return;
    }
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setFirstFrame:) object:sender];
	// NSLog(@"Touch Down Repeat");
	[self performSelector:@selector(doubleTapAfterDelay:) withObject:sender afterDelay:0.2f]; //2回目のSingleTapを消すため
}
- (void)doubleTapAfterDelay:(id)sender {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setFirstFrame:) object:sender]; // 2回目のSingleTapも削除
	[self setRepresentative:sender];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [mainView release];
    [lblVideoDuration release];
    [lblMaxDuration release];
    [btnCut release];
    [btnClear release];
    [btnSave release];
    [btnDontSave release];
    [scrollView release];
    [asset release];
    [url release];
    [super dealloc];
}
- (void)viewDidUnload {
    [mainView release];
    mainView = nil;
    [lblVideoDuration release];
    lblVideoDuration = nil;
    [lblMaxDuration release];
    lblMaxDuration = nil;
    [btnCut release];
    btnCut = nil;
    [btnClear release];
    btnClear = nil;
    [btnSave release];
    btnSave = nil;
    [btnDontSave release];
    btnDontSave = nil;
    [scrollView release];
    scrollView = nil;
    [super viewDidUnload];
}
// s = (buttons_count - ceil(max_duration / frame_duration)) + 1
- (IBAction)OnCut {
    if (!isAllDisplay) {
        return;
    }
    startIndex = (buttons.count - ceil(maxDuration / frameDuration));
    if (startIndex < 0) {
        startIndex = 0;
    }
    if (startIndex < buttons.count) { // 念のため
        [self setFirstFrame:buttons[startIndex]];
    }
}

- (IBAction)OnClear {
    if (!isAllDisplay) {
        return;
    }
    startIndex = -1;
    //representativeIndex = 0;
    representativeIndex = -1;
    lblVideoDuration.text = [NSString stringWithFormat:@"%.2f[秒]",duration];
    for (UIButton *button in buttons) {
        button.layer.borderWidth = 0.0f;
    }
    if (buttons.count > 0) {
        //[self setRepresentative:buttons[0]];
    }
}

- (IBAction)OnSave {
    if (!isAllDisplay) {
        return;
    }
    if ((duration > maxRecTime && startIndex < 0) || representativeIndex < 0) {
        [Common showDialogWithTitle:@"保存の失敗" message:@"保存する最初のフレームを選択してください。"];
        return;
    }
    isAllDisplay = NO; // 再びボタンが効かないようにする。
    indicator.hidden = NO;
    [indicator startAnimating];
    // サムネイル保存
    UIImage *thumbnail = ((UIButton *)buttons[representativeIndex]).currentImage;
    NSData *data = [self _resize2FixedFormWithThumbImg:thumbnail];  //  サムネイル規定サイズにリサイズ
    [data writeToFile:movie.thumbnailFullPath atomically:YES];
// 描画サイズ
//	CGRect imgRect = CGRectMake(0.0f, 0.0f, 128, 72);
//	UIGraphicsBeginImageContext(imgRect.size);
//	[thumbnail drawInRect:imgRect];
//	UIImage *drawImg = UIGraphicsGetImageFromCurrentImageContext();
//	UIGraphicsEndImageContext();
//	if (drawImg){
//        NSData *data = UIImagePNGRepresentation(thumbnail);
//        [data writeToFile:movie.thumbnailFullPath atomically:YES];
//
//    }
    if (duration <= maxRecTime){
        //トリミングせずに保存
        BOOL isSuccess = NO;
        NSError *error = nil;
        isSuccess = [self capacityCheck:url];
        if (isSuccess) {
            [[NSFileManager defaultManager] moveItemAtURL:url toURL:movie.movieURL error:&error];
            if (error != nil) {
                isSuccess = NO;
                NSLog(@"movie move error %@",error.localizedDescription);
            } else {
                // データベース(fc_video_table)に追加(履歴代表写真の更新も含む)
                isSuccess = [self _saveDataBase];
            }
        }
        [self performSelectorOnMainThread:@selector(finishVideoSave:) withObject:[NSNumber numberWithBool:isSuccess] waitUntilDone:NO];
        return;
    }
    // トリミング
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];

    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                               initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
        // Implementation continues.
        exportSession.outputURL = movie.movieURL;
        
        NSLog(@"%@",exportSession.outputURL.path);
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        CMTime start = CMTimeMakeWithSeconds( startIndex * frameDuration, 600);
        CMTime dura = CMTimeMakeWithSeconds(maxRecTime, 600);
        //CMTime dura = CMTimeMakeWithSeconds(duration - startIndex * frameDuration, 600);
        CMTimeRange range = CMTimeRangeMake(start, dura);
        exportSession.timeRange = range;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            BOOL isSuccess =[exportSession status] == AVAssetExportSessionStatusCompleted;
            if (isSuccess) {
                NSLog(@"video export session Completed");
                isSuccess = [self capacityCheck:url];
                if (isSuccess){
                    // データベース(fc_video_table)に追加(履歴代表写真の更新も含む)
                    isSuccess = [self _saveDataBase];
                } else {
                    NSLog(@"capacity error");
                }
            } else {
                 NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
            }
            [self performSelectorOnMainThread:@selector(finishVideoSave:) withObject:[NSNumber numberWithBool:isSuccess] waitUntilDone:NO];
        }];
    }

}
- (void)finishVideoSave:(id)isSuccessId {
    [indicator stopAnimating];
    indicator.hidden = YES;
    BOOL isSuccess = [isSuccessId boolValue];
    _isSuccess = isSuccess;
    
    //[self.view removeFromSuperview];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"動画の保存"
                                                        message:isSuccess ? @"動画を保存しました":@"動画の保存に失敗しました"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // 動画の保存確認のみ
    [self.view removeFromSuperview];
    
    // 空き容量チェックは別スレッドで実施する(ファイル数が増えると時間がかかるため)
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [MovieResource removeVideosUntilCapacityLimit];
    });
    if (self.saveDelegate) {
        [self.saveDelegate finishVideoSave:_isSuccess];
    }
    [alertView release];
}
- (BOOL)capacityCheck:(NSURL *)_url {
    
    return YES; // 同期時にS３側の使用容量を確認しているため、チェックなしにする

    NSData *data = [NSData dataWithContentsOfURL:url];
    NSUInteger dataLength = data.length;
    NSLog(@"data size %lu", (unsigned long)data.length);
    NSNumber *contractCapacityNum = nil;
    NSNumber *usedCapacityNum = nil;
    
    SYNC_RESPONSE_STATE state = [VideoSyncManager getContractCapacity:&contractCapacityNum usedCapacity:&usedCapacityNum];
    if (state == SYNC_RSP_OK) {
        long long contractCapacity = [contractCapacityNum longLongValue];
        long long usedCapacity = [usedCapacityNum longLongValue];
        
        // 既に保存　＋　今回保存する量　＜＝　契約保存料
        if (usedCapacity + dataLength <= contractCapacity) {
            return YES;
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"契約保存容量"
                                                            message:@"契約容量を超えています。\n動画を削除するかまたは\n動画保存容量増加を申し込んでください。"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            return NO;
        }
    } else {
        // オフラインの場合などは暫定的に保存を許容
        return YES;
    }
}
- (BOOL) _saveDataBase {
    
    userDbManagerVideo *usrDbMng = [[userDbManagerVideo alloc] init];
    BOOL isSuccess = [usrDbMng insertHistUserVideo:histId videoURL:movie.path];
    [usrDbMng release];
    
    if (isSuccess) {
        userDbManager *usrDbMng = [[userDbManager alloc] init];
        
        // 動画の拡張子をjpgに変更（updateHistHeadPictureメソッド仕様に合わせる）
        NSString *szJpg = [movie.path  stringByReplacingOccurrencesOfString:@".mp4"
                                                                 withString:REAL_SIZE_EXT];
        
        // 保存したファイル名（パスなしの実サイズ版でデータベースの履歴テーブルの代表画像の更新:既設の場合は何もしない
        [usrDbMng updateHistHeadPicture:histId pictureURL:szJpg isEnforceUpdate:NO];
        [usrDbMng release];
        
    }
    else {
        [Common showDialogWithTitle:@"動画保存" message:@"データベースの更新に\n失敗しました"];
    }
    
    return (isSuccess);
}
- (NSData*) _resize2FixedFormWithThumbImg:(UIImage*)originalImage
{
    NSData *data = nil;
    
    // グラフィックコンテキストを作成：横長で作成
    UIGraphicsBeginImageContext(CGSizeMake(THUBNAIL_WITH, THUBNAIL_HEIGHT));
    
    // 変換倍率 : 不要
    /*CGFloat widthRatio  = THUBNAIL_WITH/ originalImage.size.width;
    CGFloat heightRatio = THUBNAIL_HEIGHT / originalImage.size.height;
    CGFloat ratio = (widthRatio < heightRatio) ? widthRatio : heightRatio;*/
    
    // 元画像の縦横比を判定
    BOOL isOrient = (originalImage.size.width < originalImage.size.height);
    
    // 描画サイズ
    CGFloat cWidth  = (isOrient)? (THUBNAIL_HEIGHT / THUBNAIL_WITH) *THUBNAIL_HEIGHT : THUBNAIL_WITH;
    CGFloat cHeight = THUBNAIL_HEIGHT;
    CGFloat cLeft   = (isOrient)? (THUBNAIL_WITH - cWidth) / 2.0f : 0.0f;
    CGRect imgRect
        = CGRectMake(cLeft, 0.0f, cWidth, cHeight);
    
    // グラフィックコンテキストに描画
	[originalImage drawInRect:imgRect];
	// グラフィックコンテキストから縮小版のImageを取得
	UIImage *drawImg = UIGraphicsGetImageFromCurrentImageContext();
	// グラフィックコンテキストを解放
	UIGraphicsEndImageContext();
    
    if (! drawImg)
    {	return (nil); }
    
    // 縮小版のImageよりバイナリデータを取得 :透過のためPNGフォーマットを使用
    // NSData *fitdata = UIImageJPEGRepresentation(drawImg, 0.9f);
    data = UIImagePNGRepresentation(drawImg);
    
    return (data);
}

- (IBAction)OnDontSave {
    if (!isAllDisplay) {
        return;
    }
    [UIAlertView displayAlertWithTitle:@"動画の破棄"
                               message:@"動画を破棄します。よろしいですか？"
                       leftButtonTitle:@"はい"
                      leftButtonAction:^(void){
                          if (self.saveDelegate) {
                              [self.saveDelegate finishVideoSave:NO];
                          }
                          [self.view removeFromSuperview];
                      }
                      rightButtonTitle:@"いいえ"
                     rightButtonAction:^(void){
                         
                     }];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}
- (void) didRotate:(NSNotification *)notification {
    UIDeviceOrientation orientation = [(UIDevice *)[notification object] orientation];
    [self willRotateToInterfaceOrientation:orientation duration:0];
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect appFrame = [UIScreen mainScreen].bounds;
    CGSize size = appFrame.size;

	switch (toInterfaceOrientation) {
		case UIInterfaceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
			// 縦向け
            size.width = (appFrame.size.width<appFrame.size.height)? appFrame.size.width : appFrame.size.height;
            size.height = (appFrame.size.width<appFrame.size.height)? appFrame.size.height : appFrame.size.width;
            self.view.frame = CGRectMake(0, 0, size.width, size.height);
            mainView.center = self.view.center;
			break;
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
            size.width = (appFrame.size.width<appFrame.size.height)? appFrame.size.height : appFrame.size.width;
            size.height = (appFrame.size.width<appFrame.size.height)? appFrame.size.width : appFrame.size.height;
            self.view.frame = CGRectMake(0, 0, size.width, size.height);
            mainView.center = self.view.center;
			break;
        default:
            break;
	}
}
- (void)mix:(AVAsset *)_asset image:(UIImage *)image {
    //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    AVAssetTrack *assetTrack = [[_asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    CGSize naturalSize = [VideoSaveViewController getNaturalSizeOfAsset:_asset];
    AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
    
    AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, _asset.duration) ofTrack:assetTrack atTime:kCMTimeZero error:nil];
    AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    [MainInstruction retain];
    MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, _asset.duration);
    
    //>>>>> 音声ファイルも別で付け足す （マイクの許可が無い場合、音声なしで記録する）
    [MicUtil isMicAccessEnableWithIsShowAlert:NO completion:^(BOOL isMicAccessEnable) {
        if(isMicAccessEnable) {
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            NSInteger idx = [[asset tracksWithMediaType:AVMediaTypeAudio] count];
            if (idx > 0) {
                [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(_asset.duration, kCMTimeZero)) ofTrack:[[_asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
            }
        }
    }];
    //<<<<<
    
    AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    [FirstlayerInstruction setTransform:assetTrack.preferredTransform atTime:kCMTimeZero];
    
    MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,nil];
#ifdef DEBUG
    NSLog(@"stage 2");
#endif
    // 親レイヤー
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer setContents:(id)[image CGImage]];
#ifdef DEBUG
    NSLog(@"naturalSize: %f %f ",naturalSize.width, naturalSize.height);
    NSLog(@"overlayImage: %f %f",overlayImage.size.width, overlayImage.size.height);
#endif
    // overlayImageの空白の区間。意味は未調査。
    CGFloat clearwidth = ((overlayImage.size.width * naturalSize.height) / overlayImage.size.height - naturalSize.width) * 0.5f;
    overlayLayer.frame = CGRectMake(-1 * clearwidth, 0, naturalSize.width + 2 * clearwidth, naturalSize.height);
    //overlayLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    [overlayLayer setMasksToBounds:YES];
    
    // 2 - set up the parent layer
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    videoLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
    //[MainCompositionInst retain];
    MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
    MainCompositionInst.frameDuration = CMTimeMake(1, 30);
    MainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    MainCompositionInst.renderSize = naturalSize;
    //****** 3. AVAssetExportSessionを使用して1と2のコンポジションを合成。 *****
#ifdef DEBUG
    NSLog(@"stage 3");
#endif
    // 1のコンポジションをベースにAVAssetExportを生成
    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset: mixComposition presetName:AVAssetExportPresetHighestQuality];
    // 2の合成用コンポジションを設定
    assetExport.videoComposition = MainCompositionInst;
    //assetExport.audioMix = audioMix;
    
    // エクスポートファイルの設定
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"outputAtVideoSaveViewController.mp4"];
    NSURL *exportURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath])
    {
        NSError *error = nil;
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
        {
            NSLog(@"%@",error.localizedDescription);
        }
    }
    [outputPath release];
    assetExport.outputFileType = AVFileTypeMPEG4;
    assetExport.outputURL = exportURL;
    assetExport.shouldOptimizeForNetworkUse = YES;
#ifdef DEBUG
    NSLog(@"before export");
#endif
    //エクスポート実行
    [assetExport exportAsynchronouslyWithCompletionHandler:^(void) {
        if (assetExport.status == AVAssetExportSessionStatusCompleted) {

            url = exportURL;
            asset = [[[AVURLAsset alloc] initWithURL:url
                                              options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil]] retain];
            [self performSelectorOnMainThread:@selector(showThumbnails) withObject:nil waitUntilDone:NO];
        } else {
            NSLog(@"合成/保存失敗 Error: %@", [assetExport.error description]);
            //[self performSelectorOnMainThread:@selector(dismissProgress) withObject:nil waitUntilDone:NO];
        }
        [_asset release];
        [MainInstruction retain];
        [MainCompositionInst retain];
    }];
    [assetExport release];
}
+ (CGSize)getNaturalSizeOfAsset:(AVAsset *)asset {
    CGSize naturalSize = [[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    if (((AVAssetTrack *)[asset tracksWithMediaType:AVMediaTypeVideo][0]).preferredTransform.a == 0) {
        naturalSize = CGSizeMake(naturalSize.height, naturalSize.width);
    }
    return naturalSize;
}
@end
