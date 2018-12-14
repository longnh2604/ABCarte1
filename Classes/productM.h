//
//  productM.h
//  iPadCamera
//
//  Created by TMS on 16/02/29.
//
//

#import <Foundation/Foundation.h>

@interface productM : NSObject{
    NSInteger product_id;       //商品id
    NSString *product_name;     //商品名
    NSInteger brand_id;         //ブランドid
    NSString *file_name;        //商品ファイル名
    NSMutableArray *size;       //サイズ
    NSMutableArray *color;      //カラー
    NSInteger idx;               //リスト内の序列
    NSInteger num;              //個数
    NSString *selSize;          //選択中のサイズ
    NSString *selColor;         //選択中のカラー
    NSInteger selPrice;         //選択中の単価
    NSInteger selSizeVal;       //選択中のサイズの行
    NSInteger selColorVal;       //選択中のサイズの行
    
}

@property (nonatomic)               NSInteger product_id;
@property(nonatomic, retain)        NSString *product_name;
@property (nonatomic)               NSInteger brand_id;
@property(nonatomic, retain)        NSString *file_name;
@property(nonatomic, retain)        NSMutableArray *size;
@property(nonatomic, retain)        NSMutableArray *color;
@property (nonatomic)               NSInteger idx;
@property (nonatomic)               NSInteger num;
@property(nonatomic, retain)        NSString *selSize;
@property(nonatomic, retain)        NSString *selColor;
@property (nonatomic)               NSInteger selPrice;
@property (nonatomic)               NSInteger selSizeVal;
@property (nonatomic)               NSInteger selColorVal;

@end
