shader_type canvas_item;

uniform vec4 color : hint_color;
uniform float min_opacity = 0.0;
uniform float uv_scale = 4.0;
uniform float time_scale = 0.1;
uniform int fbm_octaves = 4;
uniform float fbm_scale = 0.65;

float rand(vec2 coord) {
	//pseudorandom float for each coord
	return fract(sin(dot(coord, vec2(57, 73)) * 1000.0) * 1000.0);	
}

float noise(vec2 coord) {
	vec2 i = floor(coord);
	vec2 f = fract(coord);
	
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));
	
	//cubic interpolation
	vec2 cubic = f * f * (3.0 - 2.0 * f);
	return mix(a, b, cubic.x) + (c-a)*cubic.y*(1.0-cubic.x) + (d-b)*cubic.x*cubic.y;
}

float fbm(vec2 coord) {
	float value = 0.0;
	float scale = fbm_scale;
	
	for(int i = 0; i < fbm_octaves; i++) {
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	
	return value;
}

void fragment() {
	vec2 scaled_coord = UV * uv_scale;
	float scaled_time = TIME * time_scale;
	vec2 motion = vec2(fbm(scaled_coord + vec2(-0.2*scaled_time, scaled_time)));
	float final = fbm(scaled_coord * motion);
	COLOR = vec4(color.rgb, max(final*color.a, min_opacity));
}