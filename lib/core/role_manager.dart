class RoleManager {
  RoleManager._();

  static final Map<String, List<String>> menus = {
    'admin': [
      '/main',
      '/crm/dashboard',
      '/customers',
      '/crm/customers',
      '/add_customer',
      '/leads',
      '/leads/form',
      '/admin/users',
      '/admin/add-user',
    ],
    'sales': [
      '/main',
      '/crm/dashboard',
      '/customers',
      '/crm/customers',
      '/add_customer',
      '/leads',
      '/leads/form',
    ],
    'production': [
      '/main',
      '/crm/dashboard',
    ],
    'accounting': [
      '/main',
      '/crm/dashboard',
    ],
  };

  static bool canAccess(String role, String route) {
    final allowedRoutes = menus[role];
    if (allowedRoutes == null) {
      return false;
    }
    return allowedRoutes.contains(route);
  }
}
