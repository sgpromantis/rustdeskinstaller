# Promantis Logo Integration Guide

I've updated the build configuration to use Promantis branding:
- **App Name**: "Promantis Remote"
- **Company**: "Promantis"
- **Tagline**: "professionell. progressiv. proaktiv."

## To Add Your Logo

The builds need a URL where they can download your logo during the build process. Here are your options:

### Option 1: Use GitHub Raw URL (Recommended)

1. **Save your logo** to the repository:
   - Save the Promantis logo as `prepared_images/promantis_logo.png`
   - Recommended size: 256x256 or 512x512 pixels
   - Format: PNG with transparency (if needed)

2. **Commit and push to GitHub**:
   ```powershell
   git add prepared_images/promantis_logo.png
   git commit -m "Add Promantis logo"
   git push origin master
   ```

3. **Update trigger_builds.py** with the GitHub raw URL:
   ```python
   LOGO_URL = "https://raw.githubusercontent.com/sgpromantis/rustdeskinstaller/master/prepared_images/promantis_logo.png"
   ```

### Option 2: Use Image Hosting Service

Upload your logo to:
- **ImgBB**: https://imgbb.com/
- **Imgur**: https://imgur.com/
- **GitHub Gist**: https://gist.github.com/

Then update `trigger_builds.py`:
```python
LOGO_URL = "https://your-image-host.com/your-logo.png"
```

### Option 3: Use Local Web Server (For Testing)

If you want to test locally first:

1. Start the local web server:
   ```powershell
   python manage.py runserver 8000
   ```

2. Place logo in: `media/png/`

3. Use: `http://your-server:8000/media/png/promantis_logo.png`

## Icon (Optional)

You can also provide a custom icon for the application:
- Save as `prepared_images/promantis_icon.png`
- Recommended: Square image, 256x256 or 512x512 pixels
- Update in `trigger_builds.py`:
  ```python
  ICON_URL = "https://raw.githubusercontent.com/sgpromantis/rustdeskinstaller/master/prepared_images/promantis_icon.png"
  ```

## Quick Start

1. **Save the Promantis logo** from your attachment to:
   ```
   c:\Users\SebastianGorr\GitHub\rustdeskinstaller\prepared_images\promantis_logo.png
   ```

2. **Commit to GitHub**:
   ```powershell
   cd c:\Users\SebastianGorr\GitHub\rustdeskinstaller
   git add prepared_images/promantis_logo.png
   git commit -m "Add Promantis branding"
   git push
   ```

3. **Update trigger_builds.py** on line ~24:
   ```python
   LOGO_URL = "https://raw.githubusercontent.com/sgpromantis/rustdeskinstaller/master/prepared_images/promantis_logo.png"
   ```

4. **Run the build**:
   ```powershell
   python trigger_builds.py
   ```

## Current Configuration

The trigger script is already configured with:
- ✅ App Name: "Promantis Remote"
- ✅ Company: "Promantis"  
- ✅ Tagline: "professionell. progressiv. proaktiv."
- ⏳ Logo: Waiting for URL (currently set to empty)
- ⏳ Icon: Waiting for URL (currently set to empty)

Once you set the LOGO_URL, your custom RustDesk builds will include the Promantis logo!
