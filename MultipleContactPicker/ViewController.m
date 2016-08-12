//
//  ViewController.m
//  MultipleContactPicker
//
//  Created by shivam jaiswal on 8/3/16.
//  Copyright © 2016 AppStreetSoftware Pvt. Ltd. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSArray *filteredContacts;
@property (nonatomic, strong) ContactBarButtonItem *selectItem;
@property (nonatomic, strong) UISearchController *searchController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title =  @"Pick Contatcs";
    self.tableView.tableFooterView = [UIView new];
    
    self.contacts = [[NSMutableArray alloc]init];
    
    [self setUpSearch];
    [self fetchAllContacts];
    [self addBarButtons];
}

- (void)setUpSearch
{
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.delegate = self;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleProminent;
    self.searchController.searchBar.placeholder = @"Search Contacts";
    self.definesPresentationContext = YES;
    
    [self.searchController.searchBar sizeToFit];
    self.navigationItem.titleView = self.searchController.searchBar;
}

- (void)addBarButtons
{
    self.selectItem = [[ContactBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"unselect_all"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self action:@selector(selectContact:)];
    self.selectItem.isSelectAll = NO;
    
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(doneTapped:)];
    self.navigationItem.rightBarButtonItems = @[doneButton,self.selectItem];
    
    UIBarButtonItem *lItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"cross"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self action:@selector(crossTapped:)];
    self.navigationItem.leftBarButtonItem = lItem;
}

#pragma mark UserActions

- (void)doneTapped:(UIBarButtonItem *)item{
 
    if ([_cDelegate respondsToSelector:@selector(didSelectNumbers:)])
    {
        NSMutableArray *nums = [[NSMutableArray alloc]init];
        for (Contact *cn in self.contacts) {
            if (cn.isSelected == YES) {
                [nums addObject:cn.number];
            }
        }
        [_cDelegate didSelectNumbers:nums];
    }
}

- (void)selectContact:(ContactBarButtonItem *)item{
    
    if (item.isSelectAll)
    {
        [self updateSelectButtonImage:NO];
        [self selectAllContatcs:NO];
    }
    else
    {
        [self updateSelectButtonImage:YES];
        [self selectAllContatcs:YES];
        item.isSelectAll = YES;
    }
}

- (void)updateSelectButtonImage:(BOOL)isSelectAll
{
    if (isSelectAll) {
        self.selectItem.isSelectAll = YES;
        [self.selectItem setImage:[UIImage imageNamed:@"select_all"]];
    }else{
        self.selectItem.isSelectAll = NO;
        [self.selectItem setImage:[UIImage imageNamed:@"unselect_all"]];
    }
}

- (void)selectAllContatcs:(BOOL)select
{
    for (Contact *c in self.contacts) {
        c.isSelected = select;
    }
    [self.tableView reloadData];
}

- (void)crossTapped:(UIBarButtonItem *)item{
}


#pragma mark -

- (void)fetchAllContacts{
    
    if (![CNContactStore class]) {
#warning if Less that iOS 9 return
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    
    CNContactStore *store = [[CNContactStore alloc] init];
    
    [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error)
    {
        if (granted == YES)
        {
            NSArray *keys = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey];
            NSString *containerId = store.defaultContainerIdentifier;
            NSPredicate *predicate = [CNContact predicateForContactsInContainerWithIdentifier:containerId];
            
            NSError *error;
            NSArray *cnContacts = [store unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:&error];
            
            if (error){
                [self crossTapped:nil];
            }
            else
            {
                NSMutableArray *tempContact = [[NSMutableArray alloc]init];
                for (CNContact *contact in cnContacts)
                {
                    for (CNLabeledValue *label in contact.phoneNumbers)
                    {
                        NSString *phone = [label.value stringValue];
                        if ([phone length] > 0)
                        {
                            Contact *newContact = [[Contact alloc] initWithCNContact:contact Number:phone];
                            [tempContact addObject:newContact];
                        }
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.contacts = [NSArray arrayWithArray:tempContact];
                });
            }
        }        
    }];
}

- (NSArray *)sortContatcsArray:(NSArray *)array
{
    NSArray *sortedArray = [NSArray arrayWithArray:array];
    
    sortedArray = [sortedArray sortedArrayUsingComparator:^NSComparisonResult(Contact *obj1, Contact *obj2) {
        return [obj1.fName compare:obj2.fName options:NSCaseInsensitiveSearch];
    }];
    return sortedArray;
}

