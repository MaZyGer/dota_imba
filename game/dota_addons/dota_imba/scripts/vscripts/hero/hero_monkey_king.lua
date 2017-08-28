--[[
		By: MaZy
		Date: 01.07.2017
		Updated:  23.07.2017
		
		TODO:
			- MK has bugged animation with cosmetic weapons. I dunno how to fix it. Still researching.
			
		INFO:
			modifier_monkey_king_bounce - duration: -1.00 - always there (its for tree dance)
			modifier_monkey_king_bounce_leap - duration: -1.00 - while in jump to a tree
			modifier_monkey_king_tree_dance_activity - duration: 0.45 - while jump to tree
		if on tree
			modifier_monkey_king_bounce_perch - duration: -1.00,
			modifier_monkey_king_tree_dance_hidden - duration: -1.00,
]]

-- this is the monkey boundless strike animation
local MK_STRIKE_ANIMATION = ACT_DOTA_MK_STRIKE

CreateEmptyTalents("monkey_king")
local LinkedModifiers = {}
-------------------------------------------
--                Boundless Strike
-------------------------------------------
-- Visible Modifiers:
MergeTables(LinkedModifiers,{
    ["modifier_imba_monkey_king_boundless_strike"] = LUA_MODIFIER_MOTION_NONE,
})
-- Hidden Modifiers:
-- MergeTables(LinkedModifiers,{
    -- ["modifier_imba_ABILITYNAME"] = LUA_MODIFIER_MOTION_NONE,
-- })

imba_monkey_king_boundless_strike = imba_monkey_king_boundless_strike or class({})
function imba_monkey_king_boundless_strike:IsHiddenWhenStolen() return false end
function imba_monkey_king_boundless_strike:IsRefreshable() return true end
function imba_monkey_king_boundless_strike:IsStealable() return true end
function imba_monkey_king_boundless_strike:IsNetherWardStealable() return true end
-------------------------------------------



function imba_monkey_king_boundless_strike:GetAbilityTextureName()
   return "monkey_king_boundless_strike"
end


