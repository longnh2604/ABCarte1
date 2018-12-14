//
//  LockWindowPoupup.h
//  iPadCamera
//
//  Created by  on 11/12/03.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

///
/// 画面をLockするViewController
///
@interface LockWindowPoupup : UIViewController {
    
    IBOutlet UIView         *vwConteiner;
    IBOutlet UILabel        *lblMessage;            // メッセージ
    IBOutlet UILabel        *lblWaitingMessage;     // しばらくお待ちください
    IBOutlet UIActivityIndicatorView    *activityInd;
    IBOutlet UIProgressView *progView;              // 進捗プログレスビュー
    
    BOOL                    isLockMode;             // Lockモードで表示するか？
    NSString                *message;               // 表示するメッセージ
}

// 初期化
- (id) initWithLockMode:(BOOL)isLock message:(NSString*)msg;

// プログレスビューの値挿入
+ (void) setProgressValueOnLockView:(CGFloat)value;
// プログレスビューの値とメッセージの設定
+ (void) setProgressValueOnLockView:(CGFloat)value newMessage:(NSString*)message;

@end
