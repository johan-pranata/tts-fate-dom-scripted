---@diagnostic disable: lowercase-global
--[[ The onLoad event is called after the game save finishes loading. --]]
function onLoad()
    Pool = {
        ['Artoria'] = true,
    }
    test = true
end

--[[ Dear_J Code Start Here --]]
BASE_GAME_MASTERS_GUID = "575684"
ALL_MASTERS_GUID = "2cd95b"
BASE_GAME_SERVANTS_GUID = "d8f1d7"
ALL_SERVANTS_GUID = "b214c1"
deckEventGUID = "23cc85"
deckObjectiveGUID = "71cee8"
zoneEventGUID = "eec076"
zoneObjectiveGUID = "8d95fb"
zoneBurnedEventGUID = "964b4d"
zoneDiscardedObjectiveGUID = "bd72b8"
zoneRemovedObjectiveGUID = "ed3f66"
zoneActiveEventGUID = "1b2eea"
zoneMiyamaActiveObjectiveGUIDs = {"fdb584", "3d0cf5", "050d9f"}
zoneShintoActiveObjectiveGUIDs = {"baecc3", "cf5260"}
containerMastersGUID = BASE_GAME_MASTERS_GUID
containerServantsGUID = BASE_GAME_SERVANTS_GUID
zoneVPGUIDs = {"444e23", "f7d8c9", "342d38", "d95d7e", "cc7aa2", "95ef52", "c4aed1", "0fb17d", "696526", "e7b731", "c6a17d", "96399a", "d1781f", "102d0a", "52c935", "182fbb", "7a6864", "ea1e39", "417109", "727353", "ddce8c", "2c3b04", "649235", "b08a0a", "c0a1bd", "a856d7", "f1cb25", "adae75", "a6f32a", "7c80f1", "54ccfb", "b1f99b", "3f758b", "344387", "3b1b46", "c580b3", "d8c7a9", "e76013", "452e88"}

PHASES = {
    {name = "Preparation", color = "#F2F230"},
    {name = "Outpost", color = "#C2F261"},
    {name = "Action", color = "#91F291"},
    {name = "Combat", color = "#61F2C2"},
    {name = "End of Round", color = "#30F2F2"}}
GAME_START = false
ACTIVE_PLAYER_COLORS = {}

isSettingUpGame = false
isEndingTurn = false
isEliminatingPlayer = false

firstPlayerIndex = nil
currentPlayerCount = 1
currentEventGUID = nil

function ShuffleAllDecks()
    for i = 1, 3 do
        getObjectFromGUID(deckEventGUID).shuffle()
        getObjectFromGUID(deckObjectiveGUID).shuffle()
        getObjectFromGUID(containerMastersGUID).shuffle()
        getObjectFromGUID(containerServantsGUID).shuffle()
        WaitFrames(100)
    end
end

function SetupGameRun()
    startLuaCoroutine(Global, "SetupGame")
end

function SetupGame()
    UI.setAttribute("panelSetupGame", "active", "false")
    isSettingUpGame = true
    GAME_START = false
    broadcastToAll(MESSAGE_START_SETUP, "Green")

    CountPlayer()

    if #PLAYER_COLORS <= 0 then
        broadcastToAll(MESSAGE_NOT_ENOUGH_PLAYER, "Red")
        return 1
    end

    ShuffleAllDecks()
    if containerServantsGUID ~= BASE_GAME_SERVANTS_GUID then
        SetupServantPoolFromAll()
        WaitFrames(500)
    end
    for i, color in ipairs(PLAYER_COLORS) do
        SetupMaster(color, i)
        SetupServant(color, i)
    end

    for i = 1, 2 do
        getObjectFromGUID(deckEventGUID).takeObject({position = getObjectFromGUID(zoneBurnedEventGUID).getPosition()})
        WaitFrames(200)
    end

    isSettingUpGame = false
    GAME_START = true

    DoNextPhase()

    return 1
end

function CountPlayer()
    PLAYER_COLORS = {}
    for _, color in ipairs(AVAILABLE_COLORS) do
        if HasValue(getSeatedPlayers(), color) then
            table.insert(PLAYER_COLORS, color)
            table.insert(ACTIVE_PLAYER_COLORS, color)
        end
    end
