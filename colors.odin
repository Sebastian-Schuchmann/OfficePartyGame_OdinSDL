package main

Color :: struct {
    r : u8,
    g : u8,
    b : u8,
    a : u8,
}

// Colors
COLOR_BLACK := Color{ 0, 0, 0, 255 }
COLOR_WHITE := Color{ 255, 255, 255, 255 }
COLOR_RED := Color{ 255, 0, 0, 255 }
COLOR_GREEN := Color{ 0, 255, 0, 255 }
COLOR_BLUE := Color{ 0, 0, 255, 255 }

// Aliases

/*
[{"name":"Vivid Royal","hex":"471ca8","rgb":[71,28,168],"cmyk":[58,83,0,34],"hsb":[258,83,66],"hsl":[258,71,38],"lab":[27,53,-66]},{"name":"Deep Lilac","hex":"884ab2","rgb":[136,74,178],"cmyk":[24,58,0,30],"hsb":[276,58,70],"hsl":[276,41,49],"lab":[43,45,-45]},{"name":"Deep Saffron","hex":"ff930a","rgb":[255,147,10],"cmyk":[0,42,96,0],"hsb":[34,96,100],"hsl":[34,100,52],"lab":[71,33,75]},{"name":"Molten Orange","hex":"f24b04","rgb":[242,75,4],"cmyk":[0,69,98,5],"hsb":[18,98,95],"hsl":[18,97,48],"lab":[56,62,66]},{"name":"Rosewood","hex":"d1105a","rgb":[209,16,90],"cmyk":[0,92,57,18],"hsb":[337,92,82],"hsl":[337,86,44],"lab":[45,70,12]}]
*/

COLOR_VIVID_ROYAL := Color{ 71, 28, 168, 255 }
COLOR_DEEP_LILAC := Color{ 136, 74, 178, 255 }
COLOR_DEEP_SAFFRON := Color{ 255, 147, 10, 255 }
COLOR_MOLTEN_ORANGE := Color{ 242, 75, 4, 255 }
COLOR_ROSEWOOD := Color{ 209, 16, 90, 255 }
