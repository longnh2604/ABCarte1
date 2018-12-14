//
//  GoodsColorItem.h
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GoodsColorItem : NSObject{
    UIImage * GoodsImage;
    NSString * ColorName;
}
@property(nonatomic,retain)     UIImage * GoodsImage;
@property(nonatomic,retain)     NSString * ColorName;

@end
