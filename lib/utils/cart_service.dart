import 'package:flutter/material.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  int hotQuantity = 0;
  int bbqQuantity = 0;
  int cheeseQuantity = 0;
  String? deliveryOption;

  double get totalPrice {
    double total = ((hotQuantity + bbqQuantity) * 5.0);
    total += (cheeseQuantity * 1.0);
    return total;
  }

  int get totalItems => hotQuantity + bbqQuantity + cheeseQuantity;

  void updateQuantity(String product, int qty) {
    if (product == 'HOT & SPICYYY') {
      hotQuantity = qty;
    } else if (product == 'SMOKY BBQ' || product == 'BBQ') {
      bbqQuantity = qty;
    } else if (product == 'CHEESE DIP' || product == 'Cheese Dip') {
      cheeseQuantity = qty;
    }
    notifyListeners();
  }

  void addToCart(String product, int qty) {
    if (product == 'HOT & SPICYYY') {
      hotQuantity += qty;
    } else if (product == 'SMOKY BBQ' || product == 'BBQ') {
      bbqQuantity += qty;
    } else if (product == 'CHEESE DIP' || product == 'Cheese Dip') {
      cheeseQuantity += qty;
    }
    notifyListeners();
  }

  void clear() {
    hotQuantity = 0;
    bbqQuantity = 0;
    cheeseQuantity = 0;
    deliveryOption = null;
    notifyListeners();
  }
}
