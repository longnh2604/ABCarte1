//
//  grantFmdbManager.h
//  iPadCamera
//
//  Created by TMS on 16/02/29.
//
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "productM.h"
#import "sizeM.h"
#import "colorM.h"
#import "priceM.h"
#import "brandM.h"

//以下商品データの準備（暫定対応）
//ブランド
// 2016/8/4 TMS 商品追加対応
#define BRAND @"Fantasy,Fairy,Gracy,Drainage,BiBi　Grant,Cordial Grant,RE.B5,ｳｫｰﾀｰｻｲｴﾝｽ,Leafy / Leafy Kyu-ju,Grangelina"
#define PRDCT_NAME_BRAND1 @"ﾆｯﾊﾟｰﾋﾞｽﾁｪ,ﾚｰｼｰｼｮｰﾂ,ｻﾆﾀﾘｰｼｮｰﾂ,ﾊｲｳｴｽﾄｶﾞｰﾄﾞﾙ,ﾊｲｳｴｽﾄｶﾞｰﾄﾞﾙ　3分丈,ﾊｲｳｴｽﾄｼｮｰﾄｶﾞｰﾄﾞﾙ"
#define PRDCT_NAME_BRAND2 @"Tﾊﾞｯｸﾎﾞﾃﾞｨｽｰﾂ,ﾚｷﾞｭﾗｰｶﾞｰﾄﾞﾙ,Tﾊﾞｯｸｼｮｰﾂ,ﾗﾗｸﾘｰﾝ"
#define PRDCT_NAME_BRAND3 @"ﾌﾞﾗｼﾞｬｰ,ﾚｷﾞｭﾗｰｶﾞｰﾄﾞﾙ,袖付ﾎﾞﾃﾞｨｽｰﾂ,ﾗﾗﾄﾞｰﾙ（袖なしﾎﾞﾃﾞｨｽｰﾂ）"
#define PRDCT_NAME_BRAND4 @"ｽﾊﾟｯﾂⅡ,ﾊｲｳｴｽﾄｽﾊﾟｯﾂ,ﾋｯﾌﾟｱｯﾌﾟﾊﾟﾝｽﾄ,ｸｰﾙﾋﾞｽﾞﾊﾟﾝｽﾄ(ｵｰﾌﾟﾝﾄｩ),ﾄﾞﾚﾅｰｼﾞｭ・ﾀｲﾂ,ｸｰﾙﾋﾞｽﾞ・ﾄﾚﾝｶ,ﾆｰﾊｲｿｯｸｽ,ﾌﾟﾚﾐｱﾑﾋﾞｭｰﾃｨｰﾊﾞﾝﾃｰｼﾞ(ｸﾘｰﾑ付),ﾌﾟﾚﾐｱﾑﾋﾞｭｰﾃｨｰﾎﾞﾃﾞｨｸﾘｰﾑ,ﾚｷﾞﾝｽ7分丈,ｱｰﾑｶﾞｰﾄﾞﾙⅡ(ﾚｰｽあり),ｱｰﾑｶﾞｰﾄﾞﾙⅡ(ﾚｰｽなし),ﾚｰｼｰｽﾄｰﾆｰ"
// 2016/6/24 TMS 商品追加対応
#define PRDCT_NAME_BRAND5 @"ﾚﾃﾞｨｰｽﾊﾟﾝﾌﾟ半袖,ﾚﾃﾞｨｰｽｴﾚｸﾄﾊﾟﾝﾌﾟ7分袖,ﾚﾃﾞｨｰｽﾊｲﾈｯｸｴﾚｸﾄﾊﾟﾝﾌﾟ10分袖,ﾎﾞｸｻｰﾊﾟﾝﾂ女性用,ﾚﾃﾞｨｰｽﾋﾞﾋﾞｶﾞｰﾄﾞﾙ7分丈,ﾚﾃﾞｨｰｽﾋﾞﾋﾞｶﾞｰﾄﾞﾙ10分丈,ﾚﾃﾞｨｰｽｴﾚｸﾄｶﾞｰﾄﾞﾙ7分丈,ﾚﾃﾞｨｰｽｴﾚｸﾄｶﾞｰﾄﾞﾙ10分丈,ﾒﾝｽﾞﾊﾟﾝﾌﾟ半袖,ﾒﾝｽﾞﾊｲﾈｯｸｴﾚｸﾄﾊﾟﾝﾌﾟ10分袖,ﾎﾞｸｻｰﾊﾟﾝﾂ男性用,ﾒﾝｽﾞｴﾚｸﾄｶﾞｰﾄﾞﾙ,ﾒﾝｽﾞ　ｼｪｲﾌﾟｱｯﾌﾟｽﾊﾟｯﾂ,ｱﾃｨｰﾎﾞ･ﾊｲｿｯｸｽ,ﾈｯｸｳｫｰﾏｰ,ﾚﾃﾞｨｰｽﾋﾞﾋﾞﾊﾟﾝﾌﾟ7分丈,ｼｪｲﾌﾟｱｯﾌﾟｽﾊﾟｯﾂ(男女兼用)"
#define PRDCT_NAME_BRAND6 @"ｴｲﾁ･ｼﾞｰ･ｴｲﾁ　ｸﾞﾗﾐﾉ,ﾎﾟﾘﾏｼｰﾄﾞﾚｽﾍﾞﾗ,痩健美　玄米胚芽,美容専科　ｼﾙｸｸﾞﾗﾐﾉ,ｸﾞﾗﾝﾄ酵素ﾊﾟｳﾀﾞｰ"
// 2016/5/20 TMS 商品・ブランド追加対応
#define PRDCT_NAME_BRAND7 @"ﾎﾙﾐｰｼｰﾂ,ﾎﾙﾐｰﾌﾞﾗﾄｯﾌﾟ,ﾎﾙﾐｰｸﾘｰﾑ,ﾎﾙﾐｰﾎﾞｸｻｰﾊﾟﾝﾂ,ﾎﾙﾐｰﾋﾟﾛｰｼｰﾄ,ﾎﾙﾐｰﾏｽｸ,ﾎﾙﾐｰｼｮｰﾂ"
#define PRDCT_NAME_BRAND8 @"ｳｫｰﾀｰｻｲｴﾝｽ･ｸﾚﾝｼﾞﾝｸﾞｹﾞﾙ,ｳｫｰﾀｰｻｲｴﾝｽ･ﾘｷｯﾄﾞｿｰﾌﾟ,ｳｫｰﾀｰｻｲｴﾝｽ･ｴｯｾﾝｽ,ｳｫｰﾀｰｻｲｴﾝｽ･ｽｷﾝﾛｰｼｮﾝ,ｳｫｰﾀｰｻｲｴﾝｽ･ｼﾞｪﾙﾊﾟｯｸ"
#define PRDCT_NAME_BRAND9 @"ﾍｱ ｼｽﾃﾑ ﾌﾟﾗｽ ｴｯｾﾝｽ（洗い流さないﾀｲﾌﾟ）,ｽｶﾙﾌﾟ&ﾍｱｼｽﾃﾑ ﾍｱｸﾚﾝｼﾞﾝｸﾞｵｲﾙ(洗い流すﾀｲﾌﾟ),ｽｶﾙﾌﾟ&ﾍｱ ｼｽﾃﾑ ｼｬﾝﾌﾟｰ,ｽｶﾙﾌﾟ&ﾍｱ ｼｽﾃﾑ ﾄﾘｰﾄﾒﾝﾄ（洗い流すﾀｲﾌﾟ）,ｽｶﾙﾌﾟｼｬﾝﾌﾟｰ専用容器,ｽｶﾙﾌﾟﾄﾘｰﾄﾒﾝﾄ専用容器,"
#define PRDCT_NAME_BRAND10 @"ﾌｪｲｽｳｫｯｼｭ（洗顔料）,ｸﾚﾝｼﾞﾝｸﾞｼﾞｪﾙ（ﾒｲｸ落とし）,ｵｰﾙｲﾝﾜﾝ（美容化粧水）,保湿ｸﾘｰﾑ（ﾌｪｲｽｸﾘｰﾑ）,ｻﾝｼｬｲﾝﾏｼﾞｯｸ（ﾒｲｸｱｯﾌﾟﾍﾞｰｽ）UV,UV100,ｽﾊﾟ-ｸﾘﾝｸﾞｳﾞｪ-ﾙ(ﾊﾟﾌ),ﾜﾝｽﾞｳｫｰﾀｰ,ｸﾞﾗﾝﾄﾘﾌﾄｼﾞｪﾙ(ｼﾞｪﾙ状美容液),ｽｶﾙﾌﾟｴｯｾﾝｽ,ｽｶﾙﾌﾟｸﾞﾛｰｱｯﾌﾟｼｽﾃﾑⅡ（頭皮ﾏｯｻｰｼﾞ機）,ﾊﾟｰﾌｪｸﾄｽﾃｨｯｸRF,ﾊｰﾌﾞｼｬﾝﾌﾟｰ,ﾊｰﾌﾞﾎﾞﾃﾞｨﾒｲｸｴｯｾﾝｽ,ﾊｰﾌﾞｳｫｰﾀｰｽﾌﾟﾚｰ"

