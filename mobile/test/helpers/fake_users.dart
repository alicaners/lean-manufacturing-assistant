import 'package:lean_assistant/features/admin/domain/managed_user.dart';
import 'package:lean_assistant/features/auth/domain/current_user.dart';

const operatorUser = ManagedUser(
  id: '01a177de-2504-7c0a-a458-d380e5314f01',
  userName: 'demo.operator',
  fullName: 'Demo Operatör',
  role: UserRole.operator,
  isActive: true,
  mustChangePassword: false,
);

const adminUser = ManagedUser(
  id: '01a177de-2504-7c0a-a458-d380e5314f02',
  userName: 'demo.admin',
  fullName: 'Demo Admin',
  role: UserRole.admin,
  isActive: true,
  mustChangePassword: false,
);

/// [operatorUser] as `/api/users` writes it.
const operatorUserJson =
    '{'
    '"id":"01a177de-2504-7c0a-a458-d380e5314f01",'
    '"userName":"demo.operator",'
    '"fullName":"Demo Operatör",'
    '"role":"Operator",'
    '"isActive":true,'
    '"mustChangePassword":false,'
    '"factoryId":"01a177de-2504-7c0a-a458-d380e5314faa",'
    '"lineId":null,'
    '"createdAt":"2026-10-20T08:00:00+00:00"'
    '}';
