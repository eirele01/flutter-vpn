# BaganiVPN - Getting Started Guide

Follow these steps to run the application on your Android phone using VS Code.

## 1. Setup VS Code
1.  Download and install [Visual Studio Code](https://code.visualstudio.com/).
2.  Open VS Code.
3.  Go to **File > Open Folder...** and select this `BaganiVPN` folder.
4.  You will see a prompt "This workspace has recommended extensions...". Click **Install**. 
    *   (If you missed it, go to the Extensions tab on the left and search for "Flutter" and install the one by Dart Code).

## 2. Prepare Your Phone
1.  Connect your Android phone to your computer via USB cable.
2.  On your phone, go to **Settings > About Phone**.
3.  Tap **Build Number** 7 times until it says "You are now a developer!".
4.  Go back to **Settings > System > Developer Options**.
5.  Enable **USB Debugging**.
6.  A popup might appear on your phone asking to "Allow USB debugging from this computer?". Check "Always allow" and tap **Allow**.

## 3. Run the App
1.  Look at the bottom-right of VS Code. You should see your device name (e.g., "Pixel 7" or "Samsung SM-G990").
    *   If it says "No Device", click it and select your connected phone.
2.  Press **F5** on your keyboard (or click **Run > Start Debugging** in the top menu).
3.  Wait for the build to finish. It may take 2-3 minutes the first time.
4.  Once installed, the app will open on your phone!

## 4. Using the App
1.  **Grant Permissions**: When you first try to connect, Android will ask permission to create a VPN connection. Tap **OK**.
2.  **Connect**: Tap the big "CONNECT" button.
3.  **Logs**: Tap the terminal icon in the top right to see connection logs.
