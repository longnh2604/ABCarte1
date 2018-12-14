//
//  UIPopoverContllerHelper.m
//  CaLuLu_forAderans
//
//  Created by TMS on 16/02/18.
//
//

#import "UIPopoverControllerHelper.h"

#define SEREIAL_QUEUE_NAME  "jp.co.okada.UIPopoverControllerHelper.serialque"

@interface UIPopoverControllerHelper ()
{
    __strong UIPopoverController* _popoverController;
}
@end

static UIPopoverControllerHelper* __shareInstance = nil;
static dispatch_queue_t __serealQueue;

/**
 * PopoverContl
 */
@implementation UIPopoverControllerHelper

@synthesize popoverController = _popoverController;

#pragma mark private_methods

// 初期化
- (void) _initialize
{
    _popoverController = nil;
}

// popovercontrollerのインスタンス生成とViewControllerの登録
- (void)presentPopoverWithContentViewController:(UIViewController *)contentViewController
                                       fromRect:(CGRect)fromRect inView:(UIView *)inView
                       permittedArrowDirections:(UIPopoverArrowDirection)permittedArrowDirections
                                       animated:(BOOL)animated
{
    if (_popoverController) {
        [_popoverController dismissPopoverAnimated:NO];
    }
    
    _popoverController = [[UIPopoverController alloc] initWithContentViewController:contentViewController];
    _popoverController.delegate = self;
    [_popoverController presentPopoverFromRect:fromRect inView:inView
                      permittedArrowDirections:permittedArrowDirections
                                      animated:animated];
}

- (void)dismissPopoverAnimated:(BOOL)animated
{
    if (_popoverController) {
        [_popoverController dismissPopoverAnimated:animated];
        _popoverController = nil;
        
        NSLog(@"AppContext released popoverController.");
    }
}

#pragma mark-
#pragma mark  life_cycle

+ (id)allocWithZone:(NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __serealQueue = dispatch_queue_create(SEREIAL_QUEUE_NAME, NULL);
        if (__shareInstance == nil) {
            __shareInstance = [super allocWithZone:zone];
        }
    });
    return __shareInstance;
}

- (void) dealloc {
    [_popoverController release];
    _popoverController = nil;
    
    [super dealloc];
}

/**
 *  唯一のインスタンスを取得
 *  @param      なし
 *  @return     インスタンス
 *  @remarks
 */
+ (UIPopoverControllerHelper*) getInstance
{
    static dispatch_once_t  onceToken;
    dispatch_once(&onceToken, ^{
        __shareInstance = [[UIPopoverControllerHelper alloc] init];
        [__shareInstance _initialize];
    });
    
    return __shareInstance;
}

#pragma mark public_methods

/**
 *  @discription    popoverによるViewの表示
 *  @param      DispViewController      :表示するViewController
 *              inView                  :表示位置の基準となるview
 *              permittedArrowDirections:表示方向
 *  @return     なし
 *  @remarks    なし
 */
+ (void)presentPopoverWithDispViewController:(UIViewController*) vwCtrl
                                      inView:(UIView *)view
                    permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
{
    // インスタンスの取得
    UIPopoverControllerHelper *popover = [UIPopoverControllerHelper getInstance];
    
    // サイズはViewControllerで決定する
    vwCtrl.contentSizeForViewInPopover = vwCtrl.view.frame.size;
    // NSLog(@"vwctrl size = %f/%f", vwCtrl.view.frame.size.width, vwCtrl.view.frame.size.height);
    
    // popovercontrollerのインスタンス生成とViewControllerの登録
    [popover presentPopoverWithContentViewController:vwCtrl
                                             fromRect:view.bounds inView:view
                            permittedArrowDirections:arrowDirections animated:YES];
    
}

/**
 *  @discription    popoverによるViewの表示
 *  @param      DispViewController      :表示するViewController
 *              inView                  :表示位置の基準となるview
 *  @return     なし
 *  @remarks    permittedArrowDirections:表示方向はUIPopoverArrowDirectionAny
 */
+ (void)presentPopoverWithDispViewController:(UIViewController*) vwCtrl
                                      inView:(UIView *)view
{
    [UIPopoverControllerHelper presentPopoverWithDispViewController:vwCtrl inView:view
                                           permittedArrowDirections:UIPopoverArrowDirectionAny];
}

/**
 *  @discription    popoverを閉じる
 *  @param      なし
 *  @return     なし
 *  @remarks
 */
+ (void) dismissPopover
{
    // インスタンスの取得
    UIPopoverControllerHelper *popover = [UIPopoverControllerHelper getInstance];

    [popover dismissPopoverAnimated:YES];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [_popoverController release];
    _popoverController = nil;
    
    NSLog(@"AppContext released popoverController.");
}


@end
