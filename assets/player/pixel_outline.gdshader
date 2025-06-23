shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.2) = 0.05;
uniform float pixelation_factor : hint_range(1.0, 32.0) = 8.0;

void vertex() {
	// 沿法线方向扩展顶点以创建描边
	vec4 world_position = MODEL_MATRIX * vec4(VERTEX, 1.0);
	vec3 world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// 向外扩展创建描边
	world_position.xyz += world_normal * outline_width;
	
	// 转换回局部空间
	VERTEX = (inverse(MODEL_MATRIX) * world_position).xyz;
}

void fragment() {
	// 获取屏幕坐标
	vec2 screen_uv = SCREEN_UV;
	
	// 像素化效果 - 将UV坐标量化到像素网格
	vec2 pixelated_uv = floor(screen_uv * pixelation_factor) / pixelation_factor;
	
	// 创建像素边界效果
	vec2 pixel_center = (floor(screen_uv * pixelation_factor) + 0.5) / pixelation_factor;
	vec2 pixel_distance = abs(screen_uv - pixel_center);
	float pixel_edge = max(pixel_distance.x, pixel_distance.y) * pixelation_factor;
	
	// 硬边像素效果
	float pixel_mask = step(0.4, pixel_edge);
	
	// 混合原始描边颜色和像素化效果
	vec3 final_color = mix(outline_color.rgb, outline_color.rgb * 0.8, pixel_mask);
	
	ALBEDO = final_color;
	ALPHA = outline_color.a;
} 