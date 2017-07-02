local mod = RegisterMod("Alternity", 1)
local alphaMod
local Alternity = {}

-------------------
--<<<FRAMEWORK>>>--
-------------------

---<<TABLES>>---
local PASSIVES = {}
local ACTIVES = {}
local TRINKETS = {}
local FAMILIARS = {}
local ENTITIES = {}
local ITEM_VARIABLES = {}
local ENTITY_FLAGS = {}
local SOUNDS = {}
local SFX_MANAGER
local MOD_RNG

ITEM_VARIABLES.CLOAK_AND_DAGGER = { invisible = false }
ITEM_VARIABLES.ALPHA_CREST = { active = false, symbol = nil }
ITEM_VARIABLES.GOLDEN_FLEECE = { invulnerabilityTimeOut = 0 }
ITEM_VARIABLES.AZAZELS_LOST_HORN = { swirls = {} }
ITEM_VARIABLES.WISDOM_TOOTH = { wisdomTooth = false, hasFired = 0 }

local function start()
    alphaMod = AlphaAPI.registerMod(mod)
    SFX_MANAGER = SFXManager()
    MOD_RNG = RNG()
    
    ENTITY_FLAGS = {
        ANTIMATTER_TEAR = AlphaAPI.createFlag(),
        CHOPSTICK_TEAR = AlphaAPI.createFlag()
    }
    
    SOUNDS = {}
    
    ENTITIES.LOST_HORN_SWIRL = alphaMod:getEntityConfig("Brim Swirl", 0)
    ENTITIES.CLOAK_AND_DAGGER = alphaMod:getEntityConfig("Cloak Dagger", 0)
    ENTITIES.ALPHA_CREST = alphaMod:getEntityConfig("Alpha Crest", 0)
    ENTITIES.ANTIMATTER_EXPLOSION = alphaMod:getEntityConfig("Antimatter Explosion", 0)
    
    PASSIVES.CLOAK_AND_DAGGER = alphaMod:registerItem("Cloak and Dagger")
    PASSIVES.CLOAK_AND_DAGGER:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alternity.cloakAndDaggerEffect, EntityType.ENTITY_PLAYER)
    PASSIVES.CLOAK_AND_DAGGER:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alternity.cloakAndDaggerUpdate, ENTITIES.CLOAK_AND_DAGGER.id, ENTITIES.CLOAK_AND_DAGGER.variant)
    PASSIVES.CLOAK_AND_DAGGER:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alternity.cloakAndDaggerDamage)
    
    PASSIVES.ALPHA_CREST = alphaMod:registerItem("Alpha Crest")
    PASSIVES.ALPHA_CREST:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alternity.alphaCrestDamage)
    PASSIVES.ALPHA_CREST:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alternity.alphaCrestActivate)
    PASSIVES.ALPHA_CREST:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alternity.renderAlphaCrest, EntityType.ENTITY_PLAYER)
    
    PASSIVES.GOLDEN_FLEECE = alphaMod:registerItem("Golden Fleece")
    PASSIVES.GOLDEN_FLEECE:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alternity.goldenFleeceDamage, EntityType.ENTITY_PLAYER)
    
    PASSIVES.TIME_BOMBS = alphaMod:registerItem("Time Bombs")
    PASSIVES.TIME_BOMBS:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alternity.timeBombsExplode)
    
    PASSIVES.AZAZELS_LOST_HORN = alphaMod:registerItem("Azazel's Lost Horn", "gfx/characters/costumes/costume_azazelslosthorn.anm2")
    PASSIVES.AZAZELS_LOST_HORN:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alternity.lostHornSpawnSwirls)
    PASSIVES.AZAZELS_LOST_HORN:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alternity.lostHornChain)
    
    PASSIVES.WISDOM_TOOTH = alphaMod:registerItem("Wisdom Tooth")
    PASSIVES.WISDOM_TOOTH:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, Alternity.wisdomToothUpdate, EntityType.ENTITY_PLAYER)
    PASSIVES.WISDOM_TOOTH:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alternity.makeWisdomToothTear, EntityType.ENTITY_TEAR)
    PASSIVES.WISDOM_TOOTH:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alternity.resetOnCache)
    
    PASSIVES.ANTI_MATTER = alphaMod:registerItem("Anti-Matter", "gfx/characters/costumes/costume_antimatter.anm2")
    PASSIVES.ANTI_MATTER:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alternity.makeAntiMatterTear, EntityType.ENTITY_TEAR)
    PASSIVES.ANTI_MATTER:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alternity.antiMatterDamage)
    
    PASSIVES.CHOPSTICKS = alphaMod:registerItem("Chopsticks")
    PASSIVES.CHOPSTICKS:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alternity.chopsticksCache)
    PASSIVES.CHOPSTICKS:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alternity.makeChopstickTear, EntityType.ENTITY_TEAR)
    PASSIVES.CHOPSTICKS:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alternity.chopstickCheckCollision)
    
    ACTIVES.EXCALIBUR = alphaMod:registerItem("Excalibur")
    ACTIVES.EXCALIBUR:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alternity.useExcalibur)
    
    alphaMod:addCallback(AlphaAPI.Callbacks.RUN_STARTED, Alternity.resetVariables)
