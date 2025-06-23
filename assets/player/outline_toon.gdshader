shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, depth_test_disabled;

uniform vec4 bright_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 dark_color : source_color = vec4(0.65, 0.65, 0.75, 1.0);
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.35;
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;
uniform bool show_outline : bool = true;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = VERTEX;
	world_normal = NORMAL;
	
	// 如果是描边pass，沿法线方向扩展顶点
	if (show_outline) {
		vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
		vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);
		
		vec2 offset = normalize(clip_normal.xy) * outline_width * clip_position.w;
		clip_position.xy += offset;
		
		POSITION = clip_position;
	}
}

void fragment() {
	// 检查是否为描边pass
	if (!FRONT_FACING && show_outline) {
		// 描边颜色
		ALBEDO = outline_color.rgb;
		ALPHA = outline_color.a;
	} else {
		// 正常的卡通着色
		vec3 light_dir = normalize(vec3(1.0, 1.0, 1.0));
		float light = dot(world_normal, light_dir);
		
		// 标准化到0-1范围
		light = (light + 1.0) * 0.5;
		
		// 创建硬边界的卡通效果
		float toon_mask = 0.0;
		if (light >= threshold) {
			toon_mask = 1.0;
		}
		
		// 选择颜色
		vec3 color_a = dark_color.rgb;
		vec3 color_b = bright_color.rgb;
		
		ALBEDO.r = toon_mask * color_b.r + (1.0 - toon_mask) * color_a.r;
		ALBEDO.g = toon_mask * color_b.g + (1.0 - toon_mask) * color_a.g;
		ALBEDO.b = toon_mask * color_b.b + (1.0 - toon_mask) * color_a.b;
		ALPHA = 1.0;
	}
} 