//商品
#define PRDCT_FILE_NAME_BRAND1 @"prdct11,prdct12,prdct13,prdct14,prdct15,prdct16"
#define PRDCT_FILE_NAME_BRAND2 @"prdct21,prdct22,prdct23,prdct24"
#define PRDCT_FILE_NAME_BRAND3 @"prdct31,prdct32,prdct33,prdct34"
#define PRDCT_FILE_NAME_BRAND4 @"prdct41,prdct42,prdct43,prdct44,prdct45,prdct46,prdct47,prdct48,prdct49,prdct410,prdct411,prdct412,prdct413"
// 2016/6/24 TMS 商品追加対応
#define PRDCT_FILE_NAME_BRAND5 @"prdct51,prdct52,prdct53,prdct54,prdct55,prdct56,prdct57,prdct58,prdct59,prdct510,prdct511,prdct512,prdct513,prdct514,prdct515,prdct516,prdct517"
#define PRDCT_FILE_NAME_BRAND6 @"prdct61,prdct62,prdct63,prdct64,prdct65"
// 2016/5/20 TMS 商品・ブランド追加対応
#define PRDCT_FILE_NAME_BRAND7 @"prdct71,prdct72,prdct73,prdct74,prdct75,prdct76,prdct77"
#define PRDCT_FILE_NAME_BRAND8 @"prdct81,prdct82,prdct83,prdct84,prdct85"
#define PRDCT_FILE_NAME_BRAND9 @"prdct91,prdct92,prdct93,prdct94,prdct95,prdct96"
#define PRDCT_FILE_NAME_BRAND10 @"prdct101,prdct102,prdct103,prdct104,prdct105,prdct106,prdct107,prdct108,prdct109,prdct1010,prdct1011,prdct1012,prdct1013,prdct1014,prdct1015"

