local Alternity = RegisterMod("Alternity",1); --Registers the mod under the name Alternity
local DebugText = {}; --Not used in release

---------------
-----ITEMS-----
---------------

-----VARIABLES-----

local ExcaliburItem = Isaac.GetItemIdByName("Excalibur"); --Gets the item ID of Excalibur

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

-----CALLBACKS-----

Alternity:AddCallback(ModCallbacks.MC_USE_ITEM, Alternity.UseExcalibur, ExcaliburItem) --Use item callback, UseExcalibur function, Excalibur item



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