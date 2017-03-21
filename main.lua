local Alternity = RegisterMod("Alternity",1); --Registers the mod under the name Alternity
local DebugText = {}; --Not used in release

---------------
-----ITEMS-----
---------------

-----VARIABLES-----

local ExcaliburItem = Isaac.GetItemIdByName("Excalibur"); --Gets the item ID of Excalibur
local CloakAndDaggerItem; --THIS NEEDS TO BE FILLED OUT
local CADKnife = Isaac.GetEntityVariantByName("CloakDagger"); --Gets the variant of CloakDagger (Knife for Cloak and Dagger)

-----FUNCTIONS-----

function Alternity:UseExcalibur()
  local player = Isaac.GetPlayer(0) --Gets the player
  local giveitems = (player:GetMaxHearts() / 2) --Gets the amount of heart containers the player has
  local removehearts = {-2, -4, -8, -10} --The amount of heart containers to be removed
  local weapons = {CollectibleType.COLLECTIBLE_MOMS_RAZOR, CollectibleType.COLLECTIBLE_SPEAR_OF_DESTINY, CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER, CollectibleType.COLLECTIBLE_MOMS_KNIFE} --The items to add
  
  if player:GetSoulHearts() == 0 and player:GetBlackHearts() == 0 then giveitems = giveitems - 1 end --If the player has no soul or black hearts then remove 1 from the giveitems count to prevent death
  if giveitems > 4 then giveitems = 4 end --If there are more than the max amount of hearts, set it to the max (in this case 4)
  
  if giveitems > 0 then --If the player has more than 0 free heart containers
    for i = 1, giveitems do --For every heart container being given up
      player:AddCollectible(weapons[i], 0, true) --Add the next item in the list
    end
    player:AddMaxHearts(removehearts[giveitems]) --Remove hearts equivalent to items gained
  end
  
  player:RemoveCollectible(ExcaliburItem) --Remove Excalibur
  
  return true --Makes the player hold the item above their head
end

function Alternity:CloakAndDaggerEffect()
  local player = Isaac.GetPlayer(0) --Gets the player
  local entities = Isaac.GetRoomEntities() --Gets every entity in the room
  local playerdata = player:GetData() --Gets the player's data
  
  if playerdata.CloakAndDagger == nil or player:GetFireDirection() == Direction.NO_DIRECTION then --If the player doesn't have a Cloak and Dagger charge or if they aren't shooting
    playerdata.CloakAndDagger = 0 --Set the Cloak and Dagger charge to 0
  else
    playerdata.CloakAndDagger = playerdata.CloakAndDagger + 1 --Increase Cloak and Dagger charge by 1
  end
  
  if playerdata.CloakAndDagger == 60 then --If Cloak and Dagger charge equals 60 (2 seconds or so)
    local knife = Isaac.Spawn(3,CADKnife,0,player.Position,Vector(0,0),player)
    local data = knife:GetData()
    data.MoveX = 0
    data.MoveY = 0
    data.Radius = 30
    data.XSign = 1
    data.YSign = 1
    knife.CollisionDamage = 20
    playerdata.CloakAndDagger = 0
  end
end

function Alternity:CADKnifeUpdate(knife)
  local player = Isaac.GetPlayer(0)
  local sprite = knife:GetSprite()
  local data = knife:GetData()
  
  DebugText = {}
  table.insert(DebugText,data.MoveX)
  table.insert(DebugText,data.MoveY)
  table.insert(DebugText,data.XSign)
  table.insert(DebugText,data.YSign)
  table.insert(DebugText,data.Radius)
  
  if data.MoveX >= data.Radius then
    data.XSign = -1
    data.YSign = -1
  elseif data.MoveX <= (data.Radius * -1) then
    data.XSign = 1
    data.YSign = 1
  end
  
  data.MoveX = data.MoveX + (data.XSign * 5)
  data.MoveY = math.floor(math.sqrt(data.Radius^2 - data.MoveX^2) * data.YSign)
  
  knife.Position = Vector(player.Position.X + data.MoveX, player.Position.Y - 10 + data.MoveY)
  sprite.Rotation = sprite.Rotation + 60
  
  --if knife.FrameCount == 120 then
    --knife:Remove()
  --end
end

-----CALLBACKS-----

Alternity:AddCallback(ModCallbacks.MC_USE_ITEM, Alternity.UseExcalibur, ExcaliburItem) --Use item callback, UseExcalibur function, Excalibur item
Alternity:AddCallback(ModCallbacks.MC_POST_UPDATE, Alternity.CloakAndDaggerEffect) --Post update callback, CloakAndDaggerEffect function
Alternity:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, Alternity.CADKnifeUpdate, CADKnife) --Familiar update callback, CADKnifeUpdate function, CADKnife familiar



---------------
-----DEBUG-----
---------------

-----FUNCTIONS-----

function Alternity:Debug()
  for i = 1, #DebugText do
    Isaac.RenderText(DebugText[i], 50, 30 + (20 * i), 255, 0, 0, 255)
  end
end

-----CALLBACKS-----

Alternity:AddCallback(ModCallbacks.MC_POST_RENDER, Alternity.Debug)