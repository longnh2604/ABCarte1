//
//  UIKanaSupportTextField.h
//  AutoKanaInputter
//
//  Created by MacBook on 11/05/08.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIKanaSupportTextField : UITextField
{
  @private
	UITextField		*_kanaTextField;		// 対象となるかなのtextField
	
	NSInteger		_fixedLength;			// 確定文字数
	NSString		*_fixedKana;			// 確定カナ
	NSString		*_currentKana;			// 現カナ
	BOOL            _editBegin;             // 一文字目を入力

}

@property(nonatomic, retain) UITextField		*kanaTextField;

// 初期化
- (void) initWithKanaTextField:(UITextField*)kanaTextField;

@end
