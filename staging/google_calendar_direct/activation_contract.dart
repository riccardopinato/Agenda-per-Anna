// STAGING CONTRACT ONLY: never imported by production. This contains no tokens.
// The future activation layer MUST derive the flags from trusted OAuth,
// Google calendarList owner role, secured token store and explicit user choices.
enum GcalActivationBlocker {
  cloudConfiguration,
  googleScopes,
  googleIdentity,
  accountMismatch,
  destinationOwnership,
  secureTokenLifecycle,
  privacyExportReview,
  explicitPreviewConsent,
  androidWriterStillEnabled,
  historicalExportReview,
}

/// An ephemeral readiness snapshot. Never serialize it or treat these booleans
/// as evidence that OAuth, encryption or Google provider calls were tested.
class GcalActivationReview {
  final String appAccountId;
  final String authorizedGoogleSubject;
  final String confirmedGoogleSubject;
  final String selectedOwnedCalendarId;
  final bool calendarApiEnabled;
  final bool requiredScopesGranted;
  final bool calendarOwnerVerified;
  final bool secureTokenLifecycleVerified;
  final bool privacyExportReviewed;
  final bool exportPreviewConfirmed;
  final bool androidB3Disabled;
  final bool historicalAndroidExportsReviewed;

  const GcalActivationReview({
    required this.appAccountId,
    required this.authorizedGoogleSubject,
    required this.confirmedGoogleSubject,
    required this.selectedOwnedCalendarId,
    required this.calendarApiEnabled,
    required this.requiredScopesGranted,
    required this.calendarOwnerVerified,
    required this.secureTokenLifecycleVerified,
    required this.privacyExportReviewed,
    required this.exportPreviewConfirmed,
    required this.androidB3Disabled,
    required this.historicalAndroidExportsReviewed,
  });

  List<GcalActivationBlocker> blockersFor({
    required String currentAppAccountId,
    required String targetCalendarId,
  }) {
    final issues = <GcalActivationBlocker>[];
    if (!calendarApiEnabled) {
      issues.add(GcalActivationBlocker.cloudConfiguration);
    }
    if (!requiredScopesGranted) {
      issues.add(GcalActivationBlocker.googleScopes);
    }
    if (authorizedGoogleSubject.trim().isEmpty ||
        confirmedGoogleSubject.trim().isEmpty ||
        authorizedGoogleSubject != confirmedGoogleSubject) {
      issues.add(GcalActivationBlocker.googleIdentity);
    }
    if (appAccountId.trim().isEmpty ||
        currentAppAccountId.trim().isEmpty ||
        appAccountId != currentAppAccountId) {
      issues.add(GcalActivationBlocker.accountMismatch);
    }
    if (!calendarOwnerVerified ||
        selectedOwnedCalendarId.trim().isEmpty ||
        selectedOwnedCalendarId != targetCalendarId) {
      issues.add(GcalActivationBlocker.destinationOwnership);
    }
    if (!secureTokenLifecycleVerified) {
      issues.add(GcalActivationBlocker.secureTokenLifecycle);
    }
    if (!privacyExportReviewed) {
      issues.add(GcalActivationBlocker.privacyExportReview);
    }
    if (!exportPreviewConfirmed) {
      issues.add(GcalActivationBlocker.explicitPreviewConsent);
    }
    if (!androidB3Disabled) {
      issues.add(GcalActivationBlocker.androidWriterStillEnabled);
    }
    if (!historicalAndroidExportsReviewed) {
      issues.add(GcalActivationBlocker.historicalExportReview);
    }
    return List<GcalActivationBlocker>.unmodifiable(issues);
  }
}
