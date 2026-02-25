import '../entities/category.dart';
import '../../models/app_mode.dart';

abstract class ExploreRepository {
  List<CategoryEntity> getCategoriesByMode(
    AppMode mode, {
    bool isTvSeries = false,
  });
}
