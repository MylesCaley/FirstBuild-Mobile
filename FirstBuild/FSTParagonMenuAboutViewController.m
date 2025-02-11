//
//  FSTParagonMenuAboutViewController.m
//  FirstBuild
//
//  Created by John Nolan on 7/27/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import "FSTParagonMenuAboutViewController.h"

@interface FSTParagonMenuAboutViewController ()
{
    
    IBOutlet UILabel *labelVersion;
}
@end

@implementation FSTParagonMenuAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    labelVersion.text = version;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sourceTap:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.github.com/FirstBuild/FirstBuild-Mobile"]];
}

- (IBAction)learnMoreTap:(id)sender {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://firstbuild.com/ChrisN/paragon-induction-cooktop-precision-cooking/updates/"]];

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
