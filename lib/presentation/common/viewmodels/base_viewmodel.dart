import 'package:flutter/foundation.dart';

enum ViewState { initial, loading, loaded, error }

class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.initial;
  String _errorMessage = '';
  
  ViewState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;
  
  void setLoading() {
    _state = ViewState.loading;
    notifyListeners();
  }
  
  void setLoaded() {
    _state = ViewState.loaded;
    notifyListeners();
  }
  
  void setError(String message) {
    _state = ViewState.error;
    _errorMessage = message;
    notifyListeners();
  }
  
  void reset() {
    _state = ViewState.initial;
    _errorMessage = '';
    notifyListeners();
  }
  
  // Utility method for async operations
  Future<T?> runAsyncOperation<T>(Future<T> Function() operation) async {
    try {
      setLoading();
      final result = await operation();
      setLoaded();
      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }
} 