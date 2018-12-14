//
//  GrayOutImageView.m
//  iPadCamera
//
//  Created by 管理者 on 11/06/26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GrayOutImageView.h"


@implementation GrayOutImageView

// タッチのイベント
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	self.alpha = (self.alpha < 1.0f) ? 1.0f : 0.65f; 
}


@end
