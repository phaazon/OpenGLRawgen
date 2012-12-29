{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE CPP #-}
module Graphics.Rendering.OpenGL.Raw.ARB.TextureCubeMapArray
       (gl_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY_ARB,
        gl_INT_SAMPLER_CUBE_MAP_ARRAY_ARB,
        gl_SAMPLER_CUBE_MAP_ARRAY_SHADOW_ARB,
        gl_SAMPLER_CUBE_MAP_ARRAY_ARB, gl_PROXY_TEXTURE_CUBE_MAP_ARRAY_ARB,
        gl_TEXTURE_BINDING_CUBE_MAP_ARRAY_ARB,
        gl_TEXTURE_CUBE_MAP_ARRAY_ARB)
       where
import Graphics.Rendering.OpenGL.Raw.Internal.TypesInternal
import Foreign.Ptr
import Graphics.Rendering.OpenGL.Raw.Internal.Extensions
 
gl_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY_ARB :: GLenum
gl_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY_ARB = 36879
 
gl_INT_SAMPLER_CUBE_MAP_ARRAY_ARB :: GLenum
gl_INT_SAMPLER_CUBE_MAP_ARRAY_ARB = 36878
 
gl_SAMPLER_CUBE_MAP_ARRAY_SHADOW_ARB :: GLenum
gl_SAMPLER_CUBE_MAP_ARRAY_SHADOW_ARB = 36877
 
gl_SAMPLER_CUBE_MAP_ARRAY_ARB :: GLenum
gl_SAMPLER_CUBE_MAP_ARRAY_ARB = 36876
 
gl_PROXY_TEXTURE_CUBE_MAP_ARRAY_ARB :: GLenum
gl_PROXY_TEXTURE_CUBE_MAP_ARRAY_ARB = 36875
 
gl_TEXTURE_BINDING_CUBE_MAP_ARRAY_ARB :: GLenum
gl_TEXTURE_BINDING_CUBE_MAP_ARRAY_ARB = 36874
 
gl_TEXTURE_CUBE_MAP_ARRAY_ARB :: GLenum
gl_TEXTURE_CUBE_MAP_ARRAY_ARB = 36873