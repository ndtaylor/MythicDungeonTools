---Track spells casted by enemies, susceptibility to crowd control and base health and add them to the dataset
local db
local f
local MDT = MDT

-- CHANGE HERE TO DEFINE WHICH DUNGEONS TO TRACK FOR DATA COLLECTION
local dungeonsToTrack = {
  [1] = 49,
  [2] = 48,
  [3] = 51,
  [4] = 50,
  [5] = 8,
  [6] = 16,
  [7] = 22,
  [8] = 77,
}

MDT.DataCollection = {}
local DC = MDT.DataCollection
function DC:Init()
  print("MDT: Spell+Characteristics Tracking Init")
  db = MDT:GetDB()
  db.dataCollection = db.dataCollection or {}
  db.dataCollectionCC = db.dataCollectionCC or {}
  db.dataCollectionGUID = db.dataCollectionGUID or {}
  f = CreateFrame("Frame")
  f:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  f:RegisterEvent("CHALLENGE_MODE_START")
  f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:SetScript("OnEvent", function(self, event, ...)
    return DC[event](self, ...)
  end)

  -- add already collected spells to the data
  for k, dungeonIndex in pairs(dungeonsToTrack) do
    DC:AddCollectedDataToEnemyTable(dungeonIndex)
  end
  MDT:CleanEnemyInfoSpells()
end

function DC:AddCollectedDataToEnemyTable(dungeonIndex, ignoreSpells, ignoreCC)
  db = MDT:GetDB()
  if not dungeonIndex then dungeonIndex = db.currentDungeonIdx end
  --add spells/characteristics from db to dungeonEnemies
  local spellsAdded = 0
  local ccAdded = 0
  local enemies = MDT.dungeonEnemies[dungeonIndex]
  local collectedData = db.dataCollection[dungeonIndex]
  if collectedData and not ignoreSpells then
    for id, spells in pairs(collectedData) do
      for enemyIdx, enemy in pairs(enemies) do
        if enemy.id == id then
          enemy.spells = enemy.spells or {}
          for spellId, _ in pairs(spells) do
            if not enemy.spells[spellId] then
              spellsAdded = spellsAdded + 1
            end
            enemy.spells[spellId] = enemy.spells[spellId] or {}
          end
        end

      end
    end
  end
  local collectedCC = db.dataCollectionCC[dungeonIndex]
  if collectedCC and not ignoreCC then
    for id, characteristics in pairs(collectedCC) do
      for enemyIdx, enemy in pairs(enemies) do
        if enemy.id == id then
          enemy.characteristics = enemy.characteristics or {}
          for characteristic, _ in pairs(characteristics) do
            if not enemy.characteristics[characteristic] then
              ccAdded = ccAdded + 1
            end
            enemy.characteristics[characteristic] = true
          end
        end
      end
    end
  end

  if not ignoreSpells then print("Added " .. spellsAdded .. " new spells") end
  if not ignoreCC then print("Added " .. ccAdded .. " new CC characteristics") end
end

local trackedEvents = {
  ["SPELL_CAST_SUCCESS"] = true,
  ["SPELL_CAST_START"] = true,
  ["SPELL_MISSED"] = true,
  ["SPELL_DAMAGE"] = true,
  ["SPELL_AURA_REMOVED"] = true,
  ["SPELL_AURA_APPLIED"] = true,
}
local characteristicsSpells = {
  ["Slow"] = {
    [3409] = true; --Crippling Poison
    [45524] = true; --Chains of Ice
  };
  ["Stun"] = {
    [1833] = true, --Cheap Shot
    [408] = true, --Kidney Shot
    [179057] = true, --Chaos Nova
    [119381] = true, --Leg Sweep
    [30283] = true, --Shadowfury
    [108194] = true, --Asphyxiate
  },
  ["Sap"] = {
    [6770] = true,
  },
  ["Imprison"] = {
    [217832] = true,
  },
  ["Incapacitate"] = {
    [1776] = true, --Gouge
    [115078] = true, --Paralysis
  },
  ["Repentance"] = {
    [20066] = true,
  },
  ["Disorient"] = {
    [2094] = true, --Blind
    [31661] = true, --Dragon's breath
  },
  ["Banish"] = {
    [710] = true, --Banish
  },
  ["Fear"] = {
    [118699] = true, --Fear
    [8122] = true, --Psychich Scream
    [5246] = true, --Intimidating Shout
    [207685] = true, --Sigil of Misery
  },
  ["Root"] = {
    [122] = true, --Frost Nova
    [339] = true, --Entangling Roots
    [102359] = true, --Mass Root
    [117526] = true, --Binding Shot
  },
  ["Polymorph"] = {
    [161354] = true,
    [126819] = true,
    [61780] = true,
    [118] = true,
    [277787] = true,
    [277792] = true,
    [161355] = true,
    [161372] = true,
    [61721] = true,
    [61305] = true,
    [28271] = true,
    [28272] = true,
    [33786] = true,
    [20066] = true,
    [5782] = true,
    [51514] = true,
    [277778] = true,
    [277784] = true,
    [269352] = true,
    [211004] = true,
    [211010] = true,
    [211015] = true,
    [210873] = true,
  },
  ["Shackle Undead"] = {
    [9484] = true,
  },
  ["Mind Control"] = {
    [605] = true,
    [205364] = true,
  },
  ["Grip"] = {},
  ["Knock"] = {},
  ["Silence"] = {
    [15487] = true, --Silence
    [204490] = true, --Sigil of Silence
  },
  ["Taunt"] = {
    [56222] = true, --Dark Command
    [355] = true, --Taunt
    [185245] = true, --Torment
    [116189] = true, --Provoke
  },
  ["Control Undead"] = {
    [111673] = true,
  },
  ["Subjugate Demon"] = {
    [1098] = true,
  },
}
local cmsTimeStamp
function DC.CHALLENGE_MODE_START(self, ...)
  local _, timeCM = GetWorldElapsedTime(1)
  if timeCM > 0 then return end
  cmsTimeStamp = GetTime()
