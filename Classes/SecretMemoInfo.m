//
//  TemplateInfo.m
//  iPadCamera
//
//  Created by sadamitsu kikuta on 2014/03/05.
//
//

/*
 ** IMPORT
 */
#import "SecretMemoInfo.h"

@implementation SecretMemoInfo

/*
 ** PROPERTY
 */
@synthesize userId = _userId;
@synthesize secretMemoId = _secretMemoId;
@synthesize memo = _memo;
@synthesize sakuseibi = _sakuseibi;

#pragma mark iOS_Frmaework

/**
 dealloc
 */
- (void) dealloc
{
	[super dealloc];
}

@end
