//
//  SizeSelectPopup.m
//  iPadCamera
//
//  Created by TMS on 16/02/18.
//  Copyright (c) 2016年 __MyCompanyName__. All rights reserved.
//

#import "SizeSelectPopup.h"

@interface SizeSelectPopup ()

@end

@implementation SizeSelectPopup

@synthesize sizeList;
@synthesize editItem;
@synthesize selectRow;

- (id)initWithGoodsItems:(GoodsItem *)item
             popUpID:(NSUInteger)popUpID
            callBack:(id)callBackDelegate{
    self = [super initWithPopUpViewContoller:popUpID popOverController:nil callBack:callBackDelegate nibName:@"SizeSelectPopup"];
    if (self) {
        sizeList =[[NSMutableArray alloc] init];
        switch (item.sizeType) {
            case S1:
                [self.sizeList addObject:[[NSString alloc]initWithString:@"A65~80"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"B65~95"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"C65~95"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"D65~95"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"E65~95"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"F65~95"]];
                break;
            case S2:
                [self.sizeList addObject:[[NSString alloc]initWithString:@"58"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"64"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"70"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"76"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"82"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"90"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"98"]];
                break;
            case SII:
                [self.sizeList addObject:[[NSString alloc]initWithString:@"A65~80"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"B65~85"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"C65~90"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"D65~90"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"E65~90"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"F65~90"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"G65~90"]];
                break;
            case S3:
                [self.sizeList addObject:[[NSString alloc]initWithString:@"S"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"M"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"L"]];
                [self.sizeList addObject:[[NSString alloc]initWithString:@"LL"]];
                break;
            default:
                break;
        }
        if (item.selectSize < [sizeList count]) {
            self.selectRow = item.selectSize;
        }else {
            self.selectRow = 0;
        }
        self.editItem = item;
        self.contentSizeForViewInPopover = CGSizeMake(350, 335);

        
    }
    return self;
}


-(id)setDelegateObject{
    selectRow = [picker selectedRowInComponent:0];
    [editItem.sizeBtn setTitle:[sizeList objectAtIndex:selectRow] forState:UIControlStateNormal];
    [editItem.sizeBtn setTitle:[sizeList objectAtIndex:selectRow] forState:UIControlStateHighlighted];
    [editItem.sizeBtn setTitle:[sizeList objectAtIndex:selectRow] forState:UIControlStateDisabled];
    editItem.selectSize = selectRow;
    return [NSNumber numberWithInt:selectRow];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    picker.delegate = self;
    picker.dataSource = self;
    [picker selectRow:selectRow inComponent:0 animated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

-(void)dealloc{
    [sizeList release];
    [super dealloc];
}

#pragma mark -
#pragma mark PickerView
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

-(NSInteger) pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component{
    return [self.sizeList count];
}

-(NSString*)pickerView:(UIPickerView *)pickerView
           titleForRow:(NSInteger)row 
          forComponent:(NSInteger)component{
    NSString *resultString = [self.sizeList objectAtIndex:row];
    return resultString;
}

-(void)pickerView:(UIPickerView *)pickerView
     didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component{
}
@end
