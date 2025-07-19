-- Library for Converting coordinates from Web Mercator Projection (EPSG:3857)
-- to Roblox coordinates and vise versa

local module = {}

-- Multiplies the roblox coordinates
local scaler

function module.newScaler(num: number, lat: number)
	
	local rad_lat = math.rad(lat)

	-- Calculate the scale factor using the Mercator projection formula
	local scale_factor = 1 / math.cos(rad_lat) / 3
	
	scaler = num / scale_factor
end

function module.getScaler()
	return scaler
end


local originShift = math.pi * 6378137

function module.toRoblox(lat: number, lon: number)
	
	local mx = lon * originShift / 180
	local my = math.log(math.tan((90 + lat) * math.pi / 360)) / (math.pi / 180)

	my = my * originShift / 180.0

	return Vector2.new(-mx*scaler,my*scaler)
end


function module.toLatLon(mx: number, my: number)
	
	mx, my = -mx/scaler, my/scaler

	local lon = (mx / originShift) * 180
	local lat = (my / originShift) * 180

	lat = 180 / math.pi * (2 * math.atan(math.exp(lat * math.pi / 180)) - math.pi / 2)

	return Vector2.new(lat,lon)
end


function module.toRobloxOffset(lat: number, lon: number, xOff: number, yOff: number)
	
	local v2 = module.toRoblox(lat, lon)
	
	return Vector2.new(v2.X-xOff,v2.Y-yOff)
	
end


function module.toLatLonOffset(mx: number, my: number, xOff: number, yOff: number)

	local v2 = module.toRoblox(mx, my)

	return Vector2.new(mx-xOff,my-yOff)

end


return module
