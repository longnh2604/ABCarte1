//
//  maintenaceViewController.m
//  iPadCamera
//
//  Created by MacBook on 10/10/21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "maintenaceViewController.h"

#import "userDbManager.h"

@implementation maintenaceViewController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	dbInitializeAlert = [[UIAlertView alloc] init];
	dbInitializeAlert.title = @"データベースの初期化";
	dbInitializeAlert.message = @"データベースを初期化して、全データを削除します。よろしいですか？(削除すると元に戻せません。)";
	dbInitializeAlert.delegate = self;
	[dbInitializeAlert addButtonWithTitle:@"は　い"];
	[dbInitializeAlert addButtonWithTitle:@"いいえ"];
	
}

// データベース初期化ボタン
- (IBAction) OnInitilizeDatabase : (id)sender
{
	[dbInitializeAlert show];
}


// Alertダイアログのdelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// DB初期化Alertダイアログではいの場合、データベースを初期化
	if ( (alertView == dbInitializeAlert) && (buttonIndex != 1) )
	{
		// データベース管理のインスタンス
		userDbManager *dbManager = [[userDbManager alloc] init];
		
		// データベースのクリアして、Documentフォルダにコピー
		[dbManager clearDataBase];
		
		// クライアントクラスへcallback
		[delegate OnPopUpViewSet:_popUpID setObject:@"CLEAR_DATABASE"];
		
		[self closeByPopoverContoller];
        //2012 6/22 伊藤 リークしていたため修正
        [dbManager release];

	}
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    // [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    
	[dbInitializeAlert release];
	
	[super dealloc];
}


@end
