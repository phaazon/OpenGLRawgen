{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE CPP #-}
module Graphics.Rendering.OpenGL.Raw.NV.MultisampleCoverage
       (gl_COVERAGE_SAMPLES_NV, gl_COLOR_SAMPLES_NV) where
import Graphics.Rendering.OpenGL.Raw.Internal.TypesInternal
import Foreign.Ptr
import Graphics.Rendering.OpenGL.Raw.Internal.Extensions
 
gl_COVERAGE_SAMPLES_NV :: GLenum
gl_COVERAGE_SAMPLES_NV = 32937
 
gl_COLOR_SAMPLES_NV :: GLenum
gl_COLOR_SAMPLES_NV = 36384