//サイズ
#define SIZE_BRAND1_PRDCT1 @"65A,65B,65C,65D,65E,65F,65G,70A,70B,70C,70D,70E,70F,70G,75A,75B,75C,75D,75E,75F,75G,80A,80B,80C,80D,80E,80F,80G,85A,85B,85C,85D,85E,85F,85G,90A,90B,90C,90D,90E,90F,90G,95A,95B,95C,95D,95E,95F,95G,100A,100B,100C,100D,100E,100F,100G,105A,105B,105C,105D,105E,105F,105G,110A,110B,110C,110D,110E,110F,110G"
#define PRICE_BRAND1_PRDCT1 @"48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,48500,78000,48500,48500,48500,48500,48500,48500,78000,48500,48500,48500,48500,48500,48500,78000,48500,48500,48500,48500,48500,48500,78000,78000,78000,56000,56000,56000,78000,78000,78000,78000,56000,56000,56000,78000,78000,78000,78000,78000,78000,78000,78000"
#define SIZE_BRAND1_PRDCT2 @"S,M,L,LL,3L"
#define PRICE_BRAND1_PRDCT2 @"9800,9800,9800,9800,15000"
#define SIZE_BRAND1_PRDCT3 @"S,M,L,LL,3L"
#define PRICE_BRAND1_PRDCT3 @"14000,14000,14000,14000,23000"
#define SIZE_BRAND1_PRDCT4 @"58,64,70,76,82,90,98,106,114,122"
#define PRICE_BRAND1_PRDCT4 @"39500,39500,39500,39500,39500,39500,39500,46000,68000,68000"
#define SIZE_BRAND1_PRDCT5 @"58,64,70,76,82,90,98,106,114,122"
#define PRICE_BRAND1_PRDCT5 @"34000,34000,34000,34000,34000,34000,34000,55000,55000,55000"
#define SIZE_BRAND1_PRDCT6 @"58,64,70,76,82,90,98,106,114,122"
#define PRICE_BRAND1_PRDCT6 @"29000,29000,29000,29000,29000,49000,49000,49000,49000,49000"

#define SIZE_BRAND2_PRDCT1 @"65A,65B,65C,65D,65E,65F,65G,70A,70B,70C,70D,70E,70F,70G,75A,75B,75C,75D,75E,75F,75G,80A,80B,80C,80D,80E,80F,80G,85A,85B,85C,85D,85E,85F,85G,90A,90B,90C,90D,90E,90F,90G,95A,95B,95C,95D,95E,95F,95G,100A,100B,100C,100D,100E,100F,100G,105A,105B,105C,105D,105E,105F,105G,110A,110B,110C,110D,110E,110F,110G"
#define PRICE_BRAND2_PRDCT1 @"53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,53500,85000,53500,53500,53500,53500,53500,53500,85000,85000,53500,53500,53500,53500,53500,85000,85000,85000,63000,63000,63000,85000,85000,85000,85000,63000,63000,63000,85000,85000,85000,85000,63000,63000,63000,85000,85000,85000,85000,85000,85000,85000,85000"
#define SIZE_BRAND2_PRDCT2 @"58,64,70,76,82,90,98,106,114,122"
#define PRICE_BRAND2_PRDCT2 @"36000,36000,36000,36000,36000,36000,36000,58000,58000,58000"
#define SIZE_BRAND2_PRDCT3 @"S,M,L,LL,3L"
#define PRICE_BRAND2_PRDCT3 @"6800,6800,6800,6800,11000"
#define SIZE_BRAND2_PRDCT4 @"-"
#define PRICE_BRAND2_PRDCT4 @"3500"

