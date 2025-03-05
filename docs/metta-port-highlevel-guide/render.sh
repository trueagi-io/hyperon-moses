for i in {1..3}; do
    bibtex metta-port-highlevel-guide
    lualatex --synctex=1 -shell-escape metta-port-highlevel-guide.tex
done
