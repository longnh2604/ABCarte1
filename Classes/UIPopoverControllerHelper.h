//
//  UIPopoverContllerHelper.h
//  CaLuLu_forAderans
//
//  Created by TMS on 16/02/18.
//
//

#import <UIKit/UIKit.h>

/**
 * popovercontrollerのヘルパークラス：singletonにて実装
 */
@interface UIPopoverControllerHelper : NSObject<UIPopoverControllerDelegate>
{
    
}

@property(nonatomic, strong) UIPopoverController* popoverController;

/**
 *  唯一のインスタンスを取得
 *  @param      なし
 *  @return     インスタンス
 *  @remarks
 */
+ (UIPopoverControllerHelper*) getInstance;

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
                    permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections;

/**
 *  @discription    popoverによるViewの表示
 *  @param      DispViewController      :表示するViewController
 *              inView                  :表示位置の基準となるview
 *  @return     なし
 *  @remarks    permittedArrowDirections:表示方向はUIPopoverArrowDirectionAny
 */
+ (void)presentPopoverWithDispViewController:(UIViewController*) vwCtrl
                                      inView:(UIView *)view;

/**
 *  @discription    popoverを閉じる
 *  @param      なし
 *  @return     なし
 *  @remarks    
 */
+ (void) dismissPopover;

@end
