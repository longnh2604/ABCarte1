//
//  Badge.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/10.
//
//

#import <UIKit/UIKit.h>

@interface Badge : UIView{
    UIColor *color;
    NSInteger number;
}
@property(nonatomic, retain) UIColor *color;
@property(nonatomic, assign) NSInteger number;
@property(nonatomic, assign) NSString *status;
@end
