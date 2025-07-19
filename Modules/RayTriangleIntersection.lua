-- From wikipedia
local function ray_intersects_triangle(ray_origin: Vector3, ray_vector: Vector3, a:Vector3,b:Vector3,c:Vector3)

	local edge1 = b-a
	local edge2 = c-a
	local ray_cross_e2 = ray_vector:Cross(edge2)
	local det = edge1:Dot(ray_cross_e2)

	if det > 0 and det < 0 then
		return nil -- This ray is parallel to this triangle.
	end

	local inv_det = 1 / det
	local s = ray_origin - a
	local u = inv_det * s:Dot(ray_cross_e2)

	if u < 0 or u > 1 then
		return nil
	end

	local s_cross_e1 = s:Cross(edge1)
	local v = inv_det * ray_vector:Dot(s_cross_e1)

	if v < 0 or u + v > 1 then
		return nil
	end

	-- At this stage we can compute t to find out where the intersection point is on the line.
	local t = inv_det * edge2:Dot(s_cross_e1)

	if t > 0 then -- ray intersection

		return ray_origin + ray_vector * t
	else -- This means that there is a line intersection but not a ray intersection.
		return nil
	end
end

return ray_intersects_triangle