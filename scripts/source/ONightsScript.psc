ScriptName ONightsScript extends Quest

OsexIntegrationMain ostim

actor playerref

int ralt = 184

bool debugbuild = false

AssociationType Spouse

AssociationType Courting


bool oromanceInstalled

ReferenceAlias Nav1
ReferenceAlias Nav2
ReferenceAlias TargetRef

actor[] actors

faction followerfaction

float lastSexTime


Keyword LocTypeCity
Keyword LocTypeTown

Bool SceneIsONights = false

GlobalVariable Property ONFreqMult Auto 
GlobalVariable Property ONStopWhenFound Auto

bool Function StopWhenFound()
	return (ONStopWhenFound.getvalueint() == 1)
endfunction

Float Function GetFreqMult()
	return ONFreqMult.GetValue()
endfunction


Event OnInit()
	ostim = game.GetFormFromFile(0x000801, "Ostim.esp") as OsexIntegrationMain

	if ostim.getAPIVersion() < 13
		Debug.MessageBox("Your OStim version is out of date. Please exit now and update to use ONights")
	endif

	playerref = game.GetPlayer()

	;debug.MessageBox("Installed")
	lastSexTime = 0.0

	oromanceInstalled = ostim.IsModLoaded("ORomance.esp")
	Spouse = Game.GetFormFromFile(0x0142CA, "Skyrim.esm") as AssociationType

	Courting = Game.GetFormFromFile(0x01EE23, "Skyrim.esm") as AssociationType

	quest q = self as quest 
	Nav1 = q.GetAliasById(0) as ReferenceAlias
	Nav2 = q.GetAliasById(1) as ReferenceAlias
	TargetRef = q.GetAliasById(2) as ReferenceAlias

	followerfaction = Game.GetFormFromFile(0x05C84E, "Skyrim.esm") as faction

	LocTypeTown = Keyword.GetKeyword("LocTypeTown")
	LocTypeCity = Keyword.GetKeyword("LocTypeCity")

	OnLoad()

	debug.Notification("ONights installed")
EndEvent

function OnLoad()
	if debugbuild
		RegisterForKey(ralt)
	endif 

	RegisterForModEvent("ostim_start", "OstimStart")
	RegisterForModEvent("ostim_end", "OstimEnd")
	;RegisterForModEvent(PathEvent, "PathThread")
EndFunction 

function test()
	;ostim.EndAnimation()
	;return 

	actor target = game.GetCurrentCrosshairRef() as actor 

	
	;ostim.Profile()
	;MiscUtil.ScanCellNPCS(playerref, radius = radi, HasKeyword = none)
	;console(ostim.Profile("Misutil"))
	;Utility.Wait(2)

	;ostim.StartScene(target, game.GetCurrentCrosshairRef() as actor )
;	debug.SendAnimationEvent(playerref, "IdleComeThisWay")
	
	console(HasGFBF(target))
	;console(ostim.randomint(0, 1))
	;ScanForSex()	
	;console(GetTimeUntilNight())

	;Console(IsSettlement(playerref.GetCurrentLocation()))
	

EndFunction 

Function UnregisterUpdates() 
	UnregisterForUpdateGameTime()
	UnregisterForUpdate()
EndFunction 

Event OnUpdateGameTime()
	console("Night update ran")

	If ostim.ChanceRoll(50)
		RegisterForSingleUpdate(3)
	else 
		RegisterForSingleUpdate(ostim.randomint(30, 120))
	endif 
EndEvent 

Event OnUpdate()
	console("Running update")

	If (TimeSinceLastSex() > GetMinimumSexWaitTime()) && !scanning && !playerref.IsInCombat()
		ScanForSex()
	EndIf

	If IsNight() && (TimeSinceLastSex() > 0.1)
		RegisterForSingleUpdate(120)
	EndIf
EndEvent

