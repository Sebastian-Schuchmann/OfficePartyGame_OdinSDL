package game

import engine "../engine"

// Fixed-size material pool — avoids GC pressure.
// All Materials are allocated here; Ding.material points into this array.
// Fat struct: all shader properties live in Material regardless of shader used.
MAX_MATERIALS :: 64
materials: [MAX_MATERIALS]engine.Material
material_count: int

alloc_material :: proc() -> ^engine.Material {
	assert(material_count < MAX_MATERIALS, "material pool exhausted")
	m := &materials[material_count]
	material_count += 1
	return m
}

mat_red: ^engine.Material
mat_green: ^engine.Material
mat_blue: ^engine.Material

init_materials :: proc() {
	mat_red = alloc_material()
	mat_red^ = engine.Material{shader = .UNLIT, color = {1, 0.2, 0.2, 1}}

	mat_green = alloc_material()
	mat_green^ = engine.Material{shader = .UNLIT, color = {0.2, 1, 0.2, 1}}

	mat_blue = alloc_material()
	mat_blue^ = engine.Material{shader = .UNLIT, color = {0.2, 0.4, 1, 1}}
}
