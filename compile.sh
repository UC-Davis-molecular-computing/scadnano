#pub.bat global activate webdev
echo "running webdev directly, but if it fails, try first running" 
echo "  pub.bat global activate webdev"
webdev.bat build

# most packages appear not to be needed for the production version of the app
# but keep an eye out for bugs related to this and possibly use it if needed (it's 46 MB last I checked)
for directory in build/packages/*; do
    if [[ "$directory" = "build/packages/codemirror" || "$directory" = "build/packages/split" ]]; then
        echo "leaving $directory alone since it is needed in the app"
    else
        echo "deleting $directory"
        rm -rf "$directory"
    fi
done