#define SIZE_BRAND3_PRDCT1 @"65A,65B,65C,65D,65E,65F,65G,70A,70B,70C,70D,70E,70F,70G,75A,75B,75C,75D,75E,75F,75G,80A,80B,80C,80D,80E,80F,80G,85A,85B,85C,85D,85E,85F,85G,90A,90B,90C,90D,90E,90F,90G,95A,95B,95C,95D,95E,95F,95G,100A,100B,100C,100D,100E,100F,100G,105A,105B,105C,105D,105E,105F,105G,110A,110B,110C,110D,110E,110F,110G"
#define PRICE_BRAND3_PRDCT1 @"24000,24000,24000,24000,24000,29000,29000,24000,24000,24000,24000,24000,29000,29000,24000,24000,24000,24000,24000,29000,29000,24000,24000,24000,24000,29000,29000,29000,45000,24000,24000,29000,29000,29000,29000,45000,24000,24000,29000,29000,29000,29000,45000,24000,24000,29000,29000,29000,29000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000,55000"
#define SIZE_BRAND3_PRDCT2 @"58,64,70,76,82,90,98,106,114,122"
#define PRICE_BRAND3_PRDCT2 @"36000,36000,36000,36000,36000,36000,36000,58000,58000,58000"
#define SIZE_BRAND3_PRDCT3 @"65,70,75,80,85,90,95,100,105,110"
#define PRICE_BRAND3_PRDCT3 @"55000,55000,55000,55000,55000,55000,55000,85000,85000,85000"
#define SIZE_BRAND3_PRDCT4 @"65,70,75,80,85,90,95,100,105,110"
#define PRICE_BRAND3_PRDCT4 @"55000,55000,55000,55000,55000,55000,55000,85000,85000,85000"

#define SIZE_BRAND4_PRDCT1 @"58,64,70,76,82,90,98,106,114,122"
#define PRICE_BRAND4_PRDCT1 @"38000,38000,38000,38000,38000,38000,38000,58000,58000,58000"
#define SIZE_BRAND4_PRDCT2 @"58,64,70,76,82,90,98,106,114,122"
#define PRICE_BRAND4_PRDCT2 @"38000,38000,38000,38000,38000,38000,38000,58000,58000,58000"
#define SIZE_BRAND4_PRDCT3 @"S,M,L,LL"
#define PRICE_BRAND4_PRDCT3 @"9800,9800,9800,9800"
#define SIZE_BRAND4_PRDCT4 @"S,M,L,LL"
#define PRICE_BRAND4_PRDCT4 @"11000,11000,11000,11000"
#define SIZE_BRAND4_PRDCT5 @"S,M,L,LL"
#define PRICE_BRAND4_PRDCT5 @"11000,11000,11000,11000"
#define SIZE_BRAND4_PRDCT6 @"S,M,L,LL"
#define PRICE_BRAND4_PRDCT6 @"9500,9500,9500,9500"
#define SIZE_BRAND4_PRDCT7 @"M,L"
#define PRICE_BRAND4_PRDCT7 @"6800,6800"
#define SIZE_BRAND4_PRDCT8 @"-"
#define PRICE_BRAND4_PRDCT8 @"32000"
#define SIZE_BRAND4_PRDCT9 @"-"
#define PRICE_BRAND4_PRDCT9 @"8000"
#define SIZE_BRAND4_PRDCT10 @"S,M,L"
#define PRICE_BRAND4_PRDCT10 @"11000,11000,11000"
#define SIZE_BRAND4_PRDCT11 @"M,L"
#define PRICE_BRAND4_PRDCT11 @"9800,9800"
#define SIZE_BRAND4_PRDCT12 @"M,L,LL"
#define PRICE_BRAND4_PRDCT12 @"9800,9800,9800"
#define SIZE_BRAND4_PRDCT13 @"M,L"
#define PRICE_BRAND4_PRDCT13 @"7500,7500"

