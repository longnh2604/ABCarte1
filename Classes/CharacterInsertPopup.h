//
//  CharacterInsertPopup.h
//  iPadCamera
//
//  Created by 聡史 伊藤 on 12/07/06.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PopUpViewContollerBase.h"
#import "PictureDrawParts.h"

@interface CharacterInsertPopup : PopUpViewContollerBase{
    IBOutlet    UILabel         *lblTitle;
    IBOutlet    UITextField     *textChara;
    IBOutlet    UISlider        *sliderCharaSize;
}
@property(nonatomic,retain) NSMutableArray*     drawPartsList;
@property(nonatomic)        NSInteger           textColor;
@property(nonatomic)        CGPoint             drawPoint;
@property(nonatomic)        CGContextRef        drawContext;
@property(nonatomic,retain) PictureDrawParts*   charaObj;
@property(nonatomic,retain) UIView*             pictTarget;

- (id) initCharacterInsertWithPictList:(NSMutableArray *)sendPictList
                                 color:(NSInteger)color
                         canvasContext:(CGContextRef)context
                            targetView:(UIView*)targetView
                              position:(CGPoint)position
                               popUpID:(NSUInteger)popUpID
                              callBack:(id)callBack;
@end
