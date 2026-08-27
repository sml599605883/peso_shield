import '../data/repositories/app_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/certification_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/report_repository.dart';
import 'network/http_client.dart';

/// 统一的API服务类，提供所有业务接口的访问入口
class ApiService {
  ApiService(HttpClient client)
      : auth = AuthRepository(client),
        app = AppRepository(client),
        product = ProductRepository(client),
        certification = CertificationRepository(client),
        order = OrderRepository(client),
        report = ReportRepository(client);

  /// 用户认证相关接口
  final AuthRepository auth;

  /// App相关接口
  final AppRepository app;

  /// 产品相关接口
  final ProductRepository product;

  /// 认证项相关接口
  final CertificationRepository certification;

  /// 订单相关接口
  final OrderRepository order;

  /// 数据上报相关接口
  final ReportRepository report;
}
