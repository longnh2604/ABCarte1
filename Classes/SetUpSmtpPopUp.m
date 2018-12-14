//
//  SetUpSmtpPopUp.m
//  iPadCamera
//
//  Created by GIGASJAPAN on 13/06/17.
//
//

#import "SetUpSmtpPopUp.h"

@interface SetUpSmtpPopUp ()

@end

@implementation SetUpSmtpPopUp

@synthesize senderAddr;
@synthesize smtpServer;
@synthesize smtpUser;
@synthesize smtpPass;
@synthesize smtpPort;
@synthesize smtpAuthSegment;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    noDataFlag = FALSE;
    
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    NSMutableArray *beanArray = [manager selectMailSmtpInfo:1];
    [manager release];

    if ([beanArray count] != 0) {
        mstUserMailItemBean *bean = [beanArray objectAtIndex:0];
        self.senderAddr.text = bean.sender_addr;
        self.smtpServer.text = bean.smtp_server;
        self.smtpUser.text = bean.smtp_user;
        self.smtpPass.text = bean.smtp_pass;
        self.smtpPort.text = [[NSString alloc] initWithFormat:@"%ld", (long)bean.smtp_port];
        self.smtpAuthSegment.selectedSegmentIndex = bean.smtp_auth;
    }else{
        noDataFlag = TRUE;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // キーボード表示・非表示の通知の登録
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // キーボード表示・非表示の通知の解除
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
}

//キーボードの表示
- (void)keyboardWillShow:(NSNotification *)notification
{
    NSLog(@"keyboardWillShow");
}

//キーボードの非表示
- (void)keyboardWillHide:(NSNotification *)notification
{
    NSLog(@"keyboardWillHide");
}

- (IBAction)OnCancelButton:(id)sender
{
    if(delegate != nil)
    {
        [delegate OnPopUpViewSet:-1 setObject:nil];
    }
    
    [self closeByPopoverContoller];
}

- (IBAction)OnSaveButton:(id)sender
{
    NSString *addrStr = self.senderAddr.text;
    NSString *serverStr = self.smtpServer.text;
    NSString *userStr = self.smtpUser.text;
    NSString *passStr = self.smtpPass.text;
    NSInteger portInt = [self.smtpPort.text intValue];
    NSInteger authInt = self.smtpAuthSegment.selectedSegmentIndex;
    
    userFmdbManager *manager = [[userFmdbManager alloc]init];
    [manager initDataBase];
    if(noDataFlag)
    {
        //データが無ければ新規でインサート
        [manager insertMailSmtpInfo:addrStr SmtpServer:serverStr SmtpUser:userStr SmtpPass:passStr SmtpPort:portInt SmtpAuth:authInt];
    }else{
        //データがあればアップデート
        [manager updateMailSmtpInfo:addrStr SmtpServer:serverStr SmtpUser:userStr SmtpPass:passStr SmtpPort:portInt SmtpAuth:authInt];
    }
    [manager release];
    
    if(delegate != nil)
    {
        [delegate OnPopUpViewSet:-1 setObject:nil];
    }
    [self closeByPopoverContoller];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ( (string != nil) && (![string isEqual: @""]) ) {
        if (![SetUpSmtpPopUp isNumber:string]) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)isNumber:(NSString *)value {
    
    // 空文字の場合はNO
    if ( (value == nil) || ([@"" isEqualToString:value]) ) {
        return NO;
    }
    
    NSInteger l = [value length];
    
    BOOL b = NO;
    for (NSInteger i = 0; i < l; i++) {
        NSString *str =
        [[value substringFromIndex:i]
         substringToIndex:1];
        
        const char *c =
        [str cStringUsingEncoding:
         NSASCIIStringEncoding];
        
        if ( c == NULL ) {
            b = NO;
            break;
        }
        
        if ((c[0] >= 0x30) && (c[0] <= 0x39)) {
            b = YES;
        } else {
            b = NO;
            break;
        }
    }
    
    if (b) {
        return YES;  // 数値文字列である
    } else {
        return NO;
    }  
}

- (id) setDelegateObject{
    NSString *succeed = [[[NSString alloc]init]autorelease];
    
    succeed = @"Success";
    
    return succeed;
}

- (id) initWithSmtpSetting:(NSUInteger)popUpID callBack:(id)callBack
{
    if(self = [super initWithPopUpViewContoller:popUpID
                              popOverController:nil
                                       callBack:callBack
                                        nibName:@"SetUpSmtpPopUp"]) {
        
        self.contentSizeForViewInPopover = CGSizeMake(550.0f, 380.0f);
        
    }
    return self;
}
@end
