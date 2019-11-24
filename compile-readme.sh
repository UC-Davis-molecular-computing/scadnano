#pub.bat global activate webdev
echo "compiling README.md to web/README.html using pandoc"

#grip --user pexatus@gmail.com --pass pexatus2 --title "scadnano help" --export web/README.html

pandoc -c pandoc.css -s README.md -o web/README.html
