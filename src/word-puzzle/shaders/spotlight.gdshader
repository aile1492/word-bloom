// spotlight.gdshader
// 스포트라이트 효과: 지정 영역만 밝게 남기고 나머지를 dim 처리한다.
// P02_04 기획서 준수.
shader_type canvas_item;

uniform vec4 dim_color : source_color = vec4(0.0, 0.0, 0.0, 0.7);
uniform vec2 hole_position = vec2(0.5, 0.5);   // UV 비율 (0~1)
uniform vec2 hole_size = vec2(0.3, 0.3);        // UV 비율
uniform float corner_radius : hint_range(0.0, 0.1) = 0.02;

void fragment() {
	// 현재 픽셀이 spotlight hole 안에 있는지 rounded rect SDF로 판단
	vec2 dist = abs(UV - hole_position) - hole_size * 0.5 + corner_radius;
	float d = length(max(dist, 0.0)) - corner_radius;
	// d < 0: hole 내부 → 투명, d >= 0: 외부 → dim
	float mask = smoothstep(-0.002, 0.002, d);
	COLOR = vec4(dim_color.rgb, dim_color.a * mask);
}
