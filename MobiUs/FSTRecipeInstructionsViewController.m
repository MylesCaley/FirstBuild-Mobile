//
//  FSTRecipeInstructionsViewController.m
//  FirstBuild
//
//  Created by John Nolan on 8/24/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import "FSTRecipeInstructionsViewController.h"
#import "FSTRecipeUnderLineView.h"

@interface FSTRecipeInstructionsViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *underLineSpacing;

@property (weak, nonatomic) IBOutlet FSTRecipeUnderLineView *underLineView;

@end

@implementation FSTRecipeInstructionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //self.tabBarController.tabBar.frame.size
    // Do any additional setup after loading the view.
}

-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.underLineSpacing.constant = self.tabBarController.tabBar.frame.size.height;
    [self.underLineView setHorizontalPosition:self.view.frame.size.width/2];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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