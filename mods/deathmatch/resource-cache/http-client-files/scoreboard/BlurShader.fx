texture ScreenSource;
float BlurStrength;
float2 UVSize;

sampler TextureSampler = sampler_state
{
    Texture = <ScreenSource>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

float4 PixelShaderFunction(float2 TextureCoordinate : TEXCOORD0) : COLOR0
{
    // Calculate pixel size for proper scaling
    float2 pixelSize = float2(1.0 / UVSize.x, 1.0 / UVSize.y) * BlurStrength;
    
    // Start with center sample (highest weight)
    float4 color = tex2D(TextureSampler, TextureCoordinate) * 0.20;
    float totalWeight = 0.20;
    
    // Ring 1: 12 samples for smooth radial blur
    float weight1 = 0.10;
    float diag = 0.707107; // 1/sqrt(2) for 45-degree angles
    
    // Cardinal directions (4 samples)
    color += tex2D(TextureSampler, TextureCoordinate + float2(pixelSize.x, 0.0)) * weight1;
    color += tex2D(TextureSampler, TextureCoordinate + float2(-pixelSize.x, 0.0)) * weight1;
    color += tex2D(TextureSampler, TextureCoordinate + float2(0.0, pixelSize.y)) * weight1;
    color += tex2D(TextureSampler, TextureCoordinate + float2(0.0, -pixelSize.y)) * weight1;
    
    // Diagonal directions (4 samples)
    color += tex2D(TextureSampler, TextureCoordinate + float2(pixelSize.x * diag, pixelSize.y * diag)) * weight1;
    color += tex2D(TextureSampler, TextureCoordinate + float2(-pixelSize.x * diag, pixelSize.y * diag)) * weight1;
    color += tex2D(TextureSampler, TextureCoordinate + float2(pixelSize.x * diag, -pixelSize.y * diag)) * weight1;
    color += tex2D(TextureSampler, TextureCoordinate + float2(-pixelSize.x * diag, -pixelSize.y * diag)) * weight1;
    
    // Intermediate directions (4 samples at 22.5 degrees)
    float cos22 = 0.92388;
    float sin22 = 0.382683;
    color += tex2D(TextureSampler, TextureCoordinate + float2(pixelSize.x * cos22, pixelSize.y * sin22)) * weight1;
    color += tex2D(TextureSampler, TextureCoordinate + float2(-pixelSize.x * cos22, pixelSize.y * sin22)) * weight1;
    color += tex2D(TextureSampler, TextureCoordinate + float2(pixelSize.x * sin22, pixelSize.y * cos22)) * weight1;
    color += tex2D(TextureSampler, TextureCoordinate + float2(-pixelSize.x * sin22, pixelSize.y * cos22)) * weight1;
    
    totalWeight += weight1 * 12.0;
    
    // Ring 2: 4 samples at 1.5x distance (cardinal only for performance)
    float weight2 = 0.05;
    float2 pixelSize2 = pixelSize * 1.5;
    color += tex2D(TextureSampler, TextureCoordinate + float2(pixelSize2.x, 0.0)) * weight2;
    color += tex2D(TextureSampler, TextureCoordinate + float2(-pixelSize2.x, 0.0)) * weight2;
    color += tex2D(TextureSampler, TextureCoordinate + float2(0.0, pixelSize2.y)) * weight2;
    color += tex2D(TextureSampler, TextureCoordinate + float2(0.0, -pixelSize2.y)) * weight2;
    
    totalWeight += weight2 * 4.0;
    
    // Normalize
    return color / totalWeight;
}

technique BlurShader
{
    pass Pass1
    {
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}
