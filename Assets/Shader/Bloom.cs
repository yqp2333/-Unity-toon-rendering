using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : PostEffectBase
{
    public Shader bloomShader;
    private Material bloomMaterial = null;
    public Material material {
        get { bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }

    [Range(0, 4)]
    public int interations = 3;

    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;

    [Range(1, 8)]
    public int downSample = 2;

    [Range(0.0f, 5.0f)]
    public float bloomIntence = 1;

    public Color bloomColor = new Color(1, 1, 1, 1);

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material)
        {
            int rtW = source.width / downSample;
            int rtH = source.height / downSample;

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

            buffer0.filterMode = FilterMode.Bilinear;
            Graphics.Blit(source, buffer0, material, 0);

            for (int i = 0; i < interations; i++)
            {
                //垂直高斯模糊
                material.SetVector("_offsets", new Vector4(0, 1.0f + i * blurSpread, 0, 0));
                Graphics.Blit(buffer0, buffer1, material, 1);

                //水平高斯模糊
                material.SetVector("_offsets", new Vector4(1.0f + i * blurSpread, 0, 0, 0));
                Graphics.Blit(buffer1, buffer0, material, 1);
                RenderTexture.ReleaseTemporary(buffer1);
            }

            material.SetColor("_BloomColor", bloomColor);
            material.SetFloat("_BloomIntence", bloomIntence);
            material.SetTexture("_BlurTex", buffer0);
            Graphics.Blit(source, destination, material, 2);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else {
            Graphics.Blit(source, destination);
        }
    }
}