#define SIZE_BRAND5_PRDCT1 @"S,M,L,LL,3L"
#define PRICE_BRAND5_PRDCT1 @"33500,33500,33500,33500,43500"
#define SIZE_BRAND5_PRDCT2 @"S,M,L,LL,3L"
#define PRICE_BRAND5_PRDCT2 @"35000,35000,35000,35000,45000"
#define SIZE_BRAND5_PRDCT3 @"S,M,L,LL,3L"
#define PRICE_BRAND5_PRDCT3 @"38000,38000,38000,38000,48000"
#define SIZE_BRAND5_PRDCT4 @"S,M,L,LL,3L"
#define PRICE_BRAND5_PRDCT4 @"17000,17000,17000,17000,27000"
#define SIZE_BRAND5_PRDCT5 @"L,3L特注"
#define PRICE_BRAND5_PRDCT5 @"28000,38000"
#define SIZE_BRAND5_PRDCT6 @"L,3L特注"
#define PRICE_BRAND5_PRDCT6 @"28000,38000"
#define SIZE_BRAND5_PRDCT7 @"S,M,L,LL,3L"
#define PRICE_BRAND5_PRDCT7 @"28000,28000,28000,28000,38000"
#define SIZE_BRAND5_PRDCT8 @"S,M,L,LL,3L"
#define PRICE_BRAND5_PRDCT8 @"28000,28000,28000,28000,38000"
#define SIZE_BRAND5_PRDCT9 @"M,L,LL,3L,4L"
#define PRICE_BRAND5_PRDCT9 @"33500,33500,33500,33500,33500"
#define SIZE_BRAND5_PRDCT10 @"M,L,LL,3L,4L"
#define PRICE_BRAND5_PRDCT10 @"38000,38000,38000,38000,38000"
#define SIZE_BRAND5_PRDCT11 @"M,L,LL,3L,4L"
#define PRICE_BRAND5_PRDCT11 @"15400,15400,15400,15400,15400"
#define SIZE_BRAND5_PRDCT12 @"M,L,LL,3L,4L"
#define PRICE_BRAND5_PRDCT12 @"38500,38500,38500,38500,38500"
#define SIZE_BRAND5_PRDCT13 @"M,L,LL,3L"
#define PRICE_BRAND5_PRDCT13 @"32000,32000,32000,44000"
// 2016/6/24 TMS 商品追加対応
#define SIZE_BRAND5_PRDCT14 @"-"
#define PRICE_BRAND5_PRDCT14 @"9800"
#define SIZE_BRAND5_PRDCT15 @"-"
#define PRICE_BRAND5_PRDCT15 @"25000"
#define SIZE_BRAND5_PRDCT16 @"S,M,L,LL,3L"
#define PRICE_BRAND5_PRDCT16 @"35000,35000,35000,35000,45000"
#define SIZE_BRAND5_PRDCT17 @"XS,S,M,L,LL,3L"
#define PRICE_BRAND5_PRDCT17 @"32000,32000,32000,32000,32000,44000"

#define SIZE_BRAND6_PRDCT1 @"-"
#define PRICE_BRAND6_PRDCT1 @"25000"
#define SIZE_BRAND6_PRDCT2 @"-"
#define PRICE_BRAND6_PRDCT2 @"12000"
#define SIZE_BRAND6_PRDCT3 @"-"
#define PRICE_BRAND6_PRDCT3 @"10000"
#define SIZE_BRAND6_PRDCT4 @"-"
#define PRICE_BRAND6_PRDCT4 @"60000"
#define SIZE_BRAND6_PRDCT5 @"-"
#define PRICE_BRAND6_PRDCT5 @"7800"

// 2016/5/20 TMS 商品・ブランド追加対応
#define SIZE_BRAND7_PRDCT1 @"ｼﾝｸﾞﾙ"
#define PRICE_BRAND7_PRDCT1 @"45000"
#define SIZE_BRAND7_PRDCT2 @"1L"
#define PRICE_BRAND7_PRDCT2 @"35000"
#define SIZE_BRAND7_PRDCT3 @"-"
#define PRICE_BRAND7_PRDCT3 @"9500"
#define SIZE_BRAND7_PRDCT4 @"S,M,L,LL"
#define PRICE_BRAND7_PRDCT4 @"23000,23000,23000,23000"
#define SIZE_BRAND7_PRDCT5 @"ﾌﾘｰ"
#define PRICE_BRAND7_PRDCT5 @"15000"
#define SIZE_BRAND7_PRDCT6 @"ｰ"
#define PRICE_BRAND7_PRDCT6 @"15000"
#define SIZE_BRAND7_PRDCT7 @"S,M,L,LL"
#define PRICE_BRAND7_PRDCT7 @"23000,23000,23000,23000"

