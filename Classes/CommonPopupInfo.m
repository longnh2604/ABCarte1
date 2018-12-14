//
//  CommonPopupInfo.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/06.
//
//

/*
 ** IMPORT
 */
#import "CommonPopupInfo.h"

@implementation CommonPopupInfo

/*
 ** PROPERTY
 */
@synthesize CommonId;
@synthesize strTitle;
@synthesize updateTime;
@synthesize selected;

#pragma mark iOS_Framework
/**
 初期化
 */
- (id) init
{
	self = [super init];
	if ( self )
	{
		self.CommonId = nil;
		self.strTitle = nil;
		self.updateTime = 0;
		self.selected = NO;
	}
	return self;
}

/**
 解放
 */
- (void) dealloc
{
	[super dealloc];
}

@end
