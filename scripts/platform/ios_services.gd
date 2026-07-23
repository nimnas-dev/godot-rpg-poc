class_name IOSPlatformServices
extends PlatformServices

## iOS composition root. Singleton discovery is isolated from the game loop and
## no StoreKit/GameKit method is called without an explicit verified adapter.
const IOSProviders = preload("res://scripts/platform/ios_platform_services.gd")


func _init() -> void:
	super._init(
		IOSProviders.new(),
		IOSProviders.IOSGameCenterAchievementProvider.new(),
		IOSProviders.IOSStoreKitEntitlementProvider.new()
	)
