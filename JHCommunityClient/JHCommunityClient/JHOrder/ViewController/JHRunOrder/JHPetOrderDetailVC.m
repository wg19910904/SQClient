//
//  JHPetOrderDetailVC.m
//  JHCommunityClient
//
//  Created by ijianghu on 16/3/14.
//  Copyright © 2016年 JiangHu. All rights reserved.
//

#import "JHPetOrderDetailVC.h"
#import "JHPetOrderDetailCellOne.h"
#import "JHPetOrderDetailCellTwo.h"
#import "JHPetOrderDetailCellThree.h"
#import "JHPetOrderDetailCellFour.h"
#import <MJRefresh.h>
#import <MAMapKit/MAMapKit.h>
 
#import "JHRunDetailModel.h"
#import "JHRunProgressModel.h"
#import "JHWMPayOrderVC.h"
#import "JHPersonEvaluationVC.h"
#import "JHPersonComplainVC.h"
#import <AVFoundation/AVFoundation.h>
#import "JHPEvaluateVC.h"
#import "JHRunVC.h"
#import "JHRunOederListViewController.h"
#import "UILabel+XHTool.h"
@interface JHPetOrderDetailVC ()<UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate,AVAudioPlayerDelegate>

{
    UIButton * oldBtn;//指向旧的按钮
    UILabel * label_seleter;//选中的显示条
    UIScrollView * myScrollview;//创建底部的scrollview
    NSMutableArray * btnArray;//存放两个btn的
    BOOL isMove;//判断是否是滑动
    UITableView * myTableView_order;//指向订单进度的表
    UITableView * myTableView_detail;//指向订单详情的表
    float height;
    UIImageView * imageView;
    NSMutableArray * array;//填充假数据的
    MJRefreshNormalHeader * _header;//刷新订单详情的
    MJRefreshNormalHeader * _headerOrder;//刷新订单进度的
    int num;
    NSArray * lieArray;
    XHMapView * _mapView;
    BOOL isYes;
    BOOL isFirst_progress;
    BOOL isFirst_detail;
    UIButton * btn_getMore;
    JHRunDetailModel * model_detail;
    JHRunProgressModel * model_progress;
    AVAudioPlayer * _player;
    BOOL isCall;
    NSInteger position;
    UIButton * btn_call;
    NSString * phone;//订单进度那个电话号码
    float lat;//当前的外卖的纬度
    float lng;//当前的外卖的经度
    BOOL _isPet;
}
@end
@implementation JHPetOrderDetailVC

//重写返回的方法
-(void)clickBackBtn{
    NSArray <JHBaseVC *>*vcArray = self.navigationController.viewControllers;
    for (JHBaseVC *obj in vcArray) {
        if([obj isKindOfClass:[JHRunOederListViewController class]]){
            _isPet = YES;
            [self.navigationController popToViewController:obj animated:YES];
            
        }else if ([obj isKindOfClass:[JHRunVC class]]){
            _isPet = YES;
            [self.navigationController popToViewController:obj animated:YES];
        }
        
    }
    if(!_isPet){
        [self.navigationController popToRootViewControllerAnimated:YES];
    }

}
- (void)viewDidLoad {
    [super viewDidLoad];
    num = 9;
    self.navigationItem.title = NSLocalizedString(@"我的订单", nil);
    btnArray = [NSMutableArray array];
    //创建头部的两个按钮
    [self creatHeaderView];
    //创建底部的view
    [self creatButtomView];
    //创建中间的Scrollview
    [self creatUIScrollView];
    SHOW_HUD
    //订单进度的请求
    [self postProgressHtttp];
}
#pragma mark 发送订单进度的请求
-(void)postProgressHtttp{
    NSDictionary * dic = @{@"order_id":self.order_id};
    [HttpTool postWithAPI:@"client/member/order/log" withParams:dic success:^(id json) {
        NSLog(@"%@",json);
        if ([json[@"error"] isEqualToString:@"0"]) {
            HIDE_HUD
            model_progress = [JHRunProgressModel creatJHRunProgressModelWithDictionary:json[@"data"][@"log"]];
            if (!isFirst_progress) {
                [myScrollview addSubview:myTableView_order];
                isFirst_progress = YES;
            }
            [self judgeBtnState:btn_getMore];
            for (int i = 0; i < model_progress.modelArray.count;i++) {
                JHRModel * model = model_progress.modelArray[i];
                if ([model.from isEqualToString:@"staff"]) {
                    position = i +1;
                    phone = model_progress.mobile_staff;
                    lat = [model_progress.lat_staff floatValue];
                    lng = [model_progress.lng_staff floatValue];
                }else if ([model.from isEqualToString:@"shop"]){
                    position = i+1;
                    phone = model_progress.mobile_shop;
                    lat = [model_progress.lat_shop floatValue];
                    lng = [model_progress.lng_shop floatValue];
                }
            }
            [myTableView_order reloadData];
            [_headerOrder endRefreshing];
        }else{
            HIDE_HUD
            [self creatUIAlertControlWithMessage:json[@"message"]?json[@"message"]:NSLocalizedString(@"连接服务器出错,请稍后重试", nil)];
        }
    } failure:^(NSError *error) {
        HIDE_HUD
        [_headerOrder endRefreshing];
        [self creatUIAlertControlWithMessage:NSLocalizedString(@"连接服务器出错,请稍后重试", nil)];
        NSLog(@"%@",error.localizedDescription);
    }];
}
#pragma mark - 发送订单详情的方法
-(void)postDetailHttp{
    NSDictionary * dic = @{@"order_id":self.order_id};
    [HttpTool postWithAPI:@"client/member/order/detail" withParams:dic success:^(id json) {
        NSLog(@"%@",json);
        if ([json[@"error"] isEqualToString:@"0"]) {
            HIDE_HUD
            model_detail = [JHRunDetailModel creatJHRunDetailModelWithDictionary:json[@"data"][@"order"]];
            if (!isFirst_detail) {
                [myScrollview addSubview:myTableView_detail];
                isFirst_detail = YES;
            }
            if(([model_detail.order_status intValue] == 0 && [model_detail.pay_status intValue] == 0)||([model_detail.order_status intValue] == -1&&[model_detail.pay_status intValue] == 0)){
                num = 10;
            }else if ([model_detail.order_status intValue] == 0||([model_detail.order_status intValue] == -1&&[model_detail.pay_status intValue] == 1)){
                num = 10;
            }else if ([model_detail.order_status integerValue] == 3||[model_detail.order_status integerValue] == 8){
                num = 16;
            }
            else if ([model_detail.order_status integerValue] > 3){
                num = 16;
            }
            NSString *totalText = NSLocalizedString(@"跑腿费用(已支付)", nil);
            if (model_detail.hongbao.floatValue > 0) {
                totalText = [NSString stringWithFormat:NSLocalizedString(@"跑腿费用(已支付) 红包抵扣 ¥%@", nil),model_detail.hongbao];
            }
            array = [NSMutableArray arrayWithObjects:@"",@"",NSLocalizedString(@"跑腿类别:宠物照顾", nil),
                     [NSString stringWithFormat: NSLocalizedString(@"订单ID:%@", nil),model_detail.order_id],
                     [NSString stringWithFormat:NSLocalizedString(@"联系人:%@", nil),model_detail.contact],
                     [NSString stringWithFormat:NSLocalizedString(@"联系电话:%@", nil),model_detail.mobile],
                     [NSString stringWithFormat:NSLocalizedString(@"服务地址:%@", nil),model_detail.addr],
                     [NSString stringWithFormat:NSLocalizedString(@"服务时间:%@", nil),model_detail.time],@"",@"",
                     NSLocalizedString(@"服务人员信息", nil),
                     [NSString stringWithFormat:NSLocalizedString(@"联系人:%@", nil),model_detail.o_name],
                     [NSString stringWithFormat:NSLocalizedString(@"联系电话:%@", nil),model_detail.o_mobile],
                     @"",@"",
                     totalText,nil];
            [self judgeBtnState:btn_getMore];
            [myTableView_detail reloadData];
            [_header endRefreshing];
        }else{
            HIDE_HUD
            [self creatUIAlertControlWithMessage:json[@"message"]?json[@"message"]:NSLocalizedString(@"连接服务器出错,请稍后重试", nil)];
        }
    } failure:^(NSError *error) {
        HIDE_HUD
        [_header endRefreshing];
        NSLog(@"%@",error.localizedDescription);
        [self creatUIAlertControlWithMessage:NSLocalizedString(@"连接服务器出错,请稍后重试", nil)];
    }];
}
#pragma mark - 创建头部的按钮
-(void)creatHeaderView{
    UIView * view = [[UIView alloc]init];
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];
    view.frame = FRAME(0, NAVI_HEIGHT, WIDTH, 40);
    for (int i = 0; i < 2; i ++) {
        UIButton * btn = [[UIButton alloc]init];
        btn.frame = FRAME(WIDTH/2*i+0.5, 0, WIDTH/2-0.5, 40);
        [view addSubview:btn];
        if (i == 0) {
            btn.selected = YES;
            oldBtn = btn;
            [btn setTitle:NSLocalizedString(@"订单进度", nil) forState:UIControlStateNormal];
        }else{
            [btn setTitle:NSLocalizedString(@"订单详情", nil) forState:UIControlStateNormal];
        }
        btn.tag = i;
        [btn setTitleColor:THEME_COLOR forState:UIControlStateSelected];
        [btn setTitleColor:[UIColor colorWithWhite:0.4 alpha:1] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnChange:) forControlEvents:UIControlEventTouchUpInside];
        [btnArray addObject:btn];
    }
    //创建底部的分割线
    UIView * label_buttom = [[UIView alloc]init];
    label_buttom.frame = FRAME(0, 39.5, WIDTH, 0.5);
    label_buttom.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [view addSubview:label_buttom];
    //创建选中时的绿色的显示条
    label_seleter = [[UILabel alloc]init];
    label_seleter.frame = FRAME(0, 39, WIDTH/2, 1);
    label_seleter.backgroundColor = THEME_COLOR;
    [view addSubview:label_seleter];
}
#pragma mark - 这是点击头部按钮的方法
-(void)btnChange:(UIButton *)sender{
    isMove = NO;
    oldBtn.selected = NO;
    sender.selected = !sender.selected;
    oldBtn = sender;
    if (!isMove) {
    [UIView animateWithDuration:0.1 animations:^{
        label_seleter.frame = FRAME(WIDTH/2*sender.tag, 39, WIDTH/2, 1);
    }];
    [UIView animateWithDuration:0.3 animations:^{
        myScrollview.contentOffset = CGPointMake(WIDTH*sender.tag, 0);
    }];
        if(sender.tag == 1){
            if (!isFirst_detail) {
                SHOW_HUD
                [self postDetailHttp];
            }
   
        }
    }
}
#pragma mark - 这是创建底部的view的方法
-(void)creatButtomView{
    UIView * view = [[UIView alloc]init];
    view.frame = FRAME(0, HEIGHT - 60, WIDTH, 60);
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];
    //创建分割线
    UIView * view_line = [[UIView alloc]init];
    view_line.frame = FRAME(0, 0, WIDTH, 0.5);
    view_line.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    [view addSubview:view_line];
    //创建再来一单的按钮
    btn_getMore = [UIButton buttonWithType:UIButtonTypeCustom];
    btn_getMore.frame = FRAME(WIDTH - 115, 10, 100, 40);
    [view addSubview:btn_getMore];
    btn_getMore.layer.cornerRadius  = 2;
    btn_getMore.layer.masksToBounds = YES;
    [btn_getMore addTarget:self action:@selector(clickToMore:) forControlEvents:UIControlEventTouchUpInside];
    //创建投诉的按钮
    UIButton * btn_complain = [UIButton buttonWithType:UIButtonTypeCustom];
    btn_complain.frame = FRAME(10, 1, 60, 59);
    //btn_complain.backgroundColor = [UIColor orangeColor];
    [view addSubview:btn_complain];
    UIImageView * imageV_complain = [[UIImageView alloc]init];
    //imageV_complain.backgroundColor =[UIColor redColor];
    imageV_complain.image = [UIImage imageNamed:@"complain"];
    imageV_complain.frame = FRAME(15, 10, 25, 25);
    [btn_complain addSubview:imageV_complain];
    UILabel * label_complain = [[UILabel alloc]init];
    label_complain.frame = FRAME(0, 40, 55, 15);
    label_complain.textColor = [UIColor colorWithWhite:0.6 alpha:1];
    label_complain.textAlignment = NSTextAlignmentCenter;
    label_complain.text = NSLocalizedString(@"投诉", nil);
    label_complain.font = [UIFont systemFontOfSize:14];
    [btn_complain addSubview:label_complain];
    [btn_complain addTarget:self action:@selector(clicktoComplain) forControlEvents:UIControlEventTouchUpInside];
    //创建中间的分割线
    UILabel * label_lineOne = [[UILabel alloc]init];
    label_lineOne.frame = FRAME(80, 10, 1, 40);
    label_lineOne.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    [view addSubview:label_lineOne];
    //创建催单的按纽
    UIButton * btn_cuidan = [UIButton buttonWithType:UIButtonTypeCustom];
    btn_cuidan.frame = FRAME(91, 1, 60, 59);
    [view addSubview:btn_cuidan];
    UIImageView * imageV_cuidan = [[UIImageView alloc]init];
    //imageV_cuidan.backgroundColor = [UIColor redColor];
    imageV_cuidan.image = [UIImage imageNamed:@"cui"];
    imageV_cuidan.frame = FRAME(15, 10, 25, 25);
    [btn_cuidan addSubview:imageV_cuidan];
    UILabel * label_cuidan = [[UILabel alloc]init];
    label_cuidan.frame = FRAME(0, 40, 55, 15);
    label_cuidan.textColor = [UIColor colorWithWhite:0.6 alpha:1];
    label_cuidan.textAlignment = NSTextAlignmentCenter;
    label_cuidan.text = NSLocalizedString(@"催单", nil);
    label_cuidan.font = [UIFont systemFontOfSize:14];
    [btn_cuidan addSubview:label_cuidan];
    [btn_cuidan addTarget:self action:@selector(clicktoCuiDan) forControlEvents:UIControlEventTouchUpInside];
    //创建分割线
    UILabel * label_lineTwo = [[UILabel alloc]init];
    label_lineTwo.frame = FRAME(160, 10, 1, 40);
    label_lineTwo.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    [view addSubview:label_lineTwo];
}
#pragma mark - 这是创建中间的滑动视图的方法
-(void)creatUIScrollView{
    myScrollview  = [[UIScrollView alloc]initWithFrame:CGRectMake(0, NAVI_HEIGHT+40, WIDTH, HEIGHT - NAVI_HEIGHT-60-40)];
    myScrollview.pagingEnabled = YES;
    myScrollview.bounces = NO;
    myScrollview.showsHorizontalScrollIndicator = NO;
    myScrollview.showsVerticalScrollIndicator = NO;
    myScrollview.delegate = self;
    myScrollview.contentSize = CGSizeMake(WIDTH*2, HEIGHT - NAVI_HEIGHT-60-40);
    [self.view addSubview:myScrollview];
    for (int i = 0; i<2; i++) {
        UITableView *   myTableView = [[UITableView alloc]init];
        myTableView.frame = CGRectMake(WIDTH*i, 0, WIDTH, HEIGHT - NAVI_HEIGHT-60-40);
        myTableView.tableFooterView = [UIView new];
        myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        myTableView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
        myTableView.showsVerticalScrollIndicator = NO;
        if(i == 0){
            myTableView_order = myTableView;
            [myTableView_order registerClass:[JHPetOrderDetailCellOne class] forCellReuseIdentifier:@"cell"];
            [myTableView_order registerClass:[JHPetOrderDetailCellTwo class] forCellReuseIdentifier:@"cell2"];
            _headerOrder = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(downRefreshForOrder)];
            _headerOrder.lastUpdatedTimeLabel.hidden = YES;
            [_headerOrder setTitle:NSLocalizedString(@"下拉可以刷新", nil) forState:MJRefreshStateIdle];
            [_headerOrder setTitle:NSLocalizedString(@"现在可以刷新啦", nil) forState:MJRefreshStatePulling];
            [_headerOrder setTitle:NSLocalizedString(@"正在为您努力刷新中", nil) forState:MJRefreshStateRefreshing];
            _headerOrder.stateLabel.textColor = [UIColor colorWithRed:129/255.0 green:129/255.0 blue:129/255.0 alpha:1];
            myTableView_order.mj_header = _headerOrder;
        }else{
            myTableView_detail = myTableView;
            [myTableView_detail registerClass:[JHPetOrderDetailCellThree class] forCellReuseIdentifier:@"cell3"];
            [myTableView_detail registerClass:[JHPetOrderDetailCellFour class] forCellReuseIdentifier:@"cell4"];
            _header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(downRefreshForDetail)];
            _header.lastUpdatedTimeLabel.hidden = YES;
            [_header setTitle:NSLocalizedString(@"下拉可以刷新", nil) forState:MJRefreshStateIdle];
            [_header setTitle:NSLocalizedString(@"现在可以刷新啦", nil) forState:MJRefreshStatePulling];
            [_header setTitle:NSLocalizedString(@"正在为您努力刷新中", nil) forState:MJRefreshStateRefreshing];
            _header.stateLabel.textColor = [UIColor colorWithRed:129/255.0 green:129/255.0 blue:129/255.0 alpha:1];
            myTableView_detail.mj_header = _header;
        }
        [myTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell1"];
        myTableView.delegate = self;
        myTableView.dataSource = self;
    }
}
#pragma mark - 这是scrollview的代理方法
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    isMove = YES;
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    NSLog(@"%f",scrollView.contentOffset.x);
    if (isMove) {
        if (scrollView == myScrollview) {
            if (scrollView.contentOffset.x < WIDTH/2) {
                oldBtn.selected = NO;
                UIButton * btn = btnArray[0];
                btn.selected = YES;
                oldBtn = btn;
            }else {
                oldBtn.selected = NO;
                UIButton * btn = btnArray[1];
                btn.selected = YES;
                oldBtn = btn;
                if (!isFirst_detail&&scrollView.contentOffset.x == WIDTH) {
                    SHOW_HUD
                    [self postDetailHttp];
                }
            }
            label_seleter.frame = FRAME(scrollView.contentOffset.x/2, 39, WIDTH/2, 1);
        }
        
    }
    
}

