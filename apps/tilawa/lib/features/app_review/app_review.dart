/// App review feature — provider-agnostic in-app review and store fallback.
library;

export 'domain/entities/app_review_prompt_moment.dart';
export 'domain/entities/app_review_signal.dart';
export 'domain/entities/app_review_trigger_policy.dart';
export 'domain/repositories/app_review_repository.dart';
export 'domain/services/app_review_flow_guard.dart';
export 'domain/services/app_review_trigger_manager.dart';
export 'domain/usecases/is_app_review_available_use_case.dart';
export 'domain/usecases/open_app_store_listing_use_case.dart';
export 'domain/usecases/request_app_review_use_case.dart';
export 'presentation/cubit/app_review_cubit.dart';
export 'presentation/cubit/app_review_state.dart';
export 'presentation/widgets/app_review_sacred_flow_scope.dart';
