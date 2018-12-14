//
//  palletViewPopup.m
//  iPadCamera
//
//  Created by 聡史 伊藤 on 12/07/10.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "palletViewPopup.h"

@implementation palletViewPopup
@synthesize flameW;
@synthesize flameH;

- (id) initPalletPopuWithPopupID:(NSUInteger)popUpID
                            size:(CGSize)popupSize
                              callBack:(id)callBack{
    if ( (self = [super initWithPopUpViewContoller:popUpID
                                 popOverController:nil
                                          callBack:callBack
                                           nibName:@"drawPallet"])){
        self.contentSizeForViewInPopover = popupSize;
        self.flameW = popupSize.width;
        self.flameH = popupSize.height;

    }
    return self;    
};

- (id)setLocatePortrate:(BOOL)port{
    if (port) {
        self.contentSizeForViewInPopover = CGSizeMake(self.flameW,self.flameH);
    }else {
        self.contentSizeForViewInPopover = CGSizeMake(self.flameH,self.flameW);
    }
    return self;
}
@end
