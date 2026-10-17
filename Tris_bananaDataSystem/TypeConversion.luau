--!strict

--type conversion helper for datamanager
local TypeConversion = {}

-- map types to object class names
TypeConversion.ValueMap = {
	["number"]="NumberValue",
	["string"]="StringValue",
	["boolean"]="BoolValue",
	["Instance"]="ObjectValue",
	["CFrame"]="CFrameValue",
	["Vector3"]="Vector3Value",
	["Color3"]="Color3Value",
	["BrickColor"]="BrickColorValue",
	["Ray"]="RayValue"
}

-- Returns the correct Roblox Value class name based on the data type
function TypeConversion.GetClassName(value: any): string?
	local valueType = typeof(value)
	return TypeConversion.ValueMap[valueType]
end

return TypeConversion
