//
//  CharacterInsertPopup.m
//  iPadCamera
//
//  Created by 聡史 伊藤 on 12/07/06.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CharacterInsertPopup.h"
#import "Common.h"
#import "PicturePaintManagerView.h"

@implementation CharacterInsertPopup

@synthesize drawPartsList;
@synthesize textColor;
@synthesize drawPoint;
@synthesize drawContext;
@synthesize charaObj;
@synthesize pictTarget;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    // titleの角を丸める
	[Common cornerRadius4Control:lblTitle];
    textChara.text = @"";
    self.charaObj = [[PictureDrawParts alloc] initWithString:textChara.text
                                                   drawPoint:self.drawPoint
                                                       color:self.textColor
                                                       width:sliderCharaSize.value];
    [self.drawPartsList addObject:self.charaObj];
    [textChara addTarget:self action:@selector(valueChangeAction:) forControlEvents:UIControlEventEditingChanged];

}

- (void)dealloc{
    [self.charaObj release];
    [super dealloc];
}

- (id) initCharacterInsertWithPictList:(NSMutableArray *)sendPictList
                                 color:(NSInteger)color
                         canvasContext:(CGContextRef)context
                            targetView:(UIView*)targetView
                              position:(CGPoint)position
                               popUpID:(NSUInteger)popUpID
                             callBack:(id)callBack
{
    if ( (self = [super initWithPopUpViewContoller:popUpID
                                 popOverController:nil
                                          callBack:callBack
#ifndef CALULU_IPHONE
                                           nibName:@"CharacterInsertPopup"])){
#else
                                           nibName:@"ip_CharacterInsertPopup"])){
#endif
        self.contentSizeForViewInPopover = CGSizeMake(375.0f, 244.0f);
        self.drawContext = context;
        self.pictTarget = targetView;
        if (color == ERASE_COLOR_NO) {
            color = PAINT_COLOR_RED;
        }
        self.textColor = color;
        self.drawPartsList = sendPictList;
        self.drawPoint = position;
    }
    return  (self);
}

-(IBAction)valueChangeAction:(id)sender{
    
    [self rewriteAction];
}

-(void)rewriteAction{
    [self.drawPartsList removeLastObject];
    self.charaObj.drawString = textChara.text;
    self.charaObj.penWidth = sliderCharaSize.value;
    self.charaObj.paintColor = self.textColor;

    [self.drawPartsList addObject:self.charaObj];
    [(PicturePaintManagerView*)pictTarget drawObjects:YES];
    [pictTarget setNeedsDisplay];
}

- (id) setDelegateObject{
    if([textChara.text isEqualToString:@""]){
        return nil;
    };
    return textChara.text;
}

- (IBAction) OnCancelButton:(id)sender
{
    [drawPartsList removeLastObject];
    [(PicturePaintManagerView*)pictTarget drawObjects:YES];

	[self closeByPopoverContoller];
}

- (IBAction)setColor:(id)sender{
    UIButton* selectBtn = sender;
    switch (selectBtn.tag) {
        case 1:
            self.textColor = PAINT_COLOR_RED;
            break;
        case 2:
            self.textColor = PAINT_COLOR_YERROW;
            break;   
        case 3:
            self.textColor = PAINT_COLOR_BLUE;
            break;        
        default:
            break;
    }
    [self rewriteAction];
}
@end
