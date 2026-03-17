package engine

import "core:math/rand"

Color :: struct {
	r: u8,
	g: u8,
	b: u8,
	a: u8,
}

// Colors
COLOR_BLACK := Color{0, 0, 0, 255}
COLOR_WHITE := Color{255, 255, 255, 255}
COLOR_RED := Color{255, 0, 0, 255}
COLOR_GREEN := Color{0, 255, 0, 255}
COLOR_BLUE := Color{0, 0, 255, 255}

// Aliases

/*
[{"name":"Vivid Royal","hex":"471ca8","rgb":[71,28,168],"cmyk":[58,83,0,34],"hsb":[258,83,66],"hsl":[258,71,38],"lab":[27,53,-66]},{"name":"Deep Lilac","hex":"884ab2","rgb":[136,74,178],"cmyk":[24,58,0,30],"hsb":[276,58,70],"hsl":[276,41,49],"lab":[43,45,-45]},{"name":"Deep Saffron","hex":"ff930a","rgb":[255,147,10],"cmyk":[0,42,96,0],"hsb":[34,96,100],"hsl":[34,100,52],"lab":[71,33,75]},{"name":"Molten Orange","hex":"f24b04","rgb":[242,75,4],"cmyk":[0,69,98,5],"hsb":[18,98,95],"hsl":[18,97,48],"lab":[56,62,66]},{"name":"Rosewood","hex":"d1105a","rgb":[209,16,90],"cmyk":[0,92,57,18],"hsb":[337,92,82],"hsl":[337,86,44],"lab":[45,70,12]}]
*/

//03045e
COLOR_BACKGROUND := Color{3, 4, 94, 255}
//ffca3a
COLOR_PLAYER := Color{255, 202, 58, 255}


COLOR_VIVID_ROYAL := Color{71, 28, 168, 255}
COLOR_DEEP_LILAC := Color{136, 74, 178, 255}
COLOR_DEEP_SAFFRON := Color{255, 147, 10, 255}
COLOR_MOLTEN_ORANGE := Color{242, 75, 4, 255}
COLOR_ROSEWOOD := Color{209, 16, 90, 255}
COLOR_CRIMSON_VIOLET := Color{95, 15, 64, 255}
COLOR_DEEP_CRIMSON := Color{154, 3, 30, 255}
COLOR_PRINCETON_ORANGE := Color{251, 139, 36, 255}
COLOR_AUTUMN_LEAF := Color{227, 100, 20, 255}
COLOR_DARK_TEAL := Color{15, 76, 92, 255}

/*
--baltic-blue: #22577aff;
--tropical-teal: #38a3a5ff;
--emerald: #57cc99ff;
--light-green: #80ed99ff;
--tea-green: #c7f9ccff;
*/

COLOR_BALTIIC_BLUE := Color{34, 87, 122, 255}
COLOR_TROPICAL_TEAL := Color{56, 163, 165, 255}
COLOR_EMERALD := Color{87, 204, 153, 255}
COLOR_LIGHT_GREEN := Color{128, 237, 153, 255}
COLOR_TEA_GREEN := Color{199, 249, 204, 255}


RANDOM_COLORS := [?]Color{COLOR_TROPICAL_TEAL, COLOR_EMERALD, COLOR_LIGHT_GREEN, COLOR_TEA_GREEN}

random_color :: proc() -> Color {
	return RANDOM_COLORS[rand.int_max(len(RANDOM_COLORS))]
}
