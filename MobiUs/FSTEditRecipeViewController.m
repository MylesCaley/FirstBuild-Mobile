//
//  FSTEditRecipeViewController.m
//  FirstBuild
//
//  Created by John Nolan on 8/13/15.
//  Copyright (c) 2015 FirstBuild. All rights reserved.
//

#import "FSTEditRecipeViewController.h"



@interface FSTEditRecipeViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *minPickerHeight;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maxPickerHeight;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tempPickerHeight;


@property (weak, nonatomic) IBOutlet UIImageView *imageEditor;

@property (weak, nonatomic) IBOutlet UITextField *nameField;

@property (weak, nonatomic) IBOutlet UITextView *noteView;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *stageView;

@property (weak, nonatomic) IBOutlet UIPickerView *minPicker;

@property (weak, nonatomic) IBOutlet UILabel *minLabel;

@property (weak, nonatomic) IBOutlet UIPickerView *maxPicker;

@property (weak, nonatomic) IBOutlet UILabel *maxLabel;

@property (weak, nonatomic) IBOutlet UIPickerView *tempPicker;

@property (weak, nonatomic) IBOutlet UILabel *tempLabel;

@end

@implementation FSTEditRecipeViewController
{
    FSTStagePickerManager* pickerManager;
}

typedef enum variableSelections {
    MIN_TIME,
    MAX_TIME,
    TEMPERATURE,
    NONE
} VariableSelection;
// keeps track of the open picker views

VariableSelection _selection;

CGFloat const SEL_HEIGHT_R = 90; // the standard picker height for the current selection (equal to the constant picker height

- (void)viewDidLoad {
    [super viewDidLoad];
    
    pickerManager = [[FSTStagePickerManager alloc] init];
    [self.nameField setDelegate:self];
    [self.noteView setDelegate:self];
    [self.minPicker setDelegate:pickerManager];
    [self.maxPicker setDelegate:pickerManager];
    [self.tempPicker setDelegate:pickerManager]; // holds all the
    pickerManager.minPicker = self.minPicker;
    pickerManager.maxPicker = self.maxPicker;
    pickerManager.tempPicker = self.tempPicker;
    [pickerManager setDelegate:self];
    [pickerManager selectAllIndices];
    
    if ([[self.recipeManager getSavedRecipes] objectForKey:self.activeRecipe.name]) { //started with a preexisting recipe, should delete and let it resave
        [self.recipeManager removeItemFromDefaults:self.activeRecipe.name]; // start afresh (but keep pointer to the active recipe). Could consider just passing the name and loading the recipe here
    }
    
    if (!self.activeRecipe) {
        self.activeRecipe = [[FSTRecipe alloc] init]; // need a strong property since this could be the unique pointer
    }
    
    [self updateLabels];
    
}

- (void)viewWillAppear:(BOOL)animated {
    self.imageEditor.image = self.activeRecipe.photo.image;
    // will probably save the recipes in a dictionary in NSUserDefaults
    [pickerManager selectAllIndices]; // set the current min and max indices on the picker (initially selects lowest possible for min and highest for maxPicker, and we want this to show in the view controller)
    [self.nameField setText:self.activeRecipe.name];
    [self.noteView setText:self.activeRecipe.note];
    [self resetPickerHeights];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)updateLabels {
    
    [self.tempLabel setAttributedText:[pickerManager tempLabel]];
    [self.minLabel setAttributedText:[pickerManager minLabel]];
    [self.maxLabel setAttributedText:[pickerManager maxLabel]];
    
}

// top button pressed
- (IBAction)minTimeTapGesture:(id)sender {
    [self resetPickerHeights];
    if (_selection != MIN_TIME) { // only needs to run when a change should be made
        // set selection to MIN_TIME now that the new min picker is about to show
        _selection = MIN_TIME;
        self.minPickerHeight.constant = SEL_HEIGHT_R;
    } else {
        _selection = NONE;
    }// if it was MIN_TIME it should close, then change to NONE
    [UIView animateWithDuration:0.7 animations:^(void) {
        [self.view layoutIfNeeded];//[self updateViewConstraints]; // should tell the view to update heights to zero when something moves
    }]; // animate reset and new height or just reset
    
}


- (IBAction)maxTimeTapGesture:(id)sender {
    [self resetPickerHeights];
    if (_selection != MAX_TIME) { // only needs to run when a change should be made
        _selection = MAX_TIME;
        self.maxPickerHeight.constant = SEL_HEIGHT_R;
    } else {
        _selection = NONE;
    }
    [UIView animateWithDuration: 0.7 animations:^(void) {
        [self.view layoutIfNeeded];
        //[self updateViewConstraints]; // should tell the view to update heights to zero when something moves
    }];
}


- (IBAction)temperatureTapGesture:(id)sender {
    
    [self resetPickerHeights]; // always change picker heights to zero
    
    if (_selection != TEMPERATURE) {
        _selection = TEMPERATURE;
        self.tempPickerHeight.constant = SEL_HEIGHT_R;
    } else {
        _selection = NONE;
    }
    [UIView animateWithDuration:0.7 animations:^(void) {
        [self.view layoutIfNeeded];
        //[self updateViewConstraints]; // should tell the view to update heights to zero when something moves
    }];
}

- (void)resetPickerHeights { // might want to save the current indices as well, but it should remain the same
    // should animate if the selection
    self.minPickerHeight.constant = 0;
    self.maxPickerHeight.constant = 0;
    self.tempPickerHeight.constant = 0; // careful to reset the constants, not the pointers to the constraints
    // changes layout in a subsequent animation
}

#pragma mark - image editing
- (IBAction)imageEditorTapped:(id)sender {
    UIImagePickerController* mealImagePicker = [[UIImagePickerController alloc] init];
    mealImagePicker.delegate = self;
    mealImagePicker.allowsEditing = YES;
    mealImagePicker.sourceType = UIImagePickerControllerCameraDeviceFront; // change this mode to let users select an image from the library
    
    [self presentViewController:mealImagePicker animated:YES completion:NULL];
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage* imageTaken = info[UIImagePickerControllerEditedImage];
    //self.imageEditor.image = imageTaken;
    self.activeRecipe.photo.image = imageTaken;
    self.imageEditor.image = self.activeRecipe.photo.image;
    [picker dismissViewControllerAnimated:YES completion:NULL];
    [self.view layoutIfNeeded]; // constraints seem to be off
   // self.scrollView.contentSize = CGSizeMake(self.stageView.frame.size.width, self.scrollView.contentSize.height);
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - text field and view delegates

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    self.activeRecipe.name = [NSMutableString stringWithString:textField.text];
    return YES; // might want to scroll to different positions depending on the delegate
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    } else {
        return YES;
    }
}
-(BOOL)textViewShouldEndEditing:(UITextView *)textView {
    self.activeRecipe.note = [NSMutableString stringWithString:textView.text];
    return YES;
}

#pragma mark - save button

- (IBAction)saveButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    if ([[self.recipeManager getSavedRecipes] objectForKey:self.activeRecipe.name]) {
        // do some alert
    } else {
        self.activeRecipe.name = [NSMutableString stringWithString:self.nameField.text];
        self.activeRecipe.note = [NSMutableString stringWithString:self.noteView.text];
        self.activeRecipe.photo.image = self.imageEditor.image;
        [self.recipeManager saveRecipe:self.activeRecipe];
    }
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