end

function SetupServantPoolFromAll()
    local pool = getObjectFromGUID("b214c1")
    local sabers = getObjectFromGUID("ca7252")
    local lancers = getObjectFromGUID("ab218a")
    local archers = getObjectFromGUID("ed154c")
    local riders = getObjectFromGUID("60aa4c")
    local casters = getObjectFromGUID("9300b2")
    local assassins = getObjectFromGUID("79863c")
    local berserkers = getObjectFromGUID("e8b225")
    local extras = getObjectFromGUID("87b966")
    local classes = {
        sabers,
        lancers,
        archers,
        riders,
        casters,
        assassins,
        berserkers
    }
    local takeParams = {
        index = 0,
        position = {x=62.58, y=4.21, z=-3.54},
        rotation = {x=0,y=270,z=0},
        callback_function = function(obj)
            pool.putObject(obj)
            pool.shuffle()
        end,
    }
    for i=1,7 do
        classes[i].takeObject(takeParams)
        takeParams.position.y = takeParams.position.y + 1
    end
    classes[math.random(7)].takeObject(takeParams)
    takeParams.position.y = takeParams.position.y + 1
    extras.takeObject(takeParams)
    pool.shuffle()
    for i=1,7 do
        destroyObject(classes[i])
    end
    destroyObject(extras)
end

function SetupMaster(color, index)
    local containerMasters = getObjectFromGUID(containerMastersGUID)
    local zoneRight = getObjectFromGUID(PLAYER_DATA[color].zoneRightGUID)
    local containerMaster = containerMasters.takeObject({position = zoneRight.getPosition() - PLAYER_DATA[color].vectorStandee})
    -- 1 Standee
    -- 2 VP Tracker
    -- 3 Master Profile
    -- 4~5 Skills
    -- 6 Command Seals
    -- 7 Ascension
    local zoneVP0 = getObjectFromGUID(zoneVPGUIDs[1])
    local zoneMaster = getObjectFromGUID(PLAYER_DATA[color].zoneMasterGUID)
    local zoneMasterCommandSeals = {}
    for _, guid in ipairs(PLAYER_DATA[color].zoneMasterCommandSealGUIDs) do
        table.insert(zoneMasterCommandSeals, getObjectFromGUID(guid))
    end
    local zoneMasterSkills = {}
    for _, guid in ipairs(PLAYER_DATA[color].zoneMasterSkillGUIDs) do
        table.insert(zoneMasterSkills, getObjectFromGUID(guid))
    end

    WaitObjectUntilReady(containerMaster)

    -- Standee
    PLAYER_DATA[color].Standee = containerMaster.takeObject({position=zoneMaster.getPosition() + PLAYER_DATA[color].vectorStandee, rotation=PLAYER_DATA[color].rotation, smooth=false})
    -- VP Tracker
    PLAYER_DATA[color].VPTracker = containerMaster.takeObject({position=zoneVP0.getPosition() + Vector(0,index*1.5,0), rotation=PLAYER_DATA[color].rotation, smooth=false})
    -- Master Profile
    containerMaster.takeObject({position=zoneMaster.getPosition(), rotation=PLAYER_DATA[color].rotation, smooth=false})
    -- Ascension
    containerMaster.takeObject({index=0}).destruct()
    -- Command Seals
    local commandSeals = containerMaster.takeObject({index=0})
    for i = 1, 3 do
        commandSeals.takeObject({position=zoneMasterCommandSeals[i].getPosition(), rotation=PLAYER_DATA[color].rotation, smooth=false})
    end
    -- Skills
    for i, object in ipairs(containerMaster.getObjects()) do
        containerMaster.takeObject({position=zoneMasterSkills[((i-1)%4)+1].getPosition(), rotation=PLAYER_DATA[color].rotation, smooth=false})
    end
    containerMaster.destruct()
end