Function OnLocChange(Location NewLoc)
	console("changed")
	if (NewLoc != none) && !(IsSettlement(newloc))
		
		if debugbuild
			console(newloc.getname())
		endif 

		if ostim.ChanceRoll(5)
			scanning = false ;safety
		endif

		RegisterForNight()

	else 
		UnregisterUpdates()
	endif
EndFunction

Event OnKeyDown(int KeyPress)
	if KeyPress == ralt 
		test()
	endif
EndEvent

bool scanning = false

Function ScanForSex()
	scanning = True

	actor act = GetRandomActorForSex()

	If !act 
		return 
	endif

	If IsInBed(act)
		actor a = GetBedPartner(act) 
		If a 
			DoSex(act, a)
			return
		endif
	endif 

	actor partner  = FindCompatiblePartner(act)

	if partner 
		dosex(act, partner)
	endif 

	scanning = false
EndFunction

Actor[] Function ShuffleActorArray(Actor[] arr)
    
    int i = arr.length
    int j ; an index

    actor temp
    While (i > 0)
        i -= 1
        j = OStim.RandomInt(0, i)

        temp = arr[i]
        arr[i] = arr[j]
        arr[j] = temp 

    EndWhile
    return arr
EndFunction

float radi = 0.0

Actor Function GetRandomActorForSex()
	actors = MiscUtil.ScanCellNPCS(playerref, radius = radi, HasKeyword = none)
	actors = ShuffleActorArray(actors)


	int i = 0
	int l = actors.length 


	While i < l 
		If !IsActorInvalid(actors[i])
			return actors[i]
		else 
			actors[i] = none
		endif 

		i += 1
	EndWhile

	return none
EndFunction

Actor Function FindCompatiblePartner(actor act)
	console("Getting partner")
	;Actor[] actors = MiscUtil.ScanCellNPCS(act, radius = radi, HasKeyword = none)
	actors = ShuffleActorArray(actors)

	bool female = ostim.AppearsFemale(act)
	bool married = IsMarried(act)
	bool courted = HasGFBF(act)

	int i = 0
	int l = actors.length 

	actor partner
	While i < l 
		partner = actors[i]

		If IsActorInValid(partner)
			;
		else 

			If married 
				if IsNPCSpouse(act, partner)
					return partner
				endif 
			elseif courted
				if IsNPCGFBF(act, partner)
					return partner
				endif 
			else 
				if female 
					if !ostim.AppearsFemale(partner)
						return partner
					endif 
				elseif !female 
					if ostim.AppearsFemale(partner)
						return partner
					endif
				endif 

			endif

		endif  

		i += 1
	EndWhile

	return none
EndFunction

float targetDistance = 256.0

Function DoSex(actor dom, actor sub)
	If IsInBed(dom)

		if !IsInBed(sub) || (dom.GetDistance(sub) > 400)
			Seduce(sub, dom)
		EndIf 

		StartScene(dom, sub, FindBed(dom, 400, true))

		return
	elseif IsInBed(sub)
		
		if !IsInBed(dom) || (dom.GetDistance(sub) > 400)
			Seduce(dom, sub)
		EndIf

		StartScene(dom, sub, FindBed(sub, 400, true))

		return
	endif 

	ObjectReference bed = FindBed(sub, 2500)

	if !bed 
		bed = FindBed(dom, 2500)
	endif


	If bed == none 
		Seduce(dom, sub)

		
		StartScene(dom, sub)
	else 
		Seduce(dom, sub)

		if dom.GetDistance(sub) < 400
			TravelToBed(dom, sub, bed)

			StartScene(dom, sub, bed)
	    EndIf
	endif 

EndFunction

Function StartScene(actor dom, actor sub, ObjectReference bed = none)
	if dom.Is3DLoaded() && sub.Is3DLoaded() && (dom.GetDistance(sub) < 400)
		SceneIsONights = true
		ostim.StartScene(dom, sub, bed = bed)
		lastSexTime = Utility.GetCurrentGameTime()
	endif
EndFunction 

