base_research = nil 
base_research = {
	{
		Name = "FighterDamageLevel1", 
		RequiredResearch = "", 
		RequiredSubSystems = "Research", 
		Cost = 1100, 
		Time = 60, 
		DisplayedName = "Upgradable base damage for HW1 fighters", 
		DisplayPriority = 1, 
		Description = "+16% fighter damage",
		UpgradeName = "WeaponDamage", 
		UpgradeValue = 0.875,
		UpgradeType = Modifier,
		TargetName = "Fighter", 
		TargetType = Family,
		Icon = Icon_Tech, 
		ShortDisplayedName = "Fighter Damage lvl 1",
	},
	{
		Name = "FighterDamageLevel2", 
		RequiredResearch = "FighterDamageLevel1", 
		RequiredSubSystems = "Research", 
		Cost = 1100, 
		Time = 65, 
		DisplayedName = "Upgradable base damage for HW1 fighters", 
		DisplayPriority = 2, 
		Description = "+14% fighter damage", 
		UpgradeName = "WeaponDamage", 
		UpgradeValue = 1,
		UpgradeType = Modifier,
		TargetName = "Fighter",
		TargetType = Family,
		Icon = Icon_Tech, 
		ShortDisplayedName = "Fighter Damage lvl 2",
	},
	{
		Name =			"FighterDrive",
		RequiredResearch =	"",
		RequiredSubSystems =	"Research",
		Cost = 			200,
		Time = 			35,
		DisplayedName =		"$11502",
		ShortDisplayedName =	"$11502",
		DisplayPriority =		11,
		Description =		"$11503",
		Icon = 			Icon_Build,
		TargetName =		"Kus_Scout",
	},
	{
		Name =			"FighterChassis",
		RequiredResearch =	"FighterDrive",
		RequiredSubSystems =	"Research",
		Cost = 			300,
		Time = 			40,
		DisplayedName =		"$11514",
		ShortDisplayedName =	"$11514",
		DisplayPriority =		12,
		Description =		"$11515",
		Icon = 			Icon_Build,
		TargetName =		"Kus_Interceptor",
	},
	{
		Name =			"DefenderSubSystems",
		RequiredResearch =	"FighterDrive",
		RequiredSubSystems =	"Research",
		Cost = 			800,
		Time = 			70,
		DisplayedName =		"$11528",
		ShortDisplayedName =	"$11528",
		DisplayPriority =		13,
		Description =		"$11529",
		Icon = 			Icon_Build,
		TargetName =		"Kus_Defender",
	},
	{
		Name =			"PlasmaBombLauncher",
		RequiredResearch =	"FighterChassis",
		RequiredSubSystems =	"Research",
		Cost = 			600,
		Time = 			50,
		DisplayedName =		"$11512",
		ShortDisplayedName =	"$11512",
		DisplayPriority =		14,
		Description =		"$11513",
		Icon = 			Icon_Build,
		TargetName =		"Kus_AttackBomber",
	},
	{
		Name =			"CloakedFighter",
		RequiredResearch =	"FighterChassis",
		RequiredSubSystems =	"Research",
		Cost = 			800,
		Time = 			80,
		DisplayedName =		"$11506",
		ShortDisplayedName =	"$11506",
		DisplayPriority =		15,
		Description =		"$11507",
		Icon = 			Icon_Build,
		TargetName =		"Kus_CloakedFighter",
	},

}

-- Add these items to the research tree!
for i,e in base_research do
	research[res_index] = e
	res_index = res_index+1
end

base_research = nil 
