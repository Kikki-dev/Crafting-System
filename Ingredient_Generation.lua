local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CraftingFolder = ReplicatedStorage.Mini_Projects.Crafting

local IngredientsFolder = workspace:WaitForChild("Ingredients")
local AssetsFolder = CraftingFolder:WaitForChild("Assets")

local IngrdedientsModules = CraftingFolder.Ingredient:WaitForChild("Ingredients")

local generating = true

local Ingredient_Generation = {}
Ingredient_Generation.__index = Ingredient_Generation

function Ingredient_Generation.new(MaxObjects: number)
	local self = setmetatable({}, Ingredient_Generation)
	
	self.MaxObjects = MaxObjects
	
	return self
end

function Ingredient_Generation:Start(zone)
	local x = zone.Size.X * 0.5
	local y = zone.Size.Y * 0.5
	local z = zone.Size.Z * 0.5
	
	while true do
		task.wait(1)
		if #IngredientsFolder:GetChildren() > self.MaxObjects then
			generating = false
		else
			generating = true
		end
		
		if generating then
			local objectIndex = math.random(1, #IngrdedientsModules:GetChildren())
			local objectModule = IngrdedientsModules:GetChildren()[objectIndex]

			local objectModel = AssetsFolder.Models:WaitForChild(objectModule.Name):Clone()
			objectModel.Parent = IngredientsFolder
			objectModel.Position = zone.Position + Vector3.new(math.random(0 - x, x), math.random(0 - y, y), math.random(0 - z,z))
		end
	end
end

return Ingredient_Generation