end

-----------------------
--<<<MISCELLANEOUS>>>--
-----------------------

local function random(min, max)
    if min ~= nil and max ~= nil then
        return math.floor(MOD_RNG:RandomFloat() * (max - min + 1) + min)
    elseif min ~= nil then
        return math.floor(MOD_RNG:RandomFloat() * (min + 1))
    end
    return MOD_RNG:RandomFloat()
end

function Alternity.resetVariables()
    MOD_RNG:SetSeed(AlphaAPI.GAME_STATE.GAME:GetSeeds():GetStartSeed(), 0)
    
    ITEM_VARIABLES.CLOAK_AND_DAGGER.invisible = false
    ITEM_VARIABLES.ALPHA_CREST.active = false
    ITEM_VARIABLES.GOLDEN_FLEECE.invulnerabilityTimeOut = 0
    ITEM_VARIABLES.AZAZELS_LOST_HORN.swirls = {}
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, Alternity.resetVariables)

-----------------
--<<<ACTIVES>>>--
-----------------

---<<EXCALIBUR>>---
function Alternity:useExcalibur()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    
    if player:GetMaxHearts() > 2 then
        if player:GetMaxHearts() == 4 then
        player:AddCollectible(Passive.CLOAK_AND_DAGGER, 0, true)
        elseif player:GetMaxHearts() == 6 then
        player:AddCollectible(CollectibleType.COLLECTIBLE_SPEAR_OF_DESTINY, 0, true)
        elseif player:GetMaxHearts() == 8 then
        player:AddCollectible(CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER, 0, true)
        elseif player:GetMaxHearts() >= 10 then
        player:AddCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE, 0, true)
        end
    
        player:RemoveCollectible(ACTIVES.EXCALIBUR.id)
    
        return true
    else
        player:AnimateSad()
    end
end

------------------
--<<<PASSIVES>>>--
------------------

---<<CLOAK AND DAGGER>>---
function Alternity.cloakAndDaggerEffect(player, data)
    player = player:ToPlayer()
    
    if data.cloakAndDagger == nil or data.cloakAndDagger < 0 then
        data.cloakAndDagger = 0
    elseif player:GetFireDirection() ~= Direction.NO_DIRECTION then
        data.cloakAndDagger = data.cloakAndDagger + 1
    elseif data.cloakAndDagger > 0 then
        data.cloakAndDagger = data.cloakAndDagger - 1
    end
    
    if data.invisTimeout == nil then
        data.invisTimeout = 90
    elseif data.invisTimeout <= 0 then
        data.invisTimeout = 90
        ITEM_VARIABLES.CLOAK_AND_DAGGER.invisible = false
    end
    
    if ITEM_VARIABLES.CLOAK_AND_DAGGER.invisible then
        player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_CAMO_UNDIES,false)
        data.invisTimeout = data.invisTimeout - 1
    end
    
    if data.cloakAndDagger >= 90 then
        local knife = ENTITIES.CLOAK_AND_DAGGER:spawn(player.Position, Vector(0,0), player)
        knife.CollisionDamage = 10
        data.cloakAndDagger = 0
    end
end

function Alternity.cloakAndDaggerUpdate(knife, data)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local sprite = knife:GetSprite()
    
    knife.Position = player.Position
    
    if sprite:IsFinished("Spin") then
        knife:Remove()
    end
    
    if knife.FrameCount > 10 and not sprite:IsPlaying("Spin") then
        sprite:Play("Spin",true)
    end
end

function Alternity.cloakAndDaggerDamage(entity, dmgAmount, dmgFlags, dmgSource, invincibilityFrames)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    
    if dmgSource.Type == ENTITIES.CLOAK_AND_DAGGER.id and dmgSource.Variant == ENTITIES.CLOAK_AND_DAGGER.variant then
        if dmgAmount >= entity.HitPoints then
            ITEM_VARIABLES.CLOAK_AND_DAGGER.invisible = true
        end
    end
