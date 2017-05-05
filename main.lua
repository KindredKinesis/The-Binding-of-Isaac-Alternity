local Alternity = RegisterMod("Alternity",1)

-------------------
--<<<FRAMEWORK>>>--
-------------------

---<<TABLES>>---
Alternity.Items = {
  Passives = {
    CLOAK_AND_DAGGER = Isaac.GetItemIdByName("Cloak and Dagger"),
    ALPHA_CREST = Isaac.GetItemIdByName("Alpha Crest"),
    GOLDEN_FLEECE = Isaac.GetItemIdByName("Golden Fleece")
  },
  Actives = {
    EXCALIBUR = Isaac.GetItemIdByName("Excalibur")
  },
  Familiars = {
  },
  Trinkets = {
  }
}

Alternity.ItemVariables = {
  CloakAndDagger = {
      Variant = Isaac.GetEntityVariantByName("CloakDagger"),
      Invisible = false
  },
  AlphaCrest = {
    Active = false,
    SymbolSprite = Sprite()
  },
  GoldenFleece = {
    invulnerabilityTimeOut = 0
  }
}

---<<VARIABLES>>---
local Passive = Alternity.Items.Passives
local Active = Alternity.Items.Actives
local Familiar = Alternity.Items.Familiars
local Trinket = Alternity.Items.Trinkets

local ItemVars = Alternity.ItemVariables

ItemVars.AlphaCrest.SymbolSprite:Load("gfx/effects/effect_alphacrest.anm2",true)

-----------------
--<<<ACTIVES>>>--
-----------------

---<<EXCALIBUR>>---
function Alternity:UseExcalibur()
  local player = Isaac.GetPlayer(0)
  
  if player:GetMaxHearts() > 2 then
    if player:GetMaxHearts() == 4 then
      player:AddCollectible(Passive.CLOAK_AND_DAGGER,0,true)
    elseif player:GetMaxHearts() == 6 then
      player:AddCollectible(CollectibleType.COLLECTIBLE_SPEAR_OF_DESTINY,0,true)
    elseif player:GetMaxHearts() == 8 then
      player:AddCollectible(CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER,0,true)
    elseif player:GetMaxHearts() >= 10 then
      player:AddCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE,0,true)
    end
    
    player:RemoveCollectible(Active.EXCALIBUR)
    
    return true
  else
    player:AnimateSad()
  end
end

Alternity:AddCallback(ModCallbacks.MC_USE_ITEM, Alternity.UseExcalibur, Active.EXCALIBUR)

------------------
--<<<PASSIVES>>>--
------------------

---<<CLOAK AND DAGGER>>---
function Alternity:CloakAndDaggerEffect()
  local player = Isaac.GetPlayer(0)
  local entities = Isaac.GetRoomEntities()
  local playerdata = player:GetData()
  
  if player:HasCollectible(Passive.CLOAK_AND_DAGGER) then
    if playerdata.CloakAndDagger == nil or player:GetFireDirection() == Direction.NO_DIRECTION then
      playerdata.CloakAndDagger = 0
    else
      playerdata.CloakAndDagger = playerdata.CloakAndDagger + 1
    end
    
    if playerdata.InvisTimeout == nil then
      playerdata.InvisTimeout = 120
    elseif playerdata.InvisTimeout <= 0 then
      playerdata.InvisTimeout = 120
      ItemVars.CloakAndDagger.Invisible = false
    end
    
    if ItemVars.CloakAndDagger.Invisible then
      player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_CAMO_UNDIES,false)
      playerdata.InvisTimeout = playerdata.InvisTimeout - 1
    end
    
    if playerdata.CloakAndDagger == 90 then
      local knife = Isaac.Spawn(EntityType.ENTITY_FAMILIAR,ItemVars.CloakAndDagger.Variant,0,player.Position,Vector(0,0),player)
      knife.CollisionDamage = 10
      playerdata.CloakAndDagger = 0
    end
  end
end

Alternity:AddCallback(ModCallbacks.MC_POST_UPDATE,Alternity.CloakAndDaggerEffect)

