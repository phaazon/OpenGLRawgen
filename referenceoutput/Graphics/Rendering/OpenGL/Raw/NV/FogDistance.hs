{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE CPP #-}
module Graphics.Rendering.OpenGL.Raw.NV.FogDistance
       (gl_EYE_PLANE, gl_EYE_PLANE_ABSOLUTE_NV, gl_EYE_RADIAL_NV,
        gl_FOG_DISTANCE_MODE_NV)
       where
import Graphics.Rendering.OpenGL.Raw.Core.Internal.Core11Compatibility
       (gl_EYE_PLANE)
import Graphics.Rendering.OpenGL.Raw.Internal.TypesInternal
import Foreign.Ptr
import Graphics.Rendering.OpenGL.Raw.Internal.Extensions
 
gl_EYE_PLANE_ABSOLUTE_NV :: GLenum
gl_EYE_PLANE_ABSOLUTE_NV = 34140
 
gl_EYE_RADIAL_NV :: GLenum
gl_EYE_RADIAL_NV = 34139
 
gl_FOG_DISTANCE_MODE_NV :: GLenum
gl_FOG_DISTANCE_MODE_NV = 34138