#pub.bat global activate webdev
echo "running webdev directly, but if it fails, try first running" 
echo "  pub.bat global activate webdev"
webdev.bat build
# packages directory appears not to be needed for the production version of the app
# but keep an eye out for bugs related to this and possibly use it if needed (it's 46 MB last I checked)
rm -rf build/packages 
rm build/external-libs/simpledrag.js
rm build/external-libs/svg-pan-zoom.js
