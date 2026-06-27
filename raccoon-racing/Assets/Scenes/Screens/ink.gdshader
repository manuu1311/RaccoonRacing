shader_type canvas_item;

uniform vec3 color:source_color=vec3(1.0);

void fragment() {
	vec4 tex=texture(TEXTURE,UV);
	COLOR=vec4(color.rgb,tex.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
