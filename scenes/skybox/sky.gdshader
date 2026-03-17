shader_type sky;

uniform sampler2D source_panorama : filter_linear, source_color, hint_default_black;
uniform float exposure : hint_range(0, 3) = 1.0;
uniform float speed = 0.002;

void sky() {
	vec2 skyCoords = vec2(SKY_COORDS.x + TIME * speed, SKY_COORDS.y);
	COLOR = texture(source_panorama, skyCoords).rgb * exposure;
}
