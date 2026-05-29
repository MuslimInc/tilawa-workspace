/// In-app product tour / coach-mark infrastructure.
library;

export 'domain/entities/tour_definition.dart';
export 'domain/entities/tour_step.dart';
export 'domain/entities/tour_content_align.dart';
export 'domain/entities/tour_target_shape.dart';
export 'presentation/overlay/tour_overlay_presenter.dart';
export 'domain/repositories/tour_repository.dart';
export 'domain/services/tour_catalog.dart';
export 'domain/services/tour_flow_guard.dart';
export 'presentation/services/tour_guide_service.dart';
export 'domain/services/tour_target_registry.dart';
export 'domain/usecases/complete_tour.dart';
export 'domain/usecases/is_tour_completed.dart';
export 'domain/usecases/reset_all_tours.dart';
export 'domain/usecases/reset_tour.dart';
export 'presentation/widgets/tour_sacred_flow_scope.dart';
export 'presentation/widgets/tour_target.dart';
export 'presentation/widgets/tour_tooltip_card.dart';
