shader_type canvas_item;

const float PI = 3.141592653589793238;
const float EPS = 0.0000001;

uniform vec2 rain_speed = vec2(0.613, -16.0);
//use prime numbers
uniform vec2 rain_layer_1_scale = vec2(53.0, 41.0);
uniform vec2 rain_layer_2_scale = vec2(59.0, 43.0);
uniform sampler2D rain_tex;
uniform sampler2D noise;
uniform vec4 tint_color: hint_color;
uniform float fog_effect = 0.5;

float gaussian(float x, float mean, float std_dev) {
	return exp(-0.5 * pow((x-mean)/std_dev, 2.0))/(std_dev*sqrt(2.0*PI));
}

void fragment() {
	//calculate time and moving noise samples
	vec2 time_vec_y = rain_speed*TIME;
	vec2 time_vec = vec2(0.371, 0.793)*TIME;
	vec4 tex_noise = texture(noise, (UV+time_vec)*0.25);
	vec4 tex_noise_2 = texture(noise, (UV+time_vec)*0.15);
	//calcuate uvs for two layers of rain
	vec2 flipped_uv = vec2(UV.x, -UV.y);
	vec2 scaled_uv = rain_layer_1_scale*flipped_uv;
	vec2 scaled_uv_2 = rain_layer_2_scale*flipped_uv;
	//calculate moving uvs affected by noise
	vec2 moving_uv = scaled_uv + vec2(9.716*rain_speed.x*tex_noise.r, 1.116*rain_speed.y*tex_noise.r)+time_vec_y*1.17;
	vec2 moving_uv_2 = scaled_uv_2 + vec2(8.716*rain_speed.x*tex_noise_2.r, 1.116*rain_speed.y*tex_noise_2.r)+time_vec_y;
	
	//get rain drop textures corresponding to moving UV samples
	vec4 tex_color = texture(rain_tex, moving_uv);
	vec4 tex_color_2 = texture(rain_tex, moving_uv_2);
	//get blurred screen texture
	vec4 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, fog_effect);
	
	//measures distance from center on x axis
	float fade_top = 0.15;
	float central_measure = clamp(pow(gaussian(UV.x, 0.45, 0.45)+0.25, 3.8), 0.0, 1.0);
	if(1.0-UV.y < fade_top) {
		central_measure = mix(0.0, central_measure, (1.0-UV.y)/fade_top)
	}
	//use two noise samples to calculate where fog volumes should exist
	float adj_noise = max(tex_noise.r, tex_noise_2.r)+0.4;
	adj_noise = clamp(pow(adj_noise-0.1, 2.0), 0.0, 1.0);
	float final_fog_fade = adj_noise*central_measure;
	//calculate drop number (so we can mod later)
	float rain_drop_num_1 = floor(-moving_uv.y)*rain_layer_1_scale.x+floor(moving_uv.x+tex_color_2.r);
	float rain_drop_num_2 = floor(-moving_uv_2.y)*rain_layer_2_scale.x+floor(moving_uv_2.x+tex_color_2.r);
	//determine which drop numbers we will render (use prime numbers)
	bool render_drop_1 = fract(rain_drop_num_1/3.0)<EPS || fract(rain_drop_num_1/7.0)<EPS;
	bool render_drop_2 = fract(rain_drop_num_2/5.0)<EPS || fract(rain_drop_num_2/11.0)<EPS;
	//default to screen_color
	vec4 final_color = screen_color;
	//don't use else so you can render drops on top of each other
	if(render_drop_2 && tex_color_2.a>0.8) {
		final_color = mix(final_color, tex_color_2, tex_color_2.a);
	}
	if(render_drop_1 && tex_color.a>0.8) {
		final_color = mix(final_color, tex_color, tex_color.a);
	}
	//final_color.rgb is blurred - blend this with tint_color using tint alpha so we preserve blurred appearance in fog
	vec3 blurred_tint = mix(final_color.rgb, tint_color.rgb, tint_color.a);
	//blend the blurred_tint according to where our fog volumes are
	final_color.rgb = mix(final_color.rgb, blurred_tint, final_fog_fade);
	//apply alpha corresponding to location of fog volumes
	//alpha = 0.0 means no fog and no blur
	final_color.a = final_fog_fade;
	COLOR = final_color;
}