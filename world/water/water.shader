shader_type canvas_item;

const float PI = 3.141592653589793238;

uniform vec4 tint : hint_color;
uniform float fog_scale = 4;
uniform float fog_blur = 0.0;
uniform float water_foam_thickness = 0.15;
uniform vec2 body_scale = vec2(4.0, 4.0);
uniform float time_scale = 0.1;
uniform sampler2D fbm_noise;

float gaussian(float x, float mean, float std_dev) {
	return exp(-0.5 * pow((x-mean)/std_dev, 2.0))/(std_dev*sqrt(2.0*PI));
}
float linramp(float x, float margin, float falloff) {
	if(x<margin) {
		return mix(1.0-falloff, 1.0, x/margin);
	} else if(x>1.0-margin) {
		return mix(1.0, 1.0-falloff, (x-(1.0-margin))/margin);
	} else {
		return 1.0;
	}
}

void fragment() {
	//generate ripples for water effect
	vec2 scaled_coord_1 = UV * body_scale.x;
	vec2 scaled_coord_2 = UV * body_scale.y + 4.0;
	vec2 motion_1 = vec2(TIME * 0.3, TIME * -0.4)*time_scale;
	vec2 motion_2 = vec2(TIME * 0.1, TIME * -0.5)*time_scale;
	float n1 = texture(fbm_noise, scaled_coord_1 + motion_1).r;
	float n2 = texture(fbm_noise, scaled_coord_2 + motion_1).r;
	float n3 = texture(fbm_noise, scaled_coord_1 + motion_2).r;
	float n4 = texture(fbm_noise, scaled_coord_2 + motion_2).r;
	vec2 distort_1 = vec2(n1, n2) - vec2(0.5);
	vec2 distort_2 = vec2(n3, n4) - vec2(0.5);
	vec2 distort_sum = (distort_1 + distort_2)/75.0;
	//generate fog
	vec2 fbm_scaled_coord = UV * fog_scale / body_scale;
	float fbm_scaled_time = TIME * time_scale*0.1;
	float fbm_noise_sample = texture(fbm_noise, fbm_scaled_coord + vec2(-0.2*fbm_scaled_time, fbm_scaled_time)).r;
	float fbm_final = texture(fbm_noise, fbm_scaled_coord + vec2(fbm_noise_sample)).r;
	//mix distortion with screen texture
	vec2 corrected_distortion = distort_sum * vec2(linramp(UV.x, 0.1, 1.0), linramp(UV.y, 0.1, 1.0));
	vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV + corrected_distortion, fog_blur);
	color.rgb = mix(color.rgb*fbm_final, tint.rgb, tint.a);
	//prevent entities from getting too blurry
	color.a = 1.0;
	//increase contrast
	color.rgb = mix(vec3(0.5), color.rgb, 1.4);
	
	//add ripple effect at top
	float rev_y_UV = 1.0 - UV.y;
	float near_top = (rev_y_UV + distort_sum.y) / (water_foam_thickness);
	near_top = 1.0 - clamp(near_top, 0.0, 1.0);
	color = mix(color, vec4(tint.rgb, 0.5), near_top);
	//cut off ripple abruptly
	float edge_lower = 0.8;
	float edge_upper = edge_lower + 0.1;
	if(near_top > edge_lower) {
		color.a = 0.0;
	}
	
	//COLOR = color;
	COLOR = color;
}