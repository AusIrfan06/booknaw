import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String title;
  final double price;
  int quantity;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    this.quantity = 1,
    this.imageUrl,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'quantity': quantity,
    'image_url': imageUrl,
    'metadata': metadata,
  };
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  // Helper getters for legacy compatibility
  int get hotQuantity => _getQuantityFor('HOT & SPICYYY');
  int get bbqQuantity => _getQuantityFor('SMOKY BBQ') + _getQuantityFor('BBQ');
  int get cheeseQuantity => _getQuantityFor('CHEESE DIP') + _getQuantityFor('Cheese Dip');

  int _getQuantityFor(String title) {
    try {
      return _items.firstWhere((item) => item.title == title).quantity;
    } catch (_) {
      return 0;
    }
  }

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  void updateQuantity(String title, int qty) {
    final index = _items.indexWhere((item) => item.title == title);
    if (index != -1) {
      if (qty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = qty;
      }
      notifyListeners();
    }
  }

  void addToCart(String title, int qty, {String? id, double? price, String? imageUrl, Map<String, dynamic>? metadata}) {
    final index = _items.indexWhere((item) => item.title == title);
    if (index != -1) {
      _items[index].quantity += qty;
    } else {
      _items.add(CartItem(
        id: id ?? title,
        title: title,
        price: price ?? _getDefaultPrice(title),
        quantity: qty,
        imageUrl: imageUrl,
        metadata: metadata,
      ));
    }
    notifyListeners();
  }

  double _getDefaultPrice(String title) {
    if (title.toUpperCase().contains('HOT') || title.toUpperCase().contains('SPICY')) return 5.0;
    if (title.toUpperCase().contains('BBQ')) return 5.0;
    if (title.toUpperCase().contains('CHEESE')) return 1.0;
    return 0.0;
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
