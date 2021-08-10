#import "PRIMPRootListController.h"
#import <Preferences/PSSpecifier.h>

@implementation PRIMPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	
	return _specifiers;
}


- (void)setPreferenceValue:(id)_value specifier:(PSSpecifier *)specifier {
	id value = _value;

	[super setPreferenceValue:value specifier:specifier];
	if (value != _value) {
		// Reload the specifier if some code changed the value
		[self reloadSpecifier:specifier];
	}
}

@end