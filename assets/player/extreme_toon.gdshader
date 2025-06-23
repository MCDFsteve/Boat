shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 bright_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 dark_color : source_color = vec4(0.65, 0.65, 0.75, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	// 计算基础光照
	vec3 light_dir = normalize(vec3(1.0, 1.0, 1.0));
	float light = dot(NORMAL, light_dir);
	
	// 标准化到0-1范围
	light = (light + 1.0) * 0.5;
	
	// 创建一个"查找表"效果 - 完全二进制化
	float toon_mask = 0.0;
	if (light >= threshold) {
		toon_mask = 1.0;
	}
	
	// 使用步骤函数确保没有插值
	vec3 color_a = dark_color.rgb;
	vec3 color_b = bright_color.rgb;
	
	// 手动选择颜色，避免任何GPU插值
	ALBEDO.r = toon_mask * color_b.r + (1.0 - toon_mask) * color_a.r;
	ALBEDO.g = toon_mask * color_b.g + (1.0 - toon_mask) * color_a.g;
	ALBEDO.b = toon_mask * color_b.b + (1.0 - toon_mask) * color_a.b;
} 