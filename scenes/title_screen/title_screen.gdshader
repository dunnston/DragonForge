shader_type canvas_item;

uniform float shimmer_speed : hint_range(0.1, 5.0) = 0.6;
uniform float shimmer_width : hint_range(0.01, 1.0) = 0.25;
uniform vec4 shimmer_color : source_color = vec4(0.2, 1.0, 0.3, 0.5);
uniform float shimmer_strength : hint_range(0.0, 2.0) = 0.6;
uniform float pulse_speed : hint_range(0.1, 10.0) = 1.0;

void fragment() {
    vec4 base = texture(TEXTURE, UV);

    // Move shimmer diagonally (↘ direction)
    float shimmer_pattern = fract(UV.x + UV.y + TIME * shimmer_speed);
    float shimmer_band = smoothstep(0.5 - shimmer_width, 0.5 + shimmer_width, shimmer_pattern);

    // Add a soft pulsing effect
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
    float intensity = shimmer_band * pulse * shimmer_strength;

    // Blend shimmer color with base texture
    vec3 final_color = mix(base.rgb, shimmer_color.rgb, intensity * shimmer_color.a);

    COLOR = vec4(final_color, base.a);
}
