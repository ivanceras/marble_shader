// variant of Vorocracks: https://shadertoy.com/view/lsVyRy
// integrated with cracks here: https://www.shadertoy.com/view/Xd3fRN
#import bevy_pbr::{
    forward_io::{VertexOutput, FragmentOutput},
}



fn hash22(p: vec2<f32>) -> vec2<f32> {
    let m = mat2x2(127.1, 311.7, 269.5, 183.3);
    return fract(18.5453 * sin(m * p));
}
fn disp(p: vec2<f32>) -> vec2<f32>{
    let offset = 0.5;
    return -offset + (1.0 + 2.0 * offset) * hash22(p);
}


fn voronoiB(u: vec2<f32> ) -> f32 {
    let iu: vec2<f32> = floor(u);
    var C: vec2<f32>;
    var P: vec2<f32>;
	var m: f32 = 1e9;
    var d: f32;
    for(var k=0; k < 25; k++) {
        let p = iu + vec2(f32(k % 5 - 2), f32(k / 5 - 2));
        let o = disp(p);
      	let r = p - u + o;
		d = dot(r, r);
        if d < m {
            m = d;
            C = p - iu;
            P = r;
        }
    }

    m = 1e9;

    for(var k = 0; k < 25; k++) {
        let p = iu + C + vec2(f32(k % 5 - 2), f32(k / 5 - 2));
		let o = disp(p);
        let r = p - u + o;

        if dot(P - r, P - r) > 1e-5{
            m = min(m,  dot((P + r), normalize(r - P)) *  0.5);
        }
    }
    return m;
}

// glsl style
fn rot1(a: f32) -> mat2x2<f32> {
    let c = cos(a);
    let s = sin(a);
    return mat2x2(c, -s, s, c);
}
// wgsl style
fn rot(a: f32) -> mat2x2<f32>{
    let c = cos(a);
    let s = sin(a);
    return mat2x2(c, s, -s, c);
}

fn hash21(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

fn noise2(p: vec2<f32>) -> f32 {
    let i: vec2<f32> = floor(p);
    var f: vec2<f32> = fract(p);
    f = f * f * (3.0 - 2.0 * f); // smoothstep

    let a = hash21(i + vec2(0.0, 0.0));
    let b = hash21(i + vec2(1.0, 0.0));
    let c = hash21(i + vec2(0.0, 1.0));
    let d = hash21(i + vec2(1.0, 1.0));

    let v:f32 = mix( mix(a, b, f.x), mix(c, d, f.x), f.y);
	return  2.0 * v - 1.0;
}

fn noise22(p: vec2<f32>) -> vec2<f32> {
    return vec2(noise2(p), noise2(p + 17.7));
}

fn fbm22(p1: vec2<f32>) -> vec2<f32> {
    var p = p1;
    var v = vec2<f32>(0.0);
    var a = 0.5;
    let R = rot(0.37);

    for (var i = 0; i < 6; i++) {
        p = R * p;
        v += noise22(p) * a;
        p *= 2.;
        a /= 2.;
    }
    return v;
}



fn calc_color(uv1: vec2<f32> ) -> vec4<f32> {
    var uv = uv1;
    let resolution_y = 10.0;
    uv *= 4.0 / resolution_y;
    let interval: vec2<f32> = floor(uv / 2.0);
    let is_alt: bool = i32(interval.x + interval.y) % 2 == 0;
    var color:vec4<f32> = vec4(0.0);
    let crack_slope = 50.0;
    let fractal_scale = 1.5;

    for(var i= 0; i < 3; i++) {
        let D = fbm22(uv);
        var d = voronoiB(uv + D);
        d = min(1.0, crack_slope * max(0.0, d));
        let inv_d = 1.0 - d;
        color += vec4(inv_d, inv_d, inv_d, 1.0) / exp2(f32(i));
        uv = rot(0.37) * (uv * fractal_scale);
    }
    if is_alt{
        color = 1.0 - color;
    }
    return color;
}



@fragment
fn fragment(
    vertex_output: VertexOutput,
    @builtin(front_facing) is_front: bool,
) -> FragmentOutput {
    var in: VertexOutput;
    in.position = vertex_output.position;
    in.world_position = vertex_output.world_position;
    in.world_normal = vertex_output.world_normal;

    var out: FragmentOutput;
    out.color = calc_color(vertex_output.world_position.xy);
    return out;
}