Function TravelToBed(actor act1, actor act2, ObjectReference bed)
	PathTo(act1, bed)
	PathTo(act2, bed)


	int stuckCheckCount = 0
	float x = act1.x 

	While (act1.GetDistance(bed) > targetDistance) && act1.Is3DLoaded()
		Utility.Wait(1)

		if x == act1.X 
			stuckCheckCount += 1

			if stuckCheckCount > 10
				ClearAliases()
				return
				;stuckCheckCount = 0
			endif 
		else 
			stuckCheckCount = 0
			x = act1.x
		endif 
	EndWhile

	 stuckCheckCount = 0
	 x = act2.x 

	While (act2.GetDistance(bed) > targetDistance) && act2.Is3DLoaded()
		Utility.Wait(1)

		if x == act2.X 
			stuckCheckCount += 1

			if stuckCheckCount > 10
				ClearAliases()
				return
			endif 
		else 
			stuckCheckCount = 0
			x = act2.x
		endif
	EndWhile

	ClearAliases()
EndFunction 

Function Seduce(actor act1, actor act2)
	Pathto(act1, act2)

	int stuckCheckCount = 0
	 
	float x = act1.X
	While (act1.GetDistance(act2) > targetDistance) && act1.Is3DLoaded()
		Utility.Wait(1)

		if x == act1.X 
			stuckCheckCount += 1

			if stuckCheckCount > 10
				ClearAliases()
				return 
			elseif stuckCheckCount > 5
				;debug.SendAnimationEvent(act1, "IdleForceDefaultState")
				;stuckCheckCount = 0
			endif 
		else 
			stuckCheckCount = 0
			x = act1.x
		endif 
	EndWhile

	act1.SetLookAt(act2, abPathingLookAt = false)
	Utility.Wait(0.5)
	act2.SetLookAt(act1, abPathingLookAt = false)
	debug.SendAnimationEvent(act1, "IdleComeThisWay")
	Utility.Wait(2)

	ClearAliases()
EndFunction

bool Function IsInBed(actor act)
	return (act.GetSleepState() > 2)
EndFunction

Actor Function GetBedPartner(actor act)
	Actor[] actorsz = MiscUtil.ScanCellNPCS(act, radius = 64.0, HasKeyword = none)

	if actorsz.length > 1
		If actorsz[0] == act 
			return actorsz[1]
		else 
			return actorsz[0]
		endif 
	else 
		return none
	endif 
EndFunction

ObjectReference Function FindBed(ObjectReference CenterRef, Float Radius = 0.0, bool AllowUsed = false)
	objectreference[] Beds = OSANative.FindBed(CenterRef, Radius, 1000.0)

	ObjectReference NearRef = None

	Int i = 0
	Int L = Beds.Length
	While (i < L)
		ObjectReference Bed = Beds[i]
		If AllowUsed || (!Bed.IsFurnitureInUse())
			NearRef = Bed
			i = L
		Else
			i += 1
		EndIf
	EndWhile


	If (NearRef)
		Console("Bed found")
		Return NearRef
	EndIf

	Console("Bed not found")
	Return None ; Nothing found in search loop
EndFunction

Bool Function IsActorInvalid(actor act)
	If  (act == none) || (act.IsInCombat()) || (act.IsGhost()) || (act == playerref) || (act.IsDead())  || (act.IsDisabled())|| !(act.is3dloaded()) || ostim.IsChild(act) || !(act.GetRace().HasKeyword(Keyword.GetKeyword("ActorTypeNPC"))) || (isplayerpartner(act)) || act.IsInDialogueWithPlayer() ||ostim.IsActorActive(act) || act.Isinfaction(followerfaction)
		If debugbuild
			console("Invalid: " + act.GetDisplayName())
		endif
		return true 
	else 
		if debugbuild
			console("Valid: " + act.GetDisplayName())		
		endif 
		return false
	endif 
Endfunction

