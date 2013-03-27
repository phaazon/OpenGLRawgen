# OpenGLRawgen

OpenGLRawgen is a generator tool to make a Raw FFI import of OpenGL to
haskell in style of OpenGLRaw.

[![Build Status](https://travis-ci.org/Laar/OpenGLRawgen.png)](https://travis-ci.org/Laar/OpenGLRawgen)

## Project goal

The current (01-2013) OpenGLRaw is quite outdated and not practical to
keep up to date as everything needs to be done by hand. The goal of this
project is to make a generator which can produce most the otherwise
handwritten source of OpenGLRaw. Therefore it tries to keep the work
needed to generate a new version to a minimum and keeping in mind the
current conventions, while also trying to take advantage of the extra
processing power available.

## Output
The generator has creates all sources in the
`Graphics.Rendering.OpenGL.Raw` namespace. In which it will generate
several sub namespace.

* `Core.Internal` is generated to house all the code to describe the
  functions and enumerations which are part of a certain
  specification of OpenGL. Parts are put into modules based on the
  first version of the specification to which they were added.
* Extension granter namespaces e.g. `ARB` and `NV`, for each extension
  granting entity there will be a separate namespace which will
  contain all there extensions.

Furthermore it will make several extra modules to group functions and
enumerations. Most importantly there are modules to do the grouping for
a specific version of the OpenGl specification, they can be found in the
subnamespace `Core`.

### Building
Several steps are needed to be preformed to generate a working cabal
package out of the generated sources. These steps are detailed in
`BuildSources.BUILDING.md`.

### Other sources
Some building blocks of the OpenGLRaw package have been reused from the
old package. These parts are those representing types and the several of
the internals (e.g. the ones for retrieving proc-addresses). These are
also found in `BuildSources`, with there License.

## Changes from OpenGLRaw
There are of course some changes from the OpenGLRaw. (The list is
probably not complete, but these are the major points.)

### Core modules
The major change is probably that the core modules have been rearranged
. Compatibility modules can be generated by giving the generator the -c
flag. `Raw.hs` now exports the latest OpenGL specification in stead of
every binding.

### Naming schemes
The old naming scheme for functions and enumeration was not very clear
on when the extension suffixes should be kept for a function and when
not. It seemed to depend on whether or not the specification for the
function is the same as the one without suffix.
The generator on the other hand needs a clear naming scheme, though
then there is the choice on what to do with the suffixes. Two simple
naming schemes have been included in the generator. -s Gives a version
where all extension suffixes have been removed, -S will result in
keeping all suffixes. -S is default as it results in the least trouble.
As a consequence of name clashes with the -s option, the grouping
modules for extension granters (e.g. `ARB` and `NV`) have been
disabled.

## Implementation
The generator can roughly be split in several steps.

1. Parsing of the specification files into a specific format (found in
   `Spec.Parsing`).
2. Amending and filtering the specification. (found in 
   `Spec.Processing`).
3. Generating `RawModule`s, a specification of the modules to be 
   generated  (found in the `Modules` namespace).
4. Generating files from these `RawModule`s
   (Currently done in `Main` and `Code.ModuleCode`).

Apart from these steps there are several other modules,

* `Modules.Types` Defines the types for the abstract modules.
* `Spec.RawSpec` Defines the types for working with the original
  specification.
* `Main.Options` Defines the commandline options.
* `Main.Monad` Defines the `RawGen` monads that distribute the options
  and does the error handling.

### 1. Parsing
The implementation is based around the .spec files from the OpenGL
[registry][] which provide a source of all function and enumerations in
use. The (slightly corrected) files are parsed by [noteeds spec parser][parser]
. As some information is only available in the comments of the spec
files two extra files are used to represent the reusing of functions and
enumerations from other categories. All the parsing code can be found in
`Spec.Parsing`.

[registry]: http://www.opengl.org/registry/#specfiles
[parser]: https://raw.github.com/noteed/opengl-api

### 2. Processing
The further processing is relatively simple. Some information about
reusing definitions from other categories is buried in comments. These
reuses are specified by two files (`enumreuses` and `funcreuses`). As
the amount of extensions is quite large there is the possibility to
exclude them based on vendor. Therefore a file (`novendor`) is used to
filter the categories.


### 3. `RawModule` generating
The translation from the specification to code is done via `RawModule`,
which specify the contents of a module in the final OpenGLRaw. This
extra layer is added to separate the logic creating the contents from
the actual templates used to generate the code. In addition these
intermediate forms can be used to generate other output. Different
types of modules to generate have all there own module,

* `Modules.Types` Defines the `RawModule` and associated types.
* `Modules.Builder` represents the builder monads used to generate them.
* `Modules.Compatibility` has some functions for generating modules
   that are no longer present in the new file structure.
* `Modules.GroupModule` has builders for modules that group other
   modules together to reexport them for easy imports (e.g. for Core
   and vendor modules).
* `Modules.Module` makes the actual enumeration and functions.
* `Modules.Raw` binds all the modules together to generate the full
  OpenGLRaw.

### 4. Generating output
The `RawModule`s are used to generate to forms of output.

* The real haskell modules are generated using the template from 
  `Code.ModuleCode`.
* Two listings specifying the internal modules (`other-modules` field
  in cabal) in `modulesI.txt` and the external modules
  (`exposed-modules` in cabal) in `modulesE.txt`.
* The interface, which describes what each module defines, useful to
  lookup where a piece (function or enum) has been defined and what its
  haskell name and type are.


### Dependencies
The generator has some quite some dependencies, of which some are
managed by using git submodules. The current submodules are

* `CodeGenerating` to add some extra functions to `haskell-src-exts` for
  generating source code.
* `opengl-api` the [parser][parser] from noteed, which needs to be
  patched for the latest version of the spec files.
* `OpenGLRawgenBase` basic types also used in the interface, which could
  be used without the generator.

To simplify the installation (for both
users and travis CI) there is a dependecy installation script 
`depsinstall.sh`. This should be invoked with your favorite cabal
command e.g. `./depsinstall.sh cabal` or `./depsinstall.sh cabal-dev`.
Doing so will update the git submodules and install all the
dependencies.
