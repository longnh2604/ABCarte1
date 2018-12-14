//
//  mstUserMailItemBean.h
//  iPadCamera
//
//  Created by GIGASJAPAN on 13/06/14.
//
//

#import <Foundation/Foundation.h>

@interface mstUserMailItemBean : NSObject
{
    NSInteger smtp_id;
    NSString *sender_addr;
    NSString *smtp_server;
    NSString *smtp_user;
    NSString *smtp_pass;
    NSInteger smtp_port;
    NSInteger smtp_auth;
}
@property (nonatomic, assign)NSInteger smtp_id;
@property (nonatomic, assign)NSString *sender_addr;
@property (nonatomic, assign)NSString *smtp_server;
@property (nonatomic, assign)NSString *smtp_user;
@property (nonatomic, assign)NSString *smtp_pass;
@property (nonatomic, assign)NSInteger smtp_port;
@property (nonatomic, assign)NSInteger smtp_auth;
@end
