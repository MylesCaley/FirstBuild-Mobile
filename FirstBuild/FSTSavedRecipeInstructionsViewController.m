//
//  FSTSavedRecipeInstructionsViewController.m
//  FirstBuild
//
//  Created by John Nolan on 8/24/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import "FSTSavedRecipeInstructionsViewController.h"
#import "FSTSavedRecipeUnderLineView.h"

@interface FSTSavedRecipeInstructionsViewController ()


@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *underLineSpacing;

@property (weak, nonatomic) IBOutlet FSTSavedRecipeUnderLineView *underLineView;

@property (nonatomic, assign) id currentResponder;


@end

@implementation FSTSavedRecipeInstructionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView.delegate = self;
    self.textView.text = self.instructions;
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignOnTap:)];
    [singleTap setNumberOfTapsRequired:1];
    [singleTap setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:singleTap];
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

#pragma mark - Text View delegate

//-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
//    if ([text isEqualToString:@"\n"]) {
//        [textView resignFirstResponder];
//        return NO;
//    } else {
//        return YES;
//    }
//}

-(BOOL)textViewShouldEndEditing:(UITextView *)textView {
    // must set active recipe when parent segues
    self.instructions = [NSMutableString stringWithString:textView.text];
    return YES;
}

- (void)resignOnTap:(id)iSender
{
    [self.currentResponder resignFirstResponder];
}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    self.currentResponder = textView;
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
