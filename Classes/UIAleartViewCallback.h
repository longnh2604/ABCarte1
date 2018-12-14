//
//  UIAleartViewCallback.h
//  CaLuLu_forAderans
//
//  Created by 強 片山 on 12/10/31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

// #import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIAlertView(BlocksExtension)

typedef void (^UIAlertViewCallback_t)(NSInteger buttonIndex);

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
           callback:(UIAlertViewCallback_t)callback
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString *)otherButtonTitles, ...;

@end

@interface UIAleartViewCallback : NSObject <UIAlertViewDelegate> {
    UIAlertViewCallback_t callback;
}

@property (nonatomic, copy) UIAlertViewCallback_t callback;

- (id)initWithCallback:(UIAlertViewCallback_t) callback;

@end