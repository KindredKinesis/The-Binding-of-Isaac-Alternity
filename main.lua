local Alternity = RegisterMod("Alternity",1)

---------------
--<<<ITEMS>>>--
---------------

---<<VARIABLES>>---

local ExcaliburItem = Isaac.GetItemIdByName("Excalibur")

local CloakAndDaggerItem = Isaac.GetItemIdByName("Cloak and Dagger")
local CloakDaggerVariant = Isaac.GetEntityVariantByName("CloakDagger")
local CloakAndDaggerInvis = false

local AlphaCrestItem = Isaac.GetItemIdByName("Alpha Crest")
local AlphaCrestActive = false

---<<FUNCTIONS>>---

----<EXCALIBUR>----
function Alternity:UseExcalibur()
  local player = Isaac.GetPlayer(0)
  
  if player:GetMaxHearts() > 2 then
    if player:GetMaxHearts() == 4 then
      player:AddCollectible(CloakAndDaggerItem,0,true)
    elseif player:GetMaxHearts() == 6 then
      player:AddCollectible(CollectibleType.COLLECTIBLE_SPEAR_OF_DESTINY,0,true)
    elseif player:GetMaxHearts() == 8 then
      player:AddCollectible(CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER,0,true)
    elseif player:GetMaxHearts() >= 10 then
      player:AddCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE,0,true)
    end
    
    player:RemoveCollectible(ExcaliburItem)
    
    return true
  else
    player:AnimateSad()
  end
end

----<CLOAK AND DAGGER>----
function Alternity:CloakAndDaggerEffect()
  local player = Isaac.GetPlayer(0)
  local entities = Isaac.GetRoomEntities()
  local playerdata = player:GetData()
  
  if player:HasCollectible(CloakAndDaggerItem) then
    if playerdata.CloakAndDagger == nil or player:GetFireDirection() == Direction.NO_DIRECTION then
      playerdata.CloakAndDagger = 0
    else
      playerdata.CloakAndDagger = playerdata.CloakAndDagger + 1
    end
    
    if playerdata.InvisTimeout == nil then
      playerdata.InvisTimeout = 120
    elseif playerdata.InvisTimeout <= 0 then
      playerdata.InvisTimeout = 120
      CloakAndDaggerInvis = false
    end
    
    if CloakAndDaggerInvis == true then
      player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_CAMO_UNDIES,false)
      playerdata.InvisTimeout = playerdata.InvisTimeout - 1
    end
    
    if playerdata.CloakAndDagger == 150 then
      local knife = Isaac.Spawn(3,CloakDaggerVariant,0,player.Position,Vector(0,0),player)
      knife.CollisionDamage = 10
      playerdata.CloakAndDagger = 0
    end
  end
end

function Alternity:CloakAndDaggerUpdate(knife)
  local player = Isaac.GetPlayer(0)
  local data = knife:GetData()
  
  knife.Position = player.Position
  
  if knife.FrameCount == 25 then
    knife:Remove()
  end
end

function Alternity:CloakAndDaggerDamage(Ent,DamageAmount,_,DamageSource,_)
  local player = Isaac.GetPlayer(0)
  
  if player:HasCollectible(CloakAndDaggerItem) then
    if DamageSource.Type == 3 and DamageSource.Variant == CloakDaggerVariant then
      if DamageAmount >= Ent.HitPoints then
        CloakAndDaggerInvis = true
      end
    end
  end
end

----<ALPHA CREST>----
function Alternity:AlphaCrestEffect(Ent,DamageAmount,_,DamageSource,_)
  local player = Isaac.GetPlayer(0)
  local entities = Isaac.GetRoomEntities()
  
  if player:HasCollectible(AlphaCrestItem) and Ent:IsActiveEnemy(false) then
    if AlphaCrestActive then
      Ent.HitPoints = Ent.HitPoints - (DamageAmount * 2)
      return true
    end
  end
end

local DebugText = {}

function Alternity:AlphaCrestActivate()
  local player = Isaac.GetPlayer(0)
  local entities = Isaac.GetRoomEntities()
  local room = Game():GetLevel():GetCurrentRoom()
  local data = player:GetData()
  
  if player:HasCollectible(AlphaCrestItem) then
    if room:GetFrameCount() == 1 then
      data.AlphaCount = 0
    end
    
    local totalenemies = 0
    
    for i = 1, #entities do
      if entities[i]:IsActiveEnemy(false) then
        totalenemies = totalenemies + 1
      end
    end
    
    if totalenemies > data.AlphaCount then
      data.AlphaCount = totalenemies
    end
    
    local currenemies = 0
    
    for i = 1, #entities do
      if entities[i]:IsActiveEnemy() then
        currenemies = currenemies + 1
      end
    end
    
    if currenemies >= (data.AlphaCount * 0.66) and data.AlphaCount > 3 then
      AlphaCrestActive = true
    else
      AlphaCrestActive = false
    end
    
    DebugText[1] = "AlphaCount: " .. data.AlphaCount
    DebugText[2] = "Enemies: " .. currenemies
    DebugText[3] = "AlphaCount * 0.66: " .. (data.AlphaCount * 0.66)
    DebugText[4] = "TotalEnemies: " .. totalenemies
    DebugText[5] = "AlphaCrestActive: " .. tostring(AlphaCrestActive)
  end
end

function Alternity:Debug()
  for i = 1, #DebugText do
    Isaac.RenderText(tostring(DebugText[i]),50,30 + (20*i),255,0,0,255)
  end
end

---<<CALLBACKS>>---

Alternity:AddCallback(ModCallbacks.MC_USE_ITEM, Alternity.UseExcalibur, ExcaliburItem)

Alternity:AddCallback(ModCallbacks.MC_POST_UPDATE,Alternity.CloakAndDaggerEffect)
Alternity:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,Alternity.CloakAndDaggerUpdate,CloakDaggerVariant)
Alternity:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,Alternity.CloakAndDaggerDamage)

Alternity:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,Alternity.AlphaCrestEffect)
Alternity:AddCallback(ModCallbacks.MC_POST_UPDATE,Alternity.AlphaCrestActivate)

Alternity:AddCallback(ModCallbacks.MC_POST_RENDER,Alternity.Debug)