#pragma mark - 这是表格的代理和数据源方法
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == myTableView_order) {
        return 2 + model_progress.modelArray.count;
    }else{
        if(([model_detail.order_status intValue] == 0 && [model_detail.pay_status intValue] == 0)||([model_detail.order_status intValue] == -1&&[model_detail.pay_status intValue] == 0)){
            return 10;
        }else if ([model_detail.order_status intValue] == 0||([model_detail.order_status intValue] == -1&&[model_detail.pay_status intValue] == 1)){
            return 10;
        }else if ([model_detail.order_status integerValue] >= 3 ){
            return 16;
        }else{
            return 10;
        }

    }
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == myTableView_order) {
        if (indexPath.row == 0) {
            return 60;
        }else if (indexPath.row == 1){
            if (isYes) {
                return 150;
            }else{
                return 15;
            }
            
        }else{
            return 80;
        }
    }else{
        if (indexPath.row == 0) {
            return 60;
        }else if (indexPath.row == 1 || indexPath.row == 14){
            return 15;
        }else if (indexPath.row == 13){
            return 0;
        }
        else if (indexPath.row == 8){
            if (height == 0) {
                NSString * string = model_detail.intro;
                CGSize size = [string boundingRectWithSize:CGSizeMake(WIDTH - 30, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]} context:nil].size;
                height = size.height;
            }
            if (model_detail.photo) {
                return height + 155;
            }else{
                return height + 80;
            }

        }else if (indexPath.row == 9){
            if (num > 14) {
                return 0;
            }else{
                return 40;
            }
        }
        else{
            return 40;
        }
    }
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == myTableView_order) {
        if (indexPath.row == 0) {
            JHPetOrderDetailCellOne * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
            cell.model = model_progress;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.btn addTarget:self action:@selector(clickToDoThings:) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }else if (indexPath.row == 1){
            if (isYes) {
                UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell1" forIndexPath:indexPath];
                //添加地图
                [self creatMapViewWithCell:cell];
                return cell;
            }else{
                [_mapView removeFromSuperview];
                _mapView = nil;
                UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell1" forIndexPath:indexPath];
                cell.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                return cell;
            }

        }
        else{
            JHPetOrderDetailCellTwo * cell = [tableView dequeueReusableCellWithIdentifier:@"cell2" forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.indexPath = indexPath;
            cell.model= model_progress;
//            if (indexPath.row == position+1) {
//                if (btn_call) {
//                    [btn_call removeFromSuperview];
//                    btn_call = nil;
//                }
//                if (btn_call == nil) {
//                    btn_call = [[UIButton alloc]init];
//                    btn_call.frame = FRAME(WIDTH - 50, 20, 40, 40);
//                    [cell addSubview:btn_call];
//                    [btn_call setImage:[UIImage imageNamed:@"phone01"] forState:UIControlStateNormal];
//                }
//            }
//            btn_call.tag = indexPath.row;
//            [btn_call addTarget:self action:@selector(clickToCall) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }
    }else{
        if (indexPath.row == 0) {
            JHPetOrderDetailCellThree * cell = [tableView dequeueReusableCellWithIdentifier:@"cell3" forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.model = model_detail;
            [cell.btn addTarget:self action:@selector(clickToback) forControlEvents:UIControlEventTouchUpInside];
            return cell;
        }else if (indexPath.row == 1||indexPath.row==14){
            UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell1" forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
            return cell;
        }else if (indexPath.row == 8){
            JHPetOrderDetailCellFour * cell = [tableView dequeueReusableCellWithIdentifier:@"cell4" forIndexPath:indexPath];
            cell.voice = model_detail.voice;
            cell.voice_time = model_detail.voice_time;
            cell.photo = model_detail.photo;
            cell.height = height;
            cell.label_request.text = model_detail.intro;
            UITapGestureRecognizer * tapGuester = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickToPlay:)];
            cell.imageVoice.userInteractionEnabled = YES;
            [cell.imageVoice addGestureRecognizer:tapGuester];
            cell.animationImage.image = [UIImage imageNamed:@"sy1"];
            cell.animationImage.animationImages = [NSArray arrayWithObjects:
                                                   [UIImage imageNamed:@"sy3"],
                                                   [UIImage imageNamed:@"sy2"],
                                                   [UIImage imageNamed:@"sy1"],nil];
            cell.animationImage.animationDuration = 1;
            cell.animationImage.animationRepeatCount = 0;
            imageView = cell.animationImage;
            return cell;
        }else if (indexPath.row == 9){
            static NSString * identifier = @"cel";
            UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = @"";
            if (cell == nil) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
            }
            if(num <= 10){
                NSString *hongbaoStr = [NSString stringWithFormat:NSLocalizedString(@" 红包抵扣 ¥%@", nil),model_detail.hongbao];
                if([model_detail.pay_status integerValue] == 0){
                    cell.textLabel.text = NSLocalizedString(@"跑腿费用(未支付)", nil);
                    NSString *totalText = cell.textLabel.text;
                    if (model_detail.hongbao.floatValue > 0) {
                        cell.textLabel.text = [totalText stringByAppendingString:hongbaoStr];
                    }
                }else if([model_detail.pay_status integerValue] == 1){
                    cell.textLabel.text = NSLocalizedString(@"跑腿费用(已支付)", nil);
                    NSString *totalText = cell.textLabel.text;
                    if (model_detail.hongbao.floatValue > 0) {
                        cell.textLabel.text = [totalText stringByAppendingString:hongbaoStr];
                    }
                }
                cell.textLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
                [cell.textLabel setColor:HEX(@"ff3300", 1) string:hongbaoStr];
                [cell.textLabel setFont:FONT(13) string:hongbaoStr];
                cell.textLabel.font = [UIFont systemFontOfSize:15];
                cell.detailTextLabel.font =[UIFont systemFontOfSize:13];
                cell.detailTextLabel.textColor = [UIColor orangeColor];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"¥ %@",model_detail.total_price];
            }
            //添加分割线
            UIView * view = [cell viewWithTag:1000];
            [view removeFromSuperview];
            view = nil;
            UIView * label = [[UIView alloc]init];
            label.frame = FRAME(0, 39.5, WIDTH, 0.5);
            label.tag = 1000;
            label.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
            [cell addSubview:label];
            return cell;
            
        }
        else{
            static NSString * str_identifer = @"ce";
            UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:str_identifer];
            if (cell == nil) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:str_identifer];
            }
            cell.backgroundColor = [UIColor whiteColor];
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = @"";
            cell.textLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1];
            cell.textLabel.font = [UIFont systemFontOfSize:15];
            cell.detailTextLabel.font =[UIFont systemFontOfSize:13];
            cell.textLabel.text = array[indexPath.row];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            if (indexPath.row == 3) {
                cell.detailTextLabel.text = model_detail.dateline;
            }
            else if (indexPath.row == 10||indexPath.row == 14){
                cell.backgroundColor  =[UIColor colorWithWhite:0.98 alpha:1];
            }
            if (indexPath.row == 15){
                cell.detailTextLabel.text = [NSString stringWithFormat:@"¥ %@",model_detail.total_price];
;
                cell.detailTextLabel.textColor = [UIColor orangeColor];
            }
            NSString *hongbaoStr = [NSString stringWithFormat:NSLocalizedString(@"红包抵扣 ¥%@", nil),model_detail.hongbao];
            [cell.textLabel setColor:HEX(@"ff3300", 1) string:hongbaoStr];
            [cell.textLabel setFont:FONT(13) string:hongbaoStr];
            //添加分割线
            UIView * view = [cell viewWithTag:111];
            [view removeFromSuperview];
            view = nil;
            if (indexPath.row == 13 || indexPath.row == 14) {
                
            }else{
                UIView * label = [[UIView alloc]init];
                label.frame = FRAME(0, 39.5, WIDTH, 0.5);
                label.tag = 111;
                label.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
                [cell addSubview:label];
            }
            return cell;
            
        }
    }
}