function Alternity:CloakAndDaggerUpdate(knife)
  local player = Isaac.GetPlayer(0)
  local data = knife:GetData()
  local sprite = knife:GetSprite()
  
  knife.Position = player.Position
  
  if sprite:IsFinished("Spin") then
    knife:Remove()
  end
  
  if knife.FrameCount > 10 and not sprite:IsPlaying("Spin") then
    sprite:Play("Spin",true)
  end
end

Alternity:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE,Alternity.CloakAndDaggerUpdate,ItemVars.CloakAndDagger.Variant)

function Alternity:CloakAndDaggerDamage(Ent,DamageAmount,DamageFlags,DamageSource,CountdownFrames)
  local player = Isaac.GetPlayer(0)
  
  if player:HasCollectible(Passive.CLOAK_AND_DAGGER) then
    if DamageSource.Type == EntityType.ENTITY_FAMILIAR and DamageSource.Variant == ItemVars.CloakAndDagger.Variant then
      if DamageAmount >= Ent.HitPoints then
        ItemVars.CloakAndDagger.Invisible = true
      end
    end
  end
end

Alternity:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,Alternity.CloakAndDaggerDamage)


---<<ALPHA CREST>>---
function Alternity:AlphaCrestEffect(Ent,DamageAmount,_,DamageSource,_)
  local player = Isaac.GetPlayer(0)
  local entities = Isaac.GetRoomEntities()
  
  if player:HasCollectible(Passive.ALPHA_CREST) and Ent:IsVulnerableEnemy() then
    if ItemVars.AlphaCrest.Active then
      Ent.HitPoints = Ent.HitPoints - (DamageAmount * 2)
      return true
    end
  end
end

Alternity:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,Alternity.AlphaCrestEffect)

function Alternity:AlphaCrestActivate()
  local player = Isaac.GetPlayer(0)
  local entities = Isaac.GetRoomEntities()
  local room = Game():GetLevel():GetCurrentRoom()
  local data = player:GetData()
  
  if player:HasCollectible(Passive.ALPHA_CREST) then
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
      if entities[i]:IsActiveEnemy(false) then
        currenemies = currenemies + 1
      end
    end
    
    if currenemies >= (data.AlphaCount * 0.66) and data.AlphaCount > 3 then
      ItemVars.AlphaCrest.Active = true
    else
      ItemVars.AlphaCrest.Active = false
    end
  end
end

Alternity:AddCallback(ModCallbacks.MC_POST_UPDATE,Alternity.AlphaCrestActivate)

function Alternity:RenderAlphaCrest()
  local sprite = ItemVars.AlphaCrest.SymbolSprite
  local room = Game():GetRoom()
  local player = Isaac.GetPlayer(0)
  
  if not room:IsClear() and player:HasCollectible(Passive.ALPHA_CREST) and room:GetFrameCount() > 10 then
    if ItemVars.AlphaCrest.Active then
      if not sprite:IsPlaying("FadeIn") and not sprite:IsFinished("FadeIn") then
        sprite:Play("FadeIn",true)
      end
    else
      if sprite:IsFinished("FadeIn") then
        sprite:Play("FadeOut",true)
      end
    end
    
    sprite:Update()
    sprite:Render(room:WorldToScreenPosition(player.Position),Vector(0,0),Vector(0,0))
  end
end

Alternity:AddCallback(ModCallbacks.MC_POST_RENDER,Alternity.RenderAlphaCrest)

---<<GOLDEN FLEECE>>---
function Alternity:GoldenFleeceEffect(entity, amount, damageflag, source, countdownframes)
  local player = Isaac.GetPlayer(0)
  
  if entity.Type == EntityType.ENTITY_PLAYER then
    if player:HasCollectible(Passive.GOLDEN_FLEECE) then
      chance = math.min(30, player:GetNumCoins()) * 0.87
      chance = chance + math.max(0, player:GetNumCoins() - 30) * 0.1
      
      if math.random(1, 100) < chance then
        ItemVars.GoldenFleece.invulnerabilityTimeOut = Game():GetFrameCount() + 6
        player:SetColor(Color(1,1,0,1,0,0,0), 10, 1, true, false)
      end
      
      if Game():GetFrameCount() <= ItemVars.GoldenFleece.invulnerabilityTimeOut then
        return false
      else
        ItemVars.GoldenFleece.invulnerabilityTimeOut = -1
      end
    end
  end
end

Alternity:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, Alternity.GoldenFleeceEffect)