function SetupServant(color, index)
    local containerServants = getObjectFromGUID(containerServantsGUID)
    local zoneRight = getObjectFromGUID(PLAYER_DATA[color].zoneRightGUID)
    local containerServant = containerServants.takeObject({position = zoneRight.getPosition() + PLAYER_DATA[color].vectorStandee, rotation=PLAYER_DATA[color].rotation})
    -- 1 Servant Overview
    -- 2 Skills
    -- 3 Attack Deck
    local zoneServant = getObjectFromGUID(PLAYER_DATA[color].zoneServantGUID)
    local zoneServantSkills = {}
    for i, guid in ipairs(PLAYER_DATA[color].zoneServantSkillGUIDs) do
        table.insert(zoneServantSkills, getObjectFromGUID(guid))
    end
    local zoneServantAttackDeck = getObjectFromGUID(PLAYER_DATA[color].zoneServantAttackDeckGUID)
    local zoneServantDiscardAttackDeck = getObjectFromGUID(PLAYER_DATA[color].zoneServantDiscardAttackDeckGUID)

    WaitObjectUntilReady(containerServant)

    -- Servant Overview
    containerServant.takeObject({position=zoneServant.getPosition(), rotation=PLAYER_DATA[color].rotation+Vector(0,0,180), smooth=false})
    -- Skills
    local skills = containerServant.takeObject({})
    for i = 1, 3 do
        skills.takeObject({position=zoneServantSkills[i].getPosition(), rotation=PLAYER_DATA[color].rotation+Vector(0,0,180), smooth=false})
    end
    -- Attack Deck
    containerServant.takeObject({position=zoneServantAttackDeck.getPosition(), rotation=PLAYER_DATA[color].rotation+Vector(0,0,180), smooth=false})
    containerServant.destruct()
end

-- Phases:
-- 1. Prep
--     1. Reveal new event, check if there is mana gain, and event effect
--     2. Reveal new objective in Miyama and Shinto, Shinto is face-down.
--     3. Players draw from attack deck until hold 3 cards.
--     4. Any prep skill that can be activated now.
-- 2. Outpost/Day
--     1. Put standee on turn order, gain mana on magic workshop
-- 3. Reveal face-down objective in Shinto.
-- 4. Action/Night
--     1. Move (optional).
--     2. Attack place 2 cards. Skill only can be activated on >7 mana.
--     3. Any **Action** skill can be activated now.
--     4. Calculate total power.
-- 5. Combat/Night
--     1. In turn order, player may activate **Combat** skill.
--     2. The winner will get VP from objectives + location VP bonus(2 Miyama and 3 Shinto, only applied if there are >1 players)
--     3. Split the VP evenly rounded up for even matches.
--     4. If player is on Recon, they simply collect 2 VP.
-- 6. Retrieve master, discard all face-up objective cards.
-- 7. Start new round until round 11, don't forget the elimination

