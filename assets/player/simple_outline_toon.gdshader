shader_type spatial;
render_mode unshaded;

uniform vec4 bright_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 dark_color : source_color = vec4(0.65, 0.65, 0.75, 1.0);
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.35;
uniform float outline_strength : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	// 计算基础光照
	vec3 light_dir = normalize(vec3(1.0, 1.0, 1.0));
	float light = dot(NORMAL, light_dir);
	
	// 标准化到0-1范围
	light = (light + 1.0) * 0.5;
	
	// 创建硬边界的卡通效果
	float toon_mask = 0.0;
	if (light >= threshold) {
		toon_mask = 1.0;
	}
	
	// 选择基础颜色
	vec3 color_a = dark_color.rgb;
	vec3 color_b = bright_color.rgb;
	
	vec3 base_color;
	base_color.r = toon_mask * color_b.r + (1.0 - toon_mask) * color_a.r;
	base_color.g = toon_mask * color_b.g + (1.0 - toon_mask) * color_a.g;
	base_color.b = toon_mask * color_b.b + (1.0 - toon_mask) * color_a.b;
	
	// 基于视角和法线的简单描边检测
	vec3 view_dir = normalize(VIEW);
	float rim = 1.0 - abs(dot(view_dir, NORMAL));
	
	// 创建硬边描边效果，不使用smoothstep以获得更明显的边缘
	float outline_mask = step(0.3, rim);
	
	// 直接选择颜色而不是混合，以获得更纯正的描边颜色
	vec3 final_color = outline_mask > 0.5 ? outline_color.rgb : base_color;
	
	ALBEDO = final_color;
} 