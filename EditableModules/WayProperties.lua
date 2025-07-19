--[[

		      |\      _,,,---,,_
		ZZZzz /,`.-'`'    -.  ;-;;,_
		     |,4-  ) )-,_. ,\ (  `'-'
			'---''(_/--'  `-'\_)  	
			
		* 1 meter = 3.57 studs
		* input data IN METERS
		* name of module does not matter
		
		find all info on how to edit this here: https://devforum.roblox.com/t/worldloader-plugin-documentation/3187419

]]

local roadHeight = .1

local WayPorperties = {

	["railway"] = {
		["rail"] = {
			operation = "rail",
			parent = "Railway",
			gauge = 1.435,
			ballast = {
				width = 4,
				height = 0.1,
				meshpart = "Ballast",
				color = Color3.fromRGB(103, 72, 47),
				material = Enum.Material.Pebble,
			},
			ties = {
				ties3D = false,
				texture = "WoodenTies",
				color = Color3.new(0.231373, 0.196078, 0.168627),
				material = Enum.Material.Wood,
				transparency = 0,
			},
			rails = {
				mesh = "RealisticRail",
				color = Color3.fromRGB(83, 67, 67),
				material = Enum.Material.Metal,
			}
		},
		
		["disused"] = {
			operation = "rail",
			parent = "Railway",
			gauge = 1.435,
			ballast = {
				width = 4,
				height = 0.1,
				meshpart = "Ballast",
				color = Color3.fromRGB(103, 72, 47),
				material = Enum.Material.Pebble,
			},
			ties = {
				ties3D = false,
				texture = "WoodenTies",
				color = Color3.new(0.231373, 0.196078, 0.168627),
				material = Enum.Material.Wood,
				transparency = 0,
			},
			rails = {
				mesh = "RealisticRail",
				color = Color3.fromRGB(83, 67, 67),
				material = Enum.Material.Metal,
			}
		},
		
		["light_rail"] = {
			operation = "rail",
			parent = "Railway",
			gauge = 1.435,
			ballast = {
				width = 2.5,
				height = 0.1,
				meshpart = "Ballast",
				color = Color3.fromRGB(163, 162, 165),
				material = Enum.Material.Pebble,
			},
			ties = {
				ties3D = false,
				texture = "WoodenTies",
				color = Color3.new(0.231373, 0.196078, 0.168627),
				material = Enum.Material.Wood,
				transparency = 0,
			},
			rails = {
				mesh = "RealisticRail",
				color = Color3.fromRGB(83, 67, 67),
				material = Enum.Material.Metal,
			}
		},
		["tram"] = {
			operation = "rail",
			parent = "Railway",
			gauge = 1,
			ballast = {
				width = 2.5,
				height = 0.01,
				meshpart = "Ballast",
				color = Color3.fromRGB(42, 42, 43),
				material = Enum.Material.Asphalt,
			},
			ties = {
				ties3D = false,
				texture = "WoodenTies",
				color = Color3.new(0.231373, 0.196078, 0.168627),
				material = Enum.Material.Wood,
				transparency = 1,
			},
			rails = {
				mesh = "RealisticRail",
				color = Color3.fromRGB(83, 67, 67),
				material = Enum.Material.Metal,
			},
		},
		["platform"] = {
			operation = "area/way",
			parent = "Railway",
			width = 1,
			height = .9,
			color = Color3.fromRGB(107, 106, 108),
			material = Enum.Material.Concrete
		},
		["razed"] = {
			disabled = true,
			operation = "rail",
			parent = "Railway",
			gauge = 1.435,
			ballast = {
				width = 2.5,
				height = 0.1,
				meshpart = "Ballast",
				color = Color3.fromRGB(163, 162, 165),
				material = Enum.Material.Pebble,
			},
			ties = {
				texture = "WoodenTies",
				transparency = 0,
			},
			rails = {
				mesh = "ayo",
				color = Color3.fromRGB(83, 67, 67),
				material = Enum.Material.Metal,
			}
		}

	},

	["building:part"] = {
		["nil"] = {
			operation = "building",
			parent = "Buildings",
			heightPerFloor = 3,
			deafultHeight = 4,
			color = Color3.new(0.85098, 0.827451, 0.784314),
			material = Enum.Material.Concrete
		}
	},
	
	["man_made"] = {
		["bridge"] = {
			operation = "area",
			height = .095,
			parent = "ManMade",
			color = Color3.new(0.584314, 0.584314, 0.584314),
			material = Enum.Material.Concrete
		}
	},

	["building"] = {
		["nil"] = {
			operation = "building",
			parent = "Buildings",
			heightPerFloor = 3,
			deafultHeight = 4,
			color = Color3.new(0.85098, 0.827451, 0.784314),
			material = Enum.Material.Concrete
		}
	},

	["highway"] = {
		["nil"] = {
			operation = "area/way",
			parent = "Highways",
			color = Color3.new(0.282353, 0.282353, 0.282353),
			material = Enum.Material.Asphalt,
			width = 3,
			height = roadHeight
		},
		["proposed"] = {
			disabled = true
		},
		["residential"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.new(0.282353, 0.282353, 0.282353),
			material = Enum.Material.Asphalt,
			width = 4,
			height = roadHeight
		},
		["unclassified"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.new(0.388235, 0.388235, 0.388235),
			material = Enum.Material.Asphalt,
			width = 4,
			height = roadHeight
		},
		["tertiary"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.new(0.282353, 0.282353, 0.282353),
			material = Enum.Material.Asphalt,
			width = 4,
			height = roadHeight
		},
		["secondary"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.new(0.282353, 0.282353, 0.282353),
			material = Enum.Material.Asphalt,
			width = 4,
			height = roadHeight
		},
		["primary"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.new(0.282353, 0.282353, 0.282353),
			material = Enum.Material.Asphalt,
			width = 5,
			height = roadHeight
		},
		["trunk"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.new(0.282353, 0.282353, 0.282353),
			material = Enum.Material.Asphalt,
			width = 5,
			height = roadHeight
		},
		["motorway"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.new(0.282353, 0.282353, 0.282353),
			material = Enum.Material.Asphalt,
			width = 5,
			height = roadHeight
		},
		["service"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.new(0.282353, 0.282353, 0.282353),
			material = Enum.Material.Asphalt,
			width = 4,
			height = roadHeight
		},
		["track"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.fromRGB(102, 69, 53),
			material = Enum.Material.Grass,
			width = 3,
			height = roadHeight
		},
		["cycleway"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.new(0.282353, 0.282353, 0.282353),
			material = Enum.Material.Asphalt,
			width = 1.5,
			height = roadHeight
		},
		["pedestrian"] = {
			operation = "area/way",
			parent = "Highways",
			color = Color3.new(0.498039, 0.498039, 0.498039),
			material = Enum.Material.Concrete,
			width = 1.5,
			height = roadHeight-.03
		},
		["footway"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.new(0.498039, 0.498039, 0.498039),
			material = Enum.Material.Concrete,
			width = 1.5,
			height = roadHeight-.03
		},
		["path"] = {
			operation = "way",
			parent = "Highways",
			color = Color3.fromRGB(112, 88, 66),
			material = Enum.Material.Pebble,
			width = 1.5,
			height = roadHeight-.03
		},
	},

	["landuse"] = {
		["nil"] = {
			operation = "area",
			parent = "Landuse",
			height = .03,
			color = Color3.fromRGB(63, 93, 66),
			material = Enum.Material.Grass
		},
		["residential"] = {
			operation = "area",
			parent = "Landuse",
			height = .01,
			color = Color3.fromRGB(84, 93, 78),
			material = Enum.Material.Grass
		},
		["winter_sports"] = {
			disabled = true
		},
		["meadow"] = {
			operation = "area",
			parent = "Landuse",
			height = .06,
			color = Color3.fromRGB(71, 120, 48),
			material = Enum.Material.Grass
		},
		["railway"] = {
			operation = "area",
			parent = "Landuse",
			height = .01,
			color = Color3.fromRGB(93, 73, 55),
			material = Enum.Material.Pebble
		},
		["industrial"] = {
			operation = "area",
			parent = "Landuse",
			height = .04,
			color = Color3.fromRGB(82, 121, 86),
			material = Enum.Material.Grass
		},
		["grass"] = {
			operation = "area",
			parent = "Landuse",
			height = .065,
			color = Color3.fromRGB(71, 120, 48),
			material = Enum.Material.Grass
		},
		["forest"] = {
			operation = "area",
			parent = "Landuse",
			height = .04,
			color = Color3.fromRGB(47, 79, 32),
			material = Enum.Material.Grass
		}
	},
	
	["parking"] = {
		["surface"] = {
			operation = "area",
			parent = "Landuse",
			height = .02,
			color = Color3.new(0.345098, 0.345098, 0.345098),
			material = Enum.Material.Asphalt
		}
	},
	
	["amenity"] = {
		["parking"] = {
			operation = "area",
			parent = "Landuse",
			height = .02,
			color = Color3.new(0.345098, 0.345098, 0.345098),
			material = Enum.Material.Asphalt
		},
		["taxi"] = {
			operation = "area",
			parent = "Landuse",
			height = .02,
			color = Color3.new(0.345098, 0.345098, 0.345098),
			material = Enum.Material.Asphalt
		}
	},
	
	["natural"] = {
		["water"] = {
			operation = "area",
			parent = "Natural",
			height = .11,
			color = Color3.new(0.141176, 0.32549, 0.564706),
			material = Enum.Material.Glass
		},
	},

	["leisure"] = {
		["nil"] = {
			operation = "area",
			parent = "Leisure",
			height = .05,
			color = Color3.fromRGB(50, 149, 60),
			material = Enum.Material.Grass
		},
		["park"] = {
			operation = "area",
			parent = "Leisure",
			height = .055,
			color = Color3.fromRGB(76, 141, 54),
			material = Enum.Material.Grass
		},
		["swimming_pool"] = {
			operation = "area",
			parent = "Leisure",
			height = .12,
			color = Color3.new(0.109804, 0.109804, 0.709804),
			material = Enum.Material.Glass
		},
		["pitch"] = {
			["surface"] = {
				["nil"] = {
					operation = "area",
					parent = "Leisure",
					height = .1,
					color = Color3.new(0.156863, 0.470588, 0.192157),
					material = Enum.Material.Grass
				},
				["grass"] = {
					operation = "area",
					parent = "Leisure",
					height = .1,
					color = Color3.new(0.156863, 0.470588, 0.192157),
					material = Enum.Material.Grass
				},
				["clay"] = {
					operation = "area",
					parent = "Leisure",
					height = .1,
					color = Color3.new(0.760784, 0.403922, 0.0431373),
					material = Enum.Material.Pebble
				},
				["tartan"] = {
					operation = "area",
					parent = "Leisure",
					height = .1,
					color = Color3.new(0.760784, 0.403922, 0.0431373),
					material = Enum.Material.Salt
				}
			},
		}
	},

	["barrier"] = {
		["nil"] = {
			operation  = "way",
			parent = "Barriers",
			color = Color3.new(0.721569, 0.662745, 0.584314),
			material = Enum.Material.Concrete,
			height = 1.5,
			width = .1
		}
	}

}

return WayPorperties