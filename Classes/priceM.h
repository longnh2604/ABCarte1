//
//  priceM.h
//  iPadCamera
//
//  Created by TMS on 16/02/29.
//
//

#import <Foundation/Foundation.h>

@interface priceM : NSObject{
    NSInteger product_id;       //商品id
    NSInteger size_id;         //サイズid
    NSInteger price;         //単価
}

@property (nonatomic)		NSInteger product_id;
@property (nonatomic)       NSInteger size_id;
@property (nonatomic)       NSInteger price;

@end
