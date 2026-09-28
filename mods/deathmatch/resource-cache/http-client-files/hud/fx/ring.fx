//---------------------------------------------------------------------------
// VORTEX HUD - smooth progress ring (Fix #20)
//
// Replaces dxDrawCircle strokes, which are triangle fans with hard edges and
// look pixelated at small sizes. This shader evaluates the ring analytically
// per pixel with smoothstep anti-aliasing, so the arc line is perfectly
// smooth at any screen resolution.
//
//   * UV space 0..1 across a SQUARE image
//   * band   = gBand.x (inner radius) .. gBand.y (outer radius)
//   * sweep  = starts at 12 o'clock, runs clockwise (old client)
//   * gProgress 1.0 = complete circle (no end cap)
//   * disc mode: set gBand.x <= 0 to get a filled, smooth dot
//---------------------------------------------------------------------------
float gProgress = 1.0;                     // 0..1 sweep fraction
float4 gColor   = float4(1.0, 1.0, 1.0, 1.0);
float2 gBand    = float2(0.3654, 0.4808);  // inner / outer radius (UV)
float  gRingAA  = 0.020;                   // radial edge AA (UV)
float  gCapAA   = 0.028;                   // end-cap angular AA (radians)

float4 psMain(float2 uv : TEXCOORD0) : COLOR0
{
    float2 p = uv - 0.5;
    float  r = length(p);

    // radial band: smooth inner and outer edges
    float lo = smoothstep(gBand.x - gRingAA, gBand.x + gRingAA, r);
    float hi = 1.0 - smoothstep(gBand.y - gRingAA, gBand.y + gRingAA, r);
    float band = lo * hi;

    // angular sweep: 0 at 12 o'clock, clockwise (screen UV, y grows down)
    float ang = atan2(p.x, -p.y);
    if (ang < 0) ang += 6.28318530718;
    float sweep = saturate(gProgress) * 6.28318530718;
    float arc = (gProgress >= 0.9995) ? 1.0 : smoothstep(-gCapAA, gCapAA, sweep - ang);

    return float4(gColor.rgb, gColor.a * band * arc);
}

technique simple
{
    pass P0
    {
        PixelShader = compile ps_2_0 psMain();
    }
}
