/// Name of the Dio that sends token refreshes and retries.
/// It has no AuthInterceptor, so a refresh can never start another refresh.
const String refreshDioName = 'refreshDio';
