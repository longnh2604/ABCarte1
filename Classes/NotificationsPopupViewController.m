#import "NotificationsPopupViewController.h"
#import "NotificationDetailViewController.h"
#import "NotificationItemCell.h"
#import "NotificationStore.h"
#import "NotificationClient.h"
#import "NotificationSyncer.h"
#import "ShopManager.h"

@interface NotificationsPopupViewController ()<UITableViewDelegate, UITableViewDataSource>
@end

@implementation NotificationsPopupViewController
{
    NSIndexPath *_selectedIndexPath;
    NotificationStore* _store;
    NSArray* _loadedNotifications;
}

+ (UINavigationController *) createNavigationController {
    NotificationsPopupViewController *vc = [[[NotificationsPopupViewController alloc] init] autorelease];
    UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    [nc setModalPresentationStyle:UIModalPresentationFormSheet];
    return nc;
}

- (void)dealloc {
    NSLog(@"[NotificationPopupViewController] dealloc");
    if (_selectedIndexPath != nil) {
        [_selectedIndexPath release];
    }
    [_store release];
    [_loadedNotifications release];

    [_tableView release];
    [_activityIndicator release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self != nil) {
        _selectedIndexPath = nil;
        _store = [[NotificationStore alloc] init];
        _loadedNotifications = [[NSArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"お知らせ一覧";
    
    // NavigationBarのセットアップ
    UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc]
                               initWithTitle:@"閉じる"
                               style:UIBarButtonItemStylePlain
                               target:self
                               action:@selector(onCloseClick)];
    self.navigationItem.leftBarButtonItem = buttonItem;
    [buttonItem release];
    
    // UITableViewのセットアップ
    UINib *cellNib = [UINib nibWithNibName:@"NotificationItemCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"notification-item-cell"];
    self.tableView.rowHeight = 45;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    NSLog(@"sys = %@",[UIDevice currentDevice].systemVersion);
    if ([[UIDevice currentDevice].systemVersion isEqualToString:@"10.3.2"] || [[UIDevice currentDevice].systemVersion isEqualToString:@"10.3.3"]) {
        self.tableView.contentInset = UIEdgeInsetsMake(50, 0, 0, 0);
    }
  
//    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(1, 50, 276, 45)];
//    headerView.backgroundColor = [UIColor colorWithRed:235/255.0f green:235/255.0f blue:235/255.0f alpha:1.0f];
//    self.tableView.tableHeaderView = headerView;

    // アクティビティインディケーターのセットアップ
    self.activityIndicator.hidesWhenStopped = YES;
    [self.activityIndicator startAnimating];
    
    if (![_store initializeDatabase]) {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray* notifications = [_store getAllNotifications];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_loadedNotifications release];
            _loadedNotifications = notifications;
            [_loadedNotifications retain];
            [self.activityIndicator stopAnimating];
            [self.tableView reloadData];
        });
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    if (_selectedIndexPath == nil) {
        return;
    }
    Notification *notification = _loadedNotifications[_selectedIndexPath.row];
    if (notification == nil) {
        return;
    }
    notification.isRead = YES;
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[_selectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onCloseClick {
    NSLog(@"onCloseClick");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"in count = %lu",(unsigned long)_loadedNotifications.count);
    return _loadedNotifications.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NotificationItemCell* cell = [tableView dequeueReusableCellWithIdentifier:@"notification-item-cell" forIndexPath:indexPath];
    Notification* notification = _loadedNotifications[indexPath.row];
    [cell setNotification:notification];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;

    if (_selectedIndexPath != nil) {
        [_selectedIndexPath release];
    }
    _selectedIndexPath = [indexPath retain];
    NotificationDetailViewController *vc = [[NotificationDetailViewController alloc] init];
    Notification *notification = _loadedNotifications[indexPath.row];
    vc.notification = notification;
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_store setRead:notification.id readAt:[NSDate date]]; // ignore error

        NotificationClient* client = [[NotificationClient alloc] initWithAccountHostUrl:ACCOUNT_HOST_URL];
        NotificationSyncer* syncer = [[NotificationSyncer alloc] initWithClient:client store:_store];
        if (![syncer sync]) {
            NSLog(@"[NotificationsPopupViewController] notification sync failed");
        }
        [syncer release];
        [client release];
    });
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
