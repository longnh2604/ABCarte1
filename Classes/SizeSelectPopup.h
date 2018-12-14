//
//  SizeSelectPopup.h
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "PopUpViewContollerBase.h"
#import "GoodsItem.h"

@interface SizeSelectPopup : PopUpViewContollerBase <UIPickerViewDelegate,UIPickerViewDataSource>{
    NSMutableArray              *sizeList;
    IBOutlet UIPickerView       *picker;
    NSInteger                   selectRow;
    GoodsItem                   *editItem;
}
@property(nonatomic,retain) NSMutableArray  *sizeList;
@property(nonatomic,retain) GoodsItem        *editItem;
@property(nonatomic)        NSInteger       selectRow;



- (id)initWithGoodsItems:(GoodsItem *)item
             popUpID:(NSUInteger)popUpID
            callBack:(id)callBackDelegate;

@end
