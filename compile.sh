#pub.bat global activate webdev

#bash compile-upload-readme.sh

echo "running webdev directly, but if it fails, try first running" 
echo "  pub.bat global activate webdev"

rm -rf build/ # lately getting a build crash every other time we compile
webdev.bat build #--no-release

# most packages appear not to be needed for the production version of the app
# but keep an eye out for bugs related to this and possibly use it if needed (it's 46 MB last I checked)
for directory in build/packages/*; do
    if [[ "$directory" = "build/packages/codemirror" 
    || "$directory" = "build/packages/split" 
    || "$directory" = "build/packages/build_web_compilers" 
    || "$directory" = "build/packages/\$sdk" ]]; then
        echo "leaving $directory alone since it is needed in the app"
    else
        echo "deleting $directory"
        rm -rf "$directory"
    fi
done

rm -rf build/external-libs/pyodide

