class PersonalCategoryModel {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String iconName;
  final String colorHex;
  final bool isDefault;

  PersonalCategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorHex,
    this.isDefault = true,
  });

  factory PersonalCategoryModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PersonalCategoryModel(
      id: documentId,
      name: data['name'] ?? '',
      type: data['type'] ?? 'expense',
      iconName: data['iconName'] ?? 'category',
      colorHex: data['colorHex'] ?? '0xFF3B82F6',
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'iconName': iconName,
      'colorHex': colorHex,
      'isDefault': isDefault,
    };
  }

  static List<PersonalCategoryModel> defaultCategories() {
    return [
      // Income Categories (আয়ের ক্যাটাগরি)
      PersonalCategoryModel(id: 'cat_salary', name: 'বেতন (Salary)', type: 'income', iconName: 'payments', colorHex: '0xFF10B981'),
      PersonalCategoryModel(id: 'cat_freelance', name: 'ফ্রিল্যান্সিং', type: 'income', iconName: 'laptop_mac', colorHex: '0xFF3B82F6'),
      PersonalCategoryModel(id: 'cat_business', name: 'ব্যবসা', type: 'income', iconName: 'storefront', colorHex: '0xFF8B5CF6'),
      PersonalCategoryModel(id: 'cat_tuition', name: 'টিউশন', type: 'income', iconName: 'school', colorHex: '0xFFF59E0B'),
      PersonalCategoryModel(id: 'cat_allowance', name: 'পকেটমানি / হাতখরচ', type: 'income', iconName: 'card_giftcard', colorHex: '0xFFEC4899'),
      PersonalCategoryModel(id: 'cat_gift', name: 'উপহার', type: 'income', iconName: 'card_giftcard', colorHex: '0xFF06B6D4'),
      PersonalCategoryModel(id: 'cat_interest', name: 'মুনাফা / লভ্যাংশ', type: 'income', iconName: 'trending_up', colorHex: '0xFF14B8A6'),
      PersonalCategoryModel(id: 'cat_refund', name: 'ফেরত / রিফান্ড', type: 'income', iconName: 'replay', colorHex: '0xFF64748B'),
      PersonalCategoryModel(id: 'cat_other_income', name: 'অন্যান্য আয়', type: 'income', iconName: 'attach_money', colorHex: '0xFF6B7280'),

      // Expense Categories (খরচের ক্যাটাগরি)
      PersonalCategoryModel(id: 'cat_food', name: 'খাবার ও বাজার', type: 'expense', iconName: 'restaurant', colorHex: '0xFFEF4444'),
      PersonalCategoryModel(id: 'cat_rent', name: 'বাসা ভাড়া / মেস ভাড়া', type: 'expense', iconName: 'home', colorHex: '0xFFF97316'),
      PersonalCategoryModel(id: 'cat_utilities', name: 'বিদ্যুৎ ও গ্যাস বিল', type: 'expense', iconName: 'bolt', colorHex: '0xFFEAB308'),
      PersonalCategoryModel(id: 'cat_transport', name: 'যাতায়াত ও ভাড়া', type: 'expense', iconName: 'directions_bus', colorHex: '0xFF3B82F6'),
      PersonalCategoryModel(id: 'cat_education', name: 'পড়াশোনা ও বইপত্র', type: 'expense', iconName: 'menu_book', colorHex: '0xFF6366F1'),
      PersonalCategoryModel(id: 'cat_shopping', name: 'শপিং ও পোশাক', type: 'expense', iconName: 'shopping_bag', colorHex: '0xFFEC4899'),
      PersonalCategoryModel(id: 'cat_health', name: 'ওষুধ ও চিকিৎসা', type: 'expense', iconName: 'medical_services', colorHex: '0xFF10B981'),
      PersonalCategoryModel(id: 'cat_internet', name: 'ইন্টারনেট ও মোবাইল রিচার্জ', type: 'expense', iconName: 'wifi', colorHex: '0xFF06B6D4'),
      PersonalCategoryModel(id: 'cat_entertainment', name: 'বিনোদন ও ঘুরতে যাওয়া', type: 'expense', iconName: 'movie', colorHex: '0xFF8B5CF6'),
      PersonalCategoryModel(id: 'cat_personal', name: 'ব্যক্তিগত যত্ন', type: 'expense', iconName: 'face', colorHex: '0xFFD946EF'),
      PersonalCategoryModel(id: 'cat_family', name: 'পরিবারের খরচ', type: 'expense', iconName: 'family_restroom', colorHex: '0xFFF43F5E'),
      PersonalCategoryModel(id: 'cat_travel', name: 'ভ্রমণ', type: 'expense', iconName: 'flight', colorHex: '0xFF0284C7'),
      PersonalCategoryModel(id: 'cat_subscriptions', name: 'সাবস্ক্রিপশন', type: 'expense', iconName: 'subscriptions', colorHex: '0xFF7C3AED'),
      PersonalCategoryModel(id: 'cat_charity', name: 'দান-সদকা', type: 'expense', iconName: 'favorite', colorHex: '0xFFE11D48'),
      PersonalCategoryModel(id: 'cat_fees', name: 'ফি ও চার্জ', type: 'expense', iconName: 'receipt_long', colorHex: '0xFF475569'),
      PersonalCategoryModel(id: 'cat_other_expense', name: 'অন্যান্য খরচ', type: 'expense', iconName: 'more_horiz', colorHex: '0xFF64748B'),
    ];
  }
}
