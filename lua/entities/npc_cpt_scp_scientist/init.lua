if !CPTBase then return end
AddCSLuaFile('shared.lua')
include('shared.lua')

ENT.ModelTable = {"models/cpthazama/scp/scientist.mdl"}
ENT.StartHealth = 65
ENT.CollisionBounds = Vector(18,18,70)
ENT.Faction = "FACTION_SCP_NTF"
ENT.FriendlyToPlayers = true

ENT.BloodEffect = {"blood_impact_red"}

ENT.tbl_Animations = {
	["Walk"] = {ACT_WALK},
	["Run"] = {ACT_RUN},
}

ENT.tbl_Sounds = {
	["Pain"] = {"cpthazama/scp/D9341/breath0.mp3","cpthazama/scp/D9341/breath1.mp3","cpthazama/scp/D9341/breath2.mp3","cpthazama/scp/D9341/breath3.mp3","cpthazama/scp/D9341/breath4.mp3"},
	["Death"] = {"cpthazama/scp/dclass/Gasp.mp3"}
}
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:SetInit()
	self:SetHullType(HULL_HUMAN)
	self:SetMovementType(MOVETYPE_STEP)
	self:SetSkin(math.random(0,1))
	self.NextDoorT = 0
	self.MinFollowDistance = 0
	self.NTFOwner = NULL
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:FaceOwner(owner)
	self:SetTarget(owner)
	local facetarget = ai_sched_cpt.New("cptbase_scp_faceowner")
	facetarget:EngTask("TASK_FACE_TARGET",0)
	self:StartSchedule(facetarget)
	self:LookAtPosition(self:FindCenter(owner),self.DefaultPoseParameters,self.DefaultPoseParamaterSpeed)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnThink()
	if util.IsSCPMap() then
		if CurTime() > self.NextDoorT then
			for _,v in ipairs(ents.FindInSphere(self:GetPos(),SCP_DoorOpenDistance)) do
				if v:IsValid() && v:GetClass() == "func_door" /*&& v:GetSequenceName(v:GetSequence()) == "idle"*/ then
					v:Fire("Open")
				end
			end
			self.NextDoorT = CurTime() +math.Rand(1,3)
		end
	end
	if !self.IsPossessed then
		if IsValid(self.NTFOwner) then
			local dist = self:GetClosestPoint(self.NTFOwner)
			if dist > 3000 then
				self.NTFOwner = NULL
			end
			if dist > self.MinFollowDistance && self:CanPerformProcess() then
				self:ChaseTarget(self.NTFOwner,false)
			end
			if !IsValid(self:GetEnemy()) then
				if dist <= self.MinFollowDistance && self.NTFOwner:Visible(self) then
					self:StopCompletely()
					self:FaceOwner(self.NTFOwner)
				end
			else
				if dist <= self.MinFollowDistance && (self:GetEnemy():GetClass() == "npc_cpt_scp_173" || self:GetEnemy():GetClass() == "npc_cpt_scp_087_b") && self:GetEnemy():Visible(self) then
					if self:IsMoving() then
						self:StopCompletely()
					end
					self:FaceEnemy()
				end
			end
		else
			self.CanWander = true
		end
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:OnSpottedFriendly(ent)
	if IsValid(self.NTFOwner) then return end
	if ent:GetClass() == "npc_cpt_scp_ntf" && ent:GetPos():Distance(self:GetPos()) <= 750 then
		self.NTFOwner = ent
		ent:OnScientistFollowed(self)
		self.MinFollowDistance = math.random(100,150)
		self.CanWander = false
	end
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:HandleSchedules(enemy,dist,nearest,disp)
	if self.IsPossessed then return end
	if self.IsOwned then return end
	if(disp == D_HT) then
		if enemy:GetClass() == "npc_cpt_scp_173" then
			self:FaceEnemy()
		else
			if self:CanPerformProcess() then
				self:Hide()
			end
		end
	end
end