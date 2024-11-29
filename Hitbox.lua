--// Services
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--// Class Creation
local Hitbox = {}
Hitbox.__index = Hitbox

--// Initializing New Hitbox
function Hitbox.new(cframe: CFrame, size: Vector3, overlap: OverlapParams?, owner: Instance?, visual: boolean?)
	local self = setmetatable({}, Hitbox)

	self.CFrame = cframe
	self.Size = size
	self.Overlap = overlap
	self.Owner = owner
	self.Visual = visual

	self.Hits = {}

	return self
end

--// Private Methods
function Hitbox:_targetCheck(target: Model)
	--// Add more checks if necceseary
	if target.Name == "Workspace" then return end
	if self:GetHits()[target.Name] then return end
	return true
end

function Hitbox:_targetInit(target: Instance, delayTime: number?)
	--// Checks target first
	if not self:_targetCheck(target) then return end
	self:GetHits()[target.Name] = target

	--// Delete with delay if necceseary
	if delayTime then
		task.delay(delayTime, function()
			self:GetHits()[target.Name] = nil
		end)
	end

	return true, self:GetHits()[target.Name]
end

function Hitbox:_showVisual()
	--// If no visual enabled return
	if not self.Visual then return end
	
	--// Creating and after 0.3s deleting visualizer
	local visualizer = Instance.new("Part")
	visualizer.Name = "HitboxVisualizer"
	visualizer.Size = self.Size
	visualizer.CFrame = self.CFrame
	visualizer.Color = Color3.new(1)
	visualizer.Material = Enum.Material.SmoothPlastic
	visualizer.Anchored = true
	visualizer.CanTouch = false
	visualizer.CanCollide = false
	visualizer.CanQuery = false
	visualizer.Transparency = 0.85
	visualizer.Parent = workspace
	Debris:AddItem(visualizer, 0.3)
end
	
--// Public Methods
function Hitbox:GetHits(sorted: boolean?, clean: boolean?)
	if sorted then
		--// Return pretty informative table with every target that found
		local newHits = {}
		for _, v in pairs(self.Hits) do
			table.insert(newHits, {
				Name = v.Name,
				Distance = (self.CFrame.Position - v.PrimaryPart.Position).Magnitude,
				Reference = v
			})
		end
		
		--// Clean
		if clean then self:Clean() end
		return newHits
	end
	
	--// Return basic self.Hits
	return self.Hits
end
	
function Hitbox:UpdateTargets(delayTime: number?, clean: boolean?)
	--// Get parts and show visual if enabled
	local parts = workspace:GetPartBoundsInBox(self.CFrame, self.Size, self.Overlap)
	self:_showVisual()
	
	--// Clean
	if clean then self:Clean() end 

	--// Initialize every target
	for _, part in pairs(parts) do
		self:_targetInit(part.Parent, delayTime)
	end
end

function Hitbox:SmoothMove(cframe: CFrame, moveTime: number, targets: boolean?, delayTime: number?, clean: boolean?)
	--// Create value to replicate cframe changes
	local cframeReplication = Instance.new("CFrameValue")
	cframeReplication.Value = self.CFrame
	
	--// Tween to make smooth move
	local tween = TweenService:Create(cframeReplication, TweenInfo.new(
			moveTime, Enum.EasingStyle.Linear
		), {Value = cframe})
	
	tween:Play()
	Debris:AddItem(cframeReplication, moveTime)
	
	--// Clean
	if clean then self:Clean() end

	--// Update hitbox cframe while tween is playing
	while tween.PlaybackState.Name == "Playing" do
		if targets then
			--// Getting targets
			self:UpdateTargets(delayTime)
		end
		
		self.CFrame = cframeReplication.Value
		self:_showVisual() --// Showing visual
		
		task.wait(moveTime / 17) --// 17 is optional wait time before new check (to prevent lag)
	end
end

function Hitbox:Clean(delayTime: number)
	--// Clean with/without delay
	if delayTime then
		task.delay(delayTime, function()
			table.clear(self.Hits)
		end)
	else
		table.clear(self.Hits)
	end
end

return Hitbox