#define SIZE_BRAND8_PRDCT1 @"-"
#define PRICE_BRAND8_PRDCT1 @"5000"
#define SIZE_BRAND8_PRDCT2 @"-"
#define PRICE_BRAND8_PRDCT2 @"5000"
#define SIZE_BRAND8_PRDCT3 @"-"
#define PRICE_BRAND8_PRDCT3 @"9500"
#define SIZE_BRAND8_PRDCT4 @"-"
#define PRICE_BRAND8_PRDCT4 @"7000"
#define SIZE_BRAND8_PRDCT5 @"-"
#define PRICE_BRAND8_PRDCT5 @"7000"

#define SIZE_BRAND9_PRDCT1 @"-"
#define PRICE_BRAND9_PRDCT1 @"4600"
#define SIZE_BRAND9_PRDCT2 @"-"
#define PRICE_BRAND9_PRDCT2 @"3700"
#define SIZE_BRAND9_PRDCT3 @"-"
#define PRICE_BRAND9_PRDCT3 @"6400"
#define SIZE_BRAND9_PRDCT4 @"-"
#define PRICE_BRAND9_PRDCT4 @"6400"
#define SIZE_BRAND9_PRDCT5 @"-"
#define PRICE_BRAND9_PRDCT5 @"750"
#define SIZE_BRAND9_PRDCT6 @"-"
#define PRICE_BRAND9_PRDCT6 @"750"

#define SIZE_BRAND10_PRDCT1 @"-"
#define PRICE_BRAND10_PRDCT1 @"6700"
#define SIZE_BRAND10_PRDCT2 @"-"
#define PRICE_BRAND10_PRDCT2 @"5700"
#define SIZE_BRAND10_PRDCT3 @"-"
#define PRICE_BRAND10_PRDCT3 @"15000"
#define SIZE_BRAND10_PRDCT4 @"-"
#define PRICE_BRAND10_PRDCT4 @"8600"
#define SIZE_BRAND10_PRDCT5 @"-"
#define PRICE_BRAND10_PRDCT5 @"8000"
#define SIZE_BRAND10_PRDCT6 @"-"
#define PRICE_BRAND10_PRDCT6 @"6000"
#define SIZE_BRAND10_PRDCT7 @"-"
#define PRICE_BRAND10_PRDCT7 @"11000"
#define SIZE_BRAND10_PRDCT8 @"-"
#define PRICE_BRAND10_PRDCT8 @"3600"
#define SIZE_BRAND10_PRDCT9 @"-"
#define PRICE_BRAND10_PRDCT9 @"5000"
#define SIZE_BRAND10_PRDCT10 @"-"
#define PRICE_BRAND10_PRDCT10 @"5000"
#define SIZE_BRAND10_PRDCT11 @"-"
#define PRICE_BRAND10_PRDCT11 @"18000"
#define SIZE_BRAND10_PRDCT12 @"-"
#define PRICE_BRAND10_PRDCT12 @"19800"
#define SIZE_BRAND10_PRDCT13 @"-"
#define PRICE_BRAND10_PRDCT13 @"6000"
#define SIZE_BRAND10_PRDCT14 @"-"
#define PRICE_BRAND10_PRDCT14 @"7500"
#define SIZE_BRAND10_PRDCT15 @"-"
#define PRICE_BRAND10_PRDCT15 @"5000"

//カラー
#define COLOR_BRAND1_PRDCT1 @"ｺｰﾗﾙｼｬﾝﾊﾟﾝ,ﾍﾞｲﾋﾞｰﾋﾟﾝｸ,ﾐｽﾃｨﾌﾞﾗｯｸ,LOVE,ﾌﾞﾙｰｼﾞｰﾝ,ｵﾘｰｳﾞ,ﾎﾜｲﾄ"
#define COLOR_BRAND1_PRDCT2 @"ｺｰﾗﾙｼｬﾝﾊﾟﾝ,ﾍﾞｲﾋﾞｰﾋﾟﾝｸ,ﾌﾞﾙｰﾑｰﾝ,ﾌﾞﾗｯｸ,LOVE,ﾌﾞﾙｰｼﾞｰﾝ,ｵﾘｰｳﾞ,ｴﾝｼﾞｪﾙ,ﾁｪﾘｰ,ｶﾌｪｵｰﾚ,ﾎﾜｲﾄxﾌﾞﾗｯｸ,ｷｭｰﾃｨﾐﾝﾄ"
#define COLOR_BRAND1_PRDCT3 @"ﾛｰｽﾞ,ﾌﾞﾗｯｸ"
#define COLOR_BRAND1_PRDCT4 @"ｺｰﾗﾙｼｬﾝﾊﾟﾝ,ﾍﾞｲﾋﾞｰﾋﾟﾝｸ,LOVE,ﾌﾞﾙｰｼﾞｰﾝ,ﾐｽﾃｨﾌﾞﾗｯｸ,ｵﾘｰｳﾞ,ﾎﾜｲﾄ"
#define COLOR_BRAND1_PRDCT5 @"ﾐｽﾃｨﾌﾞﾗｯｸ"
#define COLOR_BRAND1_PRDCT6 @"ﾐｽﾃｨﾌﾞﾗｯｸ,ﾍﾞｲﾋﾞｰﾋﾟﾝｸ,ｵﾘｰｳﾞ"

