//
//  mstUserMailItemBean.m
//  iPadCamera
//
//  Created by GIGASJAPAN on 13/06/14.
//
//

#import "mstUserMailItemBean.h"

@implementation mstUserMailItemBean
- (id)init
{
	self = [super init];
	
	return self;
}
@synthesize smtp_id;
@synthesize sender_addr;
@synthesize smtp_server;
@synthesize smtp_user;
@synthesize smtp_pass;
@synthesize smtp_port;
@synthesize smtp_auth;
@end
