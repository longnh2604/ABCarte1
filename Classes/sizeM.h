//
//  sizeM.h
//  iPadCamera
//
//  Created by TMS on 16/02/29.
//
//

#import <Foundation/Foundation.h>

@interface sizeM : NSObject{
    NSInteger product_id;       //商品id
    NSInteger size_id;          //サイズid
    NSString *size_name;        //サイズ名
    NSInteger price;            //単価
}

@property (nonatomic)           NSInteger product_id;
@property (nonatomic)           NSInteger size_id;
@property(nonatomic, retain)    NSString *size_name;
@property (nonatomic)           NSInteger price;

@end
