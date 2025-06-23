shader_type spatial;

uniform float toon_threshold : hint_range(0.0, 1.0) = 0.6;
uniform vec4 bright_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 dark_color : source_color = vec4(0.3, 0.3, 0.4, 1.0);

void fragment() {
	// 计算多个方向的光照
	vec3 light_dir1 = normalize(vec3(1.0, 1.0, 1.0));
	vec3 light_dir2 = normalize(vec3(-0.5, 1.0, 0.5));
	
	// 计算光照强度
	float light1 = max(0.0, dot(NORMAL, light_dir1));
	float light2 = max(0.0, dot(NORMAL, light_dir2)) * 0.5;
	
	// 合并光照
	float total_light = light1 + light2;
	
	// 使用step函数创建完全硬的边界 - 只有0或1两个值
	float toon_factor = step(toon_threshold, total_light);
	
	// 直接选择颜色，不进行混合
	vec3 final_color = toon_factor > 0.5 ? bright_color.rgb : dark_color.rgb;
	
	ALBEDO = final_color;
} 