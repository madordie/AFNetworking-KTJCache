//
//  TableViewController.m
//  Demo - AFNetworking-KTJCache
//
//  Created by 孙继刚 on 15/8/13.
//  Copyright (c) 2015年 Madordie. All rights reserved.
//

#import "TableViewController.h"
#import "AFHTTPRequestOperationManager+KTJCache.h"

@interface TableViewController () <UITableViewDataSource, UITableViewDelegate> {
    UITableViewCell *_layoutHeightCell;
}
@property (nonatomic, copy) NSArray *dataSource;
@property (nonatomic, strong) AFHTTPRequestOperationManager *httpManager;
@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    _layoutHeightCell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    
    UIRefreshControl *refreshContol = [[UIRefreshControl alloc] init];
    [refreshContol addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshContol;
    
    self.httpManager = [AFHTTPRequestOperationManager manager];
    
    [self refreshData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - download data
- (void)refreshData {
    void (^success)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        self.dataSource = responseObject[@"data"][@"entries"];
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        NSLog(@"responseObject use cache:%d", operation.ktj_isCacheData);
    };
    void (^failure)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        [self.refreshControl endRefreshing];
        NSLog(@"http request error:%@", error);
    };
        //  偷偷的感谢小米的段子接口。。。。。
    //  5个随机的页码。不要问我为啥写2185＋因为这不是我的接口。我很久以前随便抓出来的。。。
    NSString *URL = [NSString stringWithFormat:@"http://api.comm.miui.com/miuisms/res/messages?cat=3&marker=%d&count=20", 21585+arc4random()%5];
    
#if 0
    
    值得注意的地方是：如果说你是点赞的、评论的，别傻傻的使用缓存哈。。因为那些缓存了反而不好。。。
    
    试想一下：MK为啥不做GET之外的缓存呢？
    不妨猜测一下：一是没必要、二是真没必要、三是无法确定缓存的KEY。。。
    
    然后考虑到大多数的网络请求都用了加密，有的获取数据也用POST，所以，增加了ktj_cacheAddedKey字段，
    你可以自己设置一个请求的特定KEY，用来标识当前请求。
    切记：设置这个KEY时候，一定要放上你的参数！！我会根据你这个KEY去判断这个请求是否有缓存过。
        如果你把那个啥点赞、评论、啥东西的不关闭缓存，而且设置了KEY，那么我会告诉你UI将会出问题，
        因为如果有缓存会有两次成功回调～～～别骂我，因为我给你说过了的。。。 ¯\_(ツ)_/¯
    
    好了就用这么俩参数，稍微写一下吧。👇
    
#endif

    
    //  GET/!GET     不使用缓存
//    self.httpManager.ktj_cacheData = NO;
    //  GET         使用缓存
    self.httpManager.ktj_cacheData = YES;
    
    //  !GET        使用缓存
//    self.httpManager.ktj_cacheData = YES;
//    self.httpManager.ktj_cacheAddedKey = @"当前请求KEY，最好带上参数。。";
    
    //  请求放飞
    [self.httpManager GET:URL parameters:nil success:success failure:failure];
    
}

#pragma mark - Table view data source    请忽略以下TableView的优化，因为我只是为了简洁。

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    
    // Configure the cell...
    [self configureCellForData:self.dataSource[indexPath.row] forCell:cell];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self configureCellForData:self.dataSource[indexPath.row] forCell:_layoutHeightCell];
    
    return _layoutHeightCell.frame.size.height;
}
- (void)configureCellForData:(NSDictionary *)data forCell:(UITableViewCell *)cell {
    cell.textLabel.text = data[@"text"];
    cell.textLabel.numberOfLines = 0;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
