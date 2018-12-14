//
//  LockWindowPoupup.m
//  iPadCamera
//
//  Created by  on 11/12/03.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LockWindowPoupup.h"

#import "Common.h"

///
/// 画面をLockするViewController
///
@implementation LockWindowPoupup

#pragma mark -
#pragma mark private_methods

#pragma mark -
#pragma mark life_cycle

// static CGFloat _____progViewValue;


// 初期化
- (id) initWithLockMode:(BOOL)isLock message:(NSString*)msg
{
# ifdef CALULU_IPHONE
    self = [super initWithNibName:@"ip_LockWindowPopup" bundle:nil];
#else
    self = [super initWithNibName:@"LockWindowPopup" bundle:nil];
#endif
    
    if (self)
    {
        // メンバへの保存
        isLockMode = isLock;
        message = [msg copy];
    }
    return (self);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // メッセージの設定
    lblMessage.text = message;
    [message release];
    message = nil;
    progView.hidden = YES;
    progView.progress = 0.0f;

    // lockモードの場合は、メッセージのみ
    if (isLockMode)
    {
        lblWaitingMessage.hidden = YES;
        activityInd.hidden = YES;
    }
    else
    {
        [activityInd startAnimating];
    }
    // _____progViewValue = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(valueSender:)
                                                 name:@"LockWindowProgressValueChange" object:nil];
    // Viewの角を丸める
    [Common cornerRadius4Control:self.view];
    [Common cornerRadius4Control:vwConteiner];
}


// プログレスビューの値挿入
+ (void) setProgressValueOnLockView:(CGFloat)value{
    //_____progViewValue = value;
    // NSLog(@"get value : %1.2f",_____progViewValue);
    
    NSDictionary *vals = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithFloat:value], @"progValue", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LockWindowProgressValueChange" 
                                                        object:vals];
}

// プログレスビューの値とメッセージの設定
+ (void) setProgressValueOnLockView:(CGFloat)value newMessage:(NSString*)message
{
    NSDictionary *vals = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithFloat:value], @"progValue",
                    message, @"message", nil];
    
    //クラスメソッドからインスタンスメソッドへ通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LockWindowProgressValueChange" 
                                                        object:vals];
}

- (void)valueSender:(NSNotification*)center{
    
    if (! [center object])
    {   return; }
    
    __block CGFloat progValue = CGFLOAT_MIN;
    __block NSString *msg = nil;
    
    if ([[center object] isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *vals = (NSDictionary*)[center object];
        for (NSString *key in [vals allKeys])
        {
            if ([key isEqualToString:@"progValue"])
            {
                NSNumber* num = (NSNumber*)[vals objectForKey:key];
                progValue = [num floatValue];
            }
            else if ([key isEqualToString:@"message"])
            {
                msg = [vals objectForKey:key];
            }
        }
    }
    else if ([[center object] isKindOfClass:[NSNumber class]])
    {
        NSNumber* num = (NSNumber*)[center object];
        progValue = [num floatValue];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //メインスレッドで処理
        if (progValue != CGFLOAT_MIN)
        { [self setProgress:progValue];}
        if (msg)
        {  lblMessage.text = msg; }
    });
    
    // _____progViewValue = [num floatValue];
    // [self performSelectorOnMainThread:@selector(setProgress:) withObject:nil waitUntilDone:YES]; 
}

-(void)setProgress:(CGFloat)val{
    activityInd.hidden = YES;
    progView.hidden = NO;
    
    [progView setProgress:val];
    // NSLog(@"progressBar value : %1.2f",progView.progress);
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"LockWindowProgressValueChange"
                                                  object:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

@end
