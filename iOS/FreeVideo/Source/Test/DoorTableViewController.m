//
//  DoorTableViewController.m
//  livestream
//
//  Created by Max on 2017/5/17.
//  Copyright © 2017年 net.qdating. All rights reserved.
//

#import "DoorTableViewController.h"
#import "DoorTableView.h"

#import "DoorStreamViewController.h"

#import "LSSessionRequestManager.h"
#import "GetAnchorListRequest.h"

#define PageSize 50
#define DefaultSize 16

@interface DoorTableViewController () <UIScrollViewRefreshDelegate>
@property (nonatomic, strong) IBOutlet DoorTableView *tableView;

@property (nonatomic, strong) LSSessionRequestManager *sessionManager;
@property (nonatomic, strong) NSMutableArray *items;

@end

@implementation DoorTableViewController

- (void)initCustomParam {
    [super initCustomParam];

    self.isShowNavBar = NO;
    
    self.items = [NSMutableArray array];
    self.sessionManager = [LSSessionRequestManager manager];
}

- (void)dealloc {
    [self.tableView unInitPullRefresh];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (@available(iOS 11, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    if (!self.viewDidAppearEver) {
        [self.tableView startPullDown:YES];
    }

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)setupContainView {
    [super setupContainView];

    // 初始化主播列表
    [self setupTableView];
}

- (void)setupTableView {
    // 初始化下拉
    [self.tableView initPullRefresh:self pullDown:YES pullUp:YES];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    self.tableView.tableViewDelegate = self;
}

#pragma mark - 数据逻辑
- (void)reloadData:(BOOL)isReloadView {
    NSLog(@"DoorTableViewController::reloadData( isReloadView : %@ )", BOOL2YES(isReloadView));

    // 数据填充
    if (isReloadView) {
        self.tableView.items = self.items;
        [self.tableView reloadData];
    }
}

- (void)tableView:(DoorTableView *)tableView didSelectItem:(LiveRoomInfoItemObject *)item {
//    AnchorPersonalViewController *listViewController = [[AnchorPersonalViewController alloc] initWithNibName:nil bundle:nil];
//    listViewController.anchorId = item.userId;
//    listViewController.enterRoom = 1;
//    [self.navigationController pushViewController:listViewController animated:YES];
}

#pragma mark - 上下拉
- (void)pullDownRefresh {
    self.view.userInteractionEnabled = NO;
    [self getListRequest:NO];
}

- (void)pullUpRefresh {
    self.view.userInteractionEnabled = NO;
    [self getListRequest:YES];
}

#pragma mark - PullRefreshView回调
- (void)pullDownRefresh:(UIScrollView *)scrollView {
    // 下拉刷新回调
    [self pullDownRefresh];
}

- (void)pullUpRefresh:(UIScrollView *)scrollView {
    // 上拉更多回调
    [self pullUpRefresh];
}

#pragma mark 数据逻辑
- (BOOL)getListRequest:(BOOL)loadMore {
    NSLog(@"DoorTableViewController::getListRequest( loadMore : %@ )", BOOL2YES(loadMore));

    BOOL bFlag = NO;

    GetAnchorListRequest *request = [[GetAnchorListRequest alloc] init];
    int start = 0;
    if (!loadMore) {
        // 刷最新
        start = 0;
    } else {
        // 刷更多
        start = self.items ? ((int)self.items.count) : 0;
    }

    // 每页最大纪录数
    request.start = start;
    request.step = PageSize;
    request.isForTest = YES;
    request.hasWatch = NO;

    // 调用接口
    request.finishHandler = ^(BOOL success, HTTP_LCC_ERR_TYPE errnum, NSString *_Nonnull errmsg, NSArray<LiveRoomInfoItemObject *> *_Nullable array) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"DoorTableViewController::getListRequest( [%@], loadMore : %@, count : %ld )", BOOL2SUCCESS(success), BOOL2YES(loadMore), (long)array.count);
            if (success) {
                [self.tableView.tableHeaderView setHidden:NO];
                if (!loadMore) {
                    // 停止头部
                    [self.tableView finishPullDown:YES];
                    // 清空列表
                    [self.items removeAllObjects];
                } else {
                    // 停止底部
                    [self.tableView finishPullUp:YES];
                }

                for (LiveRoomInfoItemObject *item in array) {
                    [self.items addObject:item];
                }

                // 没有数据隐藏banner
                if (!(self.items.count > 0)) {
                    [self.tableView.tableHeaderView setHidden:YES];
                }

                [self reloadData:YES];

                if (!loadMore) {
                    if (self.items.count > 0) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            // 拉到最顶
                            [self.tableView scrollsToTop];
                        });
                    }
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        if (self.items.count > PageSize) {
                            // 拉到下一页
                            UITableViewCell *cell = [self.tableView visibleCells].firstObject;
                            NSIndexPath *index = [self.tableView indexPathForCell:cell];
                            NSInteger row = index.row;
                            NSIndexPath *nextIndex = [NSIndexPath indexPathForRow:row + 1 inSection:0];
                            [self.tableView scrollToRowAtIndexPath:nextIndex atScrollPosition:UITableViewScrollPositionTop animated:YES];
                        }

                    });
                }

            } else {
                if (!loadMore) {
                    // 停止头部
                    [self.tableView finishPullDown:NO];
                    [self.items removeAllObjects];
                    [self.tableView.tableHeaderView setHidden:YES];
                    self.failView.hidden = NO;
                } else {
                    // 停止底部
                    [self.tableView finishPullUp:YES];
                }

                [self reloadData:YES];
            }
            self.view.userInteractionEnabled = YES;
        });
    };

    bFlag = [self.sessionManager sendRequest:request];

    return bFlag;
}

- (void)addItemIfNotExist:(LiveRoomInfoItemObject *_Nonnull)itemNew {
    bool bFlag = NO;

    for (LiveRoomInfoItemObject *item in self.items) {
        if ([item.userId isEqualToString:itemNew.userId]) {
            // 已经存在
            bFlag = true;
            break;
        }
    }

    if (!bFlag) {
        // 不存在
        [self.items addObject:itemNew];
    }
}

- (void)reloadBtnClick:(id)sender {
    self.failView.hidden = YES;
    [self.tableView startPullDown:YES];
}

- (void)tableView:(DoorTableView *)tableView didViewItem:(LiveRoomInfoItemObject *)item {
    DoorStreamViewController *vc = [[DoorStreamViewController alloc] initWithNibName:nil bundle:nil];
    vc.item = item;
    [self.navigationController pushViewController:vc animated:YES];
}

@end