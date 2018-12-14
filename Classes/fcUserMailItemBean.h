//
//  fcUserMailItemBean.h
//  iPadCamera
//
//  Created by GIGASJAPAN on 13/06/14.
//
//

#import <Foundation/Foundation.h>

@interface fcUserMailItemBean : NSObject
{
    NSInteger smtp_id;
    NSInteger title_id;
    NSString *fix_text1;
    NSString *fix_text2;
    NSString *fix_text3;
    NSString *free_text;
}
@property (nonatomic, assign)NSInteger smtp_id;
@property (nonatomic, assign)NSInteger title_id;
@property (nonatomic, assign)NSString *fix_text1;
@property (nonatomic, assign)NSString *fix_text2;
@property (nonatomic, assign)NSString *fix_text3;
@property (nonatomic, assign)NSString *free_text;
@end
