//
//  UIAleartViewCallback.m
//  CaLuLu_forAderans
//
//  Created by 強 片山 on 12/10/31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "UIAleartViewCallback.h"

@implementation UIAleartViewCallback

@synthesize callback;

- (id)initWithCallback:(UIAlertViewCallback_t)aCallback {
    if(self = [super init]) {
        // コールバックブロックをセット
        self.callback = aCallback;
        
        // 自分自身を保持！
        [self retain];
    }
    return self;
}

// UIAlertView の delegate メソッド
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // コールバックを呼ぶ
    if(callback)
        callback(buttonIndex); 
    
    // コールバックを呼び終えたら自分自身を解放する！
    [self release];
}

- (void)dealloc {
    self.callback = nil;
    [super dealloc];
}

@end

@implementation UIAlertView(BlocksExtension)

- (id)initWithTitle:(NSString *)title message:(NSString *)message callback:(UIAlertViewCallback_t)callback  cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
    
    self = [self initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    if(self) {
        // otherButtonTitles, ... を手動でセット
        va_list args;
        va_start(args, otherButtonTitles);
        for (NSString *arg = otherButtonTitles; arg != nil; arg = va_arg(args, NSString*)) {
            [self addButtonWithTitle:arg];
        }
        va_end(args);
        
        // delegateにUIAlertViewCallbackをセット
        self.delegate = [[[UIAleartViewCallback alloc] initWithCallback:callback] autorelease];
    }
    return self;
}

@end