end

---<<ALPHA CREST>>---
function Alternity.alphaCrestDamage(entity, dmgAmount, dmgFlags, dmgSource, invincibilityFrames)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
  
    if entity:IsVulnerableEnemy() then
        if ITEM_VARIABLES.ALPHA_CREST.active then
            entity.HitPoints = entity.HitPoints - (dmgAmount * 2)
            return true
        end
    end
end

function Alternity.alphaCrestActivate()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local data = player:GetData()
  
    if AlphaAPI.GAME_STATE.ROOM:GetFrameCount() <= 2 then
        data.alphaCount = 0
    end
    
    local totalEnemies = 0
    
    for i, entity in pairs(AlphaAPI.entities.enemies) do
        if entity:IsActiveEnemy(false) then
            totalEnemies = totalEnemies + 1
        end
    end
    
    if totalEnemies > data.alphaCount or totalEnemies == 0 then
        data.alphaCount = totalEnemies
    end
    
    if totalEnemies >= (data.alphaCount * 0.66) and data.alphaCount > 3 then
        ITEM_VARIABLES.ALPHA_CREST.active = true
        
        if not ITEM_VARIABLES.ALPHA_CREST.symbol then
            ITEM_VARIABLES.ALPHA_CREST.symbol = ENTITIES.ALPHA_CREST:spawn(player.Position, Vector(0, 0), player)
        end
    else
        ITEM_VARIABLES.ALPHA_CREST.active = false
    end
end

function Alternity.renderAlphaCrest()
    if ITEM_VARIABLES.ALPHA_CREST.symbol then
        local sprite = ITEM_VARIABLES.ALPHA_CREST.symbol:GetSprite()
        local player = AlphaAPI.GAME_STATE.PLAYERS[1]
        
        ITEM_VARIABLES.ALPHA_CREST.symbol.Position = player.Position
      
        if not AlphaAPI.GAME_STATE.ROOM:IsClear() then
            if ITEM_VARIABLES.ALPHA_CREST.active then
                if not sprite:IsPlaying("FadeIn") and not sprite:IsFinished("FadeIn") then
                    sprite:Play("FadeIn", true)
                end
            else
                if sprite:IsFinished("FadeIn") then
                    sprite:Play("FadeOut", true)
                elseif sprite:IsFinished("FadeOut") then
                    ITEM_VARIABLES.ALPHA_CREST.symbol:Remove()
                    ITEM_VARIABLES.ALPHA_CREST.symbol = nil
                end
            end
        end
    end
end

---<<GOLDEN FLEECE>>---
function Alternity.goldenFleeceDamage(entity, dmgAmount, dmgFlags, dmgSource, invincibilityFrames)
    local player = entity:ToPlayer()
  
    if player then
        chance = math.min(30, player:GetNumCoins()) * 0.87
        chance = chance + math.max(0, player:GetNumCoins() - 30) * 0.1
        
        if random(1, 100) < chance then
            ITEM_VARIABLES.GOLDEN_FLEECE.invulnerabilityTimeOut = AlphaAPI.GAME_STATE.GAME:GetFrameCount() + 6
            player:SetColor(Color(1, 1, 0, 1, 0, 0, 0), 10, 1, true, false)
        end
      
        if AlphaAPI.GAME_STATE.GAME:GetFrameCount() <= ITEM_VARIABLES.GOLDEN_FLEECE.invulnerabilityTimeOut then
            return false
        else
            ITEM_VARIABLES.GOLDEN_FLEECE.invulnerabilityTimeOut = -1
        end
    end
end

---<<TIME BOMBS>>---
function Alternity.timeBombsExplode()
  local player = AlphaAPI.GAME_STATE.PLAYERS[1]
  
    for i, entity in pairs(AlphaAPI.entities.friendly) do
        if entity:ToBomb() and entity.SpawnerType == EntityType.ENTITY_PLAYER then
            local sprite = entity:GetSprite()
            local path = "gfx/items/pick ups/pickup_timebombs.anm2"
            
            if sprite:IsPlaying("Pulse") and sprite:GetFilename() ~= path then
                sprite:Load(path, true)
              
                if not sprite:IsPlaying("Pulse") then
                    sprite:Play("Pulse", true)
                end
            end
            
            if sprite:IsPlaying("Explode") then
                for u, ent in pairs(AlphaAPI.entities.enemies) do
                    ent:AddFreeze(EntityRef(player), 90)
                    ent:SetColor(Color(0.4, 0.4, 1, 1, 0, 0, 0), 90, 1, true, false)
                end
            end
        end
    end
