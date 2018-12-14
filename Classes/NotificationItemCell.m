#import "NotificationItemCell.h"

@implementation NotificationItemCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setNotification:(Notification *)notification {
    self.titleLabel.text = notification.title;
    self.isNewLabel.hidden = notification.isRead;
}

- (void)dealloc {
    [_titleLabel release];
    [_isNewLabel release];
    [super dealloc];
}
@end
