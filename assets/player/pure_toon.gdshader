shader_type spatial;
render_mode unshaded;

uniform vec4 light_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.6, 0.6, 0.7, 1.0);
uniform float split_point : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	// 计算简单的朝向光照
	vec3 light_direction = normalize(vec3(1.0, 1.0, 1.0));
	float NdotL = dot(NORMAL, light_direction);
	
	// 将范围从-1到1映射到0到1
	float light_value = (NdotL + 1.0) * 0.5;
	
	// 使用floor和ceil函数强制量化为0或1
	float quantized = floor(light_value + (1.0 - split_point));
	quantized = clamp(quantized, 0.0, 1.0);
	
	// 完全避免任何插值，直接选择颜色
	ALBEDO = quantized * light_color.rgb + (1.0 - quantized) * shadow_color.rgb;
} 