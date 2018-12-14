//
//  StampSelectView.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/07/06.
//
//

#import <UIKit/UIKit.h>
#import "OriginalStamp.h"
#import "Stamp.h"

@protocol StampSelectViewDelegate <NSObject>
- (void)setSelectedStamp:(Stamp *)stamp;
@end

@interface StampSelectView : UIScrollView{
    NSMutableArray *stamps;//スタンプ
    OriginailStamp *stampAtBegan; //タッチ開始時のスタンプの通番
}
@property(nonatomic, assign) id<StampSelectViewDelegate> stampDelegate;
- (void) setPositionWithRotate:(CGPoint)origin isPortrate:(BOOL)isPortrate;
- (void)removeAndSetStamps;
//全てのスタンプを未選択状態に
- (void)setStampsUnselected;
@end
