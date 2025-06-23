shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;
uniform bool enable_outline = true;

void fragment() {
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec4 original_color = texture(TEXTURE, UV);
	
	// 使用条件逻辑而不是return
	if (!enable_outline || original_color.a > 0.1) {
		// 如果禁用描边或当前像素已有颜色，直接显示原色
		COLOR = original_color;
	} else {
		// 检查周围像素是否有内容来决定是否绘制描边
		bool has_content = false;
		float step_size = outline_width;
		
		// 8方向采样
		vec2 offsets[8] = vec2[](
			vec2(-step_size, -step_size), vec2(0.0, -step_size), vec2(step_size, -step_size),
			vec2(-step_size, 0.0),                                vec2(step_size, 0.0),
			vec2(-step_size, step_size),  vec2(0.0, step_size),  vec2(step_size, step_size)
		);
		
		for (int i = 0; i < 8; i++) {
			vec2 offset_uv = UV + offsets[i] * TEXTURE_PIXEL_SIZE;
			vec4 sample_color = texture(TEXTURE, offset_uv);
			if (sample_color.a > 0.1) {
				has_content = true;
				break;
			}
		}
		
		// 如果周围有内容，绘制描边，否则透明
		if (has_content) {
			COLOR = outline_color;
		} else {
			COLOR = vec4(0.0, 0.0, 0.0, 0.0); // 透明
		}
	}
} 