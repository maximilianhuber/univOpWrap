# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, filepath, hashable, MissingH, text }:

cabal.mkDerivation (self: {
  pname = "univOpWrap";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  buildDepends = [ filepath hashable MissingH text ];
  meta = {
    description = "A universal wrapper, which makes searching and opening of files nicer";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
