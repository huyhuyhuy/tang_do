# Reply Message for App Store Connect

**Subject:** Resolution for Rejected Issues – Version 1.0.4

---

Hello App Review Team,

Thank you for your feedback on our previous submission (Submission ID: e9a00f5d-d50f-4641-b5bc-232a991a46b4).

We have addressed all three issues mentioned in your review and resubmitted the app as version **1.0.4**. Please find the detailed updates below:

**1. Guideline 2.3.7 – Accurate Metadata**
   ✅ All pricing-related references have been removed from the app subtitle. The current subtitle is "Chia sẻ, tặng đồ" (Share, Give Items) which describes the app's functionality without any price references. Any pricing information is now included only in the app description as per guidelines.

**2. Guideline 2.1 – App Crash on iPad**
   ✅ The crash that occurred when tapping the avatar to take a photo on iPad Air (5th generation) has been fixed by:
   - Adding required camera and photo library usage descriptions in Info.plist
   - Improving error handling in the image picker with proper mounted state checks
   - Adding file validation before processing images
   - The app has been tested on iPad devices and works correctly.

**3. Guideline 5.1.1(v) – Account Deletion**
   ✅ A permanent account deletion feature has been implemented and is accessible as follows:
   - Navigate to **Profile screen** (bottom navigation bar)
   - Tap the **three-dot menu icon** (⋮) in the top right corner
   - Select **"Xóa tài khoản"** (Delete Account)
   - Confirm deletion through a two-step confirmation dialog
   
   This feature permanently deletes all user data including:
   - User account and profile information
   - All products posted by the user
   - All reviews and comments
   - Contact information
   - Uploaded avatar and product images
   
   The deletion is irreversible as required by Apple guidelines.

We appreciate your time and look forward to your review of the updated build. Please let us know if you need any additional information.

Best regards,
[Your Name/Team Name]

---

## Notes:
- Subject line is clear and mentions the version number
- References the submission ID for easy tracking
- Each issue is numbered and addressed clearly
- Account deletion location is accurate (Profile → Menu → Delete Account)
- Provides specific details about what was fixed
- Professional and respectful tone
- Ready to copy-paste into App Store Connect reply field
