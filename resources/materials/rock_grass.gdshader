// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1);
uniform vec4 albedo_top : source_color = vec4(1);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform sampler2D texture_mesh_normal : hint_normal, filter_linear_mipmap;

uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;

uniform sampler2D texture_ambient_occlusion : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 ao_texture_channel;
uniform float ao_light_affect : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_detail_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_detail_mask : hint_default_white, filter_linear_mipmap, repeat_enable;
varying vec3 uv1_triplanar_pos;
varying vec3 uv2_triplanar_pos;

uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv1_power_normal;
uniform float uv2_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv2_power_normal;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform bool enable_top = true;
uniform sampler2D texture_albedo_top : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_metallic_top : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_roughness_top : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normal_top : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_ambient_occlusion_top : hint_default_white, filter_linear_mipmap, repeat_enable;

void vertex() {
	if (!IN_SHADOW_PASS) {
		vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;

		TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
		TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
		TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
		TANGENT = inverse(MODEL_NORMAL_MATRIX) * normalize(TANGENT);

		BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
		BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
		BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
		BINORMAL = inverse(MODEL_NORMAL_MATRIX) * normalize(BINORMAL);

		// UV1 Triplanar: Enabled (with World Triplanar)
		uv1_power_normal = pow(abs(normal), vec3(uv1_blend_sharpness));
		if (enable_top)
			uv1_power_normal.y *= sign(normal.y);
		else
			uv1_power_normal.y = -uv1_power_normal.y;
		uv1_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv1_scale + uv1_offset;
		uv1_power_normal /= dot(abs(uv1_power_normal), vec3(1.0));
		uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);

		// UV2 Triplanar: Enabled (with World Triplanar)
		uv2_power_normal = pow(abs(mat3(MODEL_MATRIX) * NORMAL), vec3(uv2_blend_sharpness));
		uv2_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv2_scale + uv2_offset;
		uv2_power_normal /= dot(uv2_power_normal, vec3(1.0));
		uv2_triplanar_pos *= vec3(1.0, -1.0, 1.0);
	}
}

vec4 triplanar_texture(sampler2D p_sampler, sampler2D p_sampler_top, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	if (p_weights.y < 0.0)
		samp += texture(p_sampler, p_triplanar_pos.xz) * abs(p_weights.y);
	else
		samp += texture(p_sampler_top, p_triplanar_pos.xz) * abs(p_weights.y);
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	//samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	//samp += texture(p_weights.y < 0.0 ? p_sampler : p_sampler_top, p_triplanar_pos.xz) * abs(p_weights.y);
	//samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp / dot(abs(p_weights), vec3(1));
}

vec3 nmap_to_normal(vec2 n) // output z is inverted
{
	n = n * 2.0 - 1.0;
	float n_z_squared = 1.0 - dot(n.xy, n.xy);
	return vec3(n, inversesqrt(n_z_squared));
}

vec3 triplanar_normal(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec3 samp = vec3(0.0);
	vec3 n_map_z = nmap_to_normal(texture(p_sampler, p_triplanar_pos.xy).xy);
	vec3 n_map_y = nmap_to_normal(texture(p_sampler, p_triplanar_pos.xz).xy);
	vec3 n_map_x = nmap_to_normal(texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)).xy);
	float weight_sum = dot(abs(p_weights), vec3(1));
	return normalize(vec3(
		(n_map_z.xy * n_map_z.z * p_weights.z
		+ n_map_y.xy * n_map_y.z * abs(p_weights.y)
		+ n_map_x.xy * n_map_x.z * p_weights.x) / weight_sum, 1));
}

void fragment() {
if (!IN_SHADOW_PASS) {
	vec3 mesh_normal = texture(texture_mesh_normal, UV).xyz * 2.0 - 1.0;
	float tangent_comp = sqrt(dot(mesh_normal.xy, mesh_normal.xy));
	float cavity = smoothstep(0.1, 1.0, tangent_comp);
	
	vec3 p_weights = uv1_power_normal / dot(abs(uv1_power_normal), vec3(1));
	vec4 albedo_tex = triplanar_texture(texture_albedo, texture_albedo_top, p_weights, uv1_triplanar_pos);
	vec4 modulate = mix(albedo, albedo_top, max(0.0, p_weights.y));
	ALBEDO = modulate.rgb * mix(albedo_tex.rgb, vec3(1), cavity * 0.35);
	float metallic_tex = dot(triplanar_texture(texture_metallic, texture_metallic_top, p_weights, uv1_triplanar_pos), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(triplanar_texture(texture_roughness, texture_roughness_top, p_weights, uv1_triplanar_pos), roughness_texture_channel);
	ROUGHNESS = mix(roughness_tex, 1.0, roughness);

	// Normal Map: Enabled
	// UBN blending: float3 r = normalize(float3(n1.xy + n2.xy, n1.z)); // (n1=base, n2=details), [-1;1]^3
	vec3 trinormal = triplanar_normal(texture_normal, p_weights, uv1_triplanar_pos).xyz;
	NORMAL_MAP = normalize(vec3(trinormal.xy + mesh_normal.xy, trinormal.z)) * .5 + .5;
	NORMAL_MAP_DEPTH = normal_scale;

	// Ambient Occlusion: Enabled
	AO = dot(triplanar_texture(texture_ambient_occlusion, texture_ambient_occlusion_top, p_weights, uv1_triplanar_pos), ao_texture_channel);
	AO_LIGHT_AFFECT = ao_light_affect;

	// Detail: Enabled
	//vec4 detail_tex = triplanar_texture(texture_detail_albedo, texture_detail_albedo, uv2_power_normal, uv2_triplanar_pos);
	//vec4 detail_norm_tex = triplanar_texture(texture_detail_normal, texture_detail_normal, uv2_power_normal, uv2_triplanar_pos);
	//vec4 detail_mask_tex = triplanar_texture(texture_detail_mask, texture_detail_mask, p_weights, uv1_triplanar_pos);

	// Detail Blend Mode: Mix
	//vec3 detail = mix(ALBEDO.rgb, detail_tex.rgb, detail_tex.a);
	//vec3 detail_norm = mix(NORMAL_MAP, detail_norm_tex.rgb, detail_tex.a);
	//NORMAL_MAP = mix(NORMAL_MAP, detail_norm, detail_mask_tex.r);
	//ALBEDO.rgb = mix(ALBEDO.rgb, detail, detail_mask_tex.r);
}
}
