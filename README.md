DCAvatar
========

A simple, asynchronous, network based avatar library for iOS and OSX. This makes using network based avatars simple, while still having great performance.

## Examples ##

A subclass for UIImageView and NSImageView is provided to make using DCAvatar very simple.

```objective-c
DCImageView *imageView = [[DCImageView alloc] initWithFrame:CGRectMake(70, 70, 60, 60)];
imageView.avatarValue = @"http://imgs.xkcd.com/comics/password_reuse.png";
[self.view addSubview:imageView];
```

Also supported are domain via meta tag scraping:

```objective-c
DCImageView *imageView = [[DCImageView alloc] initWithFrame:CGRectMake(70, 70, 60, 60)];
imageView.avatarValue = @"http://github.com";
[self.view addSubview:imageView];
```
and what is great avatar support without a little gravatar?

```objective-c
DCImageView *imageView = [[DCImageView alloc] initWithFrame:CGRectMake(70, 70, 60, 60)];
imageView.avatarValue = @"myemail@domain.com";
[self.view addSubview:imageView];
```
Other notable features:

* Completely asynchronous
* Memory and disk caching that is automatically pruned  
* Does not send multiple requests for same url
* Has both iOS and OSX support.
* gravatar support.
* domain meta tag support.

## Install ##

The recommended approach for installing DCAvatar is via the CocoaPods package manager, as it provides flexible dependency management and dead simple installation.

via CocoaPods

Install CocoaPods if not already available:

	$ [sudo] gem install cocoapods
	$ pod setup
Change to the directory of your Xcode project, and Create and Edit your Podfile and add DCAvatar:

	$ cd /path/to/MyProject
	$ touch Podfile
	$ edit Podfile
	platform :ios, '5.0' 
	# Or platform :osx, '10.8'
	pod 'DCAvatar'

Install into your project:

	$ pod install
	
Open your project in Xcode from the .xcworkspace file (not the usual project file)

## Requirements ##

DCAvatar requires at least iOS 5/Mac OSX 10.8 or above.


## License ##

DCAvatar is license under the Apache License.

## Contact ##

### Dalton Cherry ###
* https://github.com/daltoniam
* http://twitter.com/daltoniam

