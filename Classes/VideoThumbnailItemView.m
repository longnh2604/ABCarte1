//
//  VideoThumbnailItemView.m
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/11/18.
//
//

#import "VideoThumbnailItemView.h"
#import "MovieResource.h"
#import "OKDImageFileManager.h"

#import <AVFoundation/AVFoundation.h>
#import "PreviewPlayerView.h"

// TEMp
#import "defines.h"

@implementation VideoThumbnailItemView
@synthesize videoIcon, lbl;
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		
        // TODO:video_support: issue 67 
        // [btnSelected addTarget:self action:@selector(onDoubleTap) forControlEvents:UIControlEventTouchDownRepeat];
        
    }
    return self;
}
-(void) writeToThumbnail:(OKDImageFileManager*) imgFileMng
{
	if (! imgFileMng)
	{	return; }
    // [self retain]; // 画像dl中に解放されてしまわないため
    MovieResource *movieResource = [[MovieResource alloc] initWithPath:_fileName];
    //0206 [movieResource retain];
    movieResource.movieFileEffort = MovieFileLocal; //ここではDLしない。
    movieResource.movieThumnailEffort = MovieThumnailLocal;
    // ImageViewに縮小版のImageを設定
    UIImage *image = movieResource.thumbnail;
    if (image == nil) {
        [self retain];
        //[imgView retain];
        OKDImageFileManager *_imgFileMng
            = [[OKDImageFileManager alloc] initWithUserID:movieResource.userId];
        image = [_imgFileMng getThumbnailSizeImage:[movieResource.thumbnailPath lastPathComponent]];
        [_imgFileMng release];
    }
    [imgView setImage:image];
    if (movieResource.hasOverlayImage) {
        if (!self.overlayIV) {
            OKDImageFileManager *_imgFileMng
            = [[OKDImageFileManager alloc] initWithUserID:movieResource.userId];
            UIImage *overlayImage = [_imgFileMng getImage:[movieResource.overlayPath lastPathComponent]];
            [_imgFileMng release];
            self.overlayIV = [[UIImageView alloc] initWithImage:overlayImage];
        }
        self.overlayIV.contentMode = UIViewContentModeScaleAspectFit; // オーバーレイ画像は縦長であることもあるので
        self.overlayIV.frame = CGRectMake(0, 0, imgView.frame.size.width, imgView.frame.size.height);
        [imgView addSubview:self.overlayIV];
    }
    if (!self.videoIcon) {
        self.videoIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"video.png"]];
    }
    self.videoIcon.contentMode = UIViewContentModeScaleAspectFill;
    CGRect rect = imgView.frame;
    self.videoIcon.frame = CGRectMake(rect.origin.x + 20, rect.origin.y + 30, rect.size.width - 40, rect.size.height - 30);
    [self addSubview:self.videoIcon];
    if (!self.cloudIcon) {
        self.cloudIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cloud.png"]];
    }
    self.cloudIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.cloudIcon.frame = CGRectMake(rect.origin.x + 40, rect.origin.y + 30, rect.size.width - 80, rect.size.height - 30);
    [self addSubview:self.cloudIcon];
    //NSLog(@"%s before calicurate duration",__func__);
    // 計測結果：0.005s~0.009s とりあえずこれで。=> DBに保存することも
    CGFloat duration = movieResource.movieDuration;
//    AVAsset *asset = movieResource.videoAsset;
//    if (asset) {
//        duration = CMTimeGetSeconds(asset.duration);
//        [asset release];
//    }
    //NSLog(@"%s after calicurate duration",__func__);
    if (!self.lbl) {
        self.lbl = [[UILabel alloc] initWithFrame:self.videoIcon.frame];
    }
    self.lbl.backgroundColor = [UIColor clearColor];
    self.lbl.textAlignment = NSTextAlignmentCenter;
    self.lbl.textColor = [UIColor whiteColor];
    if ( duration <= 0) {
        self.lbl.text = @"";
        self.cloudIcon.hidden = NO;
        if((!movieResource.movieIsExists) && (!movieResource.movieIsExistsInCash) && (!movieResource.movieIsExistsInCloud)) {
            self.cloudIcon.image = [UIImage imageNamed:@"cloudNotExists.png"];
        }
    } else {
        NSInteger durationInt = roundf(duration);
        self.lbl.text = [NSString stringWithFormat:@"%02ld:%02ld",
                         (long)(durationInt / 60), (long)(durationInt % 60)];
        self.cloudIcon.hidden = YES;
    }
    [self addSubview:lbl];
    
    [movieResource release];

}
-(NSString *)getFileName {
    // return [_fileName lastPathComponent];
    return ( [[NSString alloc] initWithString: [_fileName lastPathComponent]]);     // baseクラスに合わせてallocする
}
- (void)onDoubleTap {
    MovieResource *movieResource = [[MovieResource alloc] initWithPath:_fileName];
    /* *
    PreviewPlayerView *player = [[PreviewPlayerView alloc] init];
    player.frame = CGRectMake(100, 100, 500, 500);
    [player setVideoUrl:movieResource.movieURL];
    [self.superview.superview.superview.superview addSubview:player];
    [player setRunButton];
    [player setNeedsDisplay];
    */
    [(id<VideoThumbnailItemViewDelegate>)self.delegate doubleTapVideoThumbnail:movieResource.movieURL];
}
- (void)dealloc {
    [self.videoIcon release];
    [self.cloudIcon release];
    [self.lbl release];
    
    [super dealloc];
}

@end
