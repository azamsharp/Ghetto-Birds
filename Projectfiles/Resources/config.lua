--[[
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim. 
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
--]]


--[[
		* Need help with the KKStartupConfig settings?
		* ------ http://www.kobold2d.com/x/ygMO ------
--]]


local config =
{
	KKStartupConfig = 
	{
		-- load first scene from a class with this name, or from a Lua script with this name with .lua appended
		FirstSceneClassName = "GameLayer",

		-- set the director type, and the fallback in case the first isn't available
		DirectorType = DirectorType.DisplayLink,
		DirectorTypeFallback = DirectorType.NSTimer,

		MaxFrameRate = 60,
		DisplayFPS = YES,

		EnableUserInteraction = YES,
		EnableMultiTouch = NO,

		-- Render settings
		DefaultTexturePixelFormat = TexturePixelFormat.RGBA8888,
		GLViewColorFormat = GLViewColorFormat.RGB565,
		GLViewDepthFormat = GLViewDepthFormat.DepthNone,
		GLViewMultiSampling = NO,
		GLViewNumberOfSamples = 0,

		Enable2DProjection = NO,
		EnableRetinaDisplaySupport = NO,	-- there are no Retina assets in this template project
		EnableGLViewNodeHitTesting = NO,
		EnableStatusBar = NO,

		-- Orientation & Autorotation
		DeviceOrientation = DeviceOrientation.LandscapeLeft,
		AutorotationType = Autorotation.CCDirector,
		ShouldAutorotateToLandscapeOrientations = YES,
		ShouldAutorotateToPortraitOrientations = NO,
		AllowAutorotateOnFirstAndSecondGenerationDevices = YES,
	
		-- iAd setup
		EnableAdBanner = NO,
		PlaceBannerOnBottom = YES,
		LoadOnlyPortraitBanners = NO,
		LoadOnlyLandscapeBanners = NO,
		AdProviders = "iAd, AdMob",	-- comma seperated list -> "iAd, AdMob" means: use iAd if available, otherwise AdMob
		AdMobRefreshRate = 15,
		AdMobFirstAdDelay = 5,
		AdMobPublisherID = "YOUR_ADMOB_PUBLISHER_ID", -- how to get an AdMob Publisher ID: http://developer.admob.com/wiki/PublisherSetup
		AdMobTestMode = YES,

		-- Mac OS specific settings
		AutoScale = NO,
		AcceptsMouseMovedEvents = NO,
		WindowFrame = RectMake(1024-640, 768-480, 640, 480),
		EnableFullScreen = NO,
	},
	
	-- you can create your own config sections using the same mechanism and use KKConfig to access the parameters
	-- or use the KKConfig injectPropertiesFromKeyPath method
	MySettings =
	{
	},
}

return config