function imba_monkey_king_boundless_strike:OnAbilityPhaseStart() 
	if not IsServer() then return end
	
	local caster = self:GetCaster()
	local ability = self
	local radius = self:GetTalentSpecialValueFor("radius")
	
	local particle_strike_start_path = "particles/units/heroes/hero_monkey_king/monkey_king_strike_cast.vpcf"

	local startPos = caster:GetAbsOrigin()
	local endPos = startPos + caster:GetForwardVector() * radius
	
	caster:StartGesture(MK_STRIKE_ANIMATION)
	
	caster.strike_cast_start = ParticleManager:CreateParticle(particle_strike_start_path,  PATTACH_RENDERORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(caster.strike_cast_start, 0, caster, PATTACH_RENDERORIGIN_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(caster.strike_cast_start, 1, caster, PATTACH_POINT_FOLLOW, "attach_weapon_bot", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(caster.strike_cast_start, 2, caster, PATTACH_POINT_FOLLOW, "attach_weapon_top", caster:GetAbsOrigin(),  true)


	self.caster_loc = caster:GetAbsOrigin() 
	
	caster:EmitSound("Hero_MonkeyKing.Strike.Cast")
		
	return true
	
end

function imba_monkey_king_boundless_strike:OnAbilityPhaseInterrupted()
	if not IsServer() then return end
	
	local caster = self:GetCaster()
	
	if caster.strike_cast_start then
	
		ParticleManager:DestroyParticle(caster.strike_cast_start, true)
		ParticleManager:ReleaseParticleIndex(caster.strike_cast_start)
		caster.strike_cast_start = nil
	end
	
	caster:FadeGesture(MK_STRIKE_ANIMATION)
	
	return true
end

function imba_monkey_king_boundless_strike:OnSpellStart() 
	if not IsServer() then return end
	
	local caster = self:GetCaster()
	local ability = self
	local range = self:GetSpecialValueFor("strike_cast_range")
	local radius = self:GetSpecialValueFor("strike_radius")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local strike_buff_duration = self:GetSpecialValueFor("strike_buff_duration")

	
	local particle_strike_path = "particles/units/heroes/hero_monkey_king/monkey_king_strike.vpcf"
	
	-- Look for mastery. If is activated (toggled on) so we remove all stacks and multiply the damage.
	local jingu_mastery_ability = caster:FindAbilityByName("imba_monkey_king_jingu_mastery")
	local stacks = 0
	
	if jingu_mastery_ability then
	
		local max_damage_stacks = jingu_mastery_ability:GetSpecialValueFor("max_damage_stacks")
		if jingu_mastery_ability:GetToggleState() then
			
			if jingu_mastery_ability.jingu_mastery_buff_modifier then
				local jingu_stacks = jingu_mastery_ability.jingu_mastery_buff_modifier:GetStackCount()
				
				if jingu_stacks > max_damage_stacks then
					stacks = max_damage_stacks
				else
					stacks = jingu_stacks
				end
					
			end
		end
	end
	
	local startPos = Vector(self.caster_loc.x, self.caster_loc.y, caster:GetCursorPosition().z + 1)
	local endPos = startPos + caster:GetForwardVector() * (range  - 60)
	
	-- Crit hehe
	-- The duration is the duration of 'Monkey Kings Staff'. Regular 0.1 is enough to make boundless strike crit.
	caster:AddNewModifier(caster, self, "modifier_imba_monkey_king_boundless_strike", {duration = strike_buff_duration, stackdamage = stacks})

	local teams = DOTA_UNIT_TARGET_TEAM_ENEMY
	local types = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP
	local flags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE
	 
	local units = FindUnitsInLine(caster:GetTeam(), startPos, endPos, caster, radius, teams, types, flags)
	 
	for _,target in pairs(units) do
		caster:PerformAttack(target, true, true, true, true, false, false, true)
		target:AddNewModifier(caster, self, "modifier_stunned", {duration = stun_duration})
	end
	
	caster:FadeGesture(MK_STRIKE_ANIMATION)

	if caster.strike_cast_start then
	
		ParticleManager:DestroyParticle(caster.strike_cast_start, false)
		ParticleManager:ReleaseParticleIndex(caster.strike_cast_start)
		caster.strike_cast_start = nil
	end
	
	local strike_impact_pfx = ParticleManager:CreateParticle(particle_strike_path, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(strike_impact_pfx, 0, startPos)
	ParticleManager:SetParticleControl(strike_impact_pfx, 1, endPos)
	ParticleManager:ReleaseParticleIndex(strike_impact_pfx)
	caster:EmitSound("Hero_MonkeyKing.Strike.Impact")
	
	return true 
end

modifier_imba_monkey_king_boundless_strike = modifier_imba_monkey_king_boundless_strike or class({})
function modifier_imba_monkey_king_boundless_strike:IsDebuff() return false end
function modifier_imba_monkey_king_boundless_strike:IsHidden() return false end -- If false, name it buff/debuff
function modifier_imba_monkey_king_boundless_strike:IsPurgable() return false end
function modifier_imba_monkey_king_boundless_strike:IsPurgeException() return false end
function modifier_imba_monkey_king_boundless_strike:IsStunDebuff() return false end
function modifier_imba_monkey_king_boundless_strike:RemoveOnDeath() return true end
-------------------------------------------
function modifier_imba_monkey_king_boundless_strike:DeclareFunctions()
    local decFuns =
    {
				MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE
    }
    return decFuns
end

function modifier_imba_monkey_king_boundless_strike:OnCreated(keys)	
	if not IsServer() then return end
	
	self.stacks = keys.stackdamage
	
	-- if self.stackdamage  <= 0 then
		-- self.stackdamage  = 1
	-- end	
	
end

function modifier_imba_monkey_king_boundless_strike:OnAttackLanded(keys)
	if not IsServer() then return end

	local caster = self:GetCaster()
	local parent = self:GetParent()
	
	if caster ~= parent then return end
	
	-- prevent that next normal attacks are also stack damage
	self.stacks = 0
	
end

function modifier_imba_monkey_king_boundless_strike:GetModifierPreAttack_CriticalStrike()
	if not IsServer() then return end
	
	-- Holy cow, to much damage. Divided by 2 for now to make less damage.
	return (self:GetAbility():GetSpecialValueFor("strike_crit_mult") + self:GetCaster():FindTalentValue("special_bonus_unique_monkey_king")) * (1 + self.stacks * 0.5)
end



-------------------------------------------
--                Jingu Mastery
-------------------------------------------
-- Visible Modifiers:
MergeTables(LinkedModifiers,{
    ["modifier_imba_monkey_king_jingu_mastery"] = LUA_MODIFIER_MOTION_NONE,
    ["modifier_imba_monkey_king_jingu_mastery_buff"] = LUA_MODIFIER_MOTION_NONE,
    ["modifier_imba_monkey_king_jingu_mastery_count_debuff"] = LUA_MODIFIER_MOTION_NONE,
    ["modifier_monkey_king_special_talent_jungu_mastery_damage"] = LUA_MODIFIER_MOTION_NONE,
		
})
-- Hidden Modifiers:
-- MergeTables(LinkedModifiers,{
    -- ["modifier_imba_ABILITYNAME"] = LUA_MODIFIER_MOTION_NONE,
-- })

imba_monkey_king_jingu_mastery = imba_monkey_king_jingu_mastery or class({})
function imba_monkey_king_jingu_mastery:IsHiddenWhenStolen() return false end
function imba_monkey_king_jingu_mastery:IsRefreshable() return false end
function imba_monkey_king_jingu_mastery:IsStealable() return false end
function imba_monkey_king_jingu_mastery:IsNetherWardStealable() return false end

function imba_monkey_king_jingu_mastery:GetAbilityTextureName()
   return "monkey_king_jingu_mastery"
end

function imba_monkey_king_jingu_mastery:GetIntrinsicModifierName()
    return "modifier_imba_monkey_king_jingu_mastery"
end

function imba_monkey_king_jingu_mastery:OnSpellStart()
	print("ok spellstart")
end

function imba_monkey_king_jingu_mastery:OnToggleOn()
	print("is on")
end

function imba_monkey_king_jingu_mastery:OnToggleOff()
	print("is off")
end

function imba_monkey_king_jingu_mastery:OnToggle()

end


modifier_imba_monkey_king_jingu_mastery = modifier_imba_monkey_king_jingu_mastery or class({})

function modifier_imba_monkey_king_jingu_mastery:IsHidden() return true end

function modifier_imba_monkey_king_jingu_mastery:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED
	}

	return funcs

end

function modifier_imba_monkey_king_jingu_mastery:OnCreated(  )
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.parent = self:GetParent()
	
	self.required_hit 					= self.ability:GetSpecialValueFor("required_hits")
	self.charges 								= self.ability:GetSpecialValueFor("charges")
	
	self.counter_duration 	 	= self.ability:GetSpecialValueFor("counter_duration")
	self.max_duration 				= self.ability:GetSpecialValueFor("max_duration")
	self.perma_lifesteal				= self.ability:GetSpecialValueFor("perma_lifesteal")

	self.is_boundless_strike_attack = false
end


function modifier_imba_monkey_king_jingu_mastery:OnRefresh(  )
		self:OnCreated(  )
end

function modifier_imba_monkey_king_jingu_mastery:OnAttackLanded( keys )
	
	local ability = keys.ability
	local target = keys.target
	local attacker = keys.attacker
	local damage = keys.damage
	


	if attacker ~= self.parent and self.caster ~= attacker then return end
	if  target:IsBuilding() or self.caster:PassivesDisabled() or not self.caster:IsRealHero() or self.caster:IsIllusion() then return end
	
	if not target:IsRealHero() or not target:IsIllusion() or not target:IsBuilding() then
		local healAmount = damage * self.perma_lifesteal * 0.01
		attacker:Heal(healAmount, self.caster)
	end
	
	print(target:IsCreep())
	
	if not target:IsRealHero() or target:IsIllusion() then return end

	-- if caster has already buff do nothing
	if self.caster:HasModifier("modifier_imba_monkey_king_jingu_mastery_buff") then return end	
	
	-- prevent monkey ulti to get buffed
	if attacker:HasModifier("modifier_monkey_king_fur_army_soldier") then return end
		
	-- when enemy get hit
	local jinguMasteryStack_debuff = target:FindModifierByName("modifier_imba_monkey_king_jingu_mastery_count_debuff")
	if not jinguMasteryStack_debuff then
			jinguMasteryStack_debuff = target:AddNewModifier(self.caster, self.ability, "modifier_imba_monkey_king_jingu_mastery_count_debuff", {duration = self.counter_duration})
			jinguMasteryStack_debuff:SetStackCount(0)
	end
	
	-- if we got all 4 hits then remove particle and give monkey 4 charges
	if jinguMasteryStack_debuff:GetStackCount() + 1 >= self.required_hit then
		jinguMasteryStack_debuff:Destroy()
			
		self.caster:AddNewModifier(self.caster, self.ability, "modifier_imba_monkey_king_jingu_mastery_buff", {duration = self.max_duration})
		
		local jinguBuffStack = self.caster:FindModifierByName("modifier_imba_monkey_king_jingu_mastery_buff")
		jinguBuffStack:SetStackCount(self.charges)
		self:GetAbility().jingu_mastery_buff_modifier = jinguBuffStack
		
		local jingu_start_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.caster)
		ParticleManager:SetParticleControl(jingu_start_particle, 0, self.caster:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(jingu_start_particle)
			
		EmitSoundOn("Hero_MonkeyKing.IronCudgel", self.caster)
		
	else
			jinguMasteryStack_debuff:IncrementStackCount()
			jinguMasteryStack_debuff:SetDuration(jinguMasteryStack_debuff:GetDuration(), true)
	-- debuff circle over the targets head
		if not target.jingu_overhead_particle then
			target.jingu_overhead_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
		end
		
		ParticleManager:SetParticleControl(target.jingu_overhead_particle, 0, target:GetAbsOrigin())
		ParticleManager:SetParticleControl(target.jingu_overhead_particle, 1, Vector(0, jinguMasteryStack_debuff:GetStackCount(), 0))
	end
		
	return 0
end

modifier_imba_monkey_king_jingu_mastery_count_debuff = class({})
function modifier_imba_monkey_king_jingu_mastery_count_debuff:OnCreated( )
	
end

function modifier_imba_monkey_king_jingu_mastery_count_debuff:OnRefresh( )

end

function modifier_imba_monkey_king_jingu_mastery_count_debuff:OnDestroy( )

		local target = self:GetParent()
		if target.jingu_overhead_particle then
			ParticleManager:DestroyParticle(target.jingu_overhead_particle, false)
			ParticleManager:ReleaseParticleIndex(target.jingu_overhead_particle)
			target.jingu_overhead_particle = nil
		end
		
end

modifier_imba_monkey_king_jingu_mastery_buff = class({})

function modifier_imba_monkey_king_jingu_mastery_buff:DeclareFunctions()

	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
	}

	return funcs

end

function modifier_imba_monkey_king_jingu_mastery_buff:OnCreated( )
		self.bonus_damage 			= self:GetAbility():GetSpecialValueFor("bonus_damage") 
		self.talent_damage 			= self:GetCaster():FindTalentValue("special_bonus_unique_monkey_king_2")  or 0
		self.lifesteal 								= self:GetAbility():GetSpecialValueFor("lifesteal")
		
		local caster = self:GetCaster()

		if caster.jingubuff_overhead_particle == nil then
			caster.jingubuff_overhead_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
			--ParticleManager:SetParticleControl(caster.jingubuff_overhead_particle, 0, caster:GetAbsOrigin())
			--ParticleManager:ReleaseParticleIndex(caster.jingubuff_overhead_particle)
		end
		
		if caster.jingubuff_weapon_glow_particle == nil then
			caster.jingubuff_weapon_glow_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_tap_buff.vpcf", PATTACH_ROOTBONE_FOLLOW, caster)
			ParticleManager:SetParticleControlEnt(caster.jingubuff_weapon_glow_particle, 0, caster, PATTACH_ROOTBONE_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(caster.jingubuff_weapon_glow_particle, 2, caster, PATTACH_POINT_FOLLOW, "attach_weapon_top", caster:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(caster.jingubuff_weapon_glow_particle, 3, caster, PATTACH_POINT_FOLLOW, "attach_weapon_bot", caster:GetAbsOrigin(), true)

			--ParticleManager:SetParticleControl(caster.jingubuff_weapon_glow_particle, 0, caster:GetAbsOrigin())
			--ParticleManager:ReleaseParticleIndex(caster.jingubuff_weapon_glow_particle)
		end

end

function modifier_imba_monkey_king_jingu_mastery_buff:OnRefresh( )
		self:OnCreated( )
end

function modifier_imba_monkey_king_jingu_mastery_buff:OnDestroy( )
	self:GetAbility().jingu_mastery_buff_modifier = nil
	
	local caster = self:GetCaster()


	if caster.jingubuff_overhead_particle then
		ParticleManager:DestroyParticle(caster.jingubuff_overhead_particle, false)
		ParticleManager:ReleaseParticleIndex(caster.jingubuff_overhead_particle)
		caster.jingubuff_overhead_particle = nil
	end
	
	if caster.jingubuff_weapon_glow_particle  then
		ParticleManager:DestroyParticle(caster.jingubuff_weapon_glow_particle, false)
		ParticleManager:ReleaseParticleIndex(caster.jingubuff_weapon_glow_particle)
		caster.jingubuff_weapon_glow_particle = nil
	end
	
end

function modifier_imba_monkey_king_jingu_mastery_buff:OnAbilityExecuted( keys )
	local caster = self:GetCaster()
	
	if caster == self:GetParent() then
		if self:GetParent():PassivesDisabled() then
			return 0
		end
					
		if keys.ability:GetName() == "imba_monkey_king_boundless_strike" then
	
			self.is_boundless_strike_attack = true
			
			Timers:CreateTimer(0.03, function()
					self.is_boundless_strike_attack = false

					if not self:GetAbility():GetToggleState() then
					
						self:DecrementStackCount()
					
					else
						self:SetStackCount(self:GetStackCount() - self:GetAbility():GetSpecialValueFor("max_damage_stacks"))
					end
					
					if self:GetStackCount() <= 0 then

						self:Destroy()
					end
					
			end)
				
		end
		
	end
end

function modifier_imba_monkey_king_jingu_mastery_buff:GetModifierPreAttack_BonusDamage(params)

	return self.bonus_damage + self.talent_damage
end

function modifier_imba_monkey_king_jingu_mastery_buff:OnAttackLanded( keys )
	local attacker 		= keys.attacker
	local caster 				= self:GetCaster()
	local target 				= keys.target
	local ability 				= keys.ability
	local damage 			= keys.damage
	
	if attacker ~= caster then return end

	if not attacker:IsRealHero() or attacker:IsIllusion() then return end
	if caster:PassivesDisabled() then
		return 0
	end
	

	-- lifesteal pfx and heal
	local lifePfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
--	ParticleManager:SetParticleControl(lifePfx, 0, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(lifePfx)

	-- jingu hit pfx
	local hitPfx = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_quad_tap_hit.vpcf", PATTACH_ROOTBONE_FOLLOW, target)
	ParticleManager:SetParticleControl(hitPfx, 1, target:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(hitPfx)
	
	if self.is_boundless_strike_attack then
		return 0
	end
	
	self:DecrementStackCount()
	if self:GetStackCount() <= 0 then
	
		self:Destroy()
	end
	
end

function modifier_imba_monkey_king_jingu_mastery_buff:OnTakeDamage( keys )
	local attacker 		= keys.attacker
	local caster 				= self:GetCaster()
	local target 				= keys.unit
	local ability 				= keys.ability
	local damage 			= keys.damage
	
	if attacker ~= caster then return end

	if not attacker:IsRealHero() or attacker:IsIllusion() then return end
	if caster:PassivesDisabled() then
		return 0
	end

	
				
	if not target:IsBuilding() then 

		local healAmount = damage *  self.lifesteal * 0.01
		attacker:Heal(healAmount, caster)
		
	end
	
	return 0
end



-------------------------------------------
--                Jungu Dash
-- Moves Monkey King forward (like force staff)
-------------------------------------------

MergeTables(LinkedModifiers,{
    ["imba_monkey_king_jingu_dash"] = LUA_MODIFIER_MOTION_NONE,
		
})

imba_monkey_king_jingu_dash = imba_monkey_king_jingu_dash or class({})
function imba_monkey_king_jingu_dash:GetAbilityTextureName()
   return "monkey_king_boundless_strike"
end

function imba_monkey_king_jingu_dash:OnIntervalThink()
  -- modifier_monkey_king_tree_dance_hidden

end




for LinkedModifier, MotionController in pairs(LinkedModifiers) do
    LinkLuaModifier(LinkedModifier, "hero/hero_monkey_king", MotionController)
end

