shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.03;

void vertex() {
	// 沿法线方向扩展顶点以创建描边
	vec4 world_position = MODEL_MATRIX * vec4(VERTEX, 1.0);
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// 向外扩展
	world_position.xyz += world_normal * outline_width;
	
	// 转换到屏幕空间
	VERTEX = (inverse(MODEL_MATRIX) * world_position).xyz;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
} 