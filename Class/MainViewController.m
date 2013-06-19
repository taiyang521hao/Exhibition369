//
//  MainViewController.m
//  Exhibition369
//
//  Created by Jack Wang on 6/17/13.
//  Copyright (c) 2013 MobilyDaily. All rights reserved.
//

#import "MainViewController.h"
#import "Model.h"
#import "Exhibition.h"
#import "ExhibitionDetailViewController.h"
#import "Utils.h"
#import "DataButton.h"
#import "Constant.h"
#import "ExhibitionTableCell.h"
#import "IconDownloader.h"

@interface MainViewController ()

@end

@implementation MainViewController


-(id)init
{
    if ((self = [super init]))
    {
        typeGroup = [[NSMutableArray alloc] init];
        typeVSExhibitions = [[NSMutableDictionary alloc] init];
        
        unAppliedExhibitions = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
    
    activeTab = MainViewActiveTabExhibitions;
    [self requestExhibitions];
    
    [typeGroup removeAllObjects];
	[typeVSExhibitions removeAllObjects];
    NSString *group;
    NSMutableArray *array;
    for (Exhibition *e in [Model sharedModel].appliedExhibitionList) {
        group = e.status;
        array = [typeVSExhibitions objectForKey:group];
        if (array == nil)
        {
            array = [NSMutableArray array];
            [typeVSExhibitions setObject:array forKey:group];
            [typeGroup addObject:group];
        }
        [array addObject:e];
    }
    
}

- (void)requestExhibitions{
    if([Model sharedModel].systemConfig){
        NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       [Model sharedModel].systemConfig.token, @"token",
                                       @"-1", @"size",
                                       @"-1", @"last",
                                       @"", @"name",
                                       nil];
        
        [self sendRequestWith:[NSString stringWithFormat:@"%@/rest/exhibitions/find", ServerURL] params:params method:RequestMethodGET];
    }
    
}

- (NSString *)getStatusTxt:(NSString *)status {
    if([status isEqualToString:EXHIBITION_STATUS_N])
        return @"未报名";
    else if([status isEqualToString:EXHIBITION_STATUS_P])
        return @"审核中";
    else if([status isEqualToString:EXHIBITION_STATUS_A])
        return @"审核通过";
    else if([status isEqualToString:EXHIBITION_STATUS_D])
        return @"审核未通过";
    else
        return @"";
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    
    [self.imageDownloadsInProgress removeAllObjects];
}

-(void)buttonTapped:(DataButton *)sender{
    
}


#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(activeTab == MainViewActiveTabAppliedExhibitions){
        NSMutableArray *array = [typeVSExhibitions objectForKey:[typeGroup objectAtIndex:section]];
        return [array count];
    } else {
        return [unAppliedExhibitions count];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(activeTab == MainViewActiveTabAppliedExhibitions)
        return [typeGroup count];
    else
        return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(activeTab == MainViewActiveTabAppliedExhibitions)
        return [self getStatusTxt:[typeGroup objectAtIndex:section]];
    else
        return @"";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    if(activeTab == MainViewActiveTabAppliedExhibitions){
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 25)];
        UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"date_bar.png"]];
        bg.frame = headerView.frame;
        //UILabel *userName = [[UILabel alloc] initWithFrame:CGRectMake (0,0,320,25)];
        [headerView addSubview:bg];
        UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake (10,0,320,25)];
        header.textColor = [UIColor whiteColor];
        header.text = [NSString stringWithFormat:@"%@ 区", [typeGroup objectAtIndex:section]];
        [headerView addSubview:header];
        [header setBackgroundColor:[UIColor clearColor]];
        return headerView;
    }
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if(activeTab == MainViewActiveTabAppliedExhibitions)
        return 25;
    else
        return 0;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *Title_ID = @"Title_ID";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Title_ID];
	UILabel *theTitle = nil;
    UILabel *theDate = nil;
	UILabel *theAddress = nil;
    UILabel *theOrganizer = nil;
    DataButton *theButton = nil;
    UIImageView *theImage;
    
	if (cell == nil)
	{
		cell = [[[ExhibitionTableCell alloc] initWithStyle:UITableViewCellStyleDefault
									   reuseIdentifier:Title_ID] autorelease];
        theButton = (DataButton *)[cell.contentView viewWithTag:5];
        [theButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
	}
    
    theTitle = (UILabel *)[cell.contentView viewWithTag:1];
    theDate = (UILabel *)[cell.contentView viewWithTag:2];
    theAddress = (UILabel *)[cell.contentView viewWithTag:3];
    theOrganizer = (UILabel *)[cell.contentView viewWithTag:4];
    theButton = (DataButton *)[cell.contentView viewWithTag:5];
    theImage = (UIImageView *)[cell.contentView viewWithTag:6];
    
    Exhibition *e;
    if(activeTab == MainViewActiveTabAppliedExhibitions){
        NSMutableArray *array = [typeVSExhibitions objectForKey:[typeGroup objectAtIndex:indexPath.section]];
        e = (Exhibition *)[array objectAtIndex:indexPath.row];
        
    } else {
        e = (Exhibition *)[unAppliedExhibitions objectAtIndex:indexPath.row];
    }
	theTitle.text = e.name;
    theDate.text = e.date;
    theAddress.text = e.address;
    theOrganizer.text = e.organizer;
    //theImage.image = [UIImage imagewith]
    
    if([e.status isEqualToString:EXHIBITION_STATUS_N]){
        [theButton setBackgroundImage:[UIImage imageNamed:@"sign-unfocus.png"] forState:UIControlStateNormal];
        [theButton setBackgroundImage:[UIImage imageNamed:@"sign-focus.png"] forState:UIControlStateHighlighted];
    } else {
        [theButton setBackgroundImage:[UIImage imageNamed:@"enter-unfocus.png"] forState:UIControlStateNormal];
        [theButton setBackgroundImage:[UIImage imageNamed:@"enter-focus.png"] forState:UIControlStateHighlighted];
    }
    
    
    // Set up the cell...
    
    // Only load cached images; defer new downloads until scrolling ends
    if (!e.icon)
    {
        if (_theTableView.dragging == NO && _theTableView.decelerating == NO)
        {
            [self startIconDownload:e forIndexPath:indexPath];
        }
        // if a download is deferred or in progress, return a placeholder image
        theImage.image = [UIImage imageNamed:@"Placeholder.png"];
    }
    else
    {
        theImage.image = e.icon;
    }
    
    
    
    
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 65;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Exhibition *e;
    if(activeTab == MainViewActiveTabAppliedExhibitions){
        NSMutableArray *array = [typeVSExhibitions objectForKey:[typeGroup objectAtIndex:indexPath.section]];
        e = (Exhibition *)[array objectAtIndex:indexPath.row];
        
    } else {
        e = (Exhibition *)[unAppliedExhibitions objectAtIndex:indexPath.row];
    }
    
    ExhibitionDetailViewController *edvc = [[[ExhibitionDetailViewController alloc] init] autorelease];
    [[Model sharedModel] pushView:edvc option:ViewTrasitionEffectMoveLeft];
}




