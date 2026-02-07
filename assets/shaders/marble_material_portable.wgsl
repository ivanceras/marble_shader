// ported to wgsl from https://www.shadertoy.com/view/Xs3fR4
//
// but had an issue with the veins not being smooth
//
// can be run in https://anukritiw.github.io/splitshade/
// by pasting the whole code here

const VARIANT: bool = true;
const OFS: f32 = 0.5;
const RATIO: f32 = 1.0;
const CRACK_DEPTH: f32 = 3.0;
const CRACK_ZEBRA_SCALE: f32 = 1.0;
const CRACK_ZEBRA_AMP: f32 = 0.67;
const CRACK_PROFILE: f32 = 1.0;
const CRACK_SLOPE: f32 = 50.0;
const CRACK_WIDTH: f32 = 0.0;

fn rot(a: f32) -> mat2x2<f32> {
    let s = sin(a);
    let c = cos(a);
    return mat2x2<f32>(c, s, -s, c);
}

fn hash22(p: vec2<f32>) -> vec2<f32> {
    let m = mat2x2<f32>(127.1, 269.5, 311.7, 183.3);
    return fract(18.5453 * sin(p * m));
}

fn disp(p: vec2<f32>) -> vec2<f32> {
    return -OFS + (1.0 + 2.0 * OFS) * hash22(p);
}

fn voronoiB(u: vec2<f32>) -> vec3<f32> {
    let iu = floor(u);
    var m = 1e9;
    var C: vec2<f32>;
    var P: vec2<f32>;

    // First pass
    for (var y = -2; y <= 2; y++) {
        for (var x = -2; x <= 2; x++) {
            let p = iu + vec2<f32>(f32(x), f32(y));
            let o = disp(p);
            let r = p - u + o;
            let d = dot(r, r);
            if (d < m) {
                m = d;
                C = p - iu;
                P = r;
            }
        }
    }

    m = 1e9;
    // Second pass for border distance
    for (var y = -2; y <= 2; y++) {
        for (var x = -2; x <= 2; x++) {
            let p = iu + C + vec2<f32>(f32(x), f32(y));
            let o = disp(p);
            let r = p - u + o;
            if (dot(P - r, P - r) > 1e-5) {
                m = min(m, 0.5 * dot((P + r), normalize(r - P)));
            }
        }
    }
    return vec3<f32>(m, P + u);
}

fn hash21(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(127.1, 311.7))) * 43758.5453123);
}

fn noise2(p: vec2<f32>) -> f32 {
    let i = floor(p);
    var f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    let v = mix(
        mix(hash21(i + vec2<f32>(0.0, 0.0)), hash21(i + vec2<f32>(1.0, 0.0)), f.x),
        mix(hash21(i + vec2<f32>(0.0, 1.0)), hash21(i + vec2<f32>(1.0, 1.0)), f.x),
        f.y
    );
    return 2.0 * v - 1.0;
}

fn fbm22(p_in: vec2<f32>) -> vec2<f32> {
    var p = p_in;
    var v = vec2<f32>(0.0);
    var a = 0.5;
    let R = rot(0.37);
    for (var i = 0; i < 6; i++) {
        p = p * R;
        v += a * vec2<f32>(noise2(p), noise2(p + 17.7));
        p *= 2.0;
        a /= 2.0;
    }
    return v;
}

@fragment
fn fragment(@builtin(position) fragCoord: vec4<f32>) -> @location(0) vec4<f32> {

    let iResolution = vec2(1920.0, 1080.0);
    let iTime = 0.0;

    var U = fragCoord.xy * 4.0 / iResolution.y;
    U.x += iTime;

    let I = floor(U / 2.0);
    let vert = (u32(I.x + I.y) % 2u) == 0u;
    var O = vec4<f32>(0.0);
    let R_mat = rot(0.37);

    for (var i: f32 = 0.0; i < CRACK_DEPTH; i += 1.0) {
        let V = U / vec2<f32>(RATIO, 1.0);
        let D = CRACK_ZEBRA_AMP * fbm22(U / CRACK_ZEBRA_SCALE) * CRACK_ZEBRA_SCALE;
        let H = voronoiB(V + D);

        var d = H.x;
        d = min(1.0, CRACK_SLOPE * pow(max(0.0, d - CRACK_WIDTH), CRACK_PROFILE));

        O += vec4<f32>(1.0 - d) / pow(2.0, i);
        U = (U * 1.5) * R_mat;
    }

    if (vert) { O = 1.0 - O; }
    O = O * vec4<f32>(0.9, 0.85, 0.85, 1.0);
    return vec4<f32>(O.rgb, 1.0);
}

