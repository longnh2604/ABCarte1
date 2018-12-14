//
//  niperBistchCourseItem.m
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import "SomeCourseItemCommon.h"

@implementation SomeCourseItemCommon

#pragma mark override_methods

// コースのitemの初期化
-(id) initCourseItem
{   return (nil); }

// Image名の取得
-(NSString*) getImageName
{   return (nil); }

// item名の取得
-(NSString*) getItemName
{   return (nil); }

@end

/**
 * ニッパービスチェのコースのitemを表すクラス
 */
@implementation niperBistchCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:50925
                              largerPrice:58800
                             specialPrice:81900]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"nipper_bisture.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"ニッパービスチェ"); }

@end

/**
 * ハイウエストショートガードルのコースのitemを表すクラス
 */
@implementation highWestShortGirdleCourseItem : SomeCourseItemCommon

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:30450
                              largerPrice:51450
                             specialPrice:51450]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"high-west-short-girdle.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"ハイウエストショートガードル"); }

@end

/**
 * ハイウエストガードルのコースのitemを表すクラス
 */
@implementation highWestGirdleCourseItem : SomeCourseItemCommon

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:41475
                              largerPrice:48300
                             specialPrice:71400]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"high-west-girdle.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"ハイウエストガードル"); }

@end


/**
 * パンストのコースのitemを表すクラス
 */
@implementation pantyhoseCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:10290
                              largerPrice:10290
                             specialPrice:10290]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"pantyhose.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"パンスト"); }

@end

/**
 * Tバックボディースーツのコースのitemを表すクラス
 */
@implementation tBackBodySuitCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:56175
                              largerPrice:66150
                             specialPrice:89250]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"t-back-body-suit.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"Tバックボディースーツ"); }

@end

/**
 * レギュラーガードルのコースのitemを表すクラス
 */
@implementation regulerGirdleCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:37800
                              largerPrice:60900
                             specialPrice:60900]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"reguler-girdle.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"レギュラーガードル"); }

@end

/**
 * スパッツのコースのitemを表すクラス
 */
@implementation spatsCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:39900
                              largerPrice:60900
                             specialPrice:60900]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"spats.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"スパッツ"); }

@end

/**
 * 3/4カップブラジャーのコースのitemを表すクラス
 */
@implementation trQuatCupBrassiereCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:25200
                              largerPrice:47250
                             specialPrice:47250]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"3_4-cup-brassiere.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"3/4カップブラジャー"); }

@end

/**
 * フルカップブラジャーのコースのitemを表すクラス
 */
@implementation fullCupBrassiereCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:30450
                              largerPrice:57750
                             specialPrice:57750]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"full-cup-brassiere.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"フルカップブラジャー"); }

@end

/**
 * 袖付ボディースーツのコースのitemを表すクラス
 */
@implementation sleevesBodySuiteCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:57750
                              largerPrice:89250
                             specialPrice:89250]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"sleeves-body-suite.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"袖付ボディースーツ"); }

@end

/**
 * ララドールのコースのitemを表すクラス
 */
@implementation lalaDoleCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:57750
                              largerPrice:89250
                             specialPrice:89250]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"lala-dole.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"ララドール"); }

@end

/**
 * ウエストニッパーのコースのitemを表すクラス
 */
@implementation waistNipperCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:23100
                              largerPrice:47250
                             specialPrice:47250]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"waist-nipper.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"ウエストニッパー"); }

@end

/**
 * パンプ半袖のコースのitemを表すクラス
 */
@implementation punpShortSleevesCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:35175
                              largerPrice:35175
                             specialPrice:35175]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"punp-short-sleeves.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"パンプ半袖"); }

@end

/**
 * パンプ七分袖のコースのitemを表すクラス
 */
@implementation punpSevenSleevesCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:36750
                              largerPrice:42000
                             specialPrice:42000]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"pump-7_sleeves.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"パンプ七分袖"); }

@end

/**
 * パンプ十分袖のコースのitemを表すクラス
 */
@implementation punpTenSleevesCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:39900
                              largerPrice:46000
                             specialPrice:46000]) {
        
    }
    return (self);
}

// Image名の取得：７分と同じ
-(NSString*) getImageName
{   return (@"pump-7_sleeves.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"パンプ十分袖"); }

@end

/**
 * レディースガードル（七分丈）のコースのitemを表すクラス
 */
@implementation ladiesGirdleSevenSleevesCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:29400
                              largerPrice:29400
                             specialPrice:29400]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"ladies-girdle_7_sleeves.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"レディースガードル（七分丈）"); }

@end

/**
 * レディースガードル（五分丈）のコースのitemを表すクラス
 */
@implementation ladiesGirdleFiveSleevesCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:29400
                              largerPrice:29400
                             specialPrice:29400]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"ladies-girdle_5_sleeves.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"レディースガードル（五分丈）"); }

@end

/**
 * レディースガードル（十分丈）のコースのitemを表すクラス
 */
@implementation ladiesGirdleTenSleevesCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:29400
                              largerPrice:29400
                             specialPrice:29400]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"ladies-girdle_10_sleeves.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"レディースガードル（十分丈）"); }

@end

#pragma mark option_items

/**
 * ハイソックス（２枚組）のコースのitemを表すクラス
 */
@implementation highSocksCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:10290
                              largerPrice:10290
                             specialPrice:10290]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"high-socks.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"ハイソックス（２枚組）"); }

@end

/**
 * Tバックショーツのコースのitemを表すクラス
 */
@implementation TbackShortsCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:7140
                              largerPrice:11550
                             specialPrice:11550]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"T-back-shorts.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"Tバックショーツ"); }

@end

/**
 * レーシーショーツのコースのitemを表すクラス
 */
@implementation laceyShortsCourseItem

// コースのitemの初期化
-(id) initCourseItem
{
    if (self = [super initWithNormalPrice:10290
                              largerPrice:15750
                             specialPrice:15750]) {
        
    }
    return (self);
}

// Image名の取得
-(NSString*) getImageName
{   return (@"lacey-shorts.png"); }

// item名の取得
-(NSString*) getItemName
{   return (@"レーシーショーツ"); }

@end