#define COLOR_BRAND2_PRDCT1 @"ｷｭｰﾃｨｰﾐﾝﾄ,ﾌﾞﾙｰﾑｰﾝ,ｴﾝｼﾞｪﾙ,ﾎﾜｲﾄxﾌﾞﾗｯｸ"
#define COLOR_BRAND2_PRDCT2 @"ｷｭｰﾃｨｰﾐﾝﾄ,ﾌﾞﾙｰﾑｰﾝ,ｴﾝｼﾞｪﾙ,ﾎﾜｲﾄxﾌﾞﾗｯｸ"
#define COLOR_BRAND2_PRDCT3 @"ｺｰﾗﾙｼｬﾝﾊﾟﾝ,ﾍﾞｲﾋﾞｰﾋﾟﾝｸ,ｷｭｰﾃｨｰﾐﾝﾄ,ﾌﾞﾙｰﾑｰﾝ,LOVE,ﾌﾞﾙｰｼﾞｰﾝ,ｵﾘｰｳﾞ,ｴﾝｼﾞｪﾙ,ﾁｪﾘｰ,ﾎﾜｲﾄxﾌﾞﾗｯｸ,ｶﾌｪｵｰﾚ,ﾌﾞﾗｯｸ"
#define COLOR_BRAND2_PRDCT4 @"-"

#define COLOR_BRAND3_PRDCT1 @"ﾌﾞﾙｰﾑｰﾝ,ｶﾌｪｵｰﾚ,ﾌﾞﾗｯｸ,ﾁｪﾘｰ"
#define COLOR_BRAND3_PRDCT2 @"ﾌﾞﾙｰﾑｰﾝ,ｶﾌｪｵｰﾚ,ﾌﾞﾗｯｸ,ﾁｪﾘｰ"
#define COLOR_BRAND3_PRDCT3 @"ﾌﾞﾙｰﾑｰﾝ,ｶﾌｪｵｰﾚ"
#define COLOR_BRAND3_PRDCT4 @"ﾌﾞﾗｯｸ,ｶﾌｪｵｰﾚ,ﾁｪﾘｰ,ﾌﾞﾙｰﾑｰﾝ"

#define COLOR_BRAND4_PRDCT1 @"ﾌﾞﾗｯｸxﾌﾞﾙｰ,ﾌﾞﾗｯｸxﾌﾞﾗｯｸ,ｼｮｺﾗﾌﾞﾗｳﾝ"
#define COLOR_BRAND4_PRDCT2 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND4_PRDCT3 @"ﾇｰﾄﾞﾍﾞｰｼﾞｭ,ﾌﾞﾗｯｸ"
#define COLOR_BRAND4_PRDCT4 @"ﾇｰﾄﾞﾍﾞｰｼﾞｭ"
#define COLOR_BRAND4_PRDCT5 @"ﾌﾞﾗｯｸ,紺,ﾌﾟﾙｰﾝ,ﾁｬｺｰﾙ,ﾄﾏﾄ,ﾎﾞﾙﾄﾞｰ,ｲﾝﾃﾞｨｺﾞ"
#define COLOR_BRAND4_PRDCT6 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND4_PRDCT7 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND4_PRDCT8 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND4_PRDCT9 @"ー"
#define COLOR_BRAND4_PRDCT10 @"ﾌﾞﾗｯｸ,ﾎﾜｲﾄ"
#define COLOR_BRAND4_PRDCT11 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND4_PRDCT12 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND4_PRDCT13 @"ﾌﾞﾗｯｸ,ﾇｰﾄﾞﾍﾞｰｼﾞｭ"

#define COLOR_BRAND5_PRDCT1 @"ﾌﾞﾗｯｸ,ﾎﾜｲﾄ"
#define COLOR_BRAND5_PRDCT2 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT3 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT4 @"ﾌﾞﾗｯｸ,ﾗﾌﾞﾘｰﾚｯﾄﾞ"
#define COLOR_BRAND5_PRDCT5 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT6 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT7 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT8 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT9 @"ﾌﾞﾗｯｸ,ﾎﾜｲﾄ"
#define COLOR_BRAND5_PRDCT10 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT11 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT12 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT13 @"ﾌﾞﾗｯｸ"
// 2016/6/24 TMS 商品追加対応
#define COLOR_BRAND5_PRDCT14 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT15 @"ﾁｬｺｰﾙxﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT16 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND5_PRDCT17 @"ﾌﾞﾗｯｸ"

