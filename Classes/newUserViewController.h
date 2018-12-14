//
//  newUserViewController.h
//  iPadCamera
//
//  Created by MacBook on 10/10/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PopUpViewContollerBase.h"

// @class mstUser;

@interface newUserViewController : PopUpViewContollerBase 
{
	// mstUser* _mstUser;
	IBOutlet UILabel			*lblTitle;
	IBOutlet UITextField		*txtFirstName;
	IBOutlet UITextField		*txtSecondName;
	IBOutlet UITextField		*txtFirstNameCana;
	IBOutlet UITextField		*txtSecondNameCana;
	IBOutlet UISegmentedControl	*segSex;
	
	IBOutlet UIButton			*btnRegist;
}

// 各TextFieldのEnterキーイベント
- (IBAction)onTextDidEnd:(id)sender;


@end
