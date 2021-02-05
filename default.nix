{ stdenv, fetchFromGitHub, ocaml, findlib, batteries }:

stdenv.mkDerivation rec {
  pname = "ocaml${ocaml.version}-portia";
  version = "1.3";

  src = fetchFromGitHub {
    owner = "rixed";
    repo = "portia";
    rev = "v${version}";
    sha256 = "1jq77rfl4v6b2v7fqv6vda0diqg5xxz4aiga4djdriwf1l086yy4";
  };

  buildInputs = [ ocaml findlib batteries ];

  # Despite portia can be considered a normal application program with
  # some plugins, those plugins need to link with portia.cma, so it's
  # much easier to install everything as a findlib package:
  createFindlibDestdir = true;

  dontStrip = !ocaml.nativeCompilers;

  meta = with stdenv.lib; {
    homepage = https://github.com/rixed/portia;
    description = "Literate Programming Preprocessor";
    platforms = ocaml.meta.platforms or [];
    maintainers = [ maintainers.rixed ];
  };
}
