local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Hitbox = {}
Hitbox.__index = Hitbox

function Hitbox.new(cframe: CFrame, size: Vector3, overlap: OverlapParams)
	local self = setmetatable({}, Hitbox)

	self.CFrame = cframe
	self.Size = size
	self.Overlap = overlap
	self.Owner = nil

	self._hits = {}

	return self
end

function Hitbox:_targetCheck(target: Model)
	if not target:HasTag("Entity") then return end
	if self._hits[target.Name] then return end
	return true
end

function Hitbox:_targetInit(target: Instance, deleteTime: number)
	if not self:_targetCheck(target) then return end
	self._hits[target.Name] = target

	if deleteTime then
		task.delay(deleteTime, function()
			self._hits[target.Name] = nil
		end)
	end

	return true, self._hits[target.Name]
end

function Hitbox:UpdateTargets(deleteTime: number)
	local parts = workspace:GetPartBoundsInBox(self.CFrame, self.Size, self.Overlap)

	for _, part in pairs(parts) do
		self:_targetInit(part.Parent, deleteTime)
	end
end

function Hitbox:SmoothMove(cframe: CFrame, moveTime: number, targets: boolean, deleteTime: number)
	local cframeReplication = Instance.new("CFrameValue")
	cframeReplication.Value = self.CFrame
	
	local tween = TweenService:Create(cframeReplication, TweenInfo.new(
			moveTime, Enum.EasingStyle.Linear
		), {Value = cframe})
	
	tween:Play()
	Debris:AddItem(cframeReplication, moveTime)
	
	while tween.PlaybackState.Name == "Playing" do
		if targets then
			self:UpdateTargets(deleteTime)
		end
		self.CFrame = cframeReplication.Value
		print(self.CFrame)
		
		task.wait(moveTime / 20)
	end

	cframeReplication:Destroy()
end

return Hitbox
