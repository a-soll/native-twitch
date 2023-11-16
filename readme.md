# ⚠️ This app is no longer maintained ⚠️
This app was used as a learning experience on working with SwiftUI and C interop. I have since been working on a "2.0" version of this app using C++ instead of C.
There are quite a few design choices made on this app that require a redesign to fully address, which is being done in the newer version. It is closed source
and will be targetting the AppStore for Mac and iPhone.

# Native Twitch
Native Twitch is a native MacOS app for Twitch with FFZ support. Still in very early development.

## Authenticate to enable your Twitch Turbo or channel subs to avoid ads
1. Open twitch.tv in your browser
2. Right click and inspect element
3. Paste `document.cookie.split("; ").find(item=>item.startsWith("auth-token="))?.split("=")[1]` into the console
4. Copy the code from the above command and paste it into Native Twitch's "OAuth Token" field in settings. Relaunch app to apply.

More info on this process can be found [here](https://streamlink.github.io/cli/plugins/twitch.html#authentication)

## For FFZ support
1. Export your user settings from FFZ extension in your browser
2. Open Native Twitch preferences and click on the button in the FFZ Settings section
3. Select the FFZ settings .json file that you exported from the browser. App may need to be relaunched for changes to take effect.

## Screenshots
#### Landing page
<img width="1723" alt="Screen Shot 2022-07-20 at 12 15 18 PM" src="https://user-images.githubusercontent.com/50970854/180032879-8591a642-58df-42ec-818d-47031813dc24.png">

#### Stream view
<img width="1723" alt="Screen Shot 2022-07-20 at 12 14 45 PM" src="https://user-images.githubusercontent.com/50970854/180033343-3dcd633f-63b9-4789-93f4-d02ce4b82675.png">

#### Theater mode
<img width="1723" alt="Screen Shot 2022-07-20 at 12 14 52 PM" src="https://user-images.githubusercontent.com/50970854/200234129-72baec54-696f-4fd8-8001-41efc64b9290.png">

#### Building the project
1. Clone recursively to get the submodules: `git clone --recursive https://github.com/a-soll/native-twitch.git`
2. Run `build.sh` from project root dir to build the dependencies
3. Open project in Xcode to run.
