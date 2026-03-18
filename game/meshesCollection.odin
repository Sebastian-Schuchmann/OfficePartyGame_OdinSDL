package game

import engine "../engine"

tri_mesh: engine.GpuMesh

init_meshes :: proc() {
	tri_verts := []engine.Vertex {
		{pos = {0, 1, 0}, normal = {0, 0, 1}},
		{pos = {-1, -1, 0}, normal = {0, 0, 1}},
		{pos = {1, -1, 0}, normal = {0, 0, 1}},
	}
	tri_mesh = engine.gpu_create_mesh(tri_verts, []u16{0, 1, 2})
}
