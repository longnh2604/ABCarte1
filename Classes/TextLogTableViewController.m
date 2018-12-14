//
//  TextLogTableViewController.m
//  iPadCamera
//
//  Created by GIGASJAPAN on 13/06/17.
//
//

#import "TextLogTableViewController.h"

@interface TextLogTableViewController ()

@end

@implementation TextLogTableViewController


- (id)initWithStyle:(UITableViewStyle)style cellItemsArray:(NSArray*)itemArray TaskTag:(NSInteger)taskTag
{
    self = [super initWithStyle:style];
    if (self) {
        self.contentSizeForViewInPopover = CGSizeMake(300.0f, 230.0f);
        logArray = [itemArray retain];
        callTaskTag = taskTag;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSInteger logCnt = [logArray count];
    if(logCnt > 5)
    {
        logCnt = 5;
    }
    return logCnt;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [NSString stringWithFormat:@"Cell%ld", (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    cell.textLabel.text = [logArray objectAtIndex:indexPath.row];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)dealloc
{
    //データの解放
    [logArray release];
    [super dealloc];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.

    NSString* selectStr = [logArray objectAtIndex:indexPath.row];
    NSLog(@"selectStr %@",selectStr);
    NSDictionary *dic = [NSDictionary dictionaryWithObject:selectStr forKey:@"SelectData"];
    NSNotification *notif;
    switch (callTaskTag) {
        case 201:
            notif= [NSNotification notificationWithName:@"SetEmailAddr" object:self userInfo:dic];
            break;
        case 202:
            notif= [NSNotification notificationWithName:@"SetEmailDomain" object:self userInfo:dic];
            break;
        case 203:
            notif= [NSNotification notificationWithName:@"SetEmailTitle" object:self userInfo:dic];
            break;
        case 204:
            notif= [NSNotification notificationWithName:@"SetEmailCCAddr" object:self userInfo:dic];
            break;
        case 205:
            notif= [NSNotification notificationWithName:@"SetEmailTitleInWebMailList" object:self userInfo:dic];
            break;
        default:
            break;
    }
    [[NSNotificationCenter defaultCenter] postNotification:notif];
}

@end