end

---<<AZAZEL'S LOST HORN>>---
function Alternity.lostHornSpawnSwirls(entity, dmgAmount, dmgFlags, dmgSource, invincibilityFrames)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local swirls = ITEM_VARIABLES.AZAZELS_LOST_HORN.swirls
  
    if entity.HitPoints - dmgAmount <= 0 and entity:IsActiveEnemy(false) then
        if #swirls < 2 then
            local swirl = ENTITIES.LOST_HORN_SWIRL:spawn(entity.Position, Vector(0,0), player)
            swirl.SpriteScale = Vector(0.5, 0.5)
            swirl:SetColor(player.TearColor, -1, 1, false, false)
            swirl:GetSprite():Play("Idle", true)
            table.insert(swirls, swirl)
        end
    end
end

function Alternity.lostHornChain()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local swirls = ITEM_VARIABLES.AZAZELS_LOST_HORN.swirls
  
    if AlphaAPI.GAME_STATE.ROOM:GetFrameCount() <= 1 then
        ITEM_VARIABLES.AZAZELS_LOST_HORN.swirls = {}
    end
    
    for i, swirl in ipairs(swirls) do
        if swirl:GetSprite():IsFinished("Idle") then
            swirl:Remove()
            table.remove(ITEM_VARIABLES.AZAZELS_LOST_HORN.swirls, i)
            break
        end
    end
    
    if #swirls >= 2 then
        local brim = EntityLaser.ShootAngle(1, swirls[1].Position, (swirls[2].Position:__sub(swirls[1].Position)):GetAngleDegrees(), 45, Vector(0,0),player)
        brim.DisableFollowParent = true
        brim:SetMaxDistance(swirls[1].Position:Distance(swirls[2].Position))
        brim.CollisionDamage = player.Damage / 3
        brim.SpriteScale = Vector(0.6, 1)
        brim.TearFlags = player.TearFlags
        brim:SetColor(player.TearColor, -1, 1, false, false)
        
        swirls[1]:GetSprite():Play("Idle", true)
        swirls[2]:GetSprite():Play("Idle", true)
        
        ITEM_VARIABLES.AZAZELS_LOST_HORN.swirls = {swirls[2]}
    end
end

---<<WISDOM TOOTH>>---
function Alternity.wisdomToothUpdate(player, data)
    player = player:ToPlayer()
    
    if player and player:HasWeaponType(WeaponType.WEAPON_TEARS) then
        if data.wisdomToothCharge == nil then
            data.wisdomToothCharge = 0
        end
        
        if not ITEM_VARIABLES.WISDOM_TOOTH.wisdomTooth then
            if player:GetFireDirection() == Direction.NO_DIRECTION then 
                if data.wisdomToothCharge < player.MaxFireDelay * 3 then
                    data.wisdomToothCharge = data.wisdomToothCharge + 1
                    
                    if data.wisdomToothCharge >= player.MaxFireDelay * 3 then
                        player:SetColor(Color(1, 0.3, 1, 1, 50, 0, 50), 15, 1, true, false)
                        ITEM_VARIABLES.WISDOM_TOOTH.wisdomTooth = true
                    end
                end
            else
                data.wisdomToothCharge = 0
            end
        end
    end
end

function Alternity.makeWisdomToothTear(tear, data)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    
    if ITEM_VARIABLES.WISDOM_TOOTH.wisdomTooth and tear.Parent:ToPlayer() then
        if ITEM_VARIABLES.WISDOM_TOOTH.hasFired > 0 then
            ITEM_VARIABLES.WISDOM_TOOTH.hasFired = ITEM_VARIABLES.WISDOM_TOOTH.hasFired - 1
            
            if ITEM_VARIABLES.WISDOM_TOOTH.hasFired <= 0 then
                ITEM_VARIABLES.WISDOM_TOOTH.wisdomTooth = false
            end
            
            return nil
        end
        
        tear = tear:ToTear()
        
        tear:ChangeVariant(TearVariant.TOOTH)
        tear.Scale = tear.Scale * 1.2
        tear.TearFlags = tear.TearFlags | TearFlags.TEAR_HOMING
        tear:SetColor(Color(1, 0, 1, 1, 0, 0, 0), -1, 1, false, false)
        tear.CollisionDamage = tear.CollisionDamage * 3.5
        
        ITEM_VARIABLES.WISDOM_TOOTH.hasFired = math.floor(math.max(1, math.min(15, 50 / player.MaxFireDelay)))
    end
