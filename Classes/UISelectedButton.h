//
//  UISelectedButton.h
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import <UIKit/UIKit.h>

#define BORDER_RESOUCE_NAME     @"select_border.png"

/**
 * 選択時に枠をつけるUIButton
 */
@interface UISelectedButton : UIButton
{
    
}

// 枠の設定
@property(nonatomic, setter = setBorder:) BOOL border;
// - (void) setBorder:(BOOL)isSet;

@end
