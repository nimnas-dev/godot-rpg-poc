class_name AndroidPlatformServices
extends PlatformServices

## Android composition root. Native provider classes are kept in one module so
## no game system depends on a third-party plugin's singleton method names.
const AndroidProviders = preload("res://scripts/platform/android_platform_services.gd")


func _init() -> void:
	super._init(
		AndroidProviders.new(),
		AndroidProviders.AndroidGooglePlayAchievementProvider.new(),
		AndroidProviders.AndroidBillingEntitlementProvider.new()
	)
