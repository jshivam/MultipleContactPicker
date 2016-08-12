//
//  ViewController.h
//  MultipleContactPicker
//
//  Created by shivam jaiswal on 8/3/16.
//  Copyright © 2016 AppStreetSoftware Pvt. Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Contacts;
@class Contact;
@class ContactCell;
@class ContactBarButtonItem;

@protocol ContactPickerDelegate<NSObject>
- (void)didSelectNumbers:(NSArray *)numbers;
@end


@interface ViewController : UITableViewController
@property (nonatomic, weak) id<ContactPickerDelegate> cDelegate;
@end


@interface Contact : NSObject
-(id)initWithCNContact:(CNContact *)contact Number:(NSString*)number;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, strong) NSString *number;
@property (nonatomic, strong) NSString *fName;
@property (nonatomic, strong) NSString *lName;
@property (nonatomic, strong) NSString *completeName;
@property (nonatomic, strong) NSData *imgData;
@end

@interface ContactCell : UITableViewCell
@end

@interface ContactBarButtonItem : UIBarButtonItem
@property (nonatomic, assign) BOOL isSelectAll;
@end