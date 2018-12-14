//
//  brandM.h
//  iPadCamera
//
//  Created by TMS on 16/02/29.
//
//

#import <Foundation/Foundation.h>

@interface brandM : NSObject{
    NSInteger brand_id;       //ブランドid
    NSString *brand_name;     //ブランド名
    NSMutableArray *prdct;    //商品リスト
}

@property (nonatomic)           NSInteger brand_id;
@property(nonatomic, retain)    NSString *brand_name;
@property(nonatomic, retain)    NSMutableArray *prdct;

@end
