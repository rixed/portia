{ stdenv, fetchFromGitHub, ocaml, findlib, batteries }:

stdenv.mkDerivation rec {
  pname = "portia";
  version = "1.3";

  src = fetchFromGitHub {
    owner = "rixed";
    repo = "portia";
    rev = "v${version}";
    sha256 = "18c430gxfvwbafpay42p0clmb4cnxqdn0g1vadydlf67sxf1lkr0";
  };

  buildInputs = [ ocaml findlib batteries ];

  createFindlibDestdir = true;

  meta = with stdenv.lib; {
    homepage = https://github.com/rixed/portia;
    description = "Literate Programming Preprocessor";
    platforms = ocaml.meta.platforms or [];
    maintainers = [ maintainers.rixed ];
  };
}
