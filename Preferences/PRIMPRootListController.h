#import <Preferences/PSListController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSliderTableCell.h>
#import <CepheiPrefs/HBRootListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Cephei/HBRespringController.h>
#import <Cephei/HBPreferences.h>
#import <SafariServices/SafariServices.h>

@interface PSListController (Private)
-(BOOL)containsSpecifier:(PSSpecifier *)arg1;
-(id)readPreferenceValue:(PSSpecifier *)arg1;
-(void)_returnKeyPressed:(id)arg1;

@end

@interface PRIMPRootListController : HBListController
@property (nonatomic, retain) NSMutableDictionary *savedSpecifiers;
-(void) showMe:(NSString *)showMe after:(NSString *)after animate:(bool)animate;
-(void) hideMe:(NSString *)hideMe animate:(bool)animate;
@end