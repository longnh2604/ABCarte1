//
//  colorM.h
//  iPadCamera
//
//  Created by TMS on 16/02/29.
//
//

#import <Foundation/Foundation.h>

@interface colorM : NSObject{
    NSInteger product_id;       //商品id
    NSInteger color_id;         //カラーid
    NSString *color_name;     //カラー名
}

@property (nonatomic)           NSInteger product_id;
@property (nonatomic)           NSInteger color_id;
@property(nonatomic, retain)    NSString *color_name;

@end