-(void)setContacts:(NSArray *)contacts
{
    _contacts  = [self sortContatcsArray:contacts];
    [self.searchController.searchBar becomeFirstResponder];
    [self.tableView reloadData];
}

#pragma mark tableView Delegates

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 64.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.searchController.isActive ? self.filteredContacts.count : self.contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *identifier = @"contactCell";
    
    ContactCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell =  [[ContactCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    Contact *c  = self.searchController.isActive ? [self.filteredContacts objectAtIndex:indexPath.row] : [self.contacts objectAtIndex:indexPath.row];
    
    cell.textLabel.text = c.completeName;
    cell.detailTextLabel.text = c.number;
    cell.imageView.image = [UIImage imageWithData:c.imgData];

    cell.accessoryType = c.isSelected ? UITableViewCellAccessoryCheckmark :  UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Contact *c  = self.searchController.isActive ? [self.filteredContacts objectAtIndex:indexPath.row] : [self.contacts objectAtIndex:indexPath.row];
    c.isSelected = !c.isSelected;
    
    if (c.isSelected ==  NO && self.selectItem.isSelectAll == YES) {
        [self updateSelectButtonImage:NO];
    }
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISearchController Delegate

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = searchController.searchBar.text;
    
    if (searchString.length == 0){
        self.filteredContacts = self.contacts;
    }
    else
    {
        NSMutableArray *filtCont = [[NSMutableArray alloc]init];
        for (Contact *cn in self.contacts)
        {
            if ([cn.number containsString:searchString] || [[cn.completeName lowercaseString] containsString:[searchString lowercaseString]]) {
                [filtCont addObject:cn];
            }
        }
        self.filteredContacts = [NSArray arrayWithArray:filtCont];
    }
    [self.tableView reloadData];
}

@end

#pragma mark - Contact Cell

@implementation ContactCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.preservesSuperviewLayoutMargins = false;
        self.separatorInset = UIEdgeInsetsZero;
        self.layoutMargins = UIEdgeInsetsZero;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect rect = self.contentView.bounds;
    
    float verticalPadding = 5.0;
    float sidePadding = 15.0;
    float betweenPadding = 10.0;
    float imgH = rect.size.height - 2 * verticalPadding;
    
    float x,y;
    
    x = sidePadding;
    y = verticalPadding;
    self.imageView.frame = (CGRect){x,y,imgH,imgH};
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.cornerRadius = imgH/2.0;
    
    x = CGRectGetMaxX(self.imageView.frame) + betweenPadding ;
    y = self.textLabel.frame.origin.y;
    self.textLabel.frame = (CGRect){x,y,self.textLabel.intrinsicContentSize};
    
    x = CGRectGetMaxX(self.imageView.frame) + betweenPadding ;
    y = self.detailTextLabel.frame.origin.y;
    self.detailTextLabel.frame = (CGRect){x,y,self.detailTextLabel.intrinsicContentSize};
}

@end


#pragma mark - Contact Model

@implementation Contact
-(id)initWithCNContact:(CNContact *)contact Number:(NSString*)number
{
    self = [super init];
    if (self)
    {
        self.isSelected = NO;
        self.fName = contact.givenName;
        self.lName = contact.familyName;
        self.completeName = [NSString stringWithFormat:@"%@ %@",self.fName,self.lName];
        self.number = [self getDigitsOnlyFromString:number];
        self.imgData = contact.imageData ? contact.imageData : UIImagePNGRepresentation([UIImage imageNamed:@"profile_image"]);
    }
    return self;
}

- (NSData*) drawText:(NSString*)text inImage:(UIImage*)image atPoint:(CGPoint)point
{
    UIFont *font = [UIFont boldSystemFontOfSize:32];
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    [[UIColor orangeColor] set];
    
    NSDictionary *att = @{NSFontAttributeName:font};
    [text drawInRect:rect withAttributes:att];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *data = UIImagePNGRepresentation(newImage);
    return data;
}

- (NSString*)getDigitsOnlyFromString:(NSString *)string
{
    NSMutableCharacterSet *mutSet = [[NSMutableCharacterSet alloc] init];
    [mutSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    NSCharacterSet *set = [mutSet invertedSet];
    NSString *result = [[string componentsSeparatedByCharactersInSet:set] componentsJoinedByString:@""];
    
    if (result.length > 10) {
        result = [result substringFromIndex:[result length] - 10];
    }
    
    return result;
}
@end

#pragma mark - ContactBarButtonItem
@implementation ContactBarButtonItem
@end


