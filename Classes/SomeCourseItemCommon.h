//
//  niperBistchCourseItem.h
//  BodyCheck
//
//  Created by TMS on 16/02/18.
//
//

#import "CourseItem.h"

@interface SomeCourseItemCommon : multiPriceCourseItem

// コースのitemの初期化
-(id) initCourseItem;

// Image名の取得
-(NSString*) getImageName;

// item名の取得
-(NSString*) getItemName;

@end

/**
 * ニッパービスチェのコースのitemを表すクラス
 */
@interface niperBistchCourseItem : SomeCourseItemCommon
@end

/**
 * ハイウエストショートガードルのコースのitemを表すクラス
 */
@interface highWestShortGirdleCourseItem : SomeCourseItemCommon
@end

/**
 * ハイウエストガードルのコースのitemを表すクラス
 */
@interface highWestGirdleCourseItem : SomeCourseItemCommon
@end

/**
 * パンストのコースのitemを表すクラス
 */
@interface pantyhoseCourseItem : SomeCourseItemCommon
@end

/**
 * Tバックボディースーツのコースのitemを表すクラス
 */
@interface tBackBodySuitCourseItem : SomeCourseItemCommon
@end

/**
 * レギュラーガードルのコースのitemを表すクラス
 */
@interface regulerGirdleCourseItem : SomeCourseItemCommon
@end

/**
 * スパッツのコースのitemを表すクラス
 */
@interface spatsCourseItem : SomeCourseItemCommon
@end

/**
 * 3/4カップブラジャーのコースのitemを表すクラス
 */
@interface trQuatCupBrassiereCourseItem : SomeCourseItemCommon
@end

/**
 * フルカップブラジャーのコースのitemを表すクラス
 */
@interface fullCupBrassiereCourseItem : SomeCourseItemCommon
@end

/**
 * 袖付ボディースーツのコースのitemを表すクラス
 */
@interface sleevesBodySuiteCourseItem : SomeCourseItemCommon
@end

/**
 * ララドールのコースのitemを表すクラス
 */
@interface lalaDoleCourseItem : SomeCourseItemCommon
@end

/**
 * ウエストニッパーのコースのitemを表すクラス
 */
@interface waistNipperCourseItem : SomeCourseItemCommon
@end

/**
 * パンプ半袖のコースのitemを表すクラス
 */
@interface punpShortSleevesCourseItem : SomeCourseItemCommon
@end

/**
 * パンプ七分袖のコースのitemを表すクラス
 */
@interface punpSevenSleevesCourseItem : SomeCourseItemCommon
@end

/**
 * パンプ十分袖のコースのitemを表すクラス
 */
@interface punpTenSleevesCourseItem : SomeCourseItemCommon
@end

/**
 * レディースガードル（七分丈）のコースのitemを表すクラス
 */
@interface ladiesGirdleSevenSleevesCourseItem : SomeCourseItemCommon
@end

/**
 * レディースガードル（五分丈）のコースのitemを表すクラス
 */
@interface ladiesGirdleFiveSleevesCourseItem : SomeCourseItemCommon
@end

/**
 * レディースガードル（十分丈）のコースのitemを表すクラス
 */
@interface ladiesGirdleTenSleevesCourseItem : SomeCourseItemCommon
@end

#pragma mark option_items

/**
 * ハイソックス（２枚組）のコースのitemを表すクラス
 */
@interface highSocksCourseItem : SomeCourseItemCommon
@end

/**
 * Tバックショーツのコースのitemを表すクラス
 */
@interface TbackShortsCourseItem : SomeCourseItemCommon
@end

/**
 * レーシーショーツのコースのitemを表すクラス
 */
@interface laceyShortsCourseItem : SomeCourseItemCommon
@end
