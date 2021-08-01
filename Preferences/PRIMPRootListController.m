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
	if ([(NSString *)[specifier propertyForKey:@"placeholder"] isEqualToString:@"Port"]) {
		// Refuse to update the port if it's not a valid port
		NSInteger integerValue = [(NSString *)value integerValue];
		if ((integerValue < 0x0000) || (integerValue > 0xFFFF)) {
			value = @(22023);
			UIAlertController *alert = [UIAlertController
				alertControllerWithTitle:@"Invalid Port"
				message:@"The port must be in the 0-65535 range."
				preferredStyle:UIAlertControllerStyleAlert
			];
			[alert addAction:[UIAlertAction
				actionWithTitle:@"OK"
				style:UIAlertActionStyleDefault
				handler:nil
			]];
			[self presentViewController:alert animated:YES completion:nil];
		}
	}
	[super setPreferenceValue:value specifier:specifier];
	if (value != _value) {
		// Reload the specifier if some code changed the value
		[self reloadSpecifier:specifier];
	}
}

@end
