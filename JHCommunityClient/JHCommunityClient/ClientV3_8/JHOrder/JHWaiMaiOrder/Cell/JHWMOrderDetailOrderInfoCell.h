//
//  JHWMDetailOrderInfoCell.h
//  JHCommunityClient
//
//  Created by ios_yangfei on 2018/5/22.
//  Copyright © 2018年 JiangHu. All rights reserved.
//

#import "YFBaseTableViewCell.h"
#import "JHWaiMaiModel.h"

@interface JHWMOrderDetailOrderInfoCell : YFBaseTableViewCell

-(void)reloadCellWithInfo:(JHWaiMaiModel *)orderInfo;
@end