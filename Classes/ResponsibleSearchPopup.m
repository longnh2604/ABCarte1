//
//  NameSearchPopup.m
//  iPadCamera
//
//  Created by TMS on 2016/08/10.
//
//

#import "ResponsibleSearchPopup.h"

@interface ResponsibleSearchPopup ()

@end

@implementation ResponsibleSearchPopup

@synthesize rs_delegate;

- (id)initWithPopUpViewContoller:(NSUInteger)popUpID
               popOverController:(UIPopoverController *)controller
                        callBack:(id)callBackDelegate
{
    self = [super initWithPopUpViewContoller:popUpID
                           popOverController:controller
                                    callBack:callBackDelegate];
    if (self) {
        rs_delegate = callBackDelegate;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    btnOK.enabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dealloc {
    [btnOK release];
    [super dealloc];
}
- (void)viewDidUnload {
    [btnOK release];
    btnOK = nil;
    [super viewDidUnload];
}

#pragma mark アクション処理部

// 検索ボタン
- (IBAction)onSearchStart:(id)sender {
    
    if([rs_delegate respondsToSelector:@selector(OnResponsibleSearch:)]) {
        [rs_delegate OnResponsibleSearch:txtName.text];
    }
    
    [self closeByPopoverContoller];
}

- (IBAction)onSearchCancel:(id)sender {
    [self OnCancelButton:sender];
}

// 文字列変更
- (IBAction) onChangeText:(id)sender
{
    // １文字でも入力されればOKボタンを有効にする
    btnOK.enabled
    = ([txtName.text length] > 0);
}

@end
