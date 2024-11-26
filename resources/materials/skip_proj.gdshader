shader_type spatial;
render_mode unshaded, depth_draw_never;
uniform sampler2D depth_tex : hint_depth_texture;
void vertex() {
	POSITION = vec4(VERTEX.x, -VERTEX.y, 1.0, 1.0);
	UV = VERTEX.xy + 1.0;
}

void fragment() {
	ALBEDO = fract(texture(depth_tex, SCREEN_UV).rgb * 10.0); //vec3(fract(SCREEN_UV), texture(depth_tex, SCREEN_UV).x);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
