shader_type canvas_item;

// The mask texture where:
// Red channel = Head region
// Green channel = Body region
// Blue channel = Tail region
uniform sampler2D mask_texture : filter_nearest;

// Colors for each dragon part
uniform vec4 head_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 body_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 tail_color : source_color = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
	// Sample the base texture (grayscale dragon with shading)
	vec4 base = texture(TEXTURE, UV);

	// Sample the mask texture to determine which region this pixel belongs to
	vec4 mask = texture(mask_texture, UV);

	// Start with transparent
	vec4 final_color = vec4(0.0, 0.0, 0.0, 0.0);

	// Use mask channels to determine which color to apply
	// Red channel = head, Green = body, Blue = tail
	float head_intensity = mask.r;
	float body_intensity = mask.g;
	float tail_intensity = mask.b;

	// Apply colors based on mask intensity
	final_color.rgb += head_color.rgb * head_intensity;
	final_color.rgb += body_color.rgb * body_intensity;
	final_color.rgb += tail_color.rgb * tail_intensity;

	// Multiply by the base texture to preserve shading and detail
	// This keeps the darker and lighter areas from the original grayscale
	final_color.rgb *= base.rgb;

	// Use the base texture's alpha for transparency
	final_color.a = base.a;

	COLOR = final_color;
}
