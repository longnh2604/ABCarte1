#import "SilhouetteGuidePopupViewController.h"

@interface SilhouetteGuidePopupViewController ()
@end

@implementation SilhouetteGuidePopupViewController

@synthesize delegate;


+ (UINavigationController *) createNavigationController{
    SilhouetteGuidePopupViewController *vc = [[[SilhouetteGuidePopupViewController alloc] init] autorelease];
    UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    [nc setModalPresentationStyle:UIModalPresentationFormSheet];
    return nc;
}

- (void)dealloc {
    NSLog(@"[NotificationPopupViewController] dealloc");
    [super dealloc];
}

- (id)init {
    self = [super init];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"シルエット一覧";
    
    // NavigationBarのセットアップ
    UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc]
                               initWithTitle:@"閉じる"
                               style:UIBarButtonItemStylePlain
                               target:self
                               action:@selector(onCloseClick)];
    self.navigationItem.leftBarButtonItem = buttonItem;
    [buttonItem release];
    
    [self showSilhouetteGuideBtn:@"silhouette_x.png":CGRectMake(32, 110, 75, 100):-1];
    [self showSilhouetteGuideBtn:@"silhouette_0.png":CGRectMake(217,110, 75, 100):0];
    [self showSilhouetteGuideBtn:@"silhouette_1.png":CGRectMake(402,110, 75, 100):1];
    [self showSilhouetteGuideBtn:@"silhouette_6.png":CGRectMake(32,275, 75, 100):6];
    [self showSilhouetteGuideBtn:@"silhouette_2.png":CGRectMake(217,275, 75, 100):2];
    [self showSilhouetteGuideBtn:@"silhouette_3.png":CGRectMake(402,275, 75, 100):3];
    [self showSilhouetteGuideBtn:@"silhouette_4.png":CGRectMake(32,430, 75, 100):4];
    [self showSilhouetteGuideBtn:@"silhouette_5.png":CGRectMake(217,430, 75, 100):5];
    [self showSilhouetteGuideBtn:@"silhouette_7.png":CGRectMake(402,430, 75, 100):7];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
}

- (void)showSilhouetteGuideBtn:(NSString*)fileName : (CGRect)r : (NSInteger)index{
    
    UIButton *btn = [[UIButton alloc] initWithFrame:r];
    btn.tag = index;
    UIImage *image = [UIImage imageNamed:fileName];
    [btn setBackgroundImage:image forState:UIControlStateNormal];
    [btn addTarget:self
            action:@selector(showSilhouetteGuide:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

-(void)showSilhouetteGuide : (UIButton*)button{
    if([delegate respondsToSelector:@selector(OnShowSilhouetteGuide:)]) {
        [delegate OnShowSilhouetteGuide:button.tag];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onCloseClick {    
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
@end
