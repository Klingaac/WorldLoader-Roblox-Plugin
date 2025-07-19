-- Preset values for Properties tab

local Presets = {
	["Rail"] = {
		{
			["Preset Name"] = "Default",
			["Enabled"] = true,
			["Ballast Height"] = 0.72,
			["Ballast Width"] = 4.8,
			["Ballast Color"] = Color3.fromRGB(163, 162, 165),
			["Ballast Material"] = "Pebble",
			["Rail Gauge"] = 1.435,
			["Rail Mesh"] = false,
			["Rail Color"] = Color3.fromRGB(163, 162, 165),
			["Rail Material"] = "Metal",
			["Tie Texture"] = "ConcreteTies",
			["3D Ties"] = true,
			["Tie Color"] = Color3.fromRGB(86, 66, 54),
			["Tie Material"] = "Wood"
			
		},
		{
			["Preset Name"] = "Realistic",
			["Enabled"] = true,
			["Ballast Height"] = .1,
			["Ballast Width"] = 4,
			["Ballast Color"] = Color3.fromRGB(103, 72, 47),
			["Ballast Material"] = "Pebble",
			["Rail Gauge"] = 1.435,
			["Rail Mesh"] = true,
			["Rail Color"] = Color3.new(0.231373, 0.196078, 0.168627),
			["Rail Material"] = "Metal",
			["Tie Texture"] = "WoodenTies",
			["3D Ties"] = false,
			["Tie Color"] = Color3.new(0.231373, 0.196078, 0.168627),
			["Tie Material"] = "Wood"
		}
	},
	["Building"] = {
		{
			["Preset Name"] = "Default",
			["Enabled"] = true,
			["Deafult Height"] = 4,
			["Height per floor"] = 3,
			["Color"] = Color3.fromRGB(202, 180, 150),
			["Material"] = "Concrete",
		}
	},
	["Road"] = {
		{
			["Preset Name"] = "Default",
			["Road Enabled"] = true,
			["Road Color"] = Color3.fromRGB(72, 72, 72),
			["Road Material"] = "Asphalt",
			["Sidewalk Enabled"] = true,
			["Sidewalk Color"] = Color3.fromRGB(126, 126, 126),
			["Sidewalk Material"] = "Concrete",
			["Rural Road Enabled"] = true,
			["Rural Road Color"] = Color3.fromRGB(105, 64, 40),
			["Rural Road Material"] = "Grass",
		}
	},
	["Barrier"] = {
		{
			["Preset Name"] = "Default",
			["Enabled"] = true,
			["Color"] = Color3.new(1, 0.941176, 0.843137),
			["Material"] = "Concrete",
			["Height"] = 1,
			["Width"] = .1,
		}
	},
	["Generation Rules"] = {
		{
			["Preset Name"] = "Deafult",
			["Ro-Scale"] = false,
			["Ro-Scale Ties"] = false,
			["Ro-Scale Ballast"] = false,
			["Track Handles"] = false,
			["Areas"] = false,
			["Safe mode (slower generation)"] = false,
			["Elevation multiplier"] = 1,
			["Train platform height multiplier"] = 1,
		}
	}
}

return Presets
