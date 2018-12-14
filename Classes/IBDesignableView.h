//
//  IBDesignableView.h
//  iPadCamera
//
//  Created by 福嶋伸之 on 2016/06/13.
//
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface IBDesignableView : UIView
@property (nonatomic, retain) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable CGFloat cornerRadius;
@end


IB_DESIGNABLE
@interface IBDesignableButton : UIButton
@property (nonatomic, retain) IBInspectable UIColor *borderColor;
@property (nonatomic) IBInspectable CGFloat borderWidth;
@property (nonatomic) IBInspectable CGFloat cornerRadius;
@end
