//---------------------------------------------------------------------------
// VORTEX HUD - smooth rounded rectangle (Fix #20)
//
// Replaces the dxDrawCircle-corner rounded rectangles, which have hard,
// pixelated edges. Draws an anti-aliased rounded box via a signed distance
// field, so corners are perfectly smooth at any radius.
//
//   * gSize    = rectangle size in pixels
//   * gRadius  = corner radius in pixels (clamped by the caller)
//   * gColor   = fill color + alpha (border, panel or frame fill)
//---------------------------------------------------------------------------
float2 gSize   = float2(100.0, 40.0);
float  gRadius = 8.0;
float4 gColor  = float4(1.0, 1.0, 1.0, 1.0);
float  gAA     = 1.0;                      // edge AA in pixels

float sdRoundBox(float2 p, float2 b, float r)
{
    float2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float4 psMain(float2 uv : TEXCOORD0) : COLOR0
{
    float2 p = (uv - 0.5) * gSize;
    float  d = sdRoundBox(p, gSize * 0.5, gRadius);
    float  a = 1.0 - smoothstep(-gAA, gAA, d);
    return float4(gColor.rgb, gColor.a * a);
}

technique simple
{
    pass P0
    {
        PixelShader = compile ps_2_0 psMain();
    }
}
