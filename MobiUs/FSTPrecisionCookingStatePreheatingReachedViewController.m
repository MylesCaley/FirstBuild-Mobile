//
//  FSTPrecisionCookingStatePreheatingReachedViewController.m
//  FirstBuild
//
//  Created by John Nolan on 8/6/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import "FSTPrecisionCookingStatePreheatingReachedViewController.h"
#import "FSTPrecisionCookingStatePreheatingReachedLayer.h"

@interface FSTPrecisionCookingStatePreheatingReachedViewController ()

@end

@implementation FSTPrecisionCookingStatePreheatingReachedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.progressView.progressLayer = [[FSTPrecisionCookingStatePreheatingReachedLayer alloc] init];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updatePercent {
    [super updatePercent];
    self.progressView.progressLayer.percent = 1.0F; // percent insignificant
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end