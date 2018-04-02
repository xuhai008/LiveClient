//
//  MeLevelViewController.m  我的等级界面
//  livestream
//
//  Created by alex shum on 17/9/25.
//  Copyright © 2017年 net.qdating. All rights reserved.
//

#import "MeLevelViewController.h"
#import "IntroduceView.h"
#import "LSLiveWKWebViewController.h"
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone)

@interface MeLevelViewController () <WKUIDelegate,WKNavigationDelegate>
// 内嵌web
@property (weak, nonatomic) IBOutlet IntroduceView *meLevelView;

@property (nonatomic, strong) LSLiveWKWebViewController *urlController;

@end

@implementation MeLevelViewController

- (void)dealloc {
    NSLog(@"MeLevelViewController::dealloc()");
    [self.meLevelView stopLoading];
    [self.meLevelView.configuration.userContentController removeScriptMessageHandlerForName:@"LiveApp"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"My Level";
    
    self.urlController = [[LSLiveWKWebViewController alloc] init];
    self.urlController.isShowTaBar = YES;
    self.urlController.isRequestWeb = YES;
    
    NSString *webSiteUrl = self.urlController.configManager.item.userLevel;
    NSString *device; // 设备类型
    if (webSiteUrl.length > 0) {
        if (IS_IPAD) {
            device = [NSString stringWithFormat:@"device=32"];
        } else {
            device = [NSString stringWithFormat:@"device=31"];
        }
        if ([webSiteUrl containsString:@"?"]) {
            webSiteUrl = [NSString stringWithFormat:@"%@&%@",webSiteUrl,device];
        } else {
            webSiteUrl = [NSString stringWithFormat:@"%@?%@",webSiteUrl,device];
        }
    }
    self.urlController.baseUrl = webSiteUrl;
}


- (void)initCustomParam {
    [super initCustomParam];
}

- (void)setupNavigationBar {
    [super setupNavigationBar];
}

- (void)setupContainView{
    [super setupContainView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    self.navigationController.navigationBar.hidden = NO;
    if (!self.viewDidAppearEver) {
        self.urlController.liveWKWebView = self.meLevelView;
        self.urlController.controller = self;
        self.urlController.isShowTaBar = YES;
        self.urlController.isRequestWeb = YES;
        [self.urlController requestWebview];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self hideAndResetLoading];
}


@end