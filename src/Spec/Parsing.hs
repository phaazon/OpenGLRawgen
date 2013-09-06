{-# LANGUAGE TypeFamilies, FlexibleContexts #-}
-----------------------------------------------------------------------------
--
-- Module      :  Spec.Parsing
-- Copyright   :  (c) 2011 Lars Corbijn
-- License     :  BSD-style (see the file /LICENSE)
--
-- Maintainer  :
-- Stability   :
-- Portability :
--
-- | The parser build over the the parsers in openGL-api , and a simple
-- parser to parse the reuse entries.
--
-----------------------------------------------------------------------------

module Spec.Parsing (
    parseSpecs,
) where

-----------------------------------------------------------------------------

import qualified Data.Foldable as F
import Data.Function
import Data.List
import qualified Data.Map as M
import Data.Maybe(fromMaybe, isNothing)
import Data.Monoid
import qualified Data.Set as S

import qualified Text.OpenGL as P

import Main.Options
import Main.Monad
import Spec.RawSpec

import Language.OpenGLRaw.Base

-----------------------------------------------------------------------------

-- | Parse the needed OpenGL spec files and generate a 'RawSpec' based on
-- them.
parseSpecs :: RawGenIO (LocationMap, ValueMap)
parseSpecs = do
    specLocation <- asksOptions specFile
    registry <- liftEither =<< (liftIO $ P.readRegistry specLocation True)
    let lm = createLocMap registry
        vm = createValMap registry
    return (lm, vm)

createLocMap :: P.Registry -> LocationMap
createLocMap reg =
    F.foldMap extensionLocs (P.regExtensions reg)
    `mappend`
--    addLocation (CompVersion 1 0 False) (mkEnumName $ P.EnumName "GL_ZERO") mempty
    featureLocs (P.regFeatures reg)

createValMap :: P.Registry -> ValueMap
createValMap reg =
    F.foldMap enumsMap (P.regEnums reg)
    `mappend`
    F.foldMap commandsMap (P.regCommands reg)
  where
    commandsMap = F.foldMap funcVal . P.commands

enumsMap :: P.Enums -> ValueMap
enumsMap ens = F.foldMap mkEnum $ P.enums ens
  where
    ty = case P.enumsType ens of
        Just "bitfield" -> BitfieldValue
        _               -> EnumValue
    mkEnum (Right _) = mempty
    mkEnum (Left  e) = enumVal ty e

enumVal :: ValueType -> P.GLEnum -> ValueMap
enumVal ty e
    = addValue 
        (mkEnumName $ P.enumName e) 
        (Value (P.enumValue e) ty)
        mempty

funcVal :: P.Command -> ValueMap
funcVal com 
    = addValue 
        (mkFuncName $ P.commandName com)
        (RawFunc retType argTypes alias)
        mempty
  where
    retType = convertType . P.returnType $ P.commandReturnType com
    argTypes = map (convertType . P.paramType) $ P.commandParams com
    alias = mkFuncName `fmap` P.commandAlias com

mkEnumName :: P.EnumName -> EnumName
mkEnumName = wrapName . tryStrip "GL_" . (\(P.EnumName n') -> n')

mkFuncName :: P.CommandName -> FuncName
mkFuncName = wrapName . tryStrip "gl" . (\(P.CommandName n) -> n)

tryStrip :: String -> String -> String
tryStrip pre n = fromMaybe n $ pre `stripPrefix` n

convertType :: P.CType -> FType
convertType ct = case ct of
    P.Struct n      -> convertStruct n
    P.CConst t      -> convertType t
    P.Ptr    t      -> case convertType t of
        UnitTCon    -> TPtr TVar
        t'          -> TPtr t'
    P.BaseType bt   -> convertBaseType bt
    P.AliasType n   -> convertAliasType n

convertStruct :: String -> FType
convertStruct n = case n of
    "_cl_context"   -> TCon "CLcontext"
    "_cl_event"     -> TCon "CLevent"
    _               -> error $ "struct " ++ n
convertBaseType :: P.BaseType -> FType
convertBaseType bt = case bt of
    P.Void  -> UnitTCon
    _       -> error $ show bt
convertAliasType :: String -> FType
convertAliasType n = case n of
    "GLboolean"         -> TCon "GLboolean"
    "GLbyte"            -> TCon "GLbyte"
    "GLubyte"           -> TCon "GLubyte"
    "GLchar"            -> TCon "GLchar"
    "GLcharARB"         -> TCon "GLchar"
    "GLshort"           -> TCon "GLshort"
    "GLushort"          -> TCon "GLushort"
    "GLint"             -> TCon "GLint"
    "GLuint"            -> TCon "GLuint"
    "GLfixed"           -> TCon "GLfixed"
    "GLint64"           -> TCon "GLint64"
    "GLint64EXT"        -> TCon "GLint64"
    "GLuint64"          -> TCon "GLuint64"
    "GLuint64EXT"       -> TCon "GLuint64"
    "GLsizei"           -> TCon "GLsizei"
    "GLenum"            -> TCon "GLenum"
    "GLintptr"          -> TCon "GLintptr"
    "GLintptrARB"       -> TCon "GLintptr"
    "GLsizeiptr"        -> TCon "GLsizeiptr"
    "GLsizeiptrARB"     -> TCon "GLsizeiptr"
    "GLbitfield"        -> TCon "GLbitfield"
    "GLsync"            -> TCon "GLsync"
    "GLhalf"            -> TCon "GLhalf"
    "GLhalfNV"          -> TCon "GLhalf"
    "GLfloat"           -> TCon "GLfloat"
    "GLclampf"          -> TCon "GLclampf"
    "GLclampx"          -> TCon "GLclampx"
    "GLdouble"          -> TCon "GLdouble"
    "GLclampd"          -> TCon "GLclampd"
    "GLvoid"            -> UnitTCon
    "GLDEBUGPROC"       -> TCon "GLdebugproc"
    "GLDEBUGPROCAMD"    -> TCon "GLdebugproc"
    "GLDEBUGPROCARB"    -> TCon "GLdebugproc"
    "GLDEBUGPROCKHR"    -> TCon "GLdebugproc"
    "GLhandleARB"       -> TCon "GLhandle"
    "GLvdpauSurfaceNV"  -> TCon "GLvdpauSurface"
    _                   -> error $ "alias type " ++ n

extensionLocs :: P.Extension -> LocationMap
extensionLocs ext = case P.extensionSupported ext of
    Nothing -> mempty
    Just s ->
        if s `P.supports` P.GL
         then snd $ featureVersion ext mempty
         else mempty

featureLocs :: S.Set P.Feature -> LocationMap
featureLocs featureSet =
    let features
            = partitionBy P.featureApi $ S.toList featureSet
    in F.foldMap featureApi features

partitionBy :: Ord a => (b -> a) -> [b] -> [[b]]
partitionBy f = groupBy ((==) `on` f) . sortBy (compare `on` f)

type IE = P.InterfaceElement
type Prof = P.ProfileName
type ProfileBuild = (S.Set IE, M.Map Prof (S.Set IE))

featureApi :: [P.Feature] -> LocationMap
featureApi features@(f:_) | P.featureApi f == P.GL =
    let features' = sortBy (compare `on` P.featureNumber) $ features
        (_, locs) = mapAccumL (flip featureVersion) mempty features'
    in mconcat locs
    -- execWriter (F.foldlM (flip featureVersion) mempty features')
featureApi _ = mempty

class ElementContainer (ElemContainer p) => ApiPart p where
    type ElemContainer p :: *
    requires :: p -> S.Set (ElemContainer p)
    removes  :: p -> S.Set (ElemContainer p)
    version  :: p -> Profile -> Category
instance ApiPart P.Feature where
    type ElemContainer P.Feature = P.FeatureElement
    requires = P.featureRequires
    removes  = P.featureRemoves
    version f = case P.featureNumber f of
        (ma, mi) -> Version ma mi
instance ApiPart P.Extension where
    type ElemContainer P.Extension = P.ExtensionElement
    requires = P.extensionRequires
    removes = P.extensionRemoves
    version e = case P.decomposeExtensionToken $ P.extensionName e of
        Nothing -> error $ "Non decomposible extension token" ++ show (P.extensionName e)
        Just (vn,name) ->
            Extension vend name
          where vend = case vn of P.VendorName n -> Vendor n

class ElementContainer e where
    elements    :: e -> S.Set P.InterfaceElement
    profileName :: e -> Maybe P.ProfileName
    -- Check if the element container supports the api, as some elements might
    -- not be applicable for all api-s.
    isOfApi     :: e -> P.ApiReference -> Bool
instance ElementContainer P.FeatureElement where
    elements    = P.feElements
    profileName = P.feProfileName
    isOfApi _ _ = True
instance ElementContainer P.ExtensionElement where
    elements    = P.eeElements
    profileName = P.eeProfileName
    isOfApi ee api = case P.eeApi ee of
        Nothing -> True
        Just a  -> a == api

featureVersion :: (ApiPart p, Ord (ElemContainer p)) -- The ord is needed for travis' ghc
    => p -> ProfileBuild -> (ProfileBuild, LocationMap)
featureVersion feat profBuild =
    let (reqGeneric, reqProfile) = S.partition (isNothing . profileName)
            . S.filter (`isOfApi` P.GL)
            $ requires feat
        (remGeneric, remProfile) = S.partition (isNothing . profileName)
            . S.filter (`isOfApi` P.GL)
            $ removes feat
        flipFoldr f = flip (F.foldr' f)
        profBuild'
            = addCore
            . flipFoldr (addProf False)    remProfile
            . flipFoldr (addProf True)     reqProfile
            . flipFoldr (addGeneric False) remGeneric
            . flipFoldr (addGeneric True)  reqGeneric
            $ profBuild
        -- | Sometimes a non default profile is added without any changes to
        -- the core profile. Yet when there are profiles the core profile acts
        -- as the default one. Thus it needs to be added when there are other
        -- profiles and it has not yet been created.
        addCore pb@(gen, profs) = if M.null profs || M.member (P.ProfileName "core") profs
            then pb
            else (gen, M.insert (P.ProfileName "core") gen profs)
        locMap = defineLocations (version feat) profBuild'
    in (profBuild', locMap)

addGeneric :: ElementContainer c => Bool -> c  -> ProfileBuild -> ProfileBuild
addGeneric addRem element p = F.foldr' (updateNonProfile addRem) p
                            $ elements element
addProf :: ElementContainer c => Bool -> c -> ProfileBuild -> ProfileBuild
addProf addRem element p = F.foldr' (updateProfile addRem prof) p
                         $ elements element
    where prof = fromMaybe (error "No profile") $ profileName element

updateNonProfile :: Bool -> IE -> ProfileBuild -> ProfileBuild
updateNonProfile addRem ie (gen, profs) =
    let update = (if addRem then S.insert else S.delete) ie
    in (update gen, fmap update profs)

updateProfile :: Bool -> Prof -> IE -> ProfileBuild -> ProfileBuild
updateProfile addRem prof ie (gen, profs) =
    let updateVal :: S.Set IE -> S.Set IE
        updateVal = (if addRem then S.insert else S.delete) ie
        update :: Maybe (S.Set IE) -> Maybe (S.Set IE)
        update = Just . updateVal . fromMaybe gen
    in (gen, M.alter update prof profs)

defineLocations :: (Profile -> Category) -> ProfileBuild -> LocationMap
defineLocations f (gen, profs) =
    if M.null profs
     then mkLocMap (f DefaultProfile) gen
     else F.fold $ M.mapWithKey (\p ies -> mkLocMap (mkCat p) ies) profs
  where
    mkCat :: Prof -> Category
    mkCat (P.ProfileName pn) = f $ case pn of
        "core"  -> DefaultProfile
        _       -> ProfileName pn
    mkLocMap :: Category -> S.Set IE -> LocationMap
    mkLocMap c = F.foldMap (ieMap c . P.ieElementType)
    ieMap :: Category -> P.ElementType -> LocationMap
    ieMap c ie = case ie of
        P.IEnum     eName -> addLocation c (mkEnumName eName) mempty
        P.ICommand  cName -> addLocation c (mkFuncName cName) mempty
        _                 -> mempty
