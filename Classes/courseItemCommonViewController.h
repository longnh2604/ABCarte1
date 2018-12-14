//
//  course1ItemViewController.h
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import "courseItemBaseViewController.h"

#import "UISelectedButton.h"

@interface course1ItemViewController : courseItemBaseViewController
{
    IBOutlet UIImageView    *imgGrp2Image;      // Group2のImageView:ORアイテム
    IBOutlet UILabel        *lblGrp2Name;       // Group2のitem名:ORアイテム
    
    IBOutlet UISelectedButton *btnSortGurdle;
    IBOutlet UISelectedButton *btnGurdle;
}

@end

@interface course2ItemViewController : courseItemBaseViewController
{
    IBOutlet UIImageView    *imgGrp2Image;      // Group2のImageView:ORアイテム
    IBOutlet UILabel        *lblGrp2Name;       // Group2のitem名:ORアイテム
    
    IBOutlet UISelectedButton *btnRegulerGurdle;
    IBOutlet UISelectedButton *btnPanst;
    IBOutlet UISelectedButton *btnSpats;
}

@end

@interface course3ItemViewController : courseItemBaseViewController
{
    IBOutlet UIImageView    *imgGrp1Image;      // Group1のImageView:ORアイテム
    IBOutlet UILabel        *lblGrp1Name;       // Group1のitem名:ORアイテム
    IBOutlet UISelectedButton *btnGrp11;        // Group1のorアイテムボタン：3/4カップブラジャー
    IBOutlet UISelectedButton *btnGrp12;
    
    IBOutlet UIImageView    *imgGrp2Image;      // Group2のImageView:ORアイテム
    IBOutlet UILabel        *lblGrp2Name;       // Group2のitem名:ORアイテム
    IBOutlet UISelectedButton *btnGrp21;        // Group2のorアイテムボタン：袖付ボディースーツ
    IBOutlet UISelectedButton *btnGrp22;
    
    IBOutlet UIImageView    *imgGrp3Image;      // Group3のImageView:ORアイテム
    IBOutlet UILabel        *lblGrp3Name;       // Group3のitem名:ORアイテム
    IBOutlet UISelectedButton *btnGrp31;        // Group3のorアイテムボタン：レギュラーガードル
    IBOutlet UISelectedButton *btnGrp32;
    IBOutlet UISelectedButton *btnGrp33;
}

@end

@interface course4ItemViewController : courseItemBaseViewController
{
    IBOutlet UIImageView    *imgGrp1Image;      // Group1のImageView:ORアイテム
    IBOutlet UILabel        *lblGrp1Name;       // Group1のitem名:ORアイテム
    IBOutlet UISelectedButton *btnGrp11;        // Group1のorアイテムボタン：3/4カップブラジャー
    IBOutlet UISelectedButton *btnGrp12;
    
    IBOutlet UIImageView    *imgGrp3Image;      // Group3のImageView:ORアイテム
    IBOutlet UILabel        *lblGrp3Name;       // Group3のitem名:ORアイテム
    IBOutlet UISelectedButton *btnGrp31;        // Group3のorアイテムボタン：レギュラーガードル
    IBOutlet UISelectedButton *btnGrp32;
    IBOutlet UISelectedButton *btnGrp33;
}

@end

@interface course5ItemViewController : courseItemBaseViewController
{
    IBOutlet UIImageView    *imgGrp1Image;      // Group1のImageView:ORアイテム
    IBOutlet UILabel        *lblGrp1Name;       // Group1のitem名:ORアイテム
    IBOutlet UISelectedButton *btnGrp11;        // Group1のorアイテムボタン：パンプ半袖
    IBOutlet UISelectedButton *btnGrp12;
    IBOutlet UISelectedButton *btnGrp13;
    
    IBOutlet UIImageView    *imgGrp2Image;      // Group2のImageView:ORアイテム
    IBOutlet UILabel        *lblGrp2Name;       // Group2のitem名:ORアイテム
    IBOutlet UISelectedButton *btnGrp21;        // Group2のorアイテムボタン：袖付ボディースーツ
    IBOutlet UISelectedButton *btnGrp22;
    IBOutlet UISelectedButton *btnGrp23;
    IBOutlet UISelectedButton *btnGrp24;
}

@end