#define COLOR_BRAND6_PRDCT1 @"-"
#define COLOR_BRAND6_PRDCT2 @"-"
#define COLOR_BRAND6_PRDCT3 @"-"
#define COLOR_BRAND6_PRDCT4 @"-"
#define COLOR_BRAND6_PRDCT5 @"-"

// 2016/5/20 TMS 商品・ブランド追加対応
#define COLOR_BRAND7_PRDCT1 @"-"
#define COLOR_BRAND7_PRDCT2 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND7_PRDCT3 @"-"
#define COLOR_BRAND7_PRDCT4 @"ﾌﾞﾗｯｸ"
#define COLOR_BRAND7_PRDCT5 @"-"
#define COLOR_BRAND7_PRDCT6 @"ｸﾞﾚｰ･ﾋﾟﾝｸ"
#define COLOR_BRAND7_PRDCT7 @"ﾌﾞﾗｯｸ"

#define COLOR_BRAND8_PRDCT1 @"-"
#define COLOR_BRAND8_PRDCT2 @"-"
#define COLOR_BRAND8_PRDCT3 @"-"
#define COLOR_BRAND8_PRDCT4 @"-"
#define COLOR_BRAND8_PRDCT5 @"-"

#define COLOR_BRAND9_PRDCT1 @"-"
#define COLOR_BRAND9_PRDCT2 @"-"
#define COLOR_BRAND9_PRDCT3 @"-"
#define COLOR_BRAND9_PRDCT4 @"-"
#define COLOR_BRAND9_PRDCT5 @"-"
#define COLOR_BRAND9_PRDCT6 @"-"

#define COLOR_BRAND10_PRDCT1 @"-"
#define COLOR_BRAND10_PRDCT2 @"-"
#define COLOR_BRAND10_PRDCT3 @"-"
#define COLOR_BRAND10_PRDCT4 @"-"
#define COLOR_BRAND10_PRDCT5 @"-"
#define COLOR_BRAND10_PRDCT6 @"-"
#define COLOR_BRAND10_PRDCT7 @"-"
#define COLOR_BRAND10_PRDCT8 @"-"
#define COLOR_BRAND10_PRDCT9 @"-"
#define COLOR_BRAND10_PRDCT10 @"-"
#define COLOR_BRAND10_PRDCT11 @"-"
#define COLOR_BRAND10_PRDCT12 @"-"
#define COLOR_BRAND10_PRDCT13 @"-"
#define COLOR_BRAND10_PRDCT14 @"-"
#define COLOR_BRAND10_PRDCT15 @"-"

@interface grantFmdbManager : NSObject
{
    NSString *dbPath;
    NSMutableArray*    sizeList;
    NSMutableArray*    colorList;
}
//初期化(コンストラクタ)
- (id)init;
// データベースに接続
- (FMDatabase *) databaseConnect;
//データベースの初期化
- (BOOL)initDataBase;
/**
 商品マスタにデータを登録
 */
- (BOOL) insertProductMst:(NSMutableArray *)productList;
/**
 サイズマスタにデータを登録
 */
- (BOOL) insertSizeMst:(NSMutableArray *)sizeList;
/**
 カラーマスタにデータを登録
 */
- (BOOL) insertColorMst:(NSMutableArray *)colorList;
/**
 ブランドマスタにデータを登録
 */
- (BOOL) insertBrandMst:(NSMutableArray *)brandList;
/**
 価格マスタにデータを登録
 */
- (BOOL) insertPriceMst:(NSMutableArray *)priceList;
/**
 商品マスタよりデータを取得
 */
- (NSMutableArray*) getProductMst:(NSInteger)brand_id;
/**
 サイズマスタよりデータを取得
 */
- (NSMutableArray*) getSizeMst:(NSInteger)product_id;
/**
 カラーマスタよりデータを取得
 */
- (NSMutableArray*) getColorMst:(NSInteger)product_id;
/**
 ブランドマスタよりデータを取得
 */
- (NSMutableArray*) getBrandMst;
/**
 価格マスタよりデータを取得
 */
- (NSMutableArray*) getPriceMst : (NSInteger)product_id : (NSInteger)size_id;
/**
 ブランドデータを用意
 */
-(NSMutableArray*)getBrandData;
/**
 サイズデータを用意
 */
-(void)setSizeData;
/**
 カラーデータを用意
 */
-(void)setColorData;
/**
 商品データを用意
 */
-(NSMutableArray*)getPrdctData : (NSInteger)brand_id : (NSInteger)cnt;
@end