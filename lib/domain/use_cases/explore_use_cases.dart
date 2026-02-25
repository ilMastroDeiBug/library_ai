import '../entities/category.dart';
import '../repositories/explore_repository.dart';
import '../../models/app_mode.dart';

class GetExploreCategoriesUseCase {
  final ExploreRepository repository;

  GetExploreCategoriesUseCase(this.repository);

  List<CategoryEntity> call(AppMode mode, {bool isTvSeries = false}) {
    return repository.getCategoriesByMode(mode, isTvSeries: isTvSeries);
  }
}