#pragma mark - ASIHTTPRequestDelegate  default handler
- (void)requestFinished:(ASIHTTPRequest *)request
{
    [super requestFinished:request];
    
    [unAppliedExhibitions removeAllObjects];
    
    NSString *responseString = [request responseString];
    
    NSDictionary *result = [Utils parseJson:responseString];
	
    NSArray *exhibitorArray = [result objectForKey:@"list"];
    
    
    for (NSDictionary *exhibitionData in exhibitorArray)
	{
        Exhibition *e = [[Exhibition alloc] initWithJSONData:exhibitionData];
        [unAppliedExhibitions addObject:e];
        [e release];
    }
    
    [_theTableView reloadData];
    
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [super requestFinished:request];
    
    
}

- (void)dealloc {
    [_theTableView release];
    [_searchInput release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setTheTableView:nil];
    [self setSearchInput:nil];
    [super viewDidUnload];
}


#pragma mark - Table cell image support

// -------------------------------------------------------------------------------
//	startIconDownload:forIndexPath:
// -------------------------------------------------------------------------------
- (void)startIconDownload:(Exhibition *)exhibition forIndexPath:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = [self.imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil)
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.exhibition = exhibition;
        [iconDownloader setCompletionHandler:^{
            
            UITableViewCell *cell = [_theTableView cellForRowAtIndexPath:indexPath];
            UIImageView *theImage = (UIImageView *)[cell viewWithTag:6];
            // Display the newly loaded image
            theImage.image = exhibition.icon;
            
            // Remove the IconDownloader from the in progress list.
            // This will result in it being deallocated.
            [self.imageDownloadsInProgress removeObjectForKey:indexPath];
            
        }];
        [self.imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload];
    }
}

// -------------------------------------------------------------------------------
//	loadImagesForOnscreenRows
//  This method is used in case the user scrolled into a set of cells that don't
//  have their app icons yet.
// -------------------------------------------------------------------------------
- (void)loadImagesForOnscreenRows
{
    if ([unAppliedExhibitions count] > 0)
    {
        NSArray *visiblePaths = [_theTableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            Exhibition *e = [unAppliedExhibitions objectAtIndex:indexPath.row];
            
            if (e.icon)
                // Avoid the app icon download if the app already has an icon
            {
                [self startIconDownload:e forIndexPath:indexPath];
            }
        }
    }
}

#pragma mark - UIScrollViewDelegate

// -------------------------------------------------------------------------------
//	scrollViewDidEndDragging:willDecelerate:
//  Load images for all onscreen rows when scrolling is finished.
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
	{
        [self loadImagesForOnscreenRows];
    }
}

// -------------------------------------------------------------------------------
//	scrollViewDidEndDecelerating:
// -------------------------------------------------------------------------------
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}
- (IBAction)searchExhibition:(id)sender {
}
@end