function DoNextPhase()
    if not currentPhaseIndex then
        currentPhaseIndex = 1
    else
        currentPhaseIndex = (currentPhaseIndex % #PHASES) + 1
    end

    UpdatePhasePanel(PHASES[currentPhaseIndex])

    if PHASES[currentPhaseIndex].name == "Preparation" then
        if not currentRound then
            currentRound = 1
        else
            currentRound = currentRound + 1
        end

		-- Returning all standees to their owners
		for _, color in ipairs(ACTIVE_PLAYER_COLORS) do
			if PLAYER_DATA[color].Standee ~= nil then
				local playerData = PLAYER_DATA[color]
				local zoneMaster = getObjectFromGUID(playerData.zoneMasterGUID)
				playerData.Standee.setPosition(zoneMaster.getPosition() + playerData.vectorStandee)
			end
		end

        Wait.time(
            function()
                broadcastToAll("Starting round "..currentRound.."!", "Pink")
            end,
            0.5
        )
        Wait.time(
            function()
                broadcastToAll(PHASES[currentPhaseIndex].name .. " Phase", "Pink")
            end, 1)

        -- Set first player color
        if currentRound == 1 then
            local rndNum = math.random(1, #ACTIVE_PLAYER_COLORS)
            currentPlayerIndex = rndNum
            firstPlayerIndex = rndNum

            local color = ACTIVE_PLAYER_COLORS[currentPlayerIndex]
            Wait.time(
                function()
                    broadcastToAll(PHASES[currentPhaseIndex].name.." - Player "..color.." Turn!", color)
                end, 2)
        end

        UpdateCurrentPlayerText()

        -- Check deck event
        local zoneEvent = getObjectFromGUID(zoneEventGUID)
        local eventDeck = nil
        --- Check for face-down events
        for _, object in ipairs(zoneEvent.getObjects()) do
            if not eventDeck and object.getRotation()[3] > 90 then
                eventDeck = object
            end
        end
        --- Check for face-up events (Climax)
        if not eventDeck then
            for _, object in ipairs(zoneEvent.getObjects()) do
                if not eventDeck and HasValue({"Deck", "Card"}, object.type) then
                    eventDeck = object
                end
            end
        end
        --- Put event to current event
        if eventDeck then
            local zoneActiveEvent = getObjectFromGUID(zoneActiveEventGUID)
            if eventDeck.type == "Deck" then
                currentEventGUID = eventDeck.takeObject({
                    position = zoneActiveEvent.getPosition(),
                    rotation = {0,180,0},
                    isSmooth = false
                }).guid
            elseif eventDeck.type == "Card" then
                eventDeck.setPosition(zoneActiveEvent.getPosition())
                eventDeck.setRotation({0,180,0})
                currentEventGUID = eventDeck.guid
            end
        end

        -- Show preparation actions
        Wait.time(
            function()
                broadcastToAll("Reveal new event, gain mana from it, and apply its effect!", "Pink")
            end,
            2
        )
        Wait.time(
            function()
                broadcastToAll("Reveal new objective in Miyama and Shinto!", "Pink")
            end,
            3.5
        )
        Wait.time(
            function()
                broadcastToAll("Draw action card until each player has 3 cards!", "Pink")
            end,
            5
        )
        Wait.time(
            function()
                broadcastToAll("Players may activate Prep skill in turn order", "Pink")
            end,
            6.5
        )
    else
        broadcastToAll(PHASES[currentPhaseIndex].name .. " Phase", "Pink")
        if PHASES[currentPhaseIndex].name == "Outpost" then
            Wait.time(
                function()
                    broadcastToAll("Put standee to location in turn order!", "Pink")
                end, 1)
        elseif PHASES[currentPhaseIndex].name == "Action" then
            Wait.time(
                function()
                    broadcastToAll("Pick and set 2 attack cards!", "Pink")
                end, 1)
            Wait.time(
                function()
                    broadcastToAll("Resolve Action effect in turn order!", "Pink")
                end, 3)
        elseif PHASES[currentPhaseIndex].name == "Combat" then
            Wait.time(
                function()
                    broadcastToAll("Resolve Combat effect in turn order!", "Pink")
                end, 1)
        elseif PHASES[currentPhaseIndex].name == "End of Round" then
            local currentRound = currentRound
            Wait.time(
                function()
                    broadcastToAll("Sum up each players VP point!", "Pink")
                end, 1)

            Wait.time(
                function()
                    if currentRound == 8 then
                        broadcastToAll("Eliminate all but the top 4 players!", "Pink")
                    elseif currentRound == 9 then
                        broadcastToAll("Eliminate all but the top 3 players!", "Pink")
                    elseif currentRound == 10 then
                        broadcastToAll("Eliminate all but the top 2 players!", "Pink")
                    elseif currentRound == 11 then
                        broadcastToAll("Pick the Holy Grail War Winner by the highest VP!", "Pink")
                    end
                end, 3)
        end
    end
end

function DoEndTurn(player, value, id)
    if value ~= "Eliminate" then
        if player.color ~= ACTIVE_PLAYER_COLORS[currentPlayerIndex] then
            return
        elseif isEndingTurn or isEliminatingPlayer then
            return
        end
    end

    isEndingTurn = true

    if currentPlayerCount < GetAlivePlayersCount() then
        currentPlayerIndex = NextPlayer(currentPlayerIndex)
        if value ~= "Eliminate" then
            currentPlayerCount = (currentPlayerCount or 0) + 1
        end
    else
        if PHASES[currentPhaseIndex].name == "End of Round" then
            firstPlayerIndex = NextPlayer(firstPlayerIndex)
            currentPlayerIndex = firstPlayerIndex
        else
            currentPlayerIndex = NextPlayer(currentPlayerIndex)
        end
        if value ~= "Eliminate" then
            currentPlayerCount = 1
            DoNextPhase()
        end
    end

    UpdateCurrentPlayerText()

    isEndingTurn = false

    local color = ACTIVE_PLAYER_COLORS[currentPlayerIndex]
    Wait.time(
        function()
            broadcastToAll(PHASES[currentPhaseIndex].name.." - Player "..color.." Turn!", color)
        end, 1)
end

function DoElimination(player, value, id)
    if not PLAYER_DATA[player.color].isAlive then
        return
    elseif isEndingTurn or isEliminatingPlayer then
        return
    end

    isEliminatingPlayer = true

    UI.setAttribute("buttonAlive"..player.color, "text", "Eliminated")
    UI.setAttribute("buttonAlive"..player.color, "colors", "Grey|Grey|Grey|Grey")
    UI.setAttribute("buttonAlive"..player.color, "interactable", "false")

    UI.setAttribute("buttonEndTurn"..player.color, "colors", "Grey|Grey|Grey|Grey")
    UI.setAttribute("buttonEndTurn"..player.color, "interactable", "false")

    PLAYER_DATA[player.color].isAlive = false

    for i, color in ipairs(ACTIVE_PLAYER_COLORS) do
        if color == player.color then
            if i == currentPlayerIndex then
                DoEndTurn(player, "Eliminate", nil)
            end
            break
        end
    end

    isEliminatingPlayer = false
end

function NextPlayer(currentIndex)
    for loopIndex=1,#ACTIVE_PLAYER_COLORS+1 do
        currentIndex = (currentIndex % #ACTIVE_PLAYER_COLORS) + 1
        if PLAYER_DATA[ACTIVE_PLAYER_COLORS[currentIndex]].isAlive then
            return currentIndex
        end
    end
    return nil
end

function GetAlivePlayersCount()
    local count = 0
    for i=1, #ACTIVE_PLAYER_COLORS do
        if PLAYER_DATA[ACTIVE_PLAYER_COLORS[i]].isAlive then
            count = count + 1
        end
    end
    return count
end

-- UI FUNCTIONS
function HideSetupGame()
    if UI.getAttribute("panelSetupGameContent", "active") == "true" then
        UI.setAttribute("panelSetupGameContent", "active", "false")
        UI.setAttribute("buttonShowHide", "width", "100")
        UI.setAttribute("buttonShowHide", "text", "Show Setup")
        UI.setAttribute("buttonShowHide", "textColor", "rgba(255,255,255,0.9)")
        UI.setAttribute("panelSetupGame", "height", "30")
    else
        UI.setAttribute("panelSetupGameContent", "active", "true")
        UI.setAttribute("buttonShowHide", "text", "Hide")
        UI.setAttribute("buttonShowHide", "textColor", "rgba(255,255,255,0.9)")
        UI.setAttribute("panelSetupGame", "height", "300")
    end
end

function SelectMasterPool(player, option, id)
    if option == "Base game only" then
        containerMastersGUID = BASE_GAME_MASTERS_GUID
    elseif option == "All" then
        containerMastersGUID = ALL_MASTERS_GUID
    end
end

function SelectServantPool(player, option, id)
    if option == "Base game only" then
        containerServantsGUID = BASE_GAME_SERVANTS_GUID
    elseif option == "All" then
        containerServantsGUID = ALL_SERVANTS_GUID
    end
end

function UpdateCurrentPlayerText()
    for _, color in ipairs(PLAYER_COLORS) do
        UI.setAttribute("textCurrentPlayer"..color, "color", ACTIVE_PLAYER_COLORS[currentPlayerIndex])
        UI.setValue("textCurrentPlayer"..color, ACTIVE_PLAYER_COLORS[currentPlayerIndex])
    end
end

function UpdatePhasePanel(phase)
    for _, color in ipairs(PLAYER_COLORS) do
        UI.setValue("textCurrentPhase"..color, phase.name)
        UI.setAttribute("textCurrentPhase"..color, "color", phase.color)
        UI.setAttribute("panelPhase"..color, "active", "true")
    end
end

-- STATIC VARIABLES
MESSAGE_START_SETUP = "Setting up game, please wait..."
MESSAGE_FINISH_SETUP = "Finished game setup"
MESSAGE_NOT_ENOUGH_PLAYER = "Please have a seat on available colors!"

PLAYER_COLORS = {}
AVAILABLE_COLORS = {"Red", "Orange", "Yellow", "Green", "Blue", "Purple", "White"}
PLAYER_DATA = {
    Red = {
        isAlive = true,
        rotation = Vector(0,180,0),
        zoneRightGUID = "069282",
        zoneMasterGUID = "16f259",
        vectorStandee = Vector(0,0,3),
        zoneMasterCommandSealGUIDs = {"225775", "03d79d", "3becf1"},
        zoneMasterSkillGUIDs = {"844ff1", "22a28d", "71ed11", "ac3a56"},
        zoneServantGUID = "5e9a05",
        zoneServantSkillGUIDs = {"fbc369", "be1678", "391b21"},
        zoneServantAttackDeckGUID = "00ff46",
        zoneServantDiscardAttackDeckGUID = "bf0803"
    },
    Orange = {
        isAlive = true,
        rotation = Vector(0,180,0),
        zoneRightGUID = "bf0925",
        zoneMasterGUID = "e36f41",
        vectorStandee = Vector(0,0,3),
        zoneMasterCommandSealGUIDs = {"7ff156", "4cd401", "8e0ae9"},
        zoneMasterSkillGUIDs = {"4eeb3f", "3b3933", "c30780", "1232cc"},
        zoneServantGUID = "8068bd",
        zoneServantSkillGUIDs = {"55f9dd", "1afbdb", "b41f65"},
        zoneServantAttackDeckGUID = "ea5979",
        zoneServantDiscardAttackDeckGUID = "c8ed91"
    },
    Yellow = {
        isAlive = true,
        rotation = Vector(0,180,0),
        zoneRightGUID = "1c7c5a",
        zoneMasterGUID = "71cca0",
        vectorStandee = Vector(0,0,3),
        zoneMasterCommandSealGUIDs = {"3dd505", "acc607", "95024a"},
        zoneMasterSkillGUIDs = {"2e7416", "ff96e3", "bc2718", "28b924"},
        zoneServantGUID = "6aa96f",
        zoneServantSkillGUIDs = {"c0501b", "0e1d6b", "6b69a1"},
        zoneServantAttackDeckGUID = "446273",
        zoneServantDiscardAttackDeckGUID = "a59edf"
    },
    Green = {
        isAlive = true,
        rotation = Vector(0,270,0),
        zoneRightGUID = "775a0a",
        zoneMasterGUID = "b36edb",
        vectorStandee = Vector(3,0,0),
        zoneMasterCommandSealGUIDs = {"f48f1d", "8125e0", "1fff78"},
        zoneMasterSkillGUIDs = {"7c3736", "0dbed2", "486801", "6361a8"},
        zoneServantGUID = "cb4e52",
        zoneServantSkillGUIDs = {"2687e4", "e59382", "464992"},
        zoneServantAttackDeckGUID = "24dffb",
        zoneServantDiscardAttackDeckGUID = "57d470"
    },
    Blue = {
        isAlive = true,
        rotation = Vector(0,0,0),
        zoneRightGUID = "402c21",
        zoneMasterGUID = "0b4d22",
        vectorStandee = Vector(0,0,-3),
        zoneMasterCommandSealGUIDs = {"c38b2e", "884f69", "27c977"},
        zoneMasterSkillGUIDs = {"1348fa", "3f0677", "42edee", "94dc13"},
        zoneServantGUID = "b0f2c9",
        zoneServantSkillGUIDs = {"c04b28", "404083", "568764"},
        zoneServantAttackDeckGUID = "6cd654",
        zoneServantDiscardAttackDeckGUID = "277204"
    },
    Purple = {
        isAlive = true,
        rotation = Vector(0,0,0),
        zoneRightGUID = "d6bf66",
        zoneMasterGUID = "71350c",
        vectorStandee = Vector(0,0,-3),
        zoneMasterCommandSealGUIDs = {"f7b849", "1d7f41", "b353b6"},
        zoneMasterSkillGUIDs = {"e112bc", "69b14c", "368f7e", "0a8f37"},
        zoneServantGUID = "aa8a4c",
        zoneServantSkillGUIDs = {"d6ac26", "0e607e", "3afcca"},
        zoneServantAttackDeckGUID = "0aa380",
        zoneServantDiscardAttackDeckGUID = "2d3636"
    },
    White = {
        isAlive = true,
        rotation = Vector(0,0,0),
        zoneRightGUID = "41dfe0",
        zoneMasterGUID = "f8d55c",
        vectorStandee = Vector(0,0,-3),
        zoneMasterCommandSealGUIDs = {"5600c2", "2cd351", "9391a7"},
        zoneMasterSkillGUIDs = {"9e0723", "37bf37", "740af8", "6a5334"},
        zoneServantGUID = "d0d922",
        zoneServantSkillGUIDs = {"225a45", "f1ef51", "fc2214"},
        zoneServantAttackDeckGUID = "05ebb1",
        zoneServantDiscardAttackDeckGUID = "7951ee"
    }
}

EVENTS = {
	-- Normal Events
	["Turning Point"] = {
		mana = 2,
		description = "Add a face-up objective to [Miyama] and [Shinto]."
	},
	["Battle in Shinto"] = {
		mana = 2,
		description = "Add a face-up objective to [Shinto]."
	},
	["Killers in Miyama"] = {
		mana = 2,
		description = "Add a face-up objective to [Miyama]."
	},
	["Visions of a Distant Life"] = {
		mana = 0,
		description = "Players in [Miyama] and [Shinto] gain +3 total power, if all their attacks have at least 1 matching type."
	},
	["Angra Mainyu's Essence"] = {
		mana = 0,
		description = "Magic type attacks gain +1 power in [Miyama] and [Shinto].\nNoble Phantasms cannot be used."
	},
	["Angra Mainyu's Shade"] = {
		mana = 0,
		description = "Agility type attacks gain +1 power in [Miyama] and [Shinto].\nNoble Phantasms cannot be used."
	},
	["Angra Mainyu's Curse"] = {
		mana = 0,
		description = "Strength type attacks gain +1 power in [Miyama] and [Shinto].\nNoble Phantasms cannot be used."
	},
	["Overwhelming Rage"] = {
		mana = 2,
		description = "Strength type attacks gain +2 power in [Miyama] and [Shinto]."
	},
	["Calm before the Storm"] = {
		mana = 2,
		description = "Agility type attacks gain +2 power in [Miyama] and [Shinto]."
	},
	["Perfect Flow"] = {
		mana = 2,
		description = "Magic type attacks gain +2 power in [Miyama] and [Shinto]."
	},

	-- Climax Events
	["The Night Fate Stood Still"] = {
		mana = 4,
		description = "Climax: 4+ Players left.\nAdd a face-up objectives to [Miyama] and [Shinto]."
	},
	["At the Gates of Hell"] = {
		mana = 4,
		description = "Climax: 3+ Players left.\nBan acces to [Shinto], Recon and all but one space in the [Workshop].\nAdd 1 face-up objectives to [Miyama]."
	},
	["Heaven's Feel"] = {
		mana = 6,
		description = "Climax: 2+ Players left.\nBan acces to [Shinto], Recon and all but one space in the [Workshop].\nAdd 2 face-up objectives to [Miyama]."
	}
}

-- BASIC FUNCTIONS
function WaitFrames(frames)
    while frames > 0 do
        coroutine.yield(0)
        frames = frames - 1
    end
end

--- To check if array has value
---@param table table
---@param value any
function HasValue(table, value)
    for i, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

--- Wait object until it is ready. To use this function you need to call it
--- under startLuaCoroutine (ex. startLuaCoroutine(Global, "startGame")).
--- @param object any
function WaitObjectUntilReady(object)
    if object == nil then
       return
    end
    repeat
       WaitFrames(25)
    until object == nil or (object.resting and not object.isSmoothMoving())
end

--- To get a specific object with type(s) in zone
---@param zone any
---@param types table
function GetObjectFromZone(zone, types)
    for _, object in ipairs(zone.getObjects()) do
        if HasValue(types, object.type) then
            return object
        end
    end
    return nil
end

function table.clone(org)
    return {table.unpack(org)}
end

--[[ Dear_J Code Start End Here --]]

function getPool(name)
    return Pool[name]
end

function togglePool(name)
    Pool[name] = not Pool[name]
end