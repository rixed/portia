(define-module (gnu packages portia)
  #:use-module (guix)
  #:use-module (guix build utils)
  #:use-module (guix build-system ocaml)
  #:use-module (guix licenses)
  #:use-module (gnu packages ocaml))

(define-public portia
  (package
    (name "portia")
    (version "1.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/rixed/" name "/archive/v"
                                  version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "14gmdcdwxq3hppwhv639nvx0kydjpjcggzcwnlap74w5iqc7adj6"))))
    (build-system ocaml-build-system)
    (arguments
      `(#:phases
        (modify-phases %standard-phases
          (delete 'configure)
          (add-after 'install 'fixup-exe-location
            (lambda* (#:key outputs #:allow-other-keys)
                     (let* ((out (assoc-ref outputs "out"))
                            (old-exe (string-append out "/lib/ocaml/site-lib/portia/portia"))
                            (new-dir (string-append out "/bin"))
                            (new-exe (string-append new-dir "/portia")))
                       (mkdir-p new-dir)
                       (link old-exe new-exe)))))
        #:make-flags
        (let ((out (assoc-ref %outputs "out")))
          (list (string-append "PREFIX=" out)
                ; Although it is not used by the Makefile yet:
                (string-append "BINDIR=" out "/bin")
                (string-append "PLUGINDIR=" out "/lib/ocaml/site-lib/portia/")))
        #:test-target "check"))
    (inputs `(("ocaml-batteries" ,ocaml-batteries)
              ("ocaml-num" ,ocaml-num)))
    (propagated-inputs `(("ocaml" ,ocaml)
                         ("ocaml-num" ,ocaml-num)))
    (native-inputs `(("ocaml-qtest" ,ocaml-qtest)))
    (synopsis "Literate Programming Preprocessor")
    (description
      "A literate programming preprocessor written in literate programming style.\n\
\n\
    @O@<literate_quine.sh@>==@{@-\n\
    #!/bin/sh\n\
    cat README.md\n\
    @}\n")
    (home-page (string-append "https://github.com/rixed/" name))
    (license gpl3+)))
