//
//  iPhoneViewResizeer.m
//  iPadCamera
//
//  Created by MacBook on 11/10/27.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iPhoneViewResizeer.h"

#import "defines.h"

///
/// iPhone用のviewリサイズクラス
///
@implementation iPhoneViewResizeer

// MainViewのリサイズ
+ (void) mainViewResize : (UIView*)view
{
	[view setFrame:CGRectMake(0.0f, 0.0f, VIEW_SIZE_WIDTH, VIEW_SIZE_HEIGHT)];
}

@end
