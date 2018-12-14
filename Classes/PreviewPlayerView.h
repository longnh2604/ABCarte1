//
//  PreviewPlayerView.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/12/10.
//
//

#import "PlayerView.h"
#import "VideoRunButton.h"

@interface PreviewPlayerView : PlayerView {
}
@property(nonatomic, retain) VideoRunButton *runView;
- (void)setRunButton;
@end