Function PathTo(actor act, ObjectReference obj)
	console("Pathing...")
	if debugbuild
		console(act.GetDisplayName())
		console(obj.GetDisplayName())
	endif

	act.StartCombat(act)

	;act.EnableAI(false)
	;act.EnableAI(true)
	debug.SendAnimationEvent(act, "IdleForceDefaultState")

	TargetRef.ForceRefTo(obj)

	if Nav1.GetReference() == none
		Nav1.ForceRefTo(act)
	else 
		Nav2.ForceRefTo(act)
	endif

	act.EvaluatePackage()
EndFunction 

Function ClearAliases()
	Nav1.Clear()
	Nav2.Clear()
	TargetRef.clear()
EndFunction

string IsPlayerPartnerKey = "or_k_part"

bool function isPlayerPartner(actor npc)
	If !oromanceInstalled
		return false 
	endif 
	return GetNPCDataBool(npc, IsPlayerPartnerKey)
EndFunction

Bool function GetNPCDataBool(actor npc, string keys)
	int value = GetNPCDataInt(npc, keys)
	bool ret = (value == 1)
	;console("got value " + value + " for key " + keys)
	return ret
EndFunction

Int function GetNPCDataInt(actor npc, string keys)
	return StorageUtil.GetIntValue(npc, keys, -1)
EndFunction

bool Function IsMarried(actor npc)
	return npc.HasAssociation(Spouse)
EndFunction

bool function IsNPCSpouse(actor npc, actor otherNPC)
	return npc.HasAssociation(spouse, othernpc)
endfunction 


bool Function HasGFBF(actor npc)
	return npc.HasAssociation(Courting)
EndFunction

bool function IsNPCGFBF(actor npc, actor otherNPC)
	return npc.HasAssociation(Courting, othernpc)
endfunction 



Event OStimStart(string eventName, string strArg, float numArg, Form sender)

	If !SceneIsONights
		return 
	endif 

	If !StopWhenFound()
		return 
	endif 

	If !ostim.IsActorActive(playerref)
		While ostim.AnimationRunning()
			if playerref.IsDetectedBy(ostim.GetDomActor())
				If playerref.HasLOS(ostim.GetDomActor()) || ostim.GetDomActor().HasLOS(playerref)
				    ostim.endanimation()
				endif
			endif
			Utility.Wait(2)
		EndWhile
	endif 

EndEvent

Event OStimEnd(string eventName, string strArg, float numArg, Form sender)
	SceneIsONights = false
EndEvent 

function console(string in)
	if !debugbuild
		return
	endif 
	OsexIntegrationMain.Console(in)
EndFunction


int Function GetTimeOfDay() global ; 0 - day | 1 - morning/dusk | 2 - Night
	float hour = GetCurrentHourOfDay()

	if (hour < 4) || (hour > 20 ) ; 8:01 to 3:59. night
		return 2
	elseif ((hour >= 18) && (hour <= 20))  || ((hour >= 4) && (hour <= 6)) ; morning/dusk
		return 1
	Else
		return 0
	endif
		
EndFunction

float Function GetCurrentHourOfDay() global
 
	float Time = Utility.GetCurrentGameTime()
	Time -= Math.Floor(Time) ; Remove "previous in-game days passed" bit
	Time *= 24 ; Convert from fraction of a day to number of hours
	Return Time
 
EndFunction

bool Function IsNight()
	return (GetTimeOfDay() == 2)
EndFunction

Float Function GetTimeUntilNight()
	if GetTimeOfDay() == 2
		return 0.0
	else 
		float ret = (20 - GetCurrentHourOfDay())
		if ret < 0.1
			ret = 0.0
		endif 
		return ret
	endif 
EndFunction

Float Function TimeSinceLastSex()
	return utility.GetCurrentGameTime() - lastSexTime
EndFunction

Float Function GetMinimumSexWaitTime()
	return 0.75 / GetFreqMult()
EndFunction 


Bool Function IsSettlement(Location loc)
	return ( (loc.HasKeyword(LocTypeTown)) || (loc.HasKeyword(LocTypeCity)) )
EndFunction

Function RegisterForNight()
	RegisterForSingleUpdateGameTime(GetTimeUntilNight())
EndFunction