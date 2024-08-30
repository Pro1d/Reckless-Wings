shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx, world_vertex_coords;

const float inv_scale = 5.0;
varying vec3 world_vertex;
varying vec3 world_normal;

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c) {
	float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}

void vertex() {
	world_vertex = VERTEX;//(MODEL_MATRIX * vec4(VERTEX, 1)).xyz;
	world_normal = NORMAL;//(MODEL_MATRIX * vec4(NORMAL, 0)).xyz;
	VERTEX = VERTEX + random3(VERTEX) * 0.07;
}

void fragment() {
	vec3 c;
	{
		vec3 offset = abs(fract(world_vertex * inv_scale + .5) - .5);
		vec3 x = step(offset, vec3(0.02));
		vec3 n = step(abs(normalize(world_normal)), vec3(0.96));
		c = n * x;
	}
	{
		vec3 offset = abs(fract(world_vertex * (inv_scale * 0.1) + .5) - .5);
		vec3 x = step(offset, vec3(0.02));
		vec3 n = step(abs(normalize(world_normal)), vec3(0.96));
		c = max(n * x, c);
	}
	c.g *= 0.7;
	ALBEDO = (dot(c, vec3(1)) < 0.001 ? vec3(1) : c);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
