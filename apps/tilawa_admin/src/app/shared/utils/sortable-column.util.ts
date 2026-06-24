import { SortRequest } from '../../core/domain/entities/pagination.types';

/** Toggle direction when same field; otherwise sort desc on the new field. */
export function nextSortForField(
  current: SortRequest,
  field: string,
): SortRequest {
  if (current.field === field) {
    return {
      field,
      direction: current.direction === 'asc' ? 'desc' : 'asc',
    };
  }
  return { field, direction: 'desc' };
}
