#import "NotificationForcePopupViewController.h"
#import "NotificationDetailViewController.h"

#import "NotificationStore.h"
#import "NotificationClient.h"
#import "NotificationSyncer.h"
#import "ShopManager.h"

@interface NotificationForcePopupViewController ()

@end

@implementation NotificationForcePopupViewController
{
    NSInteger _currentIndex;
    NotificationDetailViewController *_vc;
    NotificationStore *_store;
}

- (void)dealloc {
    [_notifications release];
    [_vc release];
    [_store release];
    [super dealloc];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _currentIndex = 0;
    _store = [[NotificationStore alloc] init];
    BOOL initDBSucceeded = [_store initializeDatabase];

    if (self.notifications == nil || self.notifications.count == 0 || !initDBSucceeded) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    
    UIBarButtonItem *setReadButton = [[UIBarButtonItem alloc]
                                      initWithTitle:@"O K"
                                      style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(onSetReadClick)];
    UIBarButtonItem *readLatorButton = [[UIBarButtonItem alloc]
                                     initWithTitle:@"後で読む"
                                     style:UIBarButtonItemStylePlain
                                     target:self
                                     action:@selector(onReadLatorClick)];
    // ボタンどうしの間隔を作るためのUIBarButtonItem
    UIBarButtonItem *flexibleSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarHidden:NO];

    _vc = [[NotificationDetailViewController alloc] init];
    _vc.title = @"お知らせ";
    _vc.notification = _notifications[_currentIndex];
    _vc.toolbarItems = @[readLatorButton, flexibleSpaceItem, setReadButton];
    [self pushViewController:_vc animated:NO];
    
    [setReadButton release];
    [readLatorButton release];
    [flexibleSpaceItem release];
}

- (void)onSetReadClick {
    [self showNextNotificationOrDismiss:YES];
}

- (void)onReadLatorClick {
    [self showNextNotificationOrDismiss:NO];
}

- (void)showNextNotificationOrDismiss:(BOOL)setRead {
    Notification *notification = _notifications[_currentIndex];
    NSInteger notificationId = notification.id;
    
    _currentIndex++;
    if (_currentIndex >= _notifications.count) {
        // 次に表示すべき通知がなかった場合、サーバーに既読フラグを一括で送信する
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (setRead) {
                [_store setRead:notificationId readAt:[NSDate date]]; // ignore error
            }

            NotificationClient* client = [[NotificationClient alloc] initWithAccountHostUrl:ACCOUNT_HOST_URL];
            NotificationSyncer* syncer = [[NotificationSyncer alloc] initWithClient:client store:_store];
            if (![syncer sync]) {
                NSLog(@"[NotificationForcePopupViewController#onSetReadClick] notification sync failed");
            }
            [syncer release];
            [client release];
        });

        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        // 次に表示すべき通知が存在した場合、今表示していた通知を既読状態にして次の通知を表示する(setReadがYESの場合)
        if (setRead) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [_store setRead:notificationId readAt:[NSDate date]]; // ignore error
            });
        }
        
        _vc.notification = _notifications[_currentIndex];
        [_vc updateView];
    }
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

@end
