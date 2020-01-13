shader_type canvas_item;

uniform vec4 tint : hint_color;
uniform float uv_scale = 4.0;
uniform float time_scale = 0.1;
uniform float brightness = 1.1;
uniform int fbm_octaves = 4;
uniform float fbm_scale = 0.65;

float rand(vec2 coord) {
	//pseudorandom float for each coord
	return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5412326);	
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
	//generate ripples for water effect
	vec2 scaled_coord_1 = UV * uv_scale;
	vec2 scaled_coord_2 = UV * uv_scale + 4.0;
	vec2 motion_1 = vec2(TIME * 0.3, TIME * -0.4)*time_scale;
	vec2 motion_2 = vec2(TIME * 0.1, TIME * -0.5)*time_scale;
	vec2 distort_1 = vec2(noise(scaled_coord_1 + motion_1), noise(scaled_coord_2 + motion_1)) - vec2(0.5);
	vec2 distort_2 = vec2(noise(scaled_coord_1 + motion_2), noise(scaled_coord_2 + motion_2)) - vec2(0.5);
	vec2 distort_sum = (distort_1 + distort_2) / 60.0;
	//generate fog
	vec2 fbm_scaled_coord = UV * uv_scale;
	float fbm_scaled_time = TIME * time_scale*0.1;
	vec2 fbm_motion = vec2(fbm(fbm_scaled_coord + vec2(-0.2*fbm_scaled_time, fbm_scaled_time)));
	float fbm_final = fbm(fbm_scaled_coord * fbm_motion);
	//mix distortion with screen texture
	vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV + distort_sum, 0.0);
	color = mix(color*fbm_final, tint, 0.3);
	//prevent entities from getting too blurry
	color.a = 1.0;
	//increase contrast
	color.rgb = mix(vec3(0.5), color.rgb, 1.4);
	//increase brightness
	color.rgb *= brightness;
	
	//add ripple effect at top
	float near_top = (UV.y + distort_sum.y) / (0.12 / uv_scale);
	near_top = 1.0 - clamp(near_top, 0.0, 1.0);
	color = mix(color, vec4(tint.rgb, 0.5), near_top);
	//cut off ripple abruptly
	float edge_lower = 0.8;
	float edge_upper = edge_lower + 0.1;
	if(near_top > edge_lower) {
		color.a = 0.0;
	}
	
	COLOR = color;
}