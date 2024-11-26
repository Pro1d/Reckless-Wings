shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE:hint_screen_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE :source_color, hint_depth_texture;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;

uniform float zNear = 2;
uniform float zFar = 10.0;

uniform float width = 1.0;
uniform bool addDepth = false;

vec3 overlay(vec3 base, vec3 blend) {
    return mix(2.0 * base * blend,
		1.0 - 2.0 * (1.0 - base) * (1.0 - blend), clamp(base, 0.0, 1.0));
}

float textureCavity(sampler2D normal_texture, vec2 uv, vec2 screen_pixel_size){
	vec4 normal = texture(normal_texture, uv);
	float r_off = texture(normal_texture, uv - vec2(screen_pixel_size.x*width, 0)).r;
	float g_off = texture(normal_texture, uv + vec2(0, screen_pixel_size.y*width)).g;
	return (normal.r - r_off) + (normal.g - g_off) + 0.5;
}

float scaledDepth(sampler2D depth_texture, vec2 uv, mat4 inv_proj_mat){
	float depth = texture(depth_texture, uv).x;
	vec3 ndc = vec3(uv, depth) * 2.0 - 1.0;
	vec4 view = inv_proj_mat * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = view.z;
	return (zFar * zNear) / (zFar + (linear_depth * (zNear - zFar)));
}

void fragment() {
	vec4 origin = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec2 SCREEN_PIXEL_SIZE = 1.0 / VIEWPORT_SIZE;

	float res = textureCavity(NORMAL_TEXTURE, SCREEN_UV, SCREEN_PIXEL_SIZE);
	float scaled_depth = scaledDepth(DEPTH_TEXTURE, SCREEN_UV, INV_PROJECTION_MATRIX);

	if (addDepth) {
		ALBEDO = overlay(overlay(origin.rgb, vec3(res)), vec3(scaled_depth));
	} else {
		ALBEDO = overlay(origin.rgb, vec3(res));
		//ALBEDO = vec3(scaled_depth);
	}
}