class AppException implements Exception { final String code; final String message; const AppException(this.code,this.message); @override String toString()=>'$code: $message'; }