end

function DC.CHALLENGE_MODE_COMPLETED(self, ...)
  cmsTimeStamp = nil
end

function DC.PLAYER_ENTERING_WORLD(self, ...)
  if C_ChallengeMode.IsChallengeModeActive() then return end
  cmsTimeStamp = nil
end

function DC.COMBAT_LOG_EVENT_UNFILTERED(self, ...)
  local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool = CombatLogGetCurrentEventInfo()
  --enemy spells
  if trackedEvents[subevent] then
    local unitType, _, serverId, instanceId, zoneId, id, spawnUid = strsplit("-", sourceGUID)
    id = tonumber(id)
    --dungeon
    for _, i in pairs(dungeonsToTrack) do
      local enemies = MDT.dungeonEnemies[i]
      --enemy
      for enemyIdx, enemy in pairs(enemies) do
        if id and spellId and enemy.id == id then
          db.dataCollection[i] = db.dataCollection[i] or {}
          db.dataCollection[i][id] = db.dataCollection[i][id] or {}
          db.dataCollection[i][id][spellId] = {}
          enemy.spells = enemy.spells or {}
          enemy.spells[spellId] = enemy.spells[spellId] or {}
          break
        end
      end
    end
  end
  --characteristics
  if subevent == "SPELL_AURA_APPLIED" then
    local unitType, _, serverId, instanceId, zoneId, id, spawnUid = strsplit("-", destGUID)
    id = tonumber(id) or 0

    --dungeon
    for _, i in pairs(dungeonsToTrack) do
      local enemies = MDT.dungeonEnemies[i]
      --enemy
      for enemyIdx, enemy in pairs(enemies) do
        if enemy.id == id then
          for characteristic, spells in pairs(characteristicsSpells) do
            if spells[spellId] then
              db.dataCollectionCC[i] = db.dataCollectionCC[i] or {}
              db.dataCollectionCC[i][id] = db.dataCollectionCC[i][id] or {}
              db.dataCollectionCC[i][id][characteristic] = true
              enemy.characteristics = enemy.characteristics or {}
              enemy.characteristics[characteristic] = true
            end
          end
          break
        end

      end

    end
  end


end

---Request users in party/raid to distribute their collected data
function MDT:RequestDataCollectionUpdate()
  print("MDT: Requesting collected data from group members...")
  local distribution = self:IsPlayerInGroup()
  if not distribution then return end
  MDTcommsObject:SendCommMessage(self.dataCollectionPrefixes.request, "0", distribution, nil, "ALERT")
end

---Distribute collected data to party/raid
function DC:DistributeData()
  print("MDT: Distributing collected data to group members")
  local distribution = MDT:IsPlayerInGroup()
  if not distribution then return end
  db = MDT:GetDB()
  local package = {
    [1] = db.dataCollection,
    [2] = db.dataCollectionCC
  }
  local export = MDT:TableToString(package, false, 5)
  MDTcommsObject:SendCommMessage(MDT.dataCollectionPrefixes.distribute, export, distribution, nil, "BULK", nil, nil)
end

