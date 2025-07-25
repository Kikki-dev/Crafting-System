local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CraftingFolder = ReplicatedStorage.Mini_Projects:WaitForChild("Crafting")
local PotionsModules = CraftingFolder:WaitForChild("Potion"):WaitForChild("Potions")

local assets = CraftingFolder:WaitForChild("Assets")

local StationManager = {}
StationManager.__index = StationManager

local function compareIngredients(listA, listB)
	if #listA ~= #listB then return false end

	local matched = {}

	for _, a in ipairs(listA) do
		local found = false
		for i, b in ipairs(listB) do
			if not matched[i] and a.name == b.name then
				matched[i] = true
				found = true
				break
			end
		end
		if not found then
			return false
		end
	end

	return true
end


function StationManager.new(Cauldron, Table: Model, player)
	local self = setmetatable({}, StationManager)
	
	self.DisplayedIngredients = {}
	self.InCauldronIngredients = {}
	self.Cauldron = Cauldron
	self.Table = Table
	self.Player = player
	
	return self
end

function StationManager:DisplayIngredient(ingredient)
	local ingredientModel: BasePart = assets.Models:WaitForChild(ingredient.name):Clone()
	local ingredientAttachment: Attachment = self.Table.Main:WaitForChild(ingredient.name)
	
	if ingredientModel:GetAttribute("DisplayedPart") == false then
		return
	end
	
	table.insert(self.DisplayedIngredients, ingredient)
	
	local dragDetector = Instance.new("DragDetector")
	dragDetector.Parent = ingredientModel
	dragDetector.DragStyle = Enum.DragDetectorDragStyle.TranslateViewPlane
	
	ingredientModel.CFrame = ingredientAttachment.WorldCFrame * CFrame.new(0, .8, 0)
	ingredientModel.Anchored = true
	ingredientModel.Parent = workspace
	ingredientModel:SetAttribute("DisplayedPart", true)
	
	dragDetector.DragStart:Connect(function()
		ingredientModel.Anchored = false
		if ingredientModel:GetAttribute("DisplayedPart") == false then
			return 
		end
		
		ingredientModel:SetAttribute("DisplayedPart", false)
		
		task.delay(5, function()
			self:DisplayIngredient(ingredient)
		end)
	end)
	
	self.Cauldron.Cauldron.AddPart.Touched:Connect(function(hit)
		if hit ~= ingredientModel then return end
		if ingredientModel:GetAttribute("DisplayedPart") == false then
			if ingredientModel:GetAttribute("Connected") == true then return end
			ingredientModel:SetAttribute("Connected", true)
			
			self:AddIngredient(ingredient)
			
			ingredientModel:Destroy()
		end
	end)
end

function StationManager:CleanCauldron()
	local IngredientsFrame = self.Cauldron.Cauldron:WaitForChild("IngredientsFrame")
	local Gui = IngredientsFrame:WaitForChild("Gui")
	local MainFrame = Gui:WaitForChild("Main")
	
	for _, ingredient in ipairs(MainFrame:GetChildren()) do
		if ingredient:IsA("Frame") then
			ingredient:Destroy()
		end
	end
	
	self.InCauldronIngredients = {}
end

function StationManager:AddIngredient(ingredient)
	table.insert(self.InCauldronIngredients, ingredient)
	local IngredientsFrame = self.Cauldron.Cauldron:WaitForChild("IngredientsFrame")
	local Gui = IngredientsFrame:WaitForChild("Gui")
	local MainFrame = Gui:WaitForChild("Main")
	
	if MainFrame:FindFirstChild(ingredient.name) then
		local objectFrame = MainFrame:FindFirstChild(ingredient.name)
		local quantity = objectFrame:GetAttribute("Quantity") + 1
		objectFrame:SetAttribute("Quantity", quantity)
		objectFrame.Quantity.Text = "x"..quantity
	else
		local Template = script.Template

		local ObjectFrame = Template:Clone()
		ObjectFrame.Name = ingredient.name
		ObjectFrame.Title.Text = ingredient.name
		ObjectFrame.Rarity.Text = ingredient.rarity
		ObjectFrame.Quantity.Text = "x1"
		ObjectFrame:SetAttribute("Quantity", 1)

		ObjectFrame.Parent = MainFrame
		ObjectFrame.Visible = true
	end
end

local Recipes = {
	["Strenght"] = require(PotionsModules.Strenght.Infos).ingredients,
	["Speed"] = require(PotionsModules.Speed.Infos).ingredients,
	["Luck"] = require(PotionsModules.Luck.Infos).ingredients,
}

function StationManager:CraftPotion()
	for potionName, ingredients in pairs(Recipes) do
		if compareIngredients(self.InCauldronIngredients, ingredients) then
			print("Potion Created :", potionName)
			self:PotionHandler(potionName)
			self:CleanCauldron()
			assets.Events.DiscoverPotion:Fire(self.Player, potionName)
			return potionName
		end
	end
	
	print("Wrong Ingredient")
	return nil
end

function StationManager:PotionHandler(potionName)
	local PotionsAssets = assets:WaitForChild("Models"):WaitForChild("Potions")
	local potionModel = PotionsAssets:WaitForChild(potionName):Clone()
	
	local spinningspeed = 0.05
	
	local spawningPosition = self.Cauldron.Cauldron.AddPart.Position + Vector3.new(0, -1.2, 0)
	potionModel.Position = spawningPosition
	
	potionModel.Parent = workspace
	
	task.spawn(function()
		local speed = spinningspeed
		while speed > 0 do
			potionModel.CFrame = potionModel.CFrame * CFrame.Angles(0, speed, 0)
			speed -= 0.00013
			task.wait()
		end
	end)
	
	local appearingTween = TweenService:Create(potionModel, TweenInfo.new(1.5, Enum.EasingStyle.Quart), {
		Position = self.Cauldron.Cauldron.AddPart.Position + Vector3.new(0, 4, 0)
	})
	
	appearingTween:Play()
	
	appearingTween.Completed:Wait()
	
	task.delay(10, function()
		local dissapearingTween = TweenService:Create(potionModel, TweenInfo.new(1.5, Enum.EasingStyle.Quart), {
			Position = spawningPosition
		})
		dissapearingTween:Play()
		dissapearingTween.Completed:Wait()
		potionModel:Destroy()
	end)
end

function StationManager:OptionsGuiHandling()
	local OptionsFrame = self.Cauldron.Cauldron:WaitForChild("OptionsFrame")
	local Gui = OptionsFrame:WaitForChild("Gui")
	local MainFrame = Gui:WaitForChild("Main")
	
	local craftButton = MainFrame:WaitForChild("CraftButton")
	local cleanButton = MainFrame:WaitForChild("CleanButton")
	
	cleanButton.MouseButton1Click:Connect(function()
		self:CleanCauldron()
	end)
	
	craftButton.MouseButton1Click:Connect(function()
		self:CraftPotion()
	end)
end

function StationManager:GetInCauldronIngredients()
	return self.InCauldronIngredients
end

return StationManager