#pragma mark - 这是点击呼叫外卖小哥的方法
-(void)clickToCall{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:phone message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //点击取消
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"呼叫", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //点击呼叫
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",phone]]];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - 这是点击订单详情的第一个cell按钮的方法
-(void)clickToback{
    NSLog(@"这是点击订单详情的第一个cell按钮的方法");
}
#pragma mark - 这是点击第一个单元格上的按钮的方法
-(void)clickToDoThings:(UIButton * )sender{
    SHOW_HUD
    [self cancelOrderWithOrder_id:model_progress.order_id];
}
#pragma mark - 这是点击去支付/评价/取消订单的方法
-(void)clickToMore:(UIButton *)sender{
    if ([sender.titleLabel.text isEqualToString:NSLocalizedString(@"去支付", nil)]) {

        JHWMPayOrderVC *vc = [[JHWMPayOrderVC alloc]init];
        vc.order_id = self.order_id;
        vc.amount = model_progress.paotui_amount;
        vc.isDetailVC = YES;
        [vc setPaySuccessBlock:^(BOOL success, NSString *msg) {
            if (success) {
                [self downRefreshForDetail];
                if (self.myBlock) {
                    self.myBlock();
                }
            }
        }];
        [self.navigationController pushViewController:vc animated:YES];
    }else if ([sender.titleLabel.text isEqualToString:NSLocalizedString(@"确认完成", nil)]){
        [HttpTool postWithAPI:@"client/order/confirm" withParams:@{@"order_id":model_progress.order_id} success:^(id json) {
            if ([json[@"error"] isEqualToString:@"0"]) {
                SHOW_HUD
                [self downRefreshForDetail];
                if (self.myBlock) {
                    self.myBlock();
                }
            }else{
                [self creatUIAlertControlWithMessage:json[@"message"]];
            }
        } failure:^(NSError *error) {
            [self creatUIAlertControlWithMessage:NSLocalizedString(@"连接服务器出错,请稍后重试", nil)];
            NSLog(@"%@",error.localizedDescription);
        }];
        
    }else if ([sender.titleLabel.text isEqualToString:NSLocalizedString(@"查看评价", nil)]){
        NSLog(@"点击了查看评价");
        JHPEvaluateVC * vc  = [[JHPEvaluateVC alloc]init];
        vc.order_id = model_progress.order_id;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([sender.titleLabel.text isEqualToString:NSLocalizedString(@"取消订单", nil)]){
        NSLog(@"点击的是取消订单");
        SHOW_HUD
        [self cancelOrderWithOrder_id:model_progress.order_id];
    }else if([sender.titleLabel.text isEqualToString:NSLocalizedString(@"去评价", nil)]){
        NSLog(@"点击的是去评价");
        JHPersonEvaluationVC * vc = [[JHPersonEvaluationVC alloc]init];
        vc.number = model_progress.jifen;
        vc.order_id = model_progress.order_id;
        vc.isTuan = NO;
        vc.personEvaluationSuccess = ^{
            [self downRefreshForDetail];
            if (isFirst_detail) {
            [self downRefreshForDetail];
            }
            if (self.myBlock) {
                self.myBlock();
            }

        };
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        NSLog(@"这样的状态下就不要点击了");
    }
}
#pragma mark - 这是发送取消订单的请求
-(void)cancelOrderWithOrder_id:(NSString *)order_id {
    [HttpTool postWithAPI:@"client/order/cancel" withParams:@{@"order_id":order_id} success:^(id json) {
        NSLog(@"%@",json);
        if ([json[@"error"] isEqualToString:@"0"]) {
            HIDE_HUD
            //刷新数据
            [self downRefreshForOrder];
            if (isFirst_detail) {
                [self downRefreshForDetail];
            }
            if (self.myBlock) {
                self.myBlock();
            }

        }else{
            HIDE_HUD
            [self creatUIAlertControlWithMessage:json[@"message"]?json[@"message"]:NSLocalizedString(@"连接服务器出错,请稍后重试", nil)];
        }
    } failure:^(NSError *error) {
        NSLog(@"error:%@",error.localizedDescription);
        [self creatUIAlertControlWithMessage:NSLocalizedString(@"连接服务器出错,请稍后重试", nil)];
    }];
}

#pragma mark - 这是点击投诉的方法
-(void)clicktoComplain{
    NSLog(@"这是投诉的方法");
    if ([model_progress.order_status integerValue] >= 2) {
        JHPersonComplainVC * vc = [[JHPersonComplainVC alloc]init];
        vc.order_id = model_progress.order_id;
        [self.navigationController pushViewController:vc animated:YES];
        
    }
    else{
        [self creatUIAlertControlWithMessage:NSLocalizedString(@"您暂时还无法进行此操作", nil)];
    }
}
#pragma mark - 这是点击催单的方法
-(void)clicktoCuiDan{
    NSLog(@"这是点击催单的方法");
    if ([model_progress.order_status integerValue]>0 && [model_progress.order_status integerValue] < 4) {
        [HttpTool postWithAPI:@"client/order/cuidan" withParams:@{@"order_id":model_progress.order_id} success:^(id json) {
            NSLog(@"json:%@",json);
            if ([json[@"error"] isEqualToString:@"0"]) {
                [self creatUIAlertControlWithMessage:NSLocalizedString(@"催单成功", nil)];
            }else{
                [self creatUIAlertControlWithMessage:json[@"message"]];
            }
        } failure:^(NSError *error) {
             NSLog(@"error:%@",error.localizedDescription);
             [self creatUIAlertControlWithMessage:NSLocalizedString(@"连接服务器出错,请稍后重试", nil)];
        }];
    }else{
        [self creatUIAlertControlWithMessage:NSLocalizedString(@"该时段无法催单", nil)];
    }
}
#pragma mark - 这是订单详情点击播放语音的方法
-(void)clickToPlay:(UITapGestureRecognizer *)tap{
    //如果语音正在播放,暂停
    if ([_player isPlaying]) {
        [imageView stopAnimating];
        [_player pause];
        return;
    }
    //如果语音不是在播放,开始播放
    NSData * data = [[NSData alloc]initWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",IMAGEADDRESS,model_detail.voice]]];
    _player = [[AVAudioPlayer alloc]initWithData:data error:nil];
    _player.delegate = self;
    [_player play];
    [imageView startAnimating];
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [imageView stopAnimating];
}
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error{
    NSLog(@"error:%@",error.localizedDescription);
}
#pragma mark - 创建mapView
-(void)creatMapViewWithCell:(UITableViewCell *)cell{
    if (_mapView == nil) {
        _mapView = [[XHMapView alloc] initWithFrame:CGRectMake(0,0, WIDTH,150)];
        [cell addSubview:_mapView];
    }
    _mapView.lat = lat;
    _mapView.lng = lng;
    CLLocationCoordinate2D custom = CLLocationCoordinate2DMake(lat,lng);
    CLLocationCoordinate2D pei = CLLocationCoordinate2DMake([XHMapKitManager shareManager].lat,[XHMapKitManager shareManager].lng);
    [_mapView changeDistanceWithCustomCoordinate:custom peiCoordinate:pei];
}


#pragma mark - 这是刷新订单进度的方法
-(void)downRefreshForOrder{
    [self postProgressHtttp];
}

#pragma mark - 这是刷新订单详情的方法
-(void)downRefreshForDetail{
    [self downRefreshForOrder];
    [self postDetailHttp];
}
#pragma mark - 创建提示框
-(void)creatUIAlertControlWithMessage:(NSString *)msg{
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"温馨提示", nil) message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"知道了", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - ************判断按钮的状态***********
-(void)judgeBtnState:(UIButton *)sender{
    if([model_progress.order_status integerValue] == 0 && [model_progress.pay_status integerValue] == 0){
        [sender setTitle:NSLocalizedString(@"去支付", nil) forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor orangeColor];
        
    }else if ([model_progress.order_status integerValue] == 0&& [model_progress.pay_status integerValue] == 1){
        [sender setTitle:NSLocalizedString(@"取消订单", nil) forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor orangeColor];
        
    }else if([model_progress.order_status integerValue] == 1||[model_progress.order_status integerValue] == 2){
        [sender setTitle:NSLocalizedString(@"等待服务", nil) forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor colorWithRed:225/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    }else if ([model_progress.order_status integerValue]== 4){
        [sender setTitle:NSLocalizedString(@"确认完成", nil) forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor orangeColor];
    }
    else if ([model_progress.order_status intValue] == 8 && [model_progress.comment_status intValue] == 0){
        [sender setTitle:NSLocalizedString(@"去评价", nil) forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor orangeColor];
    }else if([model_progress.order_status intValue] == 8 && [model_progress.comment_status intValue] == 1){
        [sender setTitle:NSLocalizedString(@"查看评价", nil) forState:UIControlStateNormal];
        sender.backgroundColor = THEME_COLOR;
    }else if ([model_progress.staff_id integerValue] > 0  && [model_progress.order_status intValue] == 1){
        [sender setTitle:NSLocalizedString(@"等待服务", nil) forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor colorWithRed:225/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    }else if ([model_progress.order_status integerValue] == -1){
        [sender setTitle:NSLocalizedString(@"订单已取消", nil) forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor colorWithRed:225/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    }
    else if([model_progress.order_status integerValue] == 3){
        [sender setTitle:NSLocalizedString(@"服务中", nil) forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor colorWithRed:225/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    }else{
        sender.backgroundColor = [UIColor clearColor];
    }
    
}
@end
