package engine

import "core:os"
import "core:strings"
import "core:strconv"
import "core:math/linalg"

// obj_load parses a .obj file and returns a GpuMesh.
// Simple approach: one Vertex emitted per face-corner reference (no deduplication).
// n-gons are fan-triangulated. If the file has no normals, flat normals are
// computed per triangle from the cross product. Supports face formats:
//   v    v/vt    v/vt/vn    v//vn    (all 1-indexed)
// Returns ok=false if the file is missing or cannot be parsed.
// Note: meshes above ~20k triangles will exceed the u16 index limit (65535).
obj_load :: proc(path: string) -> (mesh: GpuMesh, ok: bool) {
	data, file_ok := os.read_entire_file(path)
	if !file_ok do return {}, false
	defer delete(data)

	// Raw OBJ data
	positions: [dynamic][3]f32
	normals:   [dynamic][3]f32
	uvs:       [dynamic][2]f32
	defer delete(positions)
	defer delete(normals)
	defer delete(uvs)

	// Final vertex/index data
	verts:   [dynamic]Vertex
	indices: [dynamic]u16
	defer delete(verts)
	defer delete(indices)

	lines := strings.split_lines(string(data))
	defer delete(lines)

	for line in lines {
		l := strings.trim_space(line)
		if len(l) == 0 || l[0] == '#' do continue

		parts := strings.fields(l)
		defer delete(parts)
		if len(parts) == 0 do continue

		switch parts[0] {
		case "v":
			if len(parts) < 4 do continue
			x, _ := strconv.parse_f32(parts[1])
			y, _ := strconv.parse_f32(parts[2])
			z, _ := strconv.parse_f32(parts[3])
			append(&positions, [3]f32{x, y, z})
		case "vn":
			if len(parts) < 4 do continue
			x, _ := strconv.parse_f32(parts[1])
			y, _ := strconv.parse_f32(parts[2])
			z, _ := strconv.parse_f32(parts[3])
			append(&normals, [3]f32{x, y, z})
		case "vt":
			if len(parts) < 3 do continue
			u, _ := strconv.parse_f32(parts[1])
			v, _ := strconv.parse_f32(parts[2])
			append(&uvs, [2]f32{u, v})
		case "f":
			if len(parts) < 4 do continue
			// Fan-triangulate: anchor at parts[1], emit (0, i, i+1)
			face_verts: [dynamic]Vertex
			defer delete(face_verts)

			for token in parts[1:] {
				v := parse_face_token(token, positions[:], normals[:], uvs[:])
				append(&face_verts, v)
			}

			// Fan triangulation
			for i in 1 ..< len(face_verts) - 1 {
				base := u16(len(verts))
				append(&verts, face_verts[0], face_verts[i], face_verts[i + 1])
				append(&indices, base, base + 1, base + 2)
			}
		}
	}

	if len(verts) == 0 do return {}, false

	// If no normals were in the file, compute flat normals from triangle cross products.
	if len(normals) == 0 {
		for i := 0; i < len(verts); i += 3 {
			a := verts[i].pos
			b := verts[i + 1].pos
			c := verts[i + 2].pos
			ab := [3]f32{b[0] - a[0], b[1] - a[1], b[2] - a[2]}
			ac := [3]f32{c[0] - a[0], c[1] - a[1], c[2] - a[2]}
			n := linalg.normalize(linalg.cross(ab, ac))
			verts[i].normal     = n
			verts[i + 1].normal = n
			verts[i + 2].normal = n
		}
	}

	return gpu_create_mesh(verts[:], indices[:]), true
}

parse_face_token :: proc(token: string, positions: [][3]f32, normals: [][3]f32, uvs: [][2]f32) -> Vertex {
	v: Vertex

	parts := strings.split(token, "/")
	defer delete(parts)

	// Vertex position (required)
	if len(parts) >= 1 && len(parts[0]) > 0 {
		idx, _ := strconv.parse_int(parts[0])
		idx -= 1 // OBJ is 1-indexed
		if idx >= 0 && idx < len(positions) {
			v.pos = positions[idx]
		}
	}

	// UV (optional, second slot)
	if len(parts) >= 2 && len(parts[1]) > 0 {
		idx, _ := strconv.parse_int(parts[1])
		idx -= 1
		if idx >= 0 && idx < len(uvs) {
			v.uv = uvs[idx]
		}
	}

	// Normal (optional, third slot)
	if len(parts) >= 3 && len(parts[2]) > 0 {
		idx, _ := strconv.parse_int(parts[2])
		idx -= 1
		if idx >= 0 && idx < len(normals) {
			v.normal = normals[idx]
		}
	}

	return v
}