---Merge received collected data into own data collection
function DC:MergeReceiveData(package)
  print("MDT: Merging received collected data")
  db = MDT:GetDB()
  local collection, collectionCC = unpack(package)
  --db.dataCollection[dungeonIdx][npcId][spellId]
  for dungeonIdx, npcs in pairs(collection) do
    if not db.dataCollection[dungeonIdx] then
      db.dataCollection[dungeonIdx] = npcs
    else
      for npcId, spells in pairs(npcs) do
        if not db.dataCollection[dungeonIdx][npcId] then
          db.dataCollection[dungeonIdx][npcId] = spells
        else
          for spellId, tracked in pairs(spells) do
            db.dataCollection[dungeonIdx][npcId][spellId] = true
          end
        end
      end
    end
  end
  --db.dataCollectionCC[dungeonIdx][npcId][characteristic]
  for dungeonIdx, npcs in pairs(collectionCC) do
    if not db.dataCollectionCC[dungeonIdx] then
      db.dataCollectionCC[dungeonIdx] = npcs
    else
      for npcId, characteristics in pairs(npcs) do
        if not db.dataCollectionCC[dungeonIdx][npcId] then
          db.dataCollectionCC[dungeonIdx][npcId] = characteristics
        else
          for characteristic, tracked in pairs(characteristics) do
            db.dataCollectionCC[dungeonIdx][npcId][characteristic] = true
          end
        end
      end
    end
  end
  DC:AddCollectedDataToEnemyTable()
  MDT:CleanEnemyInfoSpells()
end

function MDT:CleanEnemyInfoSpells()
  local blacklist = MDT:GetEnemyInfoSpellBlacklist()
  for i = 1, 100 do
    local enemies = MDT.dungeonEnemies[i]
    if enemies then
      for enemyIdx, enemy in pairs(enemies) do
        if enemy.spells then
          for spellId, spell in pairs(enemy.spells) do
            if blacklist[spellId] then
              enemy.spells[spellId] = nil
            end
          end
        end
      end
    end
  end
  if MDT.EnemyInfoFrame then MDT.EnemyInfoFrame:Hide() end
end

function DC:InitHealthTrack()
  print("MDT: Health Tracking Init")
  db = MDT:GetDB()
  if not db.healthTrackVersion or db.healthTrackVersion < 2 then
    db.healthTrackVersion = 2
    db.healthTracking = {}
  end
  db.healthTracking = db.healthTracking or {}
  local healthTrackingFrame = CreateFrame("Frame")
  healthTrackingFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
  healthTrackingFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
  healthTrackingFrame:SetScript("OnEvent", function(_, event, ...)
    --check difficulty if challenge mode and m+ level
    local difficultyID = GetDungeonDifficultyID()
    local isChallenge = difficultyID and C_ChallengeMode.IsChallengeModeActive()
    local level, activeAffixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
    local fortified
    local tyrannical
    local thundering
    for k, v in pairs(activeAffixIDs) do
      if v == 10 then
        fortified = true
      end
      if v == 132 then
        thundering = true
      end
      if v == 9 then
        tyrannical = true
      end
    end
    level = isChallenge and level or -1
    if level > -1 then
      local unit
      if event == "UPDATE_MOUSEOVER_UNIT" then
        unit = "mouseover"
      elseif event == "NAME_PLATE_UNIT_ADDED" then
        unit = ...
      end
      if unit then
        local guid = UnitGUID(unit)
        local npcId
        if guid then
          npcId = select(6, strsplit("-", guid))
        end
        if npcId then
          db.healthTracking[tonumber(npcId)] = {
            ["health"] = UnitHealthMax(unit),
            ["name"] = UnitName(unit),
            ["level"] = level,
            ["fortified"] = fortified,
            ["thundering"] = thundering,
            ["tyrannical"] = tyrannical
          }
        end
      end
    end
  end)

  function MDT:ProcessHealthTrack()
    local enemies = MDT.dungeonEnemies[db.currentDungeonIdx]
    if enemies then
      local numEnemyHealthChanged = 0
      for enemyIdx, enemy in pairs(enemies) do
        local tracked = db.healthTracking[enemy.id]
        if tracked then
          local isBoss = enemy.isBoss and true or false
          local baseHealth = MDT:ReverseCalcEnemyHealth(tracked.health, tracked.level, isBoss, tracked.fortified,
            tracked.tyrannical,
            tracked.thundering)
          if baseHealth ~= enemy.health then
            numEnemyHealthChanged = numEnemyHealthChanged + 1
          end
          enemy.health = baseHealth
        else
          print("MDT HPTRACK: Missing: " .. enemy.name .. " id: " .. enemy.id)
        end
      end
      print("MDT HPTRACK: Processed " .. numEnemyHealthChanged .. " enemies")
    end
  end
end
