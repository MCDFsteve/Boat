shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform float light_threshold : hint_range(0.0, 1.0) = 0.5;
uniform vec4 light_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.3, 0.3, 0.5, 1.0);
uniform sampler2D texture_albedo : source_color, hint_default_white;

void fragment() {
	// 获取基础纹理
	vec4 albedo_tex = texture(texture_albedo, UV);
	
	// 计算简单的光照
	vec3 light_dir = normalize(vec3(1.0, 1.0, 1.0));
	float NdotL = dot(NORMAL, light_dir);
	
	// 将光照值映射到0-1范围
	float light_intensity = NdotL * 0.5 + 0.5;
	
	// 使用step函数创建硬边界
	float toon_factor = step(light_threshold, light_intensity);
	
	// 混合明暗颜色
	vec3 final_color = mix(shadow_color.rgb, light_color.rgb, toon_factor);
	
	// 应用到材质
	ALBEDO = final_color * albedo_tex.rgb;
	ALPHA = albedo_tex.a;
} 