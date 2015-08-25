//
//  ViewController.m
//  MZRefreshControlDemo
//
//  Created by Jamin on 8/25/15.
//  Copyright © 2015 MZ. All rights reserved.
//

#import "ViewController.h"
#import "MZRefreshControl.h"

@interface ViewController ()
@property (nonatomic, strong) MZRefreshControl *mzRefreshControl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];


    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

    MZRefreshControl * refreshControl = [[MZRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(pullToRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];

    self.mzRefreshControl = refreshControl;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


#pragma mark - Action
- (void)pullToRefresh:(MZRefreshControl *)refreshControl
{
    [self performSelector:@selector(endRefreshing) withObject:nil afterDelay:10];
}


#pragma mark - Refresh
- (void)endRefreshing
{
    [self.mzRefreshControl endRefreshing];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = [@(indexPath.row) stringValue];
    return cell;
}



@end
