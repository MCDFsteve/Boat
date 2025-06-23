shader_type spatial;

uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	ALBEDO = color.rgb;
} 