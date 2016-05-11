#version 100
#define onesqrt2 0.70710678118
#define sqrt2 1.41421356237
precision mediump float;

const float hglyph = 72.0;
const float spread = 2.0;
const float edge = 0.5;
const float mess = 32.0/25.0;

uniform sampler2D texglyph;
uniform sampler2D texicon;
uniform vec2 glyph;
uniform vec4 shadowColor;

varying vec4 vtexcoord;
varying vec4 vvertex;

// interpolated distance, and size values
// x, y is unit value [0..1]
// z, w is material width, height
varying vec4 vdist;
varying vec4 vcolor;

vec4 sampleIcon() {
  vec4 clr = texture2D(texicon, vtexcoord.xy);
  clr.rgb += vcolor.rgb;
  clr.a *= 0.54; // https://www.google.com/design/spec/style/color.html#color-ui-color-application
  return clr;
}

vec4 sampleGlyph() {
  float acoef = 0.87;
  vec2 tc = vtexcoord.xy;
  tc.y -= hglyph/512.0/mess;
  float d = texture2D(texglyph, tc).a;

  float height = vdist.w;
  float h = height/1.2;

  float gnum = 0.25; // just a numerator
  if (11.5 < h && h <= 12.5) {
    gnum = 0.105;
    d += 0.2;
    acoef *= 0.87;
  } else if (12.5 < h && h <= 14.5) {
    gnum = 0.15;
    d += 0.08;
  } else if (14.5 < h && h <= 18.5) {
    gnum = 0.15;
    d += 0.04;
  } else if (18.5 < h && h <= 20.5) {
    gnum = 0.2;
  }
  float gamma = gnum/(spread*(h/hglyph));

  // d += 0.2; // bold
  // d -= 0.2; // thin

  vec4 clr = vcolor;
  clr.a = smoothstep(edge-gamma, edge+gamma, d);
  clr.a *= acoef; // secondary text
  return clr;
}

// TODO drop this
bool shouldcolor(vec2 pos, float sz) {
  pos = 0.5-abs(pos-0.5);
  pos *= vdist.zw;

  if (pos.x <= sz && pos.y <= sz) {
    float d = length(1.0-(pos/sz));
    if (d > 1.0) {
      return false;
    }
  }
  return true;
}

float shade(vec2 pos, float sz) {
  pos = 0.5-abs(pos-0.5);
  pos *= vdist.zw;

  if (pos.x <= sz && pos.y <= sz) {
    float d = length(1.0-(pos/sz));
    if (d > 1.0) { // TODO consider moving this as discard into top of main
      return 0.0;
    }
    return 1.0-d;
  } else if (pos.x <= sz && pos.y > sz) {
    return pos.x/sz;
  } else if (pos.x > sz && pos.y <= sz) {
    return pos.y/sz;
  }
  return 1.0;
}

void main() {
  float roundness = vvertex.w;
	if (vtexcoord.x >= 0.0) {
    if (vtexcoord.z == 1.0) {
      gl_FragColor = sampleIcon();
    } else {
      gl_FragColor = sampleGlyph();
    }
	} else if (vvertex.z == 0.0) {
    if (roundness < 10.0) {
      roundness = 10.0;
    }
		gl_FragColor = shadowColor;
    // gl_FragColor = vec4(0, 0, 0, 1);
    // gl_FragColor.a = shade(vdist.xy, roundness);
    gl_FragColor.a = smoothstep(0.0, 1.0, shade(vdist.xy, roundness));
    gl_FragColor.a *= 0.25 + roundness/vdist.z/0.5;
    gl_FragColor.a *= 1.5;

    //debug
    // gl_FragColor.a *= 10.0;

    // gl_FragColor.a = clamp(smoothstep(0.0, 1.0, shade(vdist.xy, roundness)), 0.0, 0.5);
    // gl_FragColor.a = clamp(roundness/vdist.z/0.05, 1.0, 4.0)*smoothstep(0.0, 1.0, shade(vdist.xy, roundness));
  } else {
    if (shouldcolor(vdist.xy, roundness)) {
      gl_FragColor = vcolor;
      // gl_FragColor.a = 0.0;
    } else {
      discard;
    }
	}
}