end

function Alternity.resetOnCache(player, cacheFlag)
    if cacheFlag == CacheFlag.CACHE_FIREDELAY then
        ITEM_VARIABLES.WISDOM_TOOTH.wisdomTooth = false
        ITEM_VARIABLES.WISDOM_TOOTH.hasFired = 0
        player:GetData().wisdomToothCharge = 0
    end
end

---<<ANTI-MATTER>>---
function Alternity.makeAntiMatterTear(tear, data)
    if AlphaAPI.getLuckRNG(1, 1) and not AlphaAPI.hasFlag(tear, ENTITY_FLAGS.ANTIMATTER_TEAR) and tear.Parent:ToPlayer() then
        AlphaAPI.addFlag(tear, ENTITY_FLAGS.ANTIMATTER_TEAR)
        tear:GetSprite():Load("gfx/effects/effect_antimatter_tears.anm2", true)
        tear:GetSprite():Play("Idle", true)
    end
end

function Alternity.antiMatterDamage(entity, dmgAmount, dmgFlags, dmgSource, invincibilityFrames)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local tear = AlphaAPI.getEntityFromRef(dmgSource)
    
    if AlphaAPI.hasFlag(tear, ENTITY_FLAGS.ANTIMATTER_TEAR) and entity:IsActiveEnemy(false) then
        if entity.HitPoints - dmgAmount <= 0 then
            local explo = ENTITIES.ANTIMATTER_EXPLOSION:spawn(entity.Position, Vector(0, 0), player)
            explo.SpriteScale = Vector(0.6, 0.6)
            
            for i, ent in pairs(AlphaAPI.entities.enemies) do
                if entity.Position:DistanceSquared(ent.Position) <= 10000 and entity:IsVulnerableEnemy() then
                    if ent:IsBoss() then
                        ent:TakeDamage(30, 0, EntityRef(player), 30)
                    else
                        ent:Kill()
                    end
                end
            end
        end
    end
end

---<<CHOPSTICKS>>---
function Alternity.chopsticksCache(player, cacheFlag)
    if cacheFlag == CacheFlag.CACHE_RANGE then
        player.TearHeight = player.TearHeight - 7.5
    end
    if cacheFlag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage + 0.55
    end
end

function Alternity.makeChopstickTear(tear, data)
    if not AlphaAPI.hasFlag(tear, ENTITY_FLAGS.CHOPSTICK_TEAR) then
        AlphaAPI.addFlag(tear, ENTITY_FLAGS.CHOPSTICK_TEAR)
        
        tear = tear:ToTear()
        tear.TearFlags = tear.TearFlags | TearFlags.TEAR_PIERCING
        tear.SpriteScale = Vector(5, 0.1)
        tear.SpriteRotation = tear.Velocity:GetAngleDegrees()
    end
end

function Alternity.chopstickCheckCollision(entity, dmgAmount, dmgFlags, dmgSource, invincibilityFrames)
    local tear = AlphaAPI.getEntityFromRef(dmgSource)
    
    if AlphaAPI.hasFlag(tear, ENTITY_FLAGS.CHOPSTICK_TEAR) then
        local room = AlphaAPI.GAME_STATE.GAME:GetLevel():GetCurrentRoom()
        local centreY = room:GetCenterPos().Y
        local centreX = room:GetCenterPos().X
        
        local x = entity.Position.X - centreY
        local y = entity.Position.Y - centreX
        local a = math.tan((360 - tear.Velocity:GetAngleDegrees()) / 180 * math.pi)
        local b = -1
        local c = -(a * x + b * y)
        
        local perpendicularDist = math.abs((a * x) + (b * y) + c) / math.sqrt(a^2 + b^2)
        
        Isaac.DebugString("| " .. a .. " * " .. x .. " + " .. b .. " * " .. y .. " + " .. c .. " | / sqrt(" .. a .. "^2 + " .. b .. "^2)") 
        Isaac.DebugString("\nNEW DISTANCE" .. "\nx: " .. x .. "\ny: " .. y .. "\na: " .. a .. "\nb: " .. b .. "\nc: " .. c)
        
        Isaac.ConsoleOutput(perpendicularDist)
    end
end

----------------------------------
--<<<ALPHA API INITIALISATION>>>--
----------------------------------

local START_FUNC = start

if AlphaAPI then START_FUNC()
else if not __alphaInit then
    __alphaInit = {}
end __alphaInit[#__alphaInit + 1] = START_FUNC
end