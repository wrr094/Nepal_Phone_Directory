# Google Play Review Update

Use the following text for the **Full description** in Google Play Console. Replace the existing description completely.

## Full Description

Nepal HelpLine is an independent, offline-first public phone directory for Nepal. It is not a government app and does not represent, endorse, or act on behalf of any government entity.

The app helps users find public emergency and service contact information, including police, fire, ambulance, hospitals, utilities, tourism services, disaster contacts, municipalities, rural municipalities, ward offices, and other public services. For urgent emergencies, call national emergency numbers first.

Every directory record displayed in the current app release includes its original source URL. The complete record-level source register is publicly available here:
https://nepal-helpline-data.pages.dev/docs/contact_sources.csv

The complete source URL index is also available here:
https://nepal-helpline-data.pages.dev/docs/official_sources.md

Inside the app, each contact detail page displays its source name, source type, verification status, last checked date, and original source URL.

Nepal HelpLine works offline using bundled and cached directory data. It has no login requirement and no ads. Users can search contacts by organisation, category, province, district, palika, ward, address, phone number, and service. Users may optionally store personal emergency contacts only on their own device.

Disclaimer: Nepal HelpLine is an independent directory app. It is not affiliated with, endorsed by, or authorised by any government entity. Contact information is provided for public reference only and should be verified using the original source or the relevant official service. The app is not an emergency dispatch service or official government warning system.

## Required Play Console Changes

1. Open **Grow users > Store presence > Store listings > Default store listing group**.
2. Replace the existing Full description with the text above. Do not retain the old list of selected example sources.
3. Replace the Store listing app icon with [play_store_icon.png](assets/icon/play_store_icon.png). This file is generated directly from `assets/icon/app_icon2.jpg`, the same source used by Android and iOS launcher icons.
4. Submit the updated store listing together with Android version code 12.
5. Under **Policy and programs > App content > App access**, select **All functionality is available without any access restrictions**. Do not add review text there because the app has no login or restricted area.

## Optional Reviewer Note

Google Play does not show a review-note field for every release. If a **Notes for reviewers**, **Review notes**, or similar optional field appears while sending the update for review, paste the text below. If it does not appear, do not look for it elsewhere: the required disclosure is the Full description and the source links in the app.

If you submit a policy appeal instead of an update, paste this text into the appeal form's explanation of the changes made.

Nepal HelpLine is independent and not government-affiliated. The new release changes the installed app name to Nepal HelpLine consistently and regenerates all launcher icons from the same artwork provided for the Play Store listing. It also publishes a complete, record-level source register. Every directory record included in the current release is linked to its original `Data_Source_URL`; the register lists the record identifier, organisation, category, source name, source type, original URL, verification status, and last checked date.
