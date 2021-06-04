ScriptName ONightsPlayerAliasScript Extends ReferenceAlias

ONightsScript Property Main Auto

Event OnInit()
	Main = (GetOwningQuest()) as ONightsScript
EndEvent

Event OnPlayerLoadGame()
	Main.OnLoad()
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
	main.OnLocChange(aknewloc)
endEvent