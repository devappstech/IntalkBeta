//
//  CollectionViewCell.h
//  vstreaming
//
//  Created by developer on 7/24/16.
//  Copyright © 2016 ITGroup. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *tagLogo;
@property (weak, nonatomic) IBOutlet UILabel *tagName;

@end
