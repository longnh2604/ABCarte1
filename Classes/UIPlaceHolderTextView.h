//
//  UIPlaceHolderTextView.h
//  iPadCamera
//
//  Created by 捧 隆二 on 2013/10/10.
//
//

#import <UIKit/UIKit.h>

@interface UIPlaceHolderTextView : UITextView

@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end