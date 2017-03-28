local Alternity = RegisterMod("Alternity",1)
---------------
--<<<ITEMS>>>--
---------------

---<<VARIABLES>>---

local ExcaliburItem = Isaac.GetItemIdByName("Excalibur")

---<<FUNCTIONS>>---

----<EXCALIBUR>----
function Alternity:UseExcalibur()
  local player = Isaac.GetPlayer(0)
  local giveitems = (player:GetMaxHearts() / 2)
  local removehearts = {-2, -4, -8, -10}
  local weapons = {CollectibleType.COLLECTIBLE_MOMS_RAZOR, CollectibleType.COLLECTIBLE_SPEAR_OF_DESTINY, CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER, CollectibleType.COLLECTIBLE_MOMS_KNIFE}
  
  if player:GetSoulHearts() == 0 and player:GetBlackHearts() == 0 then giveitems = giveitems - 1 end
  if giveitems > 4 then giveitems = 4 end
  
  if giveitems > 0 then
    for i = 1, giveitems do 
      player:AddCollectible(weapons[i], 0, true)
    end
    player:AddMaxHearts(removehearts[giveitems])
  end
  
  player:RemoveCollectible(ExcaliburItem)
  
  return true
end

---<<CALLBACKS>>---

Alternity:AddCallback(ModCallbacks.MC_USE_ITEM, Alternity.UseExcalibur, ExcaliburItem)

------------------
--<<<PASSIVES>>>--
------------------

---<<VARIABLES>>---

local CloakAndDaggerItem = Isaac.GetItemIdByName("Cloak and Dagger")
local CloakDaggerVariant = Isaac.GetEntityVariantByName("CloakDagger")
local CloakAndDaggerInvis = false

---<<FUNCTIONS>>---

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

---<<CALLBACKS>>---

Alternity:AddCallback(ModCallbacks.MC_POST_UPDATE,Alternity.CloakAndDaggerEffect)
Alternity:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,Alternity.CloakAndDaggerUpdate,CloakDaggerVariant)
Alternity:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,Alternity.CloakAndDaggerDamage)