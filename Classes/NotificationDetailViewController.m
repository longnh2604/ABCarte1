#import "NotificationDetailViewController.h"

@interface NotificationDetailViewController ()

@end

@implementation NotificationDetailViewController

- (void)dealloc {
    NSLog(@"DetailViewController dealloc");
    [_notification release];

    [_titleLabel release];
    [_dateLabel release];
    [_bodyTextView release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    [self updateView];
}

- (void)updateView {
    self.titleLabel.text = self.notification.title;
    self.dateLabel.text = [self toDateStr:self.notification.createdAt];
    NSLog(@"%@", self.notification.body);
//    self.bodyTextView.text = self.notification.body;
    
    [self.bodyTextView setScrollEnabled:YES];
    [self.bodyTextView setText:self.notification.body];
    [self.bodyTextView sizeToFit];
    [self.bodyTextView setScrollEnabled:NO];
}

- (NSString *)toDateStr:(NSDate *)date {
    NSDateFormatter *outputDateFormatter = [[NSDateFormatter alloc] init];
    NSString *outputDateFormatterStr = @"yyyy/MM/dd HH:mm";
    [outputDateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [outputDateFormatter setDateFormat:outputDateFormatterStr];
    NSString *outputDateStr = [outputDateFormatter stringFromDate:date];
    [outputDateFormatter release];
    return outputDateStr;
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
