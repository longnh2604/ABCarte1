//
//  DoublePicturePaintPalletView.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2014/01/06.
//
//

#import "PicturePaintPalletView.h"

@interface DoublePicturePaintPalletView : PicturePaintPalletView {
    id <PicturePaintPalletDelegate> lastModifiedPaintManager;
}

// パレットイベントのリスナー２つ目
@property(nonatomic,assign)    id <PicturePaintPalletDelegate> delegate2;
- (id)initWithEventListner:(id<PicturePaintPalletDelegate>)listner otherListner:(id<PicturePaintPalletDelegate>)otherListner;
- (void)setLastModifiedPaintManager:(id<PicturePaintPalletDelegate>)_lastModifiedPaintManager;
@end
