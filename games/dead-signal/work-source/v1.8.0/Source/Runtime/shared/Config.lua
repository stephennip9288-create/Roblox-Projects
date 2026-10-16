-- DEAD SIGNAL 1.7.0 | Original game, with credited CC0 graphics sources.
local C = {}
C.Version = "1.8.0"
C.Title = "DEAD SIGNAL"
C.MaxPlayers = 4
C.LobbyPlayers = 24
C.ArrivalGrace = 35
C.ReturnCountdown = 14
C.Extraction = {seconds=180, afterBossGrace=75, holdSeconds=12, radius=18, contestRadius=14, escorts=18, escortsPerPlayer=6}
C.Warden = {baseHealth=60000, roundHealth=90, extraPlayerHealth=.65, attackCap=.045, secondCap=.12, armor=.55, weakpoint=1.35, overloadSeconds=4}
C.MapArtworkIds = {Station="",Foundry="",Frost="",Lobby=""}
C.GraphicsBundleId = 0 -- Optional creator-owned DeadSignalArt Model. See Graphics-Setup.md.
C.BayHoldSeconds = 1800
C.TravelAttempts = 3
C.TripLeaseSeconds = 86400
C.Countdown = 10
C.Intermission = 14
C.StartPoints = 500
C.Economy = {hit=2, hitCap=10, kill=60, headshot=90, meleeHit=2, meleeKill=10, repair=5, repairCap=30, revive=100, roundBase=100, roundGrowth=3}
C.DownTime = 35
C.RegenDelay = 5
C.RegenRate = 22
C.MaxEnemies = 40
C.CorpseSeconds = 30
C.MaxCorpses = 60
C.ProfileStore = "DeadSignal_Profile_v1"
C.LeaseSeconds = 150
C.Autosave = 50
C.StudioPersistence = false -- Use a separate ProfileStore name when enabling cloud saves in Studio.
C.Maps = {
    Station = {name="Blackwater Station", subtitle="The broadcast never stopped.", scale=1,
        theme="Station", wall={66,69,67}, floor={43,45,43}, accent={217,77,53}, sky={84,88,97},
        rooms={"Reception", "Antenna Yard", "Generator", "Maintenance", "Control Room", "Signal Lab"},
        description="A compact ruined bunker, upper watch galleries, boarded windows, and a rain-dark antenna yard.",
        lore="At 03:17, Blackwater transmitted its final evacuation order. The same voice has been repeating it ever since. Restore the station before the signal finds another listener."},
    Foundry = {name="Cinderworks", subtitle="The furnace is still hungry.", scale=1.22,
        theme="Foundry", wall={81,55,43}, floor={51,44,39}, accent={255,137,45}, sky={109,62,44},
        rooms={"Clock House", "Smelter Yard", "Boiler Room", "Machine Shop", "Dispatch", "Crucible Lab"},
        description="An expanded steelworks with long connecting routes, machine galleries, and a gantry over the smelter yard.",
        lore="The last shift sealed the furnace doors from the inside. Something is still keeping the boilers hot. Cross the works, restore the transmitter, and earn a way out."},
    Frost = {name="Whiteout Relay", subtitle="Nothing stays buried in the ice.", scale=1.1,
        theme="Frost", wall={67,85,103}, floor={55,65,76}, accent={80,214,237}, sky={95,130,157},
        rooms={"Outpost", "Frozen Courtyard", "Reactor", "Supply Depot", "Operations", "Cryo Lab"},
        description="An expanded polar listening post with upper galleries, long supply routes, windblown snow, and frozen machinery.",
        lore="The relay heard a reply from beneath the ice. Its crew disappeared before they could send a warning. Now the storm is carrying their voices back across the perimeter."},
}
C.MapOrder = {"Station", "Foundry", "Frost"}
C.Modes = {
    Standard={name="Survival", health=1, enemies=1, damage=1, selfRevive=true, xp=1},
    Lockdown={name="Lockdown", health=1.3, enemies=1.15, damage=1.25, selfRevive=false, xp=1.35},
}
C.Weapons = {
    Kestrel={name="Kestrel 9", upgraded="Phoenix 9", class="Pistol", damage=30, head=3, rpm=360, mag=12, reserve=84, reload=1.7, spread=1.2, range=190, auto=false, cost=500, weight=0, color={174,178,181}},
    Carbine={name="Morrow Carbine", upgraded="Tomorrow's Promise", class="Rifle", damage=65, head=2.6, rpm=330, mag=18, reserve=162, reload=2.1, spread=1.4, range=270, auto=false, cost=800, weight=8, color={117,83,56}},
    Rook={name="Rook SMG", upgraded="Checkmate", class="SMG", damage=38, head=2.5, rpm=720, mag=32, reserve=224, reload=2.2, spread=2.2, range=170, auto=true, cost=1200, weight=14, color={95,100,95}},
    Trench={name="Trench 12", upgraded="Grave Digger", class="Shotgun", damage=34, head=1.8, rpm=90, mag=6, reserve=48, reload=2.8, spread=5.4, range=105, pellets=8, auto=false, cost=1500, weight=11, color={133,96,62}},
    Vandal={name="Vandal AR", upgraded="Civil Disobedience", class="Rifle", damage=48, head=2.6, rpm=600, mag=30, reserve=210, reload=2.5, spread=1.8, range=250, auto=true, cost=1800, weight=14, color={96,107,89}},
    Harrier={name="Harrier AR", upgraded="Three Bad Omens", class="Rifle", damage=64, head=2.7, rpm=520, mag=27, reserve=216, reload=2.3, spread=0.9, range=290, auto=true, cost=1900, weight=12, color={90,110,123}},
    Anchor={name="Anchor LMG", upgraded="Dead Weight", class="Heavy", damage=65, head=2.4, rpm=480, mag=75, reserve=300, reload=4.5, spread=2.6, range=260, auto=true, cost=2600, weight=9, color={83,87,76}},
    Longwatch={name="Longwatch", upgraded="Night Watch", class="Sniper", damage=280, head=3.5, rpm=65, mag=5, reserve=55, reload=2.9, spread=0.25, range=500, auto=false, pierce=3, cost=2200, weight=8, color={132,109,75}},
    Cyclone={name="Cyclone Auto", upgraded="Eye of the Storm", class="Shotgun", damage=30, head=2, rpm=240, mag=10, reserve=80, reload=3.1, spread=6, range=100, pellets=7, auto=true, cost=2400, weight=9, color={91,96,102}},
    Mantis={name="Mantis PDW", upgraded="Praying for Trouble", class="SMG", damage=43, head=2.6, rpm=840, mag=40, reserve=240, reload=2.4, spread=2, range=180, auto=true, cost=2100, weight=10, color={139,146,154}},
    Signal={name="Signal Cannon", upgraded="End of Transmission", class="Energy", damage=700, head=1.4, rpm=90, mag=8, reserve=48, reload=3.4, spread=0.5, range=250, auto=false, splash=10, cost=0, weight=3, color={68,218,224}},
    Vigil={name="Vigil .44", upgraded="Last Rites", class="Pistol", model="Revolver", damage=155, head=3, rpm=180, mag=6, reserve=72, reload=2.6, spread=.8, range=230, auto=false, cost=1400, weight=9, color={155,158,163}},
    Needle={name="Needle Machine Pistol", upgraded="Acupuncture", class="Pistol", model="MachinePistol", damage=32, head=2.6, rpm=900, mag=24, reserve=216, reload=1.9, spread=2.8, range=150, auto=true, cost=1600, weight=10, color={82,107,117}},
    Breaker={name="Breaker Double", upgraded="Final Notice", class="Shotgun", model="DoubleBarrel", damage=48, head=1.9, rpm=160, mag=2, reserve=64, reload=2.25, spread=5.2, range=110, pellets=10, auto=false, cost=1700, weight=10, color={151,99,63}},
    Sable={name="Sable Tactical", upgraded="Black Flag", class="Shotgun", model="Tactical", damage=37, head=2, rpm=170, mag=8, reserve=80, reload=2.7, spread=4.8, range=125, pellets=8, auto=false, cost=2200, weight=10, color={71,82,84}},
    Meridian={name="Meridian DMR", upgraded="Zero Hour", class="Rifle", model="DMR", damage=145, head=3.1, rpm=240, mag=14, reserve=140, reload=2.55, spread=.6, range=380, auto=false, pierce=2, cost=2500, weight=9, color={114,112,86}},
    Wasp={name="Wasp Compact", upgraded="Hornet's Nest", class="SMG", model="Compact", damage=40, head=2.5, rpm=780, mag=36, reserve=288, reload=1.95, spread=2.4, range=175, auto=true, cost=2000, weight=12, color={132,111,57}},
    Bulwark={name="Bulwark Drum", upgraded="Hold the Line", class="Heavy", model="Drum", damage=72, head=2.4, rpm=540, mag=100, reserve=400, reload=5, spread=2.9, range=280, auto=true, cost=3200, weight=7, color={103,111,92}},
    Halcyon={name="Halcyon Precision", upgraded="Quietus", class="Sniper", model="Precision", damage=390, head=3.3, rpm=80, mag=8, reserve=64, reload=3.15, spread=.2, range=550, auto=false, pierce=4, cost=3000, weight=6, color={177,178,165}},
    Arc={name="Arc Projector", upgraded="Storm Warning", class="Energy", model="Arc", damage=240, head=1.8, rpm=260, mag=18, reserve=108, reload=3.6, spread=.7, range=220, auto=true, chain=3, cost=0, weight=2, color={152,120,240}},
}
C.BoxPool = {"Carbine","Rook","Trench","Vandal","Harrier","Anchor","Longwatch","Cyclone","Mantis","Signal","Vigil","Needle","Breaker","Sable","Meridian","Wasp","Bulwark","Halcyon","Arc"}
C.Perks = {
    Ironheart={name="Ironheart", price=3500, round=5, color={222,62,59}, description="200 maximum health. More room to recover."},
    FastHands={name="Fast Hands", price=3500, round=6, color={84,194,116}, description="Reload twice as fast."},
    Overdrive={name="Overdrive", price=3250, round=8, color={248,181,51}, description="25% more weapon damage."},
    Marathon={name="Marathon", price=2750, round=4, color={76,170,234}, description="Faster movement and twice the sprint stamina."},
    Lifeline={name="Lifeline", price=2000, soloPrice=1000, round=3, soloRound=2, color={107,205,219}, description="Faster team revives. Solo: one automatic revive, three purchases per run."},
    Insulator={name="Insulator", price=3000, round=7, color={174,107,231}, description="Immunity to your own explosives and electrical traps."},
}
C.PerkOrder = {"Lifeline","Ironheart","FastHands","Marathon","Overdrive","Insulator"}
C.MaxPerks = 4
C.PerkExtraCost = 250 -- Each perk already held adds this many points to the next purchase.
C.Powerups = {
    Ammo={name="FULL SUPPLY", color={73,195,122}}, Double={name="DOUBLE POINTS", color={250,193,55}, duration=30},
    Instant={name="LETHAL SIGNAL", color={235,70,70}, duration=25}, Nuke={name="SIGNAL PURGE", color={237,150,60}},
    Repair={name="REINFORCEMENTS", color={87,177,232}}, Sale={name="CLEARANCE", color={198,123,239}, duration=25},
}
C.Skins = {
    {id="Factory", name="Factory Issue", cost=0, color={105,111,116}},
    {id="Copper", name="Burnished Copper", cost=300, color={193,112,68}},
    {id="Frost", name="Polar White", cost=600, color={212,231,235}},
    {id="Hazard", name="Hazard Yellow", cost=900, color={233,180,48}},
    {id="Spectral", name="Spectral Violet", cost=1400, color={175,114,233}},
    {id="Rescue", name="Rescue Orange", cost=1800, color={234,91,47}},
}
C.Achievements = {
    FirstShift={name="First Shift", description="Survive round 5.", credits=75},
    LongNight={name="A Long Night", description="Survive round 15.", credits=150},
    Deadeye={name="Dead Air, Dead Eye", description="50 headshot kills in one run.", credits=100},
    Guardian={name="No One Left Behind", description="Revive teammates 5 times in one run.", credits=125},
    Technician={name="Signal Technician", description="Restore the transmitter.", credits=100},
    Homebound={name="Homebound", description="Complete an extraction.", credits=200},
    LoneWolf={name="Lone Frequency", description="Reach round 10 as a solo crew.", credits=150},
}
C.DailyGoals = {
    {id="Kills", name="Terminate 100 infected", target=100, credits=100},
    {id="Rounds", name="Clear 15 rounds", target=15, credits=100},
    {id="Headshots", name="Land 25 headshot kills", target=25, credits=75},
}
-- Original WAV files for these cues are included in Audio/. Upload to your own
-- Roblox creator, then replace an empty value with the approved numeric asset ID.
-- Built-in engine sounds provide immediate feedback before custom audio is uploaded.
C.SoundIds = {Pistol="", Rifle="", SMG="", Heavy="", Shotgun="", Sniper="", Energy="", Reload="", Empty="", Hit="", Kill="", Grenade="", Round="", Power="", Box="", Perk="", Revive="", Down="", Enemy="", Ambient="", Victory="", Click="",Radio="",Machinery="",Wind="",Attack="",ShockCharge="",Board="",Equip="",Dispatch=""}
C.DefaultSettings = {volume=0.65, fov=80, shake=0.55, aimAssist=true, hitmarkers=true, lowEffects=false}
for key,value in pairs(require(script.Parent.ControlSettings).defaults) do C.DefaultSettings[key]=value end
C.ProfileStore="DeadSignal_Profile_v1"
C.StudioPersistence=false
C.SoundIds["Shotgun"]=""
C.SoundIds["Kill"]=""
C.SoundIds["Dispatch"]=""
C.SoundIds["Enemy"]=""
C.SoundIds["Sniper"]=""
C.SoundIds["Box"]=""
C.SoundIds["Board"]=""
C.SoundIds["ShockCharge"]=""
C.SoundIds["Heavy"]=""
C.SoundIds["Wind"]=""
C.SoundIds["Equip"]=""
C.SoundIds["Rifle"]=""
C.SoundIds["Revive"]=""
C.SoundIds["Grenade"]=""
C.SoundIds["Victory"]=""
C.SoundIds["Click"]=""
C.SoundIds["Radio"]=""
C.SoundIds["Power"]=""
C.SoundIds["Round"]=""
C.SoundIds["SMG"]=""
C.SoundIds["Machinery"]=""
C.SoundIds["Pistol"]=""
C.SoundIds["Down"]=""
C.SoundIds["Perk"]=""
C.SoundIds["Ambient"]=""
C.SoundIds["Hit"]=""
C.SoundIds["Empty"]=""
C.SoundIds["Reload"]=""
C.SoundIds["Energy"]=""
C.SoundIds["Attack"]=""
C.MapArtworkIds["Station"]="125594819014430"
C.MapArtworkIds["Foundry"]="133781122932272"
C.MapArtworkIds["Frost"]="83098782431426"
C.MapArtworkIds.Lobby="125594819014430"
return C