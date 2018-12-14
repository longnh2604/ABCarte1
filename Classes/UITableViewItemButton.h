//
//  UITableViewItemButton.h
//  iPadCamera
//
//  Created by MacBook on 11/03/01.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIFlickerButton.h"

///
/// TableViewにフリッカ機能を持たせるボタン
///
@interface UITableViewItemButton : UIFlickerButton {

	UITableView*		_ownerTableView;			// オーナーのTableView
	
	NSUInteger				_section;				// このItemのセクション;
	NSUInteger				_rowIndex;				// このItemのIndex;
	
}

@property(nonatomic)  NSUInteger section;
@property(nonatomic)  NSUInteger rowIndex;

// 初期化処理
- (void) initialize:(id)ownerView tableView:(UITableView*)tableView;

@end
