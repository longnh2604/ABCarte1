//
//  palletViewPopup.h
//  iPadCamera
//
//  Created by 聡史 伊藤 on 12/07/10.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PopUpViewContollerBase.h"

@interface palletViewPopup : PopUpViewContollerBase{


}
@property (nonatomic)CGFloat  flameW;
@property (nonatomic)CGFloat  flameH;

- (id) initPalletPopuWithPopupID:(NSUInteger)popUpID
                            size:(CGSize)popupSize
                        callBack:(id)callBack;
- (id)setLocatePortrate:(BOOL)port;
@end
