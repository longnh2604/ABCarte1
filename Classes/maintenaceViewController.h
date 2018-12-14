//
//  maintenaceViewController.h
//  iPadCamera
//
//  Created by MacBook on 10/10/21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PopUpViewContollerBase.h"

// 操作権限があるユーザのみ表示できるメンテナンス画面
@interface maintenaceViewController : PopUpViewContollerBase<UIAlertViewDelegate>
{
	UIAlertView *dbInitializeAlert;			// DB初期化Alertダイアログ
}

// データベース初期化ボタン
- (IBAction) OnInitilizeDatabase : (id)sender